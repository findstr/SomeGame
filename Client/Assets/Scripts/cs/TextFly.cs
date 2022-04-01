using FairyGUI;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;

public class TextFly 
{
	class FlyItem {
		public GObject go;
		public GTextField text;
		public Transition trans;
	};
	public string package = "flytext";
	public string objname = "flytext";
	private ObjectPool<FlyItem> pool;
	private Queue<FlyItem> flying = new Queue<FlyItem>();
        private PlayCompleteCallback FlyComplete = null;
	private void FlyComplete_() {
		var go = flying.Dequeue();
		pool.Release(go);
	}
	private FlyItem Create() 
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
	private void Remove(FlyItem o)
	{
		ZX.Core.UI.RemoveObject(o.go);
	}
	public TextFly() {
		FlyComplete = FlyComplete_;
		pool = new ObjectPool<FlyItem>(Create, null, null, Remove);
	}
	public void Fly(Vector3 pos, string s, Color c) {
		var go = pool.Get();
		GRoot.inst.AddChild(go.go);
		var local = ZX.Core.WorldToFGUI(Camera.main, pos);
		go.go.SetXY(local.x, local.y);
		go.text.text = s;
		go.text.color = c;
		go.trans.Play(FlyComplete);
		flying.Enqueue(go);
	}
	private static readonly TextFly _inst = new();
	public static TextFly Instance {
		get {
			return _inst;
		}
	}
	
}

