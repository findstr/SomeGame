local socket = require "zx.socket"
local core = require "zx.core"
local strings = require "zx.strings"
local ui = require "zx.ui"
local proto = require "proto"
local router = require "router"
local server = require "server"
local resources = require "zx.resources"
local binder_skill = require "binder.skill"
local binder_hud = require "binder.hud"
local skill_vm = {}
local skill_view

local tonumber = tonumber

local M = {}
local players = {}
local time_elapse  = 0
local CM = CS.UnityEngine.GameObject.Find("Characters"):GetComponent(typeof(CS.CharacterManager))
local joystick = CS.UnityEngine.GameObject.Find("Joystick")
local input_move, input_skill
local INPUT_MOUSE<const> = 1
local INPUT_KEY<const> = 2
local SKILL_NORMAL<const> = 1
local move = {uid = uid, px = nil, pz = nil, vx = nil, vz = nil}


local dr_force_time<const> = 1.0
local sync_delta = dr_force_time

local result = core.result
local function input_process(_, delta)
	time_elapse = time_elapse + delta
	input_move:Read()
	local x, y = result[1], result[2]
	local xx, yy = x * 3, y * 3;
	local dirty = CM:LocalMove(server.uid, xx, yy, 0.2)
	sync_delta = sync_delta - delta
	if dirty or sync_delta < 0.0001 then
		CM:RemoteSync(server.uid, xx, yy)
		move.px = result[1]
		move.pz = result[2]
		move.vx = xx
		move.vz = yy
		server.send("battlemove_r", move)
		sync_delta = sync_delta + dr_force_time
	end
end

local function skill_normal()
	local uid = server.uid
	local p = players[uid]
	local s = p.skills[SKILL_NORMAL]
	if s.cd > time_elapse then
		return
	end
	local n = CM:Collect(uid, 5.0)
	if n == 0 then
		print("find on target")
		return
	end
	local atk = 1
	local tuid = result[1]
	if CM:Fire(server.uid, atk, tuid) then
		s.cd = time_elapse + 2.0
		print("find target", tuid)
		local req = {
			skill = atk,
			target = tuid,
		}
		server.send("battleskill_r", req)
	end
end

function router.battlemove_a(req)
	local uid = req.uid
	if uid ~= server.uid then
		CM:RemoteMove(uid, req.px, req.pz, req.vx, req.vz)
	end
end

function router.battleskill_a(req)
	print("battleskill_a", req.uid, req.target)
	local uid, target = req.uid, req.target
	local c = players[uid]
	local t = players[target]
	if uid ~= server.uid then
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
	ui.open("balance.balance", req.winner == players[server.uid].side and "胜利" or "失败")
end

function M.start(list)
	local jmove = joystick.transform:Find("Move")
	local jskill = joystick.transform:Find("Skill")
	jmove.gameObject:SetActive(true)
	jskill.gameObject:SetActive(false)
	input_move = jmove:GetComponent(typeof(CS.Joystick))
	input_skill = jskill:GetComponent(typeof(CS.Joystick))
	skill_view = ui.new("skill.skill")
	skill_view:MakeFullScreen()
	GRoot.inst:AddChild(skill_view)
	binder_skill.skill(skill_vm, skill_view)
	skill_vm.normal.onClick:Add(skill_normal)
	move.uid = server.uid
	CS.ZX.RL.Instance:load_scene_async("Map.unity", CS.UnityEngine.SceneManagement.LoadSceneMode.Additive);
	for _, p in pairs(list) do
		local hud = {}
		local hudview = ui.new("hud.hud")
		binder_hud.hud(hud, hudview)
		p.hud = hud
		p.hudview = hudview
		p.skills = {
			[SKILL_NORMAL] = {
				cd = time_elapse + 1.0
			}
		}
		hud.mp.min = 0
		hud.mp.max = 100
		hud.hp.min = 0
		hud.hp.max = 100
		local mode = (p.uid == server.uid) and CS.Character.Mode.LOCAL or CS.Character.Mode.REMOTE
		print("create", p.uid, server.uid, mode)
		CM:Create(p.uid, "Character/Darius/Darius.prefab", hudview, hud.hp, p.px, p.pz, p.side, mode)
	end
	players = list
	core.logicupdate(input_process, input_process)
end

function M.stop()
	input_move.gameObject:SetActive(false)
	input_skill.gameObject:SetActive(false)
	core.logicupdate(input_process, nil)
end

return M
