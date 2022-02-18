local core = require "zx.core"
local strings = require "zx.strings"
local M = {}
local session = 0
local pcall = pcall
local type = type
local xpcall = xpcall
local pairs = pairs
local tremove = table.remove
local Object = typeof(CS.UnityEngine.Object)
local LoadAsset = CS.ZX.Core.LoadAsset
local UnloadAsset = CS.ZX.Core.UnloadAsset

local assets_ref = {}
local assets = {}
local requests = {}
local pool = setmetatable({}, {__mode="kv"})

local function recycle(tbl)
	for k, v in pairs(tbl) do
		tbl[k] = nil
	end
	pool[#pool + 1] = tbl
end

function M.load_async(names, cb, ud, T)
	local key
	local typ = type(names)
	if typ == "table" then
		count = #names
		for i = 1, count do
			local name = names[i]
			local n = assets_ref[name] or 0
			assets_ref[name] = n + 1
			if not assets[name] then
				assets[name] = LoadAsset(strings[name], T)
			end
		end
	else
		key = names
		local n = assets_ref[key] or 0
		assets_ref[key] = n + 1
		if not assets[key] then
			assets[key] = LoadAsset(strings[key], T)
		end
	end
	local req = tremove(pool);
	if not req then
		req = {
			__key = key,
			__callback = cb,
			__userdata = ud,
		}
	else
		req.__key = key
		req.__callback = cb
		req.__userdata = ud
	end
	requests[#requests + 1] = req
end

function M.load(name, T)
	local n = assets_ref[name] or 0
	assets_ref[name] = n + 1
	return LoadAsset(strings[name], T)
end

function M.unload(name)
	local typ = typeof(name)
	local ref = assets_ref[name]
	if not ref then
		rint("reousrces.unload_asset:", name, " not exist")
		return
	end
	if ref > 1 then
		assets_ref[name] = ref - 1
		return
	end
	UnloadAsset(strings[name])
	assets_ref[name] = nil
	assets[name] = nil
end

M.additive = CS.UnityEngine.SceneManagement.LoadSceneMode.Additive

local LoadSceneAsync = CS.ZX.Core.LoadSceneAsync
local UnloadSceneAsync = CS.ZX.Core.UnloadSceneAsync

function M.load_scene_async(name, mode)
	LoadSceneAsync(strings[name], mode)
end

function M.unload_scene_async(name)
	UnloadSceneAsync(strings[name])
end

local function update_cb()
	for i = 1, #requests do
		local req = requests[i]
		requests[i] = nil
		local key = req.__key
		if key then
			req.__callback(assets[key], req.__userdata)
		else
			req.__callback(assets, req.__userdata)
		end
		recycle(req)
	end
end

core.update(M, update_cb)


return M

