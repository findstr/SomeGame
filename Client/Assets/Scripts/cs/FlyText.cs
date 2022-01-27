using FairyGUI;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;

[XLua.LuaCallCSharp]
public class FlyText : MonoBehaviour
{
	class FlyItem {
		public GObject go;
		public GTextField gt;
		public Transition trans;
	};
	string package;
	string objname;
	ObjectPool<FlyItem> pool;
	Queue<FlyItem> flying = new Queue<FlyItem>();
        PlayCompleteCallback FlyComplete = null;
	void FlyComplete_() {
		var go = flying.Dequeue();
		pool.Release(go);
	}
	void OnAwake() {
		FlyComplete = FlyComplete_;
		pool = new ObjectPool<FlyItem>(Create, null, null, Remove);
	}
	FlyItem Create() 
	{
		var go = ZX.Core.UI.CreateObject(package, objname) as GComponent;
		var gt = go.GetChild(objname) as GTextField;
		var ctrl = go.GetTransition("ctrl");
		return new FlyItem {
			go = go,
			gt = gt,
			trans = ctrl,
		};
	}
	void Remove(FlyItem o)
	{
		ZX.Core.UI.RemoveObject(o.go);
	}
	public void Init(int package, int name) 
	{
		this.package = ZX.Core.Strings.Get(package);
		this.objname = ZX.Core.Strings.Get(name);
	}

	public void Fly(Vector3 pos, int id) {
		var s = ZX.Core.Strings.Get(id);
		var go = pool.Get();
		go.go.SetPosition(pos.x, pos.y, pos.z);
		go.trans.Play(FlyComplete);
		flying.Enqueue(go);
	}
	
}

