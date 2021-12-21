#ifndef LUA_LIB
#define LUA_LIB
#endif
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#if defined _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#undef errno
#undef EAGAIN
#undef EINPROGRESS
#define EAGAIN 10035
#define EINPROGRESS 10035
#define errno WSAGetLastError()
#define close closesocket
#define write(fd, buf, size) send(fd, buf, size, 0)
#define read(fd, buf, size) recv(fd, buf, size, 0)
#define seterrno(n)	WSASetLastError((n))
#else
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <sys/types.h>          /* See NOTES */
#include <sys/time.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fcntl.h>
#define seterrno(n)	errno = (n)
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#if LUA_VERSION_NUM < 502

#ifndef luaL_checkversion
#define luaL_checkversion(L)	(void)0
#endif

#ifndef luaL_newlib
#define luaL_newlib(L,l)  \
	(luaL_checkversion(L),\
	lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1),\
	luaL_setfuncs(L,l,0))
/*
** Copy from lua5.3
** set functions from list 'l' into table at top - 'nup'; each
** function gets the 'nup' elements at the top as upvalues.
** Returns with only the table at the stack.
*/
LUALIB_API void
luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
	luaL_checkstack(L, nup, "too many upvalues");
	/* fill the table with given functions */
	for (; l->name != NULL; l++) {
		int i;
		for (i = 0; i < nup; i++)  /* copy upvalues to the top */
			lua_pushvalue(L, -nup);
		lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
		lua_setfield(L, -(nup + 2), l->name);
	}
	lua_pop(L, nup);  /* remove upvalues */
}
#endif
#endif


#if EAGAIN == EWOULDBLOCK
#define ETRYAGAIN EAGAIN
#else
#define ETRYAGAIN EAGAIN: case EWOULDBLOCK
#endif

struct sock {
	int fd;
	int sz;
	int cap;
	uint8_t *buf;
};

typedef uint32_t cmd_t;
typedef uint32_t session_t;

static struct addrinfo *
getsockaddr(const char *ip, const char *port)
{
	int err;
	struct addrinfo hints, *res;
	memset(&hints, 0, sizeof(hints));
	hints.ai_flags = AI_NUMERICHOST;
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;
	if ((err = getaddrinfo(ip, port, &hints, &res))) {
		fprintf(stderr, "[socket] getsockaddr:%s\n", strerror(errno));
		return NULL;
	}
	return res;
}

static void
nonblock(int fd)
{
#if defined _WIN32
	u_long iMode = 1;
	int iResult = ioctlsocket(fd, FIONBIO, &iMode);
	if (iResult != NO_ERROR)
		fprintf(stderr, "ioctlsocket failed with error: %ld\n", iResult);
#else
	int err;
	int flag;
	flag = fcntl(fd, F_GETFL, 0);
	if (flag < 0) {
		fprintf(stderr, "[socket] nonblock F_GETFL:%s\n", strerror(errno));
		return ;
	}
	flag |= O_NONBLOCK;
	err = fcntl(fd, F_SETFL, flag);
	if (err < 0) {
		fprintf(stderr, "[socket] nonblock F_SETFL:%s\n", strerror(errno));
		return ;
	}
#endif
	return ;
}

static int
block_connect(int fd, struct addrinfo *addr, int timeout)
{
	int ret, err;
	fd_set set;
	struct timeval tv = {0};
	socklen_t errlen = sizeof(err);
	nonblock(fd);
	err = connect(fd, addr->ai_addr, addr->ai_addrlen);
	if (err >= 0)
		return 0;
	if (errno != EINPROGRESS)
		return -1;
	FD_ZERO(&set);
	FD_SET(fd, &set);
	tv.tv_sec = timeout;
	err = select(fd+1, NULL, &set, NULL, &tv);
	if (err < 0) {
		return -1;
	} else if (err == 0) {
		seterrno(ETIMEDOUT);
		return -1;
	}
	ret = getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &errlen);
	if (ret < 0)
		return -1;
	if (err != 0) {
		seterrno(err);
		return -1;
	}
	return 0;
}

static int
lclose(lua_State *L)
{
	struct sock *s;
	s = (struct sock *)luaL_checkudata(L, 1, "sock");
	if (s->fd >= 0)
		close(s->fd);
	if (s->buf != NULL)
		free(s->buf);
	s->fd = -1;
	s->sz = s->cap = 0;
	s->buf = NULL;
	return 0;
}

static int
nodelay(struct sock *s, int enable)
{
	int on = enable;
	return setsockopt(s->fd, IPPROTO_TCP, TCP_NODELAY, &on, sizeof(on));
}

static int
lnodelay(lua_State *L)
{
	int err;
	struct sock *s = NULL;
	s = (struct sock *)luaL_checkudata(L, 1, "sock");
	if (s->fd < 0)
		return luaL_error(L, "socket fd is invalid");
	err = nodelay(s, 1);
	if (err < 0)
		lua_pushstring(L, strerror(errno));
	else
		lua_pushnil(L);
	return 1;
}

