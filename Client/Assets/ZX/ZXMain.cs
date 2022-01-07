using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using XLua;

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

public class ZXMain : MonoBehaviour {

    [System.Serializable]
    public struct Conf {
    #if UNITY_EDITOR
        public string lua_path; //Assets/Scripts/Lua/?.lua;Assets/ZX/Lua/?.lua
    #else
        public string lua_bundle; 
    #endif
    }

    public Conf conf;
    public int LogicHZ = 15;
    private LuaEnv L;
    private float logic_delta = 0;
    private float logic_elapse = 0.0f;

	[CSharpCallLua]
    private delegate LuaTable require_t(string name);
    [CSharpCallLua]
    private delegate void update_t();
    private delegate void expire_t(LuaTable t);

	private update_t core_fixedupdate;
    private update_t core_update;
    private update_t core_lateupdate;
    private update_t core_logicupdate;
    private expire_t core_timerexire;

#if ZX_DEBUG
    private LuaTable zx_socket;
    private float frame_time = 0;
    private int render_frame_count = 0;
    private int logic_frame_count = 0;
    private int render_fps = 0;
    private int logic_fps = 0;
#endif

    private LuaTable expire_array;
    private List<long>  expire_list = new List<long>();

    void Awake()
    {
        L = new LuaEnv();
#if ZX_DEBUG
        L.DoString("ZX_DEBUG = true");
#endif
	    L.AddBuildin("zx.socket.c", XLua.LuaDLL.Lua.ZXLoadSocket);
	    L.AddBuildin("zproto.c", XLua.LuaDLL.Lua.ZXLoadZProto);
        var str = "package.path = package.path .. " + "';Assets/ZX/Lua/?.lua;Assets/ZX/Deps/zproto/Lua/?.lua;Assets/ZX/Deps/FGUI/Lua/?.lua;" + conf.lua_path + "'";
	    L.DoString(str);
        L.DoString("require 'FairyGUI'");
        var require = L.Global.Get<require_t>("require");
        var core = require("zx.core");
        core_fixedupdate = core.Get<update_t>("_fixedupdate");
        core_update = core.Get<update_t>("_update");
        core_lateupdate = core.Get<update_t>("_lateupdate");
        core_logicupdate = core.Get<update_t>("_logicupdate");
        core_timerexire = core.Get<expire_t>("_timerexpire");
        expire_array = L.NewTable();
        logic_delta = 1.0f / LogicHZ;

#if ZX_DEBUG
        zx_socket = require("zx.socket");
        frame_time = 0.0001f;
        render_frame_count = 0;
        logic_frame_count = 0;
#endif

    }

    public void Start()
    {
        ZX.RL.Start(ZX.RL.Mode.RM);
	    L.DoString("require 'main'");
    }

    public void Restart()
    {
        Awake();
        Start();
    }

    public void FixedUpdate()
    {
        core_fixedupdate();
    }

    public void Update()
    {
        core_update();
        expire_list.Clear();
        ZX.Timer.update((int)(Time.deltaTime * 1000f), expire_list);
        if (expire_list.Count > 0) {
            for (int i = 0; i < expire_list.Count; i++)
                expire_array.Set(i, expire_list[i]);
            core_timerexire(expire_array);
        }
        logic_elapse += Time.deltaTime;
#if ZX_DEBUG
        frame_time += Time.deltaTime;
        render_frame_count++;
#endif
        for (int i = 0; i < 10 && logic_elapse >= logic_delta; i++) {
            core_logicupdate();
            logic_elapse -= logic_delta;
#if ZX_DEBUG
            logic_frame_count++;
            render_fps = (int)(render_frame_count / frame_time);
            logic_fps = (int)(logic_frame_count / frame_time);
            if (frame_time > 1.0f) {
                frame_time = 0.0f;
                render_frame_count = 0;
                logic_frame_count = 0;
            }
#endif
        }
    }

    public void LateUpdate()
    {
        core_lateupdate(); 
    }

#if ZX_DEBUG
    private GUIStyle guiStyle = new GUIStyle(); 
    private void OnGUI()
    {
        if (zx_socket != null) {
            GUI.color = Color.yellow;
            Rect rt = new Rect {x = Screen.width - 200, y = 50, width = 180, height = 30};
            GUI.Label(rt, "fps.render:" + render_fps);
            rt.y += 20;
            GUI.Label(rt, "fps.logic:" + logic_fps);
            rt.y += 20;
            string s = String.Format("{0:0.00}", zx_socket.Get<int>("sendsize") / 1024.0f);
            GUI.Label(rt, "socket.send:" + s + " KiB");
            rt.y += 20;
            s = String.Format("{0:0.00}", zx_socket.Get<int>("recvsize") / 1024.0f);
            GUI.Label(rt, "socket.recv:" + s + " KiB");
        }
    }
#endif
    
}

