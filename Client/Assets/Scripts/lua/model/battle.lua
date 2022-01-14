local socket = require "zx.socket"
local core = require "zx.core"
local proto = require "proto"
local router = require "router"
local server = require "server"
local tonumber = tonumber

local M = {}
local players = {}
local character
local root = CS.UnityEngine.GameObject.Find("Player");
local input = CS.UnityEngine.GameObject.Find("Input"):GetComponent(typeof(CS.InputManager))

local INPUT_MOUSE<const> = 1
local INPUT_KEY<const> = 2
local SKILL_ATK1<const> = CS.Character.SKILL.ATK1
local SKILL_ATK2<const> = CS.Character.SKILL.ATK2

print("hello")

local move = {uid = uid, pos = {x = nil, y = nil, z = nil}}

local function input_process()
	local t = input.type
	if t == INPUT_MOUSE then
		local point = input.point
		character:SetTarget(point)
		local pos = move.pos
		pos.x, pos.y, pos.z = point.x, point.y, point.z
		server.send("battlemove_r", move)
	elseif t == INPUT_KEY then
		local k = input.key
		if k == 1 then
			character:FireSkill(SKILL_ATK1)
		elseif k == 2 then
			character:FireSkill(SKILL_ATK2)
		end
		local req = {skill = k}
		server.send("battleskill_r", req)
	end
end

function router.battlemove_a(req)
	local uid = req.uid
	if uid ~= server.uid then
		local c = players[uid]
		c:SetTarget(req.pos)
	end
end

function router.battleskill_a(req)
	local uid = req.uid
	local c = players[uid]
	if uid ~= server.uid then
		local c = players[uid]
		local k = req.skill
		c:FireSkill(k)
	end
end

function M.start(uids)
	move.uid = server.uid
	CS.ZX.RL.Instance:load_scene_async("resource/scenes/map.unity", CS.UnityEngine.SceneManagement.LoadSceneMode.Additive);
	local ar = CS.ZX.RL.Instance:load_asset("Character/Darius/Darius.prefab")
	for _, uid in pairs(uids) do
		local go = CS.UnityEngine.Object.Instantiate(ar.asset, {x = -10, y = 0, z = -10}, CS.Quaternion.identity, root.transform)
		local c = go:GetComponent(typeof(CS.Character))
		players[uid] = c
	end
	character = players[server.uid]
	local follow = CS.UnityEngine.GameObject.Find("Main Camera"):GetComponent(typeof(CS.CameraFollow));
	print("character", character, follow)
	follow.target = character.gameObject
	core.logicupdate(input_process, input_process)
end

function M.stop()
	core.logicupdate(input_process, nil)
end

return M
