local ui = require "zx.ui"
local conf_skill = require "conf.Skill"
local M = {}

local skill_ui
local host_skill
local joystick
local joystick_go


local function skill_normal(ctx)
--[[
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
]]
	print("******skill_normal", skill_ui[ctx.sender])
end

local function touch_begin(ctx)
	local button = ctx.sender
	print("******touch_begin", skill_ui[button])
	joystick_go.transform.position = ui.screenposition(button)
	joystick_go:SetActive(true)
	joystick:Touch()
end

local function touch_move(ctx)
	local moving = joystick:Read()
	print("******touch_move", skill_ui[ctx.sender], moving)
end

local function touch_end(ctx)
	print("******touch_end", skill_ui[ctx.sender])
	joystick_go.gameObject:SetActive(false)
end

local field_name = {
	[1] = "s1",
	[2] = "s2",
	[3] = "s3",
	[4] = "s4",
	[5] = "s5",
	[6] = "s6",
}

local function create_skill(conf, cd)
	local dist = conf.Distance
	return {
		cdtime = conf.CD,
		dist2 = dist * dist,
		singtime = conf.Sing,
		level = l,
		cd = cd,
	}
end

local function new_skill_ui(skills)
	skill_ui = ui.new("skill.skill")
	for i = 1, #skills do
		skill_ui[i] = skill_ui[field_name[i]]
	end
end

function M.start(skills)
	host_skill = {}
	local go = CS.UnityEngine.GameObject.Find("Joystick")
	go = go.transform:Find("Skill")
	joystick = go:GetComponent(typeof(CS.Joystick))
	joystick_go = joystick.gameObject
	joystick_go:SetActive(false)
	new_skill_ui(skills)
	for i = 1, #skills do
		local s = skills[i]
		local ui = skill_ui[i]
		skill_ui[ui.__view] = i
		local conf = conf_skill[s.skillid][1]
		ui.name.text = conf.Name
		ui.sprite.url = conf.Icon
		local view = ui.__view
		if l == 0 then
			ui.__view.enabled = false
		else
			local dist = conf.Distance
			host_skill[i] = create_skill(conf, s.cd)
		end
		if i == 1 then
			view.onClick:Add(skill_normal)
		else
			view.onTouchBegin:Add(touch_begin)
			view.onTouchMove:Add(touch_move)
			view.onTouchEnd:Add(touch_end)
		end
	end
end

function M.stop()
	ui.del(skill_ui)
	joystick_go:SetActive(false)
	skill_ui = nil
	joystick = nil
	joystick_go = nil
end

return M
