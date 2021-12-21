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
########################
roomlist_r 0x1201 {
	.uid_:uinteger 1
}
roomlist_a 0x1202 {
	room {
		.id:integer 1
		.name:string 2
	}
	.list:room[] 1
	.uid_:uinteger 2
}
roomcreate_r 0x1203 {
	.name:string 1
	.uid_:uinteger 2
}
roomcreate_a 0x1204 {
	
	.uid_:uinteger 1
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


]]
return M

