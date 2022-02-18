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

function router.battleskill_a(req)
	print("========battleskill_a", req.uid, req.target)
	local uid, target = req.uid, req.target
	local c = players[uid]
	local t = players[target]
	if uid ~= hostuid then
		CM:Fire(uid, req.skill, req.target)
	end
	local mp, targethp = req.mp, req.targethp
	local delta_mp = mp - c.mp
	c.mp = mp
	c.hud.mp.value = mp
	CM:SkillEffect(uid, target, req.skill, targethp)
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
local resources = require "zx.resources"
local ui = require "zx.ui"
local json = require "zx.json"
local core = require "zx.core"
local server = require "server"
local router = require "router":new()

local conf_hero = require "conf.Hero"
local conf_skill = require "conf.Skill"



local red_road = {"redup", "redmiddle", "reddown"}
local blue_road = {"blueup", "bluemiddle", "bluedown"}


local pairs = pairs
local load = resources.load
local unload = resources.unload
local CM = CS.UnityEngine.GameObject.Find("Characters"):GetComponent(typeof(CS.CharacterManager))

local M = {}
local depend
local skill_ui
local host = nil
local entities = {}
local joystick_move
local joystick_skill
local resource = setmetatable({}, {
__index = function(t, path)
	local ar = load(path)
	t[path] = ar
	return ar
end,
 __gc = function(t)
	 for path, _ in pairs(t) do
		t[path] = nil
		unload(path);
	 end
 end
})

local function build(e, sidehud)
	local heroid = e.heroid
	return {
		prefab = resource[conf_hero[heroid][1].Prefab],
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

local function create_hero(entity, heroid)
	local conf = conf_hero[heroid][1]
	local nskill = conf_skill[conf.NormalSkill][1]
	entity.skills = {
		[1] = {
			time = 0,
			cd = nskill.CD,
			dist = nskill.Distance * nskill.Distance,
		}
	}
end

local time_elapse  = 0
local dr_force_time<const> = 1.0
local sync_delta = dr_force_time
local result = core.result
local move = {uid = uid, px = nil, pz = nil, vx = nil, vz = nil}
local lastmoving = false

local function move_update(_, delta)
	time_elapse = time_elapse + delta
	local dirty = false
	local moving = joystick_move:Read()
	if moving then
		local speed = host.speed
		local x, y = result[1], result[2]
		print("move_update", speed, x, y)
		local xx, yy = x * speed, y * speed;
		dirty = CM:LocalMove(hostuid, xx, yy, 0.2)
		if not dirty and moving == false and lastmoving == true then
			dirty = true
		end
		lastmoving = moving
	end
	sync_delta = sync_delta - delta
	if dirty or sync_delta < 0.0001 then
		CM:RemoteSync(hostuid, xx, yy)
		move.px = result[1]
		move.pz = result[2]
		move.vx = x
		move.vz = y
		server.send("battlemove_r", move)
		sync_delta = sync_delta + dr_force_time
	end
end

local function init_skill_ui()
	local joystick = CS.UnityEngine.GameObject.Find("Joystick")
	local jmove = joystick.transform:Find("Move")
	local jskill = joystick.transform:Find("Skill")
	joystick_move = jmove:GetComponent(typeof(CS.Joystick))
	joystick_skill = jskill:GetComponent(typeof(CS.Joystick))
	joystick_move.gameObject:SetActive(true)
	joystick_skill.gameObject:SetActive(false)
	skill_ui = ui.new("skill.skill")
	--skill_vm.normal.onClick:Add(skill_normal)
end

function M.start(ack)
	depend = {}
	hostuid = server.uid
	router:attach()
	CM:Reset()
	move.uid = hostuid
	init_skill_ui()
	resources.load_scene_async("Map.unity", resources.additive)
	print(json.encode(ack))
	local list = ack.entities
	host = list[hostuid]
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
		local hud, hudview = ui.new(c.hud)
		hud.name.text = e.name
		create_hero(e, e.heroid)
		hud.mp.min = 0
		hud.mp.max = e.hpmax
		hud.hp.min = 0
		hud.hp.max = e.mpmax
		hud.mp.value = e.mp
		hud.hp.value = e.hp
		e.hud = hud
		CM:Create(uid, c.prefab, hudview, e.px, e.pz)
		entities[uid] = e
	end
	for uid, e in pairs(list) do
		CM:Join(uid, e.side)
	end
	CM:SetHost(hostuid)
	core.logicupdate(move_update, move_update)
end

function M.stop()
	router:detach()
	CM:Reset()
	depend = nil
	host = nil
	for path, _ in pairs(resource) do
		resource[path] = nil
		unload(path)
	end
	for uid, e in pairs(entities) do
		ui.del(e.hud)
		entities[uid] = nil
	end
	ui.del(skill_ui)
	skill_ui = nil
	joystick_move.gameObject:SetActive(false)
	joystick_skill.gameObject:SetActive(false)
	core.logicupdate(input_process, nil)
	resources.unload_scene_async("Map.unity");
end

return M
