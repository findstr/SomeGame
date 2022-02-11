local M = {
[1] = {
	id = 1,
	["type"] = "condition",
	["name"] = "bt_is_hp_less",
	["properties"] = {
		["hp"] = 50,
	},
	success = nil,
	failure = nil,
},
[2] = {
	id = 2,
	["type"] = "action",
	["name"] = "bt_gohome",
	failure = nil,
},
[3] = {
	id = 3,
	["type"] = "condition",
	["name"] = "bt_is_lock_target",
	["properties"] = {
		["range"] = 10,
	},
	success = nil,
	failure = nil,
},
[4] = {
	id = 4,
	["type"] = "action",
	["name"] = "bt_atk_target",
	success = nil,
	failure = nil,
},
[5] = {
	id = 5,
	["type"] = "action",
	["name"] = "bt_stop_follow",
	failure = nil,
},
[6] = {
	id = 6,
	["type"] = "action",
	["name"] = "bt_follow_target",
	failure = nil,
},
[7] = {
	id = 7,
	["type"] = "action",
	["name"] = "bt_lock_nearest",
	["properties"] = {
		["range"] = 10,
	},
},
}
M[1].success = M[2]
M[1].failure = M[3]
M[2].failure = M[3]
M[3].success = M[4]
M[3].failure = M[7]
M[4].success = M[5]
M[4].failure = M[6]
M[5].failure = M[6]
M[6].failure = M[7]
return M[1]
