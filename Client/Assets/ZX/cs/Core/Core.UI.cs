using FairyGUI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static FairyGUI.UIPackage;

namespace ZX {
static partial class Core {
	static private UI UI = null;
	static void InitUI() {
		if (UI != null)
			UI.RemoveAllPackages();
		UI = new UI();
	}
        static public void SetPathPrefix(string s) {
		UI.SetPathPrefix(s);
        }
        static public int AddPackage(int id) {
		return UI.AddPackage(Strings.Get(id));
	}
        static public void RemovePackage(int id) {
		UI.RemovePackage(id);
        }
	static public GObject CreateObject(int id, int resName) {
		return UI.CreateObject(id, Strings.Get(resName));
        }
        static public void CreateObjectAsync(int id, int resName, CreateObjectCallback callback) {
		UI.CreateObjectAsync(id, Strings.Get(resName), callback);
	}
}}

