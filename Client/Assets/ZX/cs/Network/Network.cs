using System;
using System.Collections.Generic;
using UnityEngine;
using zprotobuf;

namespace ZX { 

public class Network {
	//delegate
	public delegate void event_cb_t();
	public delegate void msg_cb_t(iwirep b);
	//socket
	private NetSocket socket = new NetSocket();
	private byte[] buffer = new byte[8];
	private byte[] cmd_buf = new byte[4];
	private short length_val = 0;
	//protocol
	private Dictionary<int, iwirep> protocol_obj = new Dictionary<int, iwirep>();
	//event
	private int socket_status = NetSocket.CLOSE;
	private event_cb_t event_connect = null;
	private event_cb_t event_close = null;
	private msg_cb_t event_msg = null;
	private string connect_addr;
	private int connect_port;

	public void Close() {
		length_val = 0;
		socket.Close();
		socket_status = socket.Status;
		Debug.Log("[NetProtocol] Close");
		return ;
	}

	public void Connect(string addr, int port, event_cb_t connect, event_cb_t close, msg_cb_t msg) {
		Close();
		Debug.Log("Connect:" + addr + ":" + port);
		connect_addr = addr;
		connect_port = port;
		socket.Connect(addr, port);
		socket_status = socket.Status;
		event_connect = connect;
		event_close = close;
		event_msg = msg;
	}

	public void Event(event_cb_t open, event_cb_t close) {
		event_connect = open;
		event_close = close;
	}

	public void Reconnect() {
		if (socket.Status == NetSocket.CONNECTED)
			return ;
		socket.Connect(connect_addr, connect_port);
		socket_status = socket.Status;
	}

	public bool isConnected() {
		return socket.Status == NetSocket.CONNECTED;
	}

	public bool Send(iwirep obj) {
		if (!isConnected()) {
			Debug.Log("[NetProtocol] Send:" + obj._name() + " disconnect" + socket.Status);
			return false;
		}
		int cmd = obj._tag();
		byte[] dat = null;
		obj._serialize(out dat);
		short len = (short)(4 + dat.Length);
		int need = len + 2;
		byte[] buffer = new byte[need];
		len = System.Net.IPAddress.HostToNetworkOrder(len);
		BitConverter.GetBytes(len).CopyTo(buffer, 0);
		dat.CopyTo(buffer, 2);
		BitConverter.GetBytes(cmd).CopyTo(buffer, 2 + dat.Length);
		socket.Send(buffer);
		return true;
	}

	public void Register(iwirep obj) {
		int cmd = obj._tag();
		Debug.Log("[NetProtocol] Register:" + obj._name() + " tag:" + cmd);
		if (protocol_obj.ContainsKey(cmd)) {
			Debug.Assert(protocol_obj[cmd]._tag() == obj._tag());
			return;
		}
		protocol_obj[cmd] = obj;
		return ;
	}

	public void Update() {
		if (socket_status == NetSocket.CLOSE)
			return ;
		switch (socket_status) {
		case NetSocket.CONNECTING:
		case NetSocket.DISCONNECT:
			if (socket.Status == NetSocket.CONNECTED) {
				socket_status = NetSocket.CONNECTED;
				if (event_connect != null) {
					event_connect();
					event_connect = null;
				}
			}
			break;
		}
		if (socket.Length < 2) {
			if (socket.Status == NetSocket.DISCONNECT) {
				if (event_close != null)
					event_close();
				socket_status = NetSocket.DISCONNECT;
				Debug.Log("[NetProtocol] Reconnect addr " + connect_addr + ":" + connect_port);
				socket.Connect(connect_addr, connect_port);
			}
			return ;
		}
		if (length_val == 0) {
			socket.Read(buffer, 2);
			length_val = BitConverter.ToInt16(buffer, 0);
			length_val = System.Net.IPAddress.NetworkToHostOrder(length_val);
		}
		if (socket.Length < length_val)
			return ;
		if (buffer.Length < length_val)
			buffer = new byte[length_val];
		Debug.Assert(length_val > 4);
		length_val -= sizeof(int);
		socket.Read(buffer, length_val);
		socket.Read(cmd_buf, 4);
		int cmd = BitConverter.ToInt32(cmd_buf, 0);
		if (!protocol_obj.ContainsKey(cmd)) {
			Debug.Log("[NetProtocol] can't has handler of cmd[" + cmd + "]");
			return ;
		}
		iwirep obj = protocol_obj[cmd];
		int err = obj._parse(buffer, length_val);
		length_val = 0;
		if (err < 0)
			return ;
		if (event_msg != null)
				event_msg(obj);
		return ;
	}
}

}

