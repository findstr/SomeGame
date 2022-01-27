using FairyGUI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static FairyGUI.UIPackage;

namespace ZX {
static partial class Core {
	static public UI UI = null;
	static void InitUI() {
		if (UI != null)
			UI.RemoveAllPackages();
		UI = new UI();
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
}}

