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
    public class UI {
        private int pkg_idx = 0;
        private int ud_idx = 0;
        private string prefix = "";
        List<int> pkg_id_pool = new List<int>();
        Dictionary<int, PackageItem> ud_map = new Dictionary<int, PackageItem>();
        Dictionary<int, UIPackage> id_to_package = new Dictionary<int, UIPackage>();
        Dictionary<string, int> name_to_packageid = new Dictionary<string, int>();
        Dictionary<string , UIPackage> dead_package = new Dictionary<string, UIPackage>();
        static void unload_audio (AudioClip asset)  {
            RL.Instance.unload_asset(asset);
        }
        static void unload_texture(Texture asset) {
            RL.Instance.unload_asset(asset);
        }
	    
        void LoadCB(UnityEngine.Object obj, string name, int ud) {
            PackageItem pi;
            if (!ud_map.TryGetValue(ud, out pi)) {
                Debug.LogWarning(string.Format("ZX.UI load_cb incorrect ud:{0} of {1}", ud, name));
                return ;
            }
            pi.owner.SetItemAsset(pi, obj as object, DestroyMethod.Custom);
        }

        void LoadAsync(string name, string extension, System.Type type, PackageItem item) {
            Debug.Log("load_async:" + name);
            ud_map[ud_idx] = item;
            RL.Instance.load_asset_async(name + extension, type, LoadCB, ud_idx++);
        }
 
        public UI () {
            NAudioClip.CustomDestroyMethod = unload_audio;
            NTexture.CustomDestroyMethod -= unload_texture;
            NTexture.CustomDestroyMethod += unload_texture;
        }
       
        public void SetPathPrefix(string s) {
            prefix = s;
        }

        public int AddPackage(string package) {
            if (name_to_packageid.TryGetValue(package, out int id))
                return id;
            if (pkg_id_pool.Count > 0) {
                int i = pkg_id_pool.Count - 1;
                id = pkg_id_pool[i];
                pkg_id_pool.RemoveAt(i);
            } else {
                id = pkg_idx++;
            }
            if (dead_package.TryGetValue(package, out UIPackage pkg)) {//try resurrect uipackage
                    pkg.ReloadAssets();
            } else {
                var name = string.Format("{0}/{1}", prefix, package);
                var path = name + "_fui.bytes";
                var abr = RL.Instance.load_asset(path, typeof(TextAsset));
                pkg = UIPackage.AddPackage((abr.asset as TextAsset).bytes, name, LoadAsync);
                RL.Instance.unload_asset(abr);
                if (pkg == null) 
                    return -1;
            }
            id_to_package.Add(id, pkg);
            name_to_packageid.Add(package, id);
            return id;
        }

        public void RemovePackage(int id) {
            if (id_to_package.TryGetValue(id, out UIPackage pkg)) {
                id_to_package.Remove(id);
                name_to_packageid.Remove(pkg.name);
                dead_package.Add(pkg.name, pkg);
                pkg.UnloadAssets();
                //TODO:use LRU to evict package
            }
        }

        public GObject CreateObject(int id, string resName) {
            if (!id_to_package.TryGetValue(id, out UIPackage pkg))
                return null;
            return pkg.CreateObject(resName);
        }

        public void CreateObjectAsync(int id, string resName, CreateObjectCallback callback) {
            if (!id_to_package.TryGetValue(id, out UIPackage pkg))
                return ;
            pkg.CreateObjectAsync(resName, callback);
        }

        public void RemoveAllPackages() {
                UIPackage.RemoveAllPackages();
		pkg_id_pool.Clear();
		ud_map.Clear();
		id_to_package.Clear();
		name_to_packageid.Clear();
		dead_package.Clear();
        }
    }
}

