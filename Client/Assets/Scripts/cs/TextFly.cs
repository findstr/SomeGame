using FairyGUI;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;

[XLua.LuaCallCSharp]
public class TextFly : MonoBehaviour
{
	class FlyItem {
		public GObject go;
		public GTextField text;
		public Transition trans;
	};
	public string package;
	public string objname;
	ObjectPool<FlyItem> pool;
	Queue<FlyItem> flying = new Queue<FlyItem>();
        PlayCompleteCallback FlyComplete = null;
	void FlyComplete_() {
		var go = flying.Dequeue();
		pool.Release(go);
	}
	void Awake() {
		FlyComplete = FlyComplete_;
		pool = new ObjectPool<FlyItem>(Create, null, null, Remove);
	}
	FlyItem Create() 
	{
		var go = ZX.Core.UI.CreateObject(package, objname) as GComponent;
		var gt = go.GetChild("text") as GTextField;
		var ctrl = go.GetTransition("ctrl");
		return new FlyItem {
			go = go,
			text = gt,
			trans = ctrl,
		};
	}
	void Remove(FlyItem o)
	{
		ZX.Core.UI.RemoveObject(o.go);
	}

	public void Fly(Vector3 pos, string s, Color c) {
		var go = pool.Get();
		GRoot.inst.AddChild(go.go);
		go.go.SetPosition(pos.x, pos.y, pos.z);
		go.text.text = s;
		go.text.color = c;
		go.trans.Play(FlyComplete);
		flying.Enqueue(go);
	}
	
}

