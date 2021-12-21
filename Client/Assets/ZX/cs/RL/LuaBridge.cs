using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/*

public class LuaBridge
{
	static LuaInterface.LuaFunction lua_toid = null;
	static LuaInterface.LuaFunction lua_call = null;
	static Dictionary<string, int> str_to_id = new Dictionary<string, int>();
	static private int toid(string name)
	{
		int fid;
		if (!str_to_id.TryGetValue(name, out fid)) {
			fid = lua_toid.Invoke<string, int>(name);
			str_to_id[name] = fid;
		}
		return fid;
	}
	static public void start() {
		str_to_id.Clear();
		var require = SSR.GameMain.Lua.GetStata().GetFunction("require");
		var bridge =  require.Invoke<string, LuaInterface.LuaTable>("bridge");
		lua_toid = bridge.GetLuaFunction("toid");
		lua_call = bridge.GetLuaFunction("call");
		bridge.Dispose();
		require.Dispose();
	}
	static public int fetch(string module) {
		int mid = toid(module);
		return mid;
	}
	static public void call(string module, string name) {
		int mid = toid(module);
		int fid = toid(name);
		lua_call.Call(mid, fid);
	}
	static public void call<T1>(string module, string name, T1 arg1) {
		int mid = toid(module);
		int fid = toid(name);
		lua_call.Call(mid, fid, arg1);
	}
	static public void call<T1,T2>(string module, string name, T1 arg1, T2 arg2) {
		int mid = toid(module);
		int fid = toid(name);
		lua_call.Call(mid, fid, arg1, arg2);
	}
	static public void call<T1,T2,T3>(string module, string name, T1 arg1, T2 arg2, T3 arg3) {
		int mid = toid(module);
		int fid = toid(name);
		lua_call.Call(mid, fid, arg1, arg2,arg3);
	}
	static public void call<T1,T2,T3,T4>(string module, string name, T1 arg1, T2 arg2, T3 arg3, T4 arg4) {
		int mid = toid(module);
		int fid = toid(name);
		lua_call.Call(mid, fid, arg1, arg2,arg3,arg4);
	}
	static public R1 invoke<R1>(string module, string name) {
		int mid = toid(module);
		int fid = toid(name);
		return lua_call.Invoke<int, int, R1>(mid, fid);
	}
	static public R1 invoke<R1,T1>(string module, string name, T1 arg1) {
		int mid = toid(module);
		int fid = toid(name);
		return lua_call.Invoke<int, int,T1,R1>(mid, fid, arg1);
	}
	static public R1 invoke<R1,T1,T2>(string module, string name, T1 arg1, T2 arg2) {
		int mid = toid(module);
		int fid = toid(name);
		return lua_call.Invoke<int, int,T1,T2,R1>(mid, fid, arg1, arg2);
	}
	static public R1 invoke<R1,T1,T2,T3>(string module, string name, T1 arg1, T2 arg2, T3 arg3) {
		int mid = toid(module);
		int fid = toid(name);
		return lua_call.Invoke<int, int,T1,T2,T3,R1>(mid, fid, arg1, arg2, arg3);
	}
	static public R1 invoke<R1,T1,T2,T3,T4>(string module, string name, T1 arg1, T2 arg2, T3 arg3, T4 arg4) {
		int mid = toid(module);
		int fid = toid(name);
		return lua_call.Invoke<int, int,T1,T2,T3,T4, R1>(mid, fid, arg1, arg2, arg3, arg4);
	}

}

*/

