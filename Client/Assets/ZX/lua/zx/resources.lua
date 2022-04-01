local core = require "zx.core"
local strings = require "zx.strings"
local session = 0
local pcall = pcall
local type = type
local xpcall = xpcall
local pairs = pairs
local tremove = table.remove
local setmetatable = setmetatable
local Object = typeof(CS.UnityEngine.Object)
local LoadAsset = CS.ZX.Core.LoadAsset
local UnloadAsset = CS.ZX.Core.UnloadAsset

local M = {}
local loading = {}
local weakmt = {__mode = "kv"}
local propmt = {__mode = "k", __index = function(tbl, k)
	local v = {}
	tbl[k] = v
	return v
end}
local pool = setmetatable({}, weakmt)
local reference = setmetatable({}, propmt)
local requests = setmetatable({}, propmt)
local function recycle(tbl)
	for k, v in pairs(tbl) do
		tbl[k] = nil
	end
	pool[#pool + 1] = tbl
end

local function load(self, name, T)
	local assets_ref = reference[self]
	local n = assets_ref[name] or 0
	assets_ref[name] = n + 1
	local abr = LoadAsset(strings[name], T)
	self[name] = abr
	return abr
end

local function load_async(self, names, cb, ud, T)
	local key
	local assets = self
	local assets_ref = reference[self]
	local reqlist = requests[self]
	local typ = type(names)
	if typ == "table" then
		local count = #names
		for i = 1, count do
			local name = names[i]
			load(self, name, T)		
		end
	else
		key = names
		load(self, key, T)
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
	reqlist[#reqlist + 1] = req
	loading[self] = true
end

local function unload(self, name)
	local assets_ref = reference[self]
	local typ = typeof(name)
	local ref = assets_ref[name]
	if not ref then
		print("reousrces.unload_asset:", name, " not exist")
		return
	end
	if ref > 1 then
		assets_ref[name] = ref - 1
		return
	end
	UnloadAsset(strings[name])
	assets_ref[name] = nil
	self[name] = nil
end


local LoadSceneAsync = CS.ZX.Core.LoadSceneAsync
local UnloadSceneAsync = CS.ZX.Core.UnloadSceneAsync
local mode_type = {
	["single"] = CS.UnityEngine.SceneManagement.LoadSceneMode.Single,
	["additive"] = CS.UnityEngine.SceneManagement.LoadSceneMode.Additive,
}

local function load_scene_async(name, mode)
	LoadSceneAsync(strings[name], mode_type[mode])
end

local function unload_scene_async(name)
	UnloadSceneAsync(strings[name])
end

local function clear(self)
	local assets = self
	local ref = reference[self]
	local req = requests[self]
	for name, _ in pairs(ref) do
		UnloadAsset(strings[name])
		ref[name] = nil
		assets[name] = nil
	end
	for i, req in pairs(req) do
		req[i] = nil
		recycle(req)
	end
end


local mt = {__index = function(tbl, k)
	return (load(tbl, k))
end,
__gc = function(self)
	clear(self)
end}

function M:new()
	local r = setmetatable({
		unload = unload,
		load_async = load_async,
		load_scene_async = load_scene_async,
		unload_scene_async = unload_scene_async,
	}, mt)
	return r
end

local function update_cb()
	for mgr, _ in pairs(loading) do
		loading[mgr] = nil
		local req = requests[mgr]
		local assets = mgr
		for i = 1, #req do
			local r = req[i]
			req[i] = nil
			local key = r.__key
			if key then
				r.__callback(assets[key], r.__userdata)
			else
				r.__callback(assets, r.__userdata)
			end
			recycle(r)
		end
	end
end

core.fixedupdate(M, update_cb)


return M

