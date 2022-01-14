using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace ZX
{

    public class RM : IRL
    {
        private class AssetRef : AssetRequest
        {
            public override Object asset { get { return _asset; } }
            public override Object[] allAssets { get { return _allAssets; } }
            public Object _asset = null;
            public Object[] _allAssets = null;
            public AssetRef(Object asset)
            {
                _asset = asset;
                _allAssets = new Object[] { asset };
            }
            public AssetRef(Object[] all)
            {
                _allAssets = all;
                _asset = all[0];
            }
        };
        private struct Async
        {
            public Async(string name, Object asset, load_name_cb_t cb, int ud)
            {
                this.name = name;
                this.asset = asset;
                this.cb = cb;
                this.ud = ud;
            }
            public string name;
            public Object asset;
            public load_name_cb_t cb;
            public int ud;
        };
        private Dictionary<string, string> asset_path = null;
        private List<Async> finish_cb = new List<Async>();
        private List<string> scene_activing = new List<string>();
        private void DBGPRINT(string str)
        {
            Debug.Log(str);
        }
        public override void start()
        {
#if UNITY_EDITOR
                var abt = new ABT(UnityEditor.EditorUserSettings.GetConfigValue("zx.buildab.config"));
                asset_path = abt.GetFullName();
#endif
        }
        public override void stop()
        {

        }
        public override AssetRequest load_asset(string name, System.Type T)
        {
#if UNITY_EDITOR
            name = asset_path[name];
            var res = UnityEditor.AssetDatabase.LoadAssetAtPath(name, T);
            return new AssetRef(res);
#else
		return new AssetRef(new Object[0]);
#endif
        }
        public override void unload_asset(AssetRequest o)
        {
            for (int i = 0; i < o.allAssets.Length; i++)
                Resources.UnloadAsset(o.allAssets[i]);
        }
        public override void load_asset_async(string name, System.Type T, load_name_cb_t cb, int ud)
        {
#if UNITY_EDITOR
            name = asset_path[name];
            var res = UnityEditor.AssetDatabase.LoadAssetAtPath(name, T);
            finish_cb.Add(new Async(name, res, cb, ud));
#endif
        }
        public override void unload_asset(Object obj)
        {
            if (!(obj is GameObject || obj is Component))
                Resources.UnloadAsset(obj);
        }
        public override void unload_asset(string name)
        {
            //Do nothing
        }
        public override void load_scene(string name, LoadSceneMode mode)
        {
            name = name.ToLower();
            DBGPRINT("RM:load_scene:" + name);
            var scenename = System.IO.Path.GetFileNameWithoutExtension(name);
            SceneManager.LoadScene(scenename, mode);
        }
        public override AsyncOperation load_scene_async(string name, LoadSceneMode mode)
        {
            name = name.ToLower();
            DBGPRINT("RM:load_scene_async:" + name);
            var scenename = System.IO.Path.GetFileNameWithoutExtension(name);
            return SceneManager.LoadSceneAsync(scenename, mode);
        }
        public override AsyncOperation unload_scene_async(string name)
        {
            name = name.ToLower();
            DBGPRINT("RM:unload_scene_async:" + name);
            var scenename = System.IO.Path.GetFileNameWithoutExtension(name);
            return SceneManager.UnloadSceneAsync(scenename);
        }
        public override void set_active_scene(string scenepath)
        {
            scenepath = scenepath.ToLower();
            var scenename = System.IO.Path.GetFileNameWithoutExtension(scenepath);
            scene_activing.Add(scenename);
            DBGPRINT("RM:set_active_scene:" + scenename);
        }
        public override void update()
        {
            var siter = scene_activing.GetEnumerator();
            while (siter.MoveNext()) {
                var scene = SceneManager.GetSceneByName(siter.Current);
                SceneManager.SetActiveScene(scene);
                DBGPRINT("RM: set_active_scene really:" + siter.Current);
            }
            scene_activing.Clear();
            var cbs = finish_cb;
            if (cbs.Count == 0)
                return;
            finish_cb = new List<Async>();
            var cbiter = cbs.GetEnumerator();
            while (cbiter.MoveNext()) {
                var asset = cbiter.Current.asset;
                var ud = cbiter.Current.ud;
                var name = cbiter.Current.name;
                cbiter.Current.cb(asset, name, ud);
            }
        }

		public override void load_asset_async(List<string> names, System.Type T, load_cb_t cb, int ud)
		{
			throw new System.NotImplementedException();
		}

		public override AssetRequest load_asset(int id, System.Type T = null)
		{
			throw new System.NotImplementedException();
		}
	}
}

