local M = [[
error_a 0x10000 {
	.cmd:integer 1
	.errno:integer 2
	.uid_:uinteger 3
}
auth_r 0x11000 {
	.account:string 1
	.passwd:string 2
	.server:integer 3
	.uid_:uinteger 4
}
auth_a 0x11001 {
	.uid:uinteger 1
	.gate:string 2
	.token:integer 3
	.uid_:uinteger 4
}
login_r 0x1102 {
	.uid:uinteger 1
	.token:integer 2
	.uid_:uinteger 3
}
login_a 0x1103 {
	
	.uid_:uinteger 1
}
kick_n 0x1104 {
	.errno:integer 1
	.uid_:uinteger 2
}
########################
roomlist_r 0x1201 {
	.uid_:uinteger 1
}
roomlist_a 0x1202 {
	room {
		.id:integer 1
		.name:string 2
		.owner:uinteger 3
	}
	.list:room[id] 1
	.uid_:uinteger 2
}
roomcreate_c 0x1203 {
	.name:string 1
	.uid:uinteger 2
	.gate:integer 3
	.uid_:uinteger 4
}
roomcreate_r 0x1204 {
	.name:string 1
	.uid_:uinteger 2
}
roomcreate_a 0x1205 {
	.id:integer 1
	.name:string 2
	.uid:uinteger 3
	.uid_:uinteger 4
}
roomenter_c 0x1206 {
	.id:integer 1
	.uid:uinteger 2
	.gate:integer 3
	.uid_:uinteger 4
}
roomenter_r 0x1207 {
	.id:integer 1
	.uid_:uinteger 2
}
roomenter_a 0x1208 {
	.id:integer 1
	.name:string 2
	.list:uinteger[] 3
	.uid_:uinteger 4
}
roomleave_r 0x120a {
	.uid_:uinteger 1
}
roomleave_a 0x120b {
	.id:integer 1
	.uid:uinteger 2
	.owner:uinteger 3
	.uid_:uinteger 4
}
roomplay_r 0x120d {
	.uid_:uinteger 1
}
roomplay_a 0x120e {
	.uid_:uinteger 1
}
roomplay_n 0x120f {
	.uids:uinteger[] 1
	.uid_:uinteger 2
}
battlenew_c 0x1300 {
	.uids:uinteger[] 1
	.uid_:uinteger 2
}
battlenew_a 0x1301 {
	.uid_:uinteger 1
}
battleready_c 0x1302 {
	.battle:integer 1
	.uids:integer[] 2
	.uid_:uinteger 3
}
battleready_a 0x1303 {
	.uid_:uinteger 1
}
battleenter_c 0x1304 {
	.uid:uinteger 1
	.gate:integer 2
	.uid_:uinteger 3
}
battleenter_a 0x1305 {
	.uid:uinteger 1
	.uid_:uinteger 2
}
battleleave_r 0x1308 {
	.uid_:uinteger 1
}
battleleave_a 0x1309 {
	.uid:integer 1
	.uid_:uinteger 2
}
vec3 {
	.x:float 1
	.y:float 2
	.z:float 3
	.uid_:uinteger 4
}
battlemove_r 0x130a {
	.pos:vec3 1
	.uid_:uinteger 2
}
battlemove_a 0x130b {
	.uid:integer 1
	.pos:vec3 2
	.uid_:uinteger 3
}
battleskill_r 0x130c {
	.skill:integer 1
	.uid_:uinteger 2
}
battleskill_a 0x130d {
	.uid:uinteger 1
	.skill:integer 2
	.uid_:uinteger 3
}
#----------cluster protocol----------

error 0x1000 {
	.errno:integer 1
}

ping_c 0x1001 {
	.txt:string 1
}

pong_a 0x1002 {
	.txt:string 1
}

handle_c 0x1003 {
	.type:string 1
	.list:string[] 2
}

handle_a 0x1004 {
	.list:string[] 1
}

gateonline_c 0x1005 {

}

gateonline_a 0x1006 {
	.uids:uinteger[] 1
}

gatekick_c 0x1007 {
	.uid:integer 1
}

gatekick_a 0x1008 {
	.result:integer 1
}

gatetoken_c 0x1009 {
	.uid:uinteger 1
}

gatetoken_a 0x100a {
	.token:integer 1
	.addr:string 2
}

logingate_c 0x100b {
	.uid:integer 1
	.slot:integer 2
}

logingate_a 0x100c {

}

forward_n 0x100d {
	.uid:integer 1
	.cmd:integer 2
	.dat:string 3
}

multicast_n 0x100e {
	.uids:integer[] 1
	.cmd:integer 2
	.dat:string 3
}

]]
return M

