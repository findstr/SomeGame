local zproto = require "zproto"
local M = zproto:parse [[
error_a 0x10000 {
	.cmd:integer 1
	.errno:integer 2
}


auth_r 0x11000 {
	.account:string 1
	.passwd:string 2
	.server:integer 3
}

auth_a 0x11001 {
	.uid:uinteger 1
	.gate:string 2
	.token:integer 3
}

login_r 0x1102 {
	.uid:uinteger 1
	.token:integer 2
}

login_a 0x1103 {
}

kick_n 0x1104 {
	.errno:integer 1
}

########################

roomlist_r 0x1201 {

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

}

battleleave_a 0x120b {
	.roomid:integer 1
	.uid:uinteger 2
}

battleready_r 0x120c {

}

battleready_a 0x120d {
	.current:integer 1
	.total:integer 2
}

battlestart_n 0x120e {
	player {
		skill {
			.skillid:integer 1
			.level:integer 2
			.cd:float 3
			.sing:float 4
		}
		.uid:uinteger 1
		.heroid:integer 2
		.level:integer 3
		.name:string 4
		.px:float 5
		.pz:float 6
		.side:integer 7
		.hp:integer 8
		.mp:integer 9
		.hpmax:integer 10
		.mpmax:integer 11
		.speed:integer 12
		.skills:skill[] 13
	}
	.roomtime:float 1
	.entities:player[uid] 2
	.redcrystal:player 3
	.bluecrystal:player 4
	.redup:player[] 5
	.redmiddle:player[] 6
	.reddown:player[] 7
	.blueup:player[] 8
	.bluemiddle:player[] 9
	.bluedown:player[] 10
}

battlemove_r 0x1301 {
	.px:float 1
	.pz:float 2
	.vx:float 3
	.vz:float 4
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

]]
return M

