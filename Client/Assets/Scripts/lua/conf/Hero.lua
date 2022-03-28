local M = {
[1] = {ID = 1,HeroID = 10000,Level = 1,Prefab = "Character/Darius/Darius.prefab",HP = 24,MP = 100,HPR = 13,MPR = 14,PATK = 10,PTH = 0,PDEF = 1000,MATK = 5,MTH = 10,MDEF = 10,SPEED = 5,Skill = {{1000,1,},{1002,0,},{1003,0,},{1004,0,},{1005,1,},{1006,1,},},},
[2] = {ID = 2,HeroID = 10001,Level = 1,Prefab = "Character/Darius/Darius.prefab",HP = 24,MP = 200,HPR = 13,MPR = 14,PATK = 5,PTH = 1,PDEF = 1000,MATK = 5,MTH = 10,MDEF = 10,SPEED = 5,Skill = {{1001,1,},},},
[3] = {ID = 3,HeroID = 10002,Level = 1,Prefab = "Character/Darius/Darius.prefab",HP = 24,MP = 200,HPR = 13,MPR = 14,PATK = 5,PTH = 1,PDEF = 1000,MATK = 5,MTH = 10,MDEF = 10,SPEED = 5,Skill = {{1001,1,},},},
[4] = {ID = 4,HeroID = 10003,Level = 1,Prefab = "Character/Darius/Darius.prefab",HP = 24,MP = 200,HPR = 13,MPR = 14,PATK = 5,PTH = 1,PDEF = 1000,MATK = 5,MTH = 10,MDEF = 10,SPEED = 5,Skill = {{1001,1,},},},

[10000] = nil,
[10001] = nil,
[10002] = nil,
[10003] = nil,
}

M[10000]={
	[1] = M[1],
}

M[10001]={
	[1] = M[2],
}

M[10002]={
	[1] = M[3],
}

M[10003]={
	[1] = M[4],
}
return M
