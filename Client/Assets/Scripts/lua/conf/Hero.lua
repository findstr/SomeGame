local M = {
[1] = {ID=1,HeroID=10000,Level=1,HP=100,MP=100,HPR=13,MPR=14,PATK=10,PTH=0,PDEF=1000,MATK=5,MTH=10,MDEF=10,Speed=5,NormalSkill=1000,},
[2] = {ID=2,HeroID=10001,Level=1,HP=200,MP=200,HPR=13,MPR=14,PATK=5,PTH=1,PDEF=1000,MATK=5,MTH=10,MDEF=10,Speed=5,NormalSkill=1000,},

[10000] = nil,
[10001] = nil,
}

M[10000]={
	[1] = M[1],
}

M[10001]={
	[1] = M[2],
}
return M