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


namespace ZX { 

public class ZXMain : MonoBehaviour {

    [System.Serializable]
    public struct Conf {
        public string bootstrap; //Scripts/lua/main.lua
    #if UNITY_EDITOR
        public string lua_path; //Scripts/lua/?.lua;zx/lua/?.lua;ZX/deps/tolua/ToLua/Lua/?.lua
    #else
        public string lua_bundle; 
    #endif
    }

    public Conf conf;
    private LuaEnv L;

	[CSharpCallLua]
    private delegate LuaTable require_t(string name);
    [CSharpCallLua]
    private delegate void update_t();

	private update_t core_fixedupdate;
    private update_t core_update;
    private update_t core_lateupdate;


    void Awake()
    {
        L = new LuaEnv();
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
    }

    public void Start()
    {
	    L.DoString("require 'main'");
    }

    public void FixedUpdate()
    {
        core_fixedupdate();
    }

    public void Update()
    {
        core_update();
    }

    public void LateUpdate()
    {
        core_lateupdate();
    }
    
}}

