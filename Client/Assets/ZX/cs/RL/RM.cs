using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;
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
		private Dictionary<string, string> asset_path = null;
		private ObjectPool<LoadResult> result_pool = null;
		private List<LoadResult> loading = null;
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
			result_pool = new ObjectPool<LoadResult>(LoadResult.Create);
			loading = new List<LoadResult>();
#endif
		}
		public override void stop()
		{

		}
		public override AssetRequest load_asset(string name, System.Type T)
		{
#if UNITY_EDITOR
			if (T == null)
				T = typeof(UnityEngine.Object);
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
		public override void load_asset_async(string name, System.Type T, load_cb_t cb, int ud)
		{
#if UNITY_EDITOR
			var result = result_pool.Get();
			result.name = name;
			result.ud = ud;
			result.callback = cb;
			result.assets = ListPool<AssetRequest>.Get();
			result.assets.Add(load_asset(name, T));
			loading.Add(result);
#endif
		}
		public override void load_asset_async(List<string> names, System.Type T, load_cb_t cb, int ud)
		{
			var result = result_pool.Get();
			result.names = names;
			result.ud = ud;
			result.callback = cb;
			result.assets = ListPool<AssetRequest>.Get();
			for (int i = 0; i < names.Count; i++) {
				result.assets.Add(load_asset(names[i], T));
			}
			loading.Add(result);
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
			DBGPRINT("RM:load_scene:" + name);
			name = asset_path[name];
			var scenename = System.IO.Path.GetFileNameWithoutExtension(name);
			SceneManager.LoadScene(scenename, mode);
		}
		public override AsyncOperation load_scene_async(string name, LoadSceneMode mode)
		{
			DBGPRINT("RM:load_scene_async:" + name);
			name = asset_path[name];
			var scenename = System.IO.Path.GetFileNameWithoutExtension(name);
			return SceneManager.LoadSceneAsync(scenename, mode);
		}
		public override AsyncOperation unload_scene_async(string name)
		{
			DBGPRINT("RM:unload_scene_async:" + name);
			name = asset_path[name];
			var scenename = System.IO.Path.GetFileNameWithoutExtension(name);
			return SceneManager.UnloadSceneAsync(scenename);
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
			for (int i = loading.Count - 1; i >= 0; i--) {
				var lr = loading[i];
				loading.RemoveAt(i);
				lr.callback(lr);
				ListPool<AssetRequest>.Release(lr.assets);
				lr.assets = null;
				result_pool.Release(lr);
			}
		}
	}
}

