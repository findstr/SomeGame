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
		.id:integer 1
		.name:string 2
		.owner:uinteger 3
	}
	.list:room[id] 1
}

roomcreate_c 0x1203 {
	.name:string 1
	.uid:uinteger 2
	.gate:integer 3
}

roomcreate_r 0x1204 {
	.name:string 1
}

roomcreate_a 0x1205 {
	.id:integer 1
	.name:string 2
	.uid:uinteger 3
}

roomenter_c 0x1206 {
	.id:integer 1
	.uid:uinteger 2
	.gate:integer 3
}

roomenter_r 0x1207 {
	.id:integer 1
}

roomenter_a 0x1208 {
	.id:integer 1
	.name:string 2
	.list:uinteger[] 3
}

roomleave_r 0x120a {

}

roomleave_a 0x120b {
	.id:integer 1
	.uid:uinteger 2
	.owner:uinteger 3
}

roomplay_r 0x120d {

}

roomplay_a 0x120e {

}

roomplay_n 0x120f {
	.uids:uinteger[] 1
}

battlenew_c 0x1300 {
	.uids:uinteger[] 1
}

battlenew_a 0x1301 {

}

battleready_c 0x1302 {
	.battle:integer 1
	.uids:integer[] 2
}

battleready_a 0x1303 {

}

battleenter_c 0x1304 {
	.uid:uinteger 1
	.gate:integer 2
}

battleenter_a 0x1305 {
	.uid:uinteger 1
}

battleleave_r 0x1308 {

}

battleleave_a 0x1309 {
	.uid:integer 1
}

vec3 {
	.x:float 1
	.y:float 2
	.z:float 3
}

battlemove_r 0x130a {
	.pos:vec3 1
}

battlemove_a 0x130b {
	.uid:integer 1
	.pos:vec3 2
}

battleskill_r 0x130c {
	.skill:integer 1
}

battleskill_a 0x130d {
	.uid:uinteger 1
	.skill:integer 2
}

]]
return M

