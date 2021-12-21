using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace ZX { 

public class RFrame {
	private bool isfree = false;

    public string name = null;

    private Array<IRL.AssetRequest> list = new Array<IRL.AssetRequest>(64);
	public void record(IRL.AssetRequest ar) {
		if (!(ar.asset is AudioClip))
			list.push(ar);
	}
	public void dispose() {
		
        for (int i = 0; i < list.count; i++) {
#if UNITY_EDITOR
            Debug.Log("RFrame:" + name + ":dispose:" + list[i]);
#endif
            RL.Instance.unload_asset(list[i]);
        }
		list.clear();
		 
	}
}

public class RStack : IRE {
	private RFrame stktop = null;
	private bool stktop_is_free = false;
	private Stack<RFrame> stk = new Stack<RFrame>();
	private static RStack inst = new RStack();
	public static RStack Instance { get {
		return inst;
	}}
	public override void load(IRL.AssetRequest ar) {
		if (stktop != null)
			stktop.record(ar);
	}
	public void open(RFrame rf) {
		if (stktop != null && stktop_is_free == false)
			stk.Push(stktop);
		stktop_is_free = true;
		stktop = rf;
		return ;
	}
	private void popframe() {
		if (stk.Count > 0)
			stktop = stk.Pop();
		else
			stktop = null;
		stktop_is_free = false;
	}
	public void close() {
		if (stktop_is_free == false)
			return ;
		popframe();
	}
	public RFrame push(string name = null) {
		RFrame rf = new RFrame();
#if UNITY_EDITOR
        rf.name = name;
#endif
        open(rf);
		stktop_is_free = false;
        return rf;
		//Debug.Log("=================RStack.Push======================");
	}
	public void pop() {
		close();
		//Debug.Log("=================RStack.Pop======================");
		if (stktop == null) {
			Debug.LogWarning("RStack.pop: stack is empty");
		} else {
			stktop.dispose();
			popframe();
		}
	}
	public void stop() {
		inst = new RStack();
	}
}

}

