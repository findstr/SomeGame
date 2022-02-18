local M = {
[1] = {ID = 1,SkillID = 1000,Level = 1,PATK = 10,PTH = 5,Distance = 5,CD = 1000,},
[2] = {ID = 2,SkillID = 1001,Level = 1,PATK = 5,PTH = 6,Distance = 5,CD = 1000,},

[1000] = nil,
[1001] = nil,
}

M[1000]={
	[1] = M[1],
}

M[1001]={
	[1] = M[2],
}
return M
