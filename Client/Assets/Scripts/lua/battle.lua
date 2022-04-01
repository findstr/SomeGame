--[[
local socket = require "zx.socket"
local core = require "zx.core"SideBarEnhancements
local json = require "zx.json"
local strings = require "zx.strings"
local ui = require "zx.ui"
local proto = require "proto"
local router = require "router":new()
local server = require "server"
local resources = require "zx.resources"
local binder_skill = require "binder.skill"
local binder_hud = require "binder.hud"
local skill_vm = {}
local skill_view


local pairs = pairs

local RED<const> = 1
local BLUE<const> = 2

local tonumber = tonumber

local M = {}
local players = {}
local hostuid = 0
local time_elapse  = 0
local CM = CS.UnityEngine.GameObject.Find("Characters"):GetComponent(typeof(CS.CharacterManager))
local joystick = CS.UnityEngine.GameObject.Find("Joystick")
local input_move, input_skill
local INPUT_MOUSE<const> = 1
local INPUT_KEY<const> = 2
local SKILL_NORMAL<const> = 1
local LOCAL<const> = CS.Character.Mode.LOCAL
local REMOTE<const> = CS.Character.Mode.REMOTE
local move = {uid = uid, px = nil, pz = nil, vx = nil, vz = nil}


local function skill_normal()
	local uid = hostuid
	local p = players[uid]
	local s = p.skills[SKILL_NORMAL]
	if s.cd > time_elapse then
		return
	end
	local tuid = CM:SelectNearestEnemy(uid, 5.0)
	if n == 0 then
		print("find on target")
		return
	end
	if CM:Fire(hostuid, 1, tuid) then
		s.cd = time_elapse + 2.0
		print("find target", tuid)
		local req = {
			skill = 1,
			target = tuid,
		}
		server.send("battleskill_r", req)
	end
end

function router.battlemove_a(req)
	local uid = req.uid
	if uid ~= hostuid then
		local p = players[uid]
		if p then
			local speed = p.speed
			CM:RemoteMove(uid, req.px, req.pz, req.vx * speed, req.vz * speed)
		end
	end
end



function router.battleover_n(req)
	print("battleover_n", req.winner)
	ui.open("balance.balance", req.winner == players[hostuid].side and "胜利" or "失败")
end

function router.battleclose_n(req)
	print("battleclose_n")
	M.stop()
	ui.inplace("lobby.lobby")
end

local function debug_info()
	local Quaternion = 	CS.UnityEngine.Quaternion
	local l = require "conf.Building"
	print("building:", #l)
	for i = 1, #l do
		local path = l[i].Path
		local go = CS.UnityEngine.GameObject.Find(path)
		local mesh = go:GetComponent(typeof(CS.UnityEngine.MeshFilter)).mesh
		local position = mesh.vertices[1]
		local rot = Quaternion.AngleAxis(-90, CS.UnityEngine.Vector3.right)
		local pos = rot * position
		print(path, pos)
	end
end

]]
local strings = require "zx.strings"
local resources = require "zx.resources":new()
local ui = require "zx.ui"
local json = require "zx.json"
local core = require "zx.core"
local server = require "server"
local skill = require "skill"
local entities = require "entities"
local router = require "router":new()

local conf_hero = require "conf.Hero"

local red_road = {"redup", "redmiddle", "reddown"}
local blue_road = {"blueup", "bluemiddle", "bluedown"}

local pairs = pairs
local CM = CS.UnityEngine.GameObject.Find("Characters"):GetComponent(typeof(CS.CharacterManager))

local M = {}
local TIME
local host
local joystick_move
local depend

local function build(e, sidehud)
	local heroid = e.heroid
	return {
		prefab = resources[conf_hero[heroid][1].Prefab],
		hud = sidehud[e.side],
		entity = e,
	}
end

local function build_road(root, list, sidehud, creating)
	for i = 1, #list do
		local e = list[i]
		if e.hp > 0 then
			depend[e] = root
			root = e
		end
		local conf = conf_hero[e.heroid][1]
		creating[#creating + 1] = build(e, sidehud)
	end
	return root
end

local dr_force_time<const> = 1.0
local sync_delta = dr_force_time
local result = core.result
local move = {uid = uid, px = nil, pz = nil, vx = nil, vz = nil}
local lastmoving = false

local function main_update(_, delta)
	TIME = TIME + delta
	local dirty = false
	local moving = joystick_move:ReadN()
	if moving or lastmoving == true then
		local speed = host.speed
		local x, y = result[1], result[2]
		local xx, yy = x * speed, y * speed;
		dirty = CM:LocalMove(hostuid, xx, yy, 0.2)
		if not moving then
			dirty = true
		end
		lastmoving = moving
	end
	sync_delta = sync_delta - delta
	if dirty or sync_delta < 0.0001 then
		local speed = host.speed
		local x, y = result[1], result[2]
		local xx, yy = x * speed, y * speed;
		CM:RemoteSync(hostuid, xx, yy)
		move.px = result[1]
		move.pz = result[2]
		move.vx = x
		move.vz = y
		server.send("battlemove_r", move)
		sync_delta = sync_delta + dr_force_time
	end
end

function router.battlemove_a(req)
end

function M.start(ack)
	depend = {}
	hostuid = server.uid
	router:attach()
	CM:Reset()
	move.uid = hostuid
	resources.load_scene_async("Map.unity", "additive")
	print(json.encode(ack))
	TIME = ack.roomtime
	local list = ack.entities
	host = list[hostuid]
	local joystick = CS.UnityEngine.GameObject.Find("Joystick")
	local jmove = joystick.transform:Find("Move")
	joystick_move = jmove:GetComponent(typeof(CS.Joystick))
	joystick_move.gameObject:SetActive(true)
	local hostside = host.side
	local sidehud = {
		[hostside] = "hud.blue",
		[hostside % 2 + 1] = "hud.red",
	}
	local creating = {}
	for uid, e in pairs(list) do
		creating[#creating + 1] = build(e, sidehud)
	end
	local root = ack.redcrystal
	creating[#creating + 1] = build(root, sidehud)
	for _, name in pairs(red_road) do
		local e = build_road(root, ack[name], sidehud, creating)
		list[e.uid] = e
	end
	local root = ack.bluecrystal
	creating[#creating + 1] = build(root, sidehud)
	for _, name in pairs(blue_road) do
		local e = build_road(root, ack[name], sidehud, creating)
		list[e.uid] = e
	end

	for i = 1, #creating do
		local c = creating[i]
		local e = c.entity
		local uid = e.uid
		local hud = ui.new(c.hud)
		hud.name.text = e.name
		hud.mp.min = 0
		hud.mp.max = e.hpmax
		hud.hp.min = 0
		hud.hp.max = e.mpmax
		hud.mp.value = e.mp
		hud.hp.value = e.hp
		e.hud = hud
		CM:Create(uid, c.prefab, hud.__view, e.px, e.pz)
		entities[uid] = e
	end
	for uid, e in pairs(list) do
		CM:Join(uid, e.side)
	end
	skill.start(CM, hostuid, host.skills)
	CM:SetHost(hostuid)
	core.logicupdate(M, main_update)
end

function M.stop()
	router:detach()
	CM:Reset()
	depend = nil
	host = nil
	for uid, e in pairs(entities) do
		ui.del(e.hud)
		entities[uid] = nil
	end
	skill.stop()
	joystick_move.gameObject:SetActive(false)
	core.logicupdate(M, nil)
	resources:clear()
	resources.load_scene_async("Map.unity");
end

return M
