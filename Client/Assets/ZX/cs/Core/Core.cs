using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using XLua;

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
public static partial class Core {   
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
	public delegate LuaTable require_t(string name);
	[CSharpCallLua]
	public delegate void update_t(float deltaTime);
	[CSharpCallLua]
	public delegate void expire_t(LuaTable t);

	static private LuaEnv L = null;
	static private Timer Timer = null;

	static private float logic_last_frame = 0;
	static private float logic_delta = 0;
	static private float logic_elapse = 0.0f;
	static private LuaTable expire_array;
	static public LuaTable result = null;
	static private List<ulong>  expire_list = null;

	static private update_t core_fixedupdate;
	static private update_t core_update;
	static private update_t core_lateupdate;
	static private update_t core_logicupdate;
	static private expire_t core_timerexire;


	static void InitTimer() {
		Timer = new Timer();
	}

	static void InitLua() {
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
		result = core.Get<LuaTable>("result");
		expire_list = new List<ulong>();
		expire_array = L.NewTable();
	}

	static public void Prepare(bool UseAB, int LogicHZ) {
#if ZX_DEBUG
		debug = new DebugInfo();
#endif
		L = new LuaEnv();
		InitStrings();
		InitTimer();
		InitRL(UseAB);
		InitUI();
		InitLua();
		logic_delta = 1.0f / LogicHZ;
	}
	static public ulong Timeout(int ms) {
		return Timer.TimeOut(ms);
	}
	static public void Start() {
		logic_last_frame = Time.realtimeSinceStartup;
		L.DoString("require 'main'");
	}
	///////////////Update Function
	static public void FixedUpdate() {
#if ZX_DEBUG
		debug.frame_time += Time.deltaTime;
		debug.render_frame_count++;
#endif
		logic_elapse += Time.deltaTime;
		for (int i = 0; i < 10 && logic_elapse >= logic_delta; i++) {
			float t = Time.realtimeSinceStartup;
			core_logicupdate(t - logic_last_frame);
			logic_last_frame = t;
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
		core_fixedupdate(Time.fixedDeltaTime);
	}
	static public void Update() {
		expire_list.Clear();
		Timer.Update((int)(Time.deltaTime * 1000f), expire_list);
		if (expire_list.Count > 0) {
		    for (int i = 0; i < expire_list.Count; i++)
			expire_array.Set(i, expire_list[i]);
		    core_timerexire(expire_array);
		}
		core_update(Time.deltaTime);
	}
	static public void LateUpdate() {
		ZX.RL.Instance.update();
		core_lateupdate(Time.deltaTime); 
	}

	}
}
