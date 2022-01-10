local M = [[
error_a 0x10000 {
	.cmd:integer 1
	.errno:integer 2
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
}
login_r 0x1102 {
	.uid:uinteger 1
	.token:integer 2
	.uid_:uinteger 3
}
login_a 0x1103 {
	.roomid:integer 1
	.roomstate:integer 2
	.members:uinteger[] 3
}
kick_n 0x1104 {
	.errno:integer 1
}
########################
roomlist_r 0x1201 {
	.uid_:uinteger 2
}
roomlist_a 0x1202 {
	room {
		.battle:integer 1
		.roomid:integer 2
		.name:string 3
		.owner:uinteger 4
	}
	.list:room[] 1
}
roomcreate_c 0x1203 {
	.name:string 1
	.uid:uinteger 2
	.gate:integer 3
}
roomcreate_r 0x1204 {
	.name:string 1
	.uid_:uinteger 2
}
roomcreate_a 0x1205 {
	.roomid:integer 1
	.name:string 2
}
roomenter_c 0x1206 {
	.roomid:integer 1
	.uid:uinteger 2
	.gate:integer 3
}
roomenter_r 0x1207 {
	.roomid:integer 1
	.battle:integer 2
	.side:boolean 3 #false -> red, true ->blue
	.uid_:uinteger 4
}
roomenter_a 0x1208 {
	.roomid:integer 1
	.name:string 2
	.list:uinteger[] 3
}
roomenter_n 0x1209 {
	.roomid:integer 1
	.uid:integer 2
}
roomleave_r 0x120a {
	.uid_:uinteger 3
}
roomleave_a 0x120b {
	.roomid:integer 1
	.uid:uinteger 2
}
roomplay_r 0x120c {
	.uid_:uinteger 3
}
roomplay_a 0x120d {
}
roombattle_n 0x120e {
	.uids:uinteger[] 1
}
roomshow_c 0x120f {
	.battle:integer 1
	.roomid:integer 2
	.name:string 3
	.owner:uinteger 4
}
roomshow_a 0x1210 {
}
roomhide_c 0x1211 {
	.battle:integer 1
	.roomid:integer 2
}
roomhide_a 0x1212 {
}
battlejoin_c 0x1213 {
	.battle:integer 1
	.uid:uinteger 2
}
battlejoin_a 0x1214 {
}
battleleave_c 0x1215 {
	.uid:uinteger 1
}
battleleave_a 0x1216 {
}
whichbattle_c 0x1217 {
	.uid:uinteger 1
}
whichbattle_a 0x1218 {
	.battle:integer 1
}
roomrestore_c 0x1219 {
	.uid:integer 1
}
roomrestore_a 0x121a {
	.roomid:integer 1
	.roomstate:integer 2
	.members:uinteger[] 3
}
battleplayers_c 0x121b {
}
battleplayers_a 0x121c {
	.uids:integer[] 1
}
vec3 {
	.x:float 1
	.y:float 2
	.z:float 3
}
battlemove_r 0x1301 {
	.pos:vec3 1
	.uid_:uinteger 2
}
battlemove_a 0x1302 {
	.uid:integer 1
	.pos:vec3 2
}
battleskill_r 0x1304 {
	.skill:integer 1
	.uid_:uinteger 2
}
battleskill_a 0x1305 {
	.uid:uinteger 1
	.skill:integer 2
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

