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
		.roomid:integer 1
		.name:string 2
		.red:integer 3
		.blue:integer 4
	}
	.list:room[] 1
}
battlecreate_r 0x1204 {
	.name:string 1
	.uid_:uinteger 2
}
battlecreate_a 0x1205 {
	.roomid:integer 1
	.name:string 2
}
battleenter_c 0x1206 {
	.roomid:integer 1
	.uid:uinteger 2
	.gate:integer 3
	.side:byte 4
}
battleenter_r 0x1207 {
	.roomid:integer 1
	.side:byte 2 #0 -> left, 1 -> right
	.uid_:uinteger 3
}
battleenter_a 0x1208 {
	.roomid:integer 1
	.name:string 2
	.redcount:byte 3
	.uidlist:integer[] 4
}
battleenter_n 0x1209 {
	.roomid:integer 1
	.uid:integer 2
	.side:byte 3
}
battleleave_r 0x120a {
	.uid_:uinteger 4
}
battleleave_a 0x120b {
	.roomid:integer 1
	.uid:uinteger 2
}
battleready_r 0x120c {
	.uid_:uinteger 3
}
battleready_a 0x120d {
	.current:integer 1
	.total:integer 2
}
battlestart_n 0x120e {
	player {
		.uid:uinteger 1
		.heroid:integer 2
		.px:float 3
		.pz:float 4
		.side:integer 5
		.hp:integer 6
		.mp:integer 7
		.hpmax:integer 8
		.mpmax:integer 9
		.speed:integer 10
	}
	.entities:player[uid] 1
}
battlemove_r 0x1301 {
	.px:float 1
	.pz:float 2
	.vx:float 3
	.vz:float 4
	.uid_:uinteger 5
}
battlemove_a 0x1302 {
	.px:float 1
	.pz:float 2
	.vx:float 3
	.vz:float 4
	.uid:uinteger 5
}
battleskill_r 0x1304 {
	.skill:integer 1
	.target:uinteger 2
	.uid_:uinteger 3
}
battleskill_a 0x1305 {
	.uid:uinteger 1
	.skill:integer 2
	.mp:integer 3
	.target:uinteger 4
	.targethp:integer 5
}
battleover_n 0x1306 {
	.winner:byte 1
}
battleclose_n 0x1307 {
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

battlerestore_c 0x100f {
	.uid:integer 1
}

battlerestore_a 0x1010 {
}

battlecreate_c 0x1011 {
	.name:string 1
	.uid:uinteger 2
	.gate:integer 3
}


battleplayers_c 0x1013 {
}

battleplayers_a 0x1014 {
	room {
		.name:string 1
		.roomid:integer 2
		.redcount:integer 3
		.uidlist:uinteger[] 4
	}
	.rooms:room[] 1
}

battlejoin_c 0x1015 {
	.roomid:integer 1
	.uid:uinteger 2
}

battlejoin_a 0x1016 {

}

whichroom_c 0x1018 {
	.uid:uinteger 1
}

whichroom_a 0x1019 {
	.roomid:integer 1
}

roomcreate_c 0x101a {
	.roomid:integer 1
	.name:string 2
	.owner:uinteger 3
}

roomcreate_a 0x101b {

}

roomhide_c 0x101c {
	.roomid:integer 1
}

roomhide_a 0x101d {

}

roomclear_c 0x101e {
	.roomid:integer 1
	.uidlist:uinteger[] 2
}

roomclear_a 0x101f {
}

roomjoin_c 0x1020 {
	.roomid:integer 1
	.uid:uinteger 3
	.side:byte 4
}

roomjoin_a 0x1021 {
	.roomid:integer 1
	.battle:integer 2
	.uid:uinteger 3
	.side:byte 4
}

roomleave_c 0x1022 {
	.uid:uinteger 1
	.side:byte 2
}

roomleave_a 0x1023 {
}

]]
return M

