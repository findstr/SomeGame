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

########################

roomlist_r 0x1201 {

}

roomlist_a 0x1202 {
	room {
		.id:integer 1
		.name:string 2
	}
	.list:room[] 1
}

roomcreate_r 0x1203 {
	.name:string 1
}

roomcreate_a 0x1204 {
	
}
]]
return M

