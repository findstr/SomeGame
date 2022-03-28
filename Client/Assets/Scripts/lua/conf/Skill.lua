local lan = require (ZX_LAN .. ".Skill")
local M = {
[1] = {ID = 1,SkillID = 1000,Level = 1,Name = nil,Sing = 0,CD = 1,Distance = 5,PATK = 10,PTH = 5,Icon = "Skills/Darius/normal.png",},
[2] = {ID = 2,SkillID = 1001,Level = 1,Name = nil,Sing = 0,CD = 1,Distance = 5,PATK = 5,PTH = 6,Icon = "Skills/Darius/normal.png",},
[3] = {ID = 3,SkillID = 1002,Level = 1,Name = lan.Name_6,Sing = 0,CD = 12,Distance = 5,PATK = 10,PTH = 5,Icon = "Skills/Darius/skill2.png",},
[4] = {ID = 4,SkillID = 1003,Level = 1,Name = lan.Name_7,Sing = 0,CD = 12,Distance = 5,PATK = 10,PTH = 5,Icon = "Skills/Darius/skill3.png",},
[5] = {ID = 5,SkillID = 1004,Level = 1,Name = lan.Name_8,Sing = 0,CD = 10,Distance = 5,PATK = 10,PTH = 5,Icon = "Skills/Darius/skill1.png",},
[6] = {ID = 6,SkillID = 1005,Level = 1,Name = lan.Name_9,Sing = 0,CD = 60,Distance = 5,PATK = 10,PTH = 5,Icon = "Skills/Darius/recover.png",},
[7] = {ID = 7,SkillID = 1006,Level = 1,Name = lan.Name_10,Sing = 3,CD = 0,Distance = 5,PATK = 10,PTH = 5,Icon = "Skills/Darius/home.png",},

[1000] = nil,
[1001] = nil,
[1002] = nil,
[1003] = nil,
[1004] = nil,
[1005] = nil,
[1006] = nil,
}

M[1000]={
	[1] = M[1],
}

M[1001]={
	[1] = M[2],
}

M[1002]={
	[1] = M[3],
}

M[1003]={
	[1] = M[4],
}

M[1004]={
	[1] = M[5],
}

M[1005]={
	[1] = M[6],
}

M[1006]={
	[1] = M[7],
}
return M
