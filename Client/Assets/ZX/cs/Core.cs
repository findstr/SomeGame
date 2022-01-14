﻿using FairyGUI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using XLua;
using static FairyGUI.UIPackage;

/*
 * ZX_DEBUG
 * ZX_USEAB
 */

namespace XLua.LuaDLL
{ 
    public partial class Lua
    { 
	[DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
	public static extern int luaopen_socket_c(System.IntPtr L);
	[DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
	public static extern int luaopen_zproto_c(System.IntPtr L);

	[MonoPInvokeCallback(typeof(lua_CSFunction))]
	public static int ZXLoadSocket(System.IntPtr L)
	{
	    return luaopen_socket_c(L);
	}
	[MonoPInvokeCallback(typeof(lua_CSFunction))]
	public static int ZXLoadZProto(System.IntPtr L)
	{
	    return luaopen_zproto_c(L);
	}
    }
}

namespace ZX{
[LuaCallCSharp]
public static class Core {   
#if ZX_DEBUG
	public class DebugInfo {
		public float frame_time = 0;
		public int render_frame_count = 0;
		public int logic_frame_count = 0;
		public int render_fps = 0;
		public int logic_fps = 0;
		public int send_size = 0;
		public int recv_size = 0;
	};
	public static DebugInfo debug = null;
#endif
	[CSharpCallLua]
	private delegate LuaTable require_t(string name);
	[CSharpCallLua]
	private delegate void update_t();
	private delegate void expire_t(LuaTable t);

	static private LuaEnv L = null;
	static private UI UI = null;
	static private Timer Timer = null;
	static private Strings Strings = null;

	static private float logic_delta = 0;
	static private float logic_elapse = 0.0f;
	static private LuaTable expire_array;
	static private List<long>  expire_list = null;

	static private update_t core_fixedupdate;
	static private update_t core_update;
	static private update_t core_lateupdate;
	static private update_t core_logicupdate;
	static private expire_t core_timerexire;

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
#if UNITY_EDITOR
		if (useAB)
			RL.Start(RL.Mode.ABM);
		else
			RL.Start(RL.Mode.RM);
#else
		RL.Start(RL.Mode.ABM);
#endif
	}
	static void InitStrings() {
		Strings = new Strings();
	}
	static void InitTimer() {
		Timer = new Timer();
	}
	static void InitUI() {
		if (UI != null)
			UI.RemoveAllPackages();
		UI = new UI();
	}

	static void InitLua() {
		L = new LuaEnv();
		L.AddLoader(LuaLoader);
#if ZX_DEBUG
		L.DoString("ZX_DEBUG = true");
#endif
		L.AddBuildin("zx.socket.c", XLua.LuaDLL.Lua.ZXLoadSocket);
		L.AddBuildin("zproto.c", XLua.LuaDLL.Lua.ZXLoadZProto);
		L.DoString("require 'FairyGUI'");
		var require = L.Global.Get<require_t>("require");
		var core = require("zx.core");
		core_fixedupdate = core.Get<update_t>("_fixedupdate");
		core_update = core.Get<update_t>("_update");
		core_lateupdate = core.Get<update_t>("_lateupdate");
		core_logicupdate = core.Get<update_t>("_logicupdate");
		core_timerexire = core.Get<expire_t>("_timerexpire");

		expire_list = new List<long>();
		expire_array = L.NewTable();
	}

	static public void Prepare(bool UseAB, int LogicHZ) {
#if ZX_DEBUG
		debug = new DebugInfo();
#endif
		InitStrings();
		InitTimer();
		InitRL(UseAB);
		InitUI();
		InitLua();
		logic_delta = 1.0f / LogicHZ;
	}

	static public void Start() {
		L.DoString("require 'main'");
	}
	////////////////Strings Module
	static public int StringNew(string s) {
		return Strings.New(s);
	}
	////////////////UI Module
        static public void SetPathPrefix(string s) {
		UI.SetPathPrefix(s);
        }
        static public int AddPackage(int id) {
		return UI.AddPackage(Strings.Get(id));
	}
        static public void RemovePackage(int id) {
		UI.RemovePackage(id);
        }
	static public GObject CreateObject(int id, string resName) {
		return UI.CreateObject(id, resName);
        }
        static public void CreateObjectAsync(int id, string resName, CreateObjectCallback callback) {
		UI.CreateObjectAsync(id, resName, callback);
	}
	///////////////RM Module
	static public IRL.AssetRequest LoadAsset(int id, Type T = null) {
		return RL.Instance.load_asset(Strings.Get(id), T);
	}
	///////////////Update Function
	static public void FixedUpdate() {
		core_fixedupdate();
	}
	static public void Update() {
		core_update();
		expire_list.Clear();
		Timer.Update((int)(Time.deltaTime * 1000f), expire_list);
		if (expire_list.Count > 0) {
		    for (int i = 0; i < expire_list.Count; i++)
			expire_array.Set(i, expire_list[i]);
		    core_timerexire(expire_array);
		}
		logic_elapse += Time.deltaTime;
#if ZX_DEBUG
		debug.frame_time += Time.deltaTime;
		debug.render_frame_count++;
#endif
		for (int i = 0; i < 10 && logic_elapse >= logic_delta; i++) {
		    core_logicupdate();
		    logic_elapse -= logic_delta;
	#if ZX_DEBUG
		    debug.logic_frame_count++;
		    debug.render_fps = (int)(debug.render_frame_count / debug.frame_time);
		    debug.logic_fps = (int)(debug.logic_frame_count / debug.frame_time);
		    if (debug.frame_time > 1.0f) {
			debug.frame_time = 0.0f;
			debug.render_frame_count = 0;
			debug.logic_frame_count = 0;
		    }
#endif
		}
	}
	static public void LateUpdate() {
		ZX.RL.Instance.update();
		core_lateupdate(); 
	}

	}
}
