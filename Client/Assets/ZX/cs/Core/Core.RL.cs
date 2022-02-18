using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Pool;
using UnityEngine.SceneManagement;
using XLua;
using LuaAPI = XLua.LuaDLL.Lua;
using LuaCSFunction = XLua.LuaDLL.lua_CSFunction;

namespace ZX{
static partial class Core {
	static byte[] LuaLoader(ref string name) {
		var abr = RL.Instance.load_asset(name, typeof(TextAsset));
		if (abr == null)
		    return null;
		var ta = abr.asset as TextAsset;
		var bytes = ta.bytes;
		RL.Instance.unload_asset(name);
		return bytes;	
	}
		
	static void InitRL(bool useAB) {
		L.AddLoader(LuaLoader);
#if UNITY_EDITOR
		if (useAB)
			RL.Start(RL.Mode.ABM);
		else
			RL.Start(RL.Mode.RM);
#else
		RL.Start(RL.Mode.ABM);
#endif
	}

	static public IRL.AssetRequest LoadAsset(int id, Type T = null) {
		return RL.Instance.load_asset(Strings.Get(id), T);
	}
	static public void UnloadAsset(int id) {
		RL.Instance.unload_asset(Strings.Get(id));
	}
	static public AsyncOperation LoadSceneAsync(int id, LoadSceneMode mode) {
		return RL.Instance.load_scene_async(Strings.Get(id), mode);
	}
	static public void UnloadSceneAsync(int id) {
		RL.Instance.unload_scene_async(Strings.Get(id));
	}
}}
