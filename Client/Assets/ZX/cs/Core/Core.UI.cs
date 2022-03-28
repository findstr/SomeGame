using FairyGUI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using static FairyGUI.UIPackage;

namespace ZX {
static partial class Core {
	static public UI UI = null;
	static void InitUI() {
		if (UI != null)
			UI.RemoveAllPackages();
		UI = new UI();
		UIObjectFactory.SetLoaderExtension(typeof(ZXGLoader));
	}
        static public void SetPathPrefix(string s) {
		UI.SetPathPrefix(s);
        }
	static public GObject CreateObject(int package, int name) {
		return UI.CreateObject(Strings.Get(package), Strings.Get(name));
        }
        static public void CreateObjectAsync(int package, int name, CreateObjectCallback callback) {
		UI.CreateObjectAsync(Strings.Get(package), Strings.Get(name), callback);
	}
	static public void RemoveObject(GObject obj) {
		UI.RemoveObject(obj);
	}
	static public Vector3 ScreenPosition(GObject obj) {
		var pos = obj.LocalToGlobal(Vector2.zero);
		pos.y = Screen.height - pos.y;
		return new Vector3(pos.x, pos.y, 0);
	}	
}}