static int
lconnect(lua_State *L)
{
	int fd = -1;
	const char *ip;
	struct sock *s = NULL;
	struct addrinfo *addr;
	int type = lua_type(L, 1);
	if (type == LUA_TSTRING) {
		ip = lua_tostring(L, 1);
	} else if (type == LUA_TNUMBER) {
		struct in_addr addr;
		addr.s_addr = (unsigned int)lua_tointeger(L, 1);
		ip = inet_ntoa(addr);
	}
	const char *port = luaL_checkstring(L, 2);
	addr = getsockaddr(ip, port);
	if (addr == NULL)
		goto fail;
	fd = socket(addr->ai_family, SOCK_STREAM, 0);
	if (fd < 0)
		goto fail;
	int timeout = (int)luaL_optinteger(L, 3, 1);
	if (block_connect(fd, addr, timeout))
		goto fail;
	s = (struct sock *)lua_newuserdata(L, sizeof(*s));
	if (luaL_newmetatable(L, "sock")) {
		lua_pushcfunction(L, lclose);
		lua_setfield(L, -2, "__gc");
	}
	lua_setmetatable(L, -2);
	s->fd = fd;
	s->sz = 0;
	s->cap = 256;
	s->buf = (uint8_t *)malloc(s->cap);
	return 1;
fail:
	if (addr != NULL)
		freeaddrinfo(addr);
	if (fd >= 0)
		close(fd);
	lua_pushnil(L);
	lua_pushinteger(L, errno);
	return 2;
}

static int
lsend(lua_State *L)
{
	int ret = 0;
	char *ptr, *buf;
	size_t bodysz;
	int cmd, left;
	struct sock *s;
	const char *body;
	char buff[256];
	s = (struct sock *)luaL_checkudata(L, 1, "sock");
	cmd = (int)luaL_checkinteger(L, 2);
	if (lua_isnil(L, 3)) {
		body = NULL;
		bodysz = 0;
	} else {
		body = luaL_checklstring(L, 3, &bodysz);
	}
	if (bodysz == 0 || (bodysz + 2 + 4) < sizeof(buff)) {
		buf = NULL;
		ptr = buff;
	} else {
		buf = ptr = malloc(bodysz + 2 + 4);
	}
	int body_and_cmd = (int)bodysz + 4;
    ptr[0] = (body_and_cmd >> 8) & 0xff;
    ptr[1] = (body_and_cmd & 0xff);
	memcpy(&ptr[2], body, bodysz);
    ptr[bodysz + 2 + 0] = (cmd >> 0) & 0xff;
    ptr[bodysz + 2 + 1] = (cmd >> 8) & 0xff;
    ptr[bodysz + 2 + 2] = (cmd >> 16) & 0xff;
    ptr[bodysz + 2 + 3] = (cmd >> 24) & 0xff;
    left = body_and_cmd + 2;
	while (left > 0) {
		int n;
		n = (int)write(s->fd, ptr, left);
		if (n < 0) {
			switch (errno) {
			case EINTR:
			case ETRYAGAIN:
				continue;
			default:
				ret = errno;
				goto out;
			}
		}
		ptr += n;
		left -= n;
	}
out:
	if (buf != NULL)
		free(buf);
	lua_pushinteger(L, ret);
	return 1;
}

static int
trypull(lua_State *L, struct sock *s)
{
	if (s->sz >= 2 ) {
        int size = ((int)s->buf[0] >> 8) | s->buf[1];
		if (s->sz >= (size + 2)) {
			int body = size - 4;
            int cmd = 	((unsigned int)s->buf[body + 2 + 0]) << 0 |
						((unsigned int)s->buf[body + 2 + 1]) << 8 |
						((unsigned int)s->buf[body + 2 + 2]) << 16|
						((unsigned int)s->buf[body + 2 + 3]) << 24;
			lua_pushinteger(L, cmd);
			lua_pushlstring(L, (char *)&s->buf[2], body);
			s->sz -= size + 2;
			memmove(s->buf, &s->buf[size + 2], s->sz);
			return 2;
		}
	}
	return 0;
}

static int
lrecv(lua_State *L)
{
	int p, n, retry;
	struct sock *s;
	s = (struct sock *)luaL_checkudata(L, 1, "sock");
	p = trypull(L, s);
	if (p > 0)
		return p;
	retry = 0;
	n = (int)read(s->fd, &s->buf[s->sz], s->cap - s->sz);
	if (n > 0) { //read success
		s->sz += n;
		p = trypull(L, s);
		if (p > 0)
			return p;
		if (s->sz >= s->cap) {
			s->cap *= 2;
			s->buf = (uint8_t *)realloc(s->buf, s->cap);
		}
		retry = 1;
	} else if (n < 0) { //retry
		switch (errno) {
		case EINTR:
		case ETRYAGAIN:
			retry = 1;
			break;
		default:
			break;
		}
	}
	lua_pushnil(L);
	if (retry == 1)
		lua_pushnil(L);
	else
		lua_pushinteger(L, errno);
	return 2;
}

LUALIB_API int
luaopen_socket_c(lua_State *L)
{
	luaL_Reg tbl[] = {
		{"connect", lconnect},
		{"close", lclose},
		{"send", lsend},
		{"recv", lrecv},
		{"nodelay", lnodelay},
		{NULL, NULL},
	};
	luaL_checkversion(L);
	luaL_newlib(L, tbl);
#if defined _WIN32
	{
		WSADATA wsaData;
		int iResult;
		iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
		if (iResult != NO_ERROR)
			fprintf(stderr, "WSAStartup failed: %d\n", iResult);
	}
#else
	signal(SIGPIPE, SIG_IGN);
#endif
	return 1;
}


