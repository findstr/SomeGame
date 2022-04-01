local ui = require "zx.ui"
local core = require "zx.core"
local conf_skill = require "conf.Skill"
local entities = require "entities"
local server = require "server"
local router = require "router":new()
local resources = require "zx.resources":new()
local M = {}

local CM 
local hostuid
local skill_ui
local host_skill
local joystick
local joystick_go
local skill_range
local skill_select
local assert = assert
local result = core.result
local vector3 = {x = 0, y = 0, z = 0}
local timer_ctx = {}
local ceil = math.ceil
local NORMAL<const> = 1

local function update_range(skill, _)
	joystick:Read()
	local off_x = result[1] * 5.0
	local off_y = result[2] * 5.0
	CM:Follow(hostuid, skill_range, 0, 0)
	CM:Follow(hostuid, skill_select, off_x, off_y);
end

local function update_cd(skill, delta)
	local cd, ui = skill.cd, skill.ui
	cd = cd - delta
	if cd <= 0.0 then

		skill.cd = nil
		ui.__view.touchable = true
		ui.cdtime.text = ""
		ui.cdmask.fillAmount = 0.0
		core.update(skill, nil)
		return
	else
		skill.cd = cd
		local cdtime = skill.cdtime
		ui.cdtime.text = ceil(cd)
		ui.cdmask.fillAmount = cd / cdtime
	end
end

local function skill_enable()
		host_skill[NORMAL].ui.__view.touchable = true
end

local function skill_normal(ctx)
	print("***skill_normal")
	local uid = hostuid
	local skill = host_skill[NORMAL]
	local tuid = CM:SelectNearestEnemy(uid, 5.0)
	if tuid == 0 then
		print("find on target")
		return
	end
	if CM:Fire(hostuid, 1, tuid) then
		local req = {
			skill = 1,
			target = tuid,
		}
		server.send("battleskill_r", req)
		print("find target", tuid)
		--skill.ui.__view.touchable = false
		--core.timeout(1000, skill_enable)
	end
end

local function touch_begin(ctx)
	local skill = host_skill[ctx.sender]
	if skill.cd then
		return
	end
	local data = ctx.data
	joystick_go.transform.position = ui.screenposition(skill.ui.__view)
	joystick_go:SetActive(true)
	joystick:TouchBegin(data.x, data.y)
	skill_range:SetActive(true)
	skill_select:SetActive(true)
	core.setscale(skill_range, 10, 10, 1)
	core.logicupdate(skill, update_range)
end

local function touch_move(ctx)
	local skill = host_skill[ctx.sender]
	if skill.cd then
		return
	end
	local data = ctx.data
	joystick:TouchMove(data.x, data.y)
	joystick:Read()
end

local function touch_end(ctx)
	local skill = host_skill[ctx.sender]
	if skill.cd then
		return
	end
	joystick_go.gameObject:SetActive(false)
	joystick:TouchEnd()
	skill_range:SetActive(false)
	skill_select:SetActive(false)
	core.logicupdate(skill, nil)
	local ui = skill.ui
	local cdtime = skill.cdtime
	skill.cd = cdtime
	ui.cdtime.text = cdtime
	ui.__view.touchable = false
	core.update(skill, update_cd)
end

function router.battleskill_a(req)
	local uid, target = req.uid, req.target
	local c = entities[uid]
	local t = entities[target]
	if uid ~= hostuid then
		CM:Fire(uid, req.skill, req.target)
	end
	local targethp = req.targethp
	local delta_hp = targethp - t.hp
	t.mp = req.mp
	t.hp = targethp
	t.hud.mp.value = mp
	print("****battkeskill_a", delta_hp)
	CM:SkillEffect(uid, target, delta_hp)
end


local field_name = {
	[1] = "s1",
	[2] = "s2",
	[3] = "s3",
	[4] = "s4",
	[5] = "s5",
	[6] = "s6",
}

local function create_skill(conf, ui, cd)
	local dist = conf.Distance
	return {
		--TODO:
		cdtime = 10,
		dist2 = dist * dist,
		singtime = conf.Sing,
		level = l,
		cd = cd,
		ui = ui,
	}
end

local function new_skill_ui(skills)
	for i = 1, #skills do
		skill_ui[i] = skill_ui[field_name[i]]
	end
end
local Instantiate = CS.UnityEngine.GameObject.Instantiate
local function create_range(asset, _)
	skill_range = Instantiate(asset.asset)
end
local function create_select(asset, _)
	skill_select = Instantiate(asset.asset);
end

function M.start(CMgr, host, skills)
	CM = CMgr
	hostuid = host
	host_skill = {}
	router:attach()
	local go = CS.UnityEngine.GameObject.Find("Joystick")
	go = go.transform:Find("Skill")
	joystick = go:GetComponent(typeof(CS.Joystick))
	joystick_go = joystick.gameObject
	joystick_go:SetActive(false)
	skill_ui = ui.new("skill.skill")
	for i = 1, #skills do
		local s = skills[i]
		local ui = skill_ui[field_name[i]]
		local conf = conf_skill[s.skillid][1]
		ui.name.text = conf.Name
		ui.sprite.url = conf.Icon
		local view = ui.__view
		if l == 0 then
			ui.__view.enabled = false
		end
		local skill = create_skill(conf, ui, nil)
		host_skill[i] = skill
		host_skill[view] = skill
		if i == 1 then
			view.onClick:Add(skill_normal)
		else
			view.onTouchBegin:Add(touch_begin)
			view.onTouchMove:Add(touch_move)
			view.onTouchEnd:Add(touch_end)
		end
	end
	resources:load_async("Skills/Common/Range.prefab", create_range)
	resources:load_async("Skills/Common/Range.prefab", create_select)
end

function M.stop()
	router:detach()
	resources:clear()
	ui.del(skill_ui)
	skill_ui = nil
	joystick = nil
	joystick_go = nil
	joystick_go:SetActive(false)
end

return M
