using FairyGUI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Pool;
using static FairyGUI.UIPackage;

namespace ZX
{
	public class UI
	{
		private int ud_idx = 0;
		private string prefix = "";
		Dictionary<UIPackage, int> package_ref = new Dictionary<UIPackage, int>();
		Dictionary<int, PackageItem> ud_map = new Dictionary<int, PackageItem>();
		IRL.load_cb_t ui_load_callback = null;
		static void unload_audio(AudioClip asset)
		{
			RL.Instance.unload_asset(asset);
		}
		static void unload_texture(Texture asset)
		{
			RL.Instance.unload_asset(asset);
		}

		void LoadCB(IRL.LoadResult result)
		{
			PackageItem pi;
			if (!ud_map.TryGetValue(result.ud, out pi)) {
				Debug.LogWarning(string.Format("ZX.UI load_cb incorrect ud:{0} of {1}", result.ud, result.name));
				return;
			}
			pi.owner.SetItemAsset(pi, result.assets[0].asset, DestroyMethod.Custom);
		}

		void LoadAsync(string name, string extension, System.Type type, PackageItem item)
		{
			ud_map[ud_idx] = item;
			RL.Instance.load_asset_async(name + extension, type, ui_load_callback, ud_idx++);
		}

		public UI()
		{
			NAudioClip.CustomDestroyMethod = unload_audio;
			NTexture.CustomDestroyMethod -= unload_texture;
			NTexture.CustomDestroyMethod += unload_texture;
			ui_load_callback = LoadCB;
		}

		public void SetPathPrefix(string s)
		{
			prefix = s;
		}
		
		private UIPackage AddPackage(string package)
		{
			var pkg = GetByName(package);
			if (pkg != null) {
				int n = package_ref[pkg];
				package_ref[pkg] = n + 1;
				if (n == 0) //try resurrent UIPackage
					pkg.ReloadAssets();
			} else {
				var name = string.Format("{0}/{1}", prefix, package);
				var path = name + "_fui.bytes";
				var abr = RL.Instance.load_asset(path, typeof(TextAsset));
				pkg = UIPackage.AddPackage((abr.asset as TextAsset).bytes, name, LoadAsync);
				RL.Instance.unload_asset(abr);
				if (pkg != null)
					package_ref[pkg] = 1;
			}
			return pkg;
		}

		private void RemovePackage(UIPackage pkg)
		{
			int n = package_ref[pkg];
			package_ref[pkg] = n - 1;
			if (n == 1) {
				pkg.UnloadAssets();
				//TODO:use LRU to evict package
			}
		}

		public GObject CreateObject(string package, string name)
		{
			var pkg = AddPackage(package);
			if (pkg == null)
				return null;
			return pkg.CreateObject(name);
		}

		public void CreateObjectAsync(string package, string name, CreateObjectCallback callback)
		{
			var pkg = AddPackage(package);
			if (pkg == null)
				return ;
			pkg.CreateObjectAsync(name, callback);
		}

		public void RemoveObject(GObject go)
		{
			var pkg = go.packageItem.owner;
			RemovePackage(pkg);
			go.Dispose();
		}

		public void RemoveAllPackages()
		{
			UIPackage.RemoveAllPackages();
			ud_map.Clear();
			package_ref.Clear();
		}
	}
}

