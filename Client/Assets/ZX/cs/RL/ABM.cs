#if UNITY_IOS
#define LOAD_BLOCK
#else
#define LOAD_ASYNC
#endif

using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Pool;
using UnityEngine.SceneManagement;

namespace ZX
{
	public class ABM : IRL
	{
		private class Bundle : BundleRequest
		{
			static Bundle[] NULL = new Bundle[0];
			public Bundle(string path)
			{
				this.path = path;
			}
#if LOAD_ASYNC
			//566 ms
			private AssetBundleCreateRequest request = null;
			public override AssetBundle assetBundle {
				get {
					if (request != null)
						return request.assetBundle;
					else
						return null;
				}
			}
			public void load()
			{
				request = AssetBundle.LoadFromFileAsync(path);
			}
			public void unload(bool all)
			{
				assetBundle.Unload(all);
				request = null;
			}
#elif LOAD_BLOCK
			//651 ms
			private AssetBundle asset = null;
			public void load () {
				asset = AssetBundle.LoadFromFile (path);
			}
			public void unload (bool all) {
				asset.Unload (all);
				asset = null;
			}
			public override AssetBundle assetBundle {
				get {
					return asset;
				}
			}
#endif
			public int refn = 0;
			public string path = null;
			public Bundle[] dependencies = NULL;
		};
		private class Asset : AssetRequest
		{
			public Asset(Bundle bundle, string name)
			{
				this.inbundle = bundle;
				this.name = name;
			}
			public int refn = 0;
			public string name = null;
			public Bundle inbundle = null;

			public AssetBundleRequest request = null;
			public bool isDone { get { return request.isDone; } }
			//override AssetReqeust
			public override Object asset {
				get {
					try {
						return request.asset;
					} catch (System.Exception) {
						UnityEngine.Debug.LogWarning("ABM:" + name + ":is droped");
					}
					return null;
				}
			}
			public override Object[] allAssets { get { return request.allAssets; } }
		};

		private static void DBGPRINT(string str)
		{
			//UnityEngine.Debug.Log(str);
		}
		public int progress_total { get; private set; }
		public int progress_current { get; private set; }
		private LRU<Bundle> lru_bundle = null;
		private ObjectPool<LoadResult> result_pool;
		private Dictionary<string, Asset> all_assets = null;
		private Dictionary<string, Bundle> all_bundles = null;
		private Dictionary<Object, AssetRequest> object_to_asset = new Dictionary<Object, AssetRequest>();
		private List<LoadResult> loading = new List<LoadResult>();
		private List<string> scene_activing = new List<string>();
		private List<Asset> unload_pending = new List<Asset>();
		private void assert(bool x)
		{
#if UNITY_EDITOR_WIN || UNITY_STANDALONE_WIN
			UnityEngine.Debug.Assert(x);
#endif
		}
		public ABM()
		{
			lru_bundle = new LRU<Bundle>(8, drop_bundle);
		}
		private string determine_path(string name)
		{
			var abspath = Application.persistentDataPath + name;
			if (!File.Exists(abspath)) {
				abspath = Application.streamingAssetsPath + "/" + name;
			}
			return abspath;
		}

		static private void drop_bundle(Bundle obj)
		{
			DBGPRINT("ABM: drop_bundle:" + obj.path);
			obj.unload(true);
		}

		private void drop_asset(Asset obj)
		{
			DBGPRINT("ABM: drop_asset:" + obj.name);

			if (obj.request == null)
				return;
			obj.request = null;
			unload_bundle_(obj.inbundle);
		}

		private void build_bundleinfo()
		{
			var sw = new System.Diagnostics.Stopwatch();
			sw.Start();
			int i, bundle_count, dependencies_count;
			var path = determine_path("main");
			var ab = AssetBundle.LoadFromFile(path);
			var MANIFEST = ab.LoadAsset<TextAsset>("manifest");
			var lines = MANIFEST.text.Split('\n');
			ab.Unload(true);
			sw.Stop();
			Debug.Log("ABM: start load main bundle takes:" + sw.ElapsedMilliseconds + "ms");
			sw.Restart();
			if (lines.Length < 5)
				throw new System.Exception("ABM: invalid manifest");
			if (lines[0] != "zx.manifest 1.0")
				throw new System.Exception("ABM: invalid manifest");
			bundle_count = int.Parse(lines[1]);
			var bundle_array = new Bundle[bundle_count];
			all_bundles = new Dictionary<string, Bundle>(bundle_count);
			all_assets = new Dictionary<string, Asset>(bundle_count);
			i = 2;
			if (lines[i++] != "+bundles")
				throw new System.Exception("ABM: invalid manifest");
			for (int j = 0; j < bundle_count; j++) {
				var bname = lines[i++];
				var bundle = new Bundle(determine_path(bname));
				bundle_array[j] = bundle;
				all_bundles[bname] = bundle;
			}
			if (lines[i++] != "+assets")
				throw new System.Exception("ABM: invalid manifest");
			for (int j = 0; j < bundle_count; j++) {
				int bundle_id = int.Parse(lines[i++]);
				int count = int.Parse(lines[i++]);
				for (int k = 0; k < count; k++) {
					var asset_name = lines[i++];
					all_assets.Add(asset_name, new Asset(bundle_array[bundle_id], asset_name));
				}
			}
			if (lines[i++] != "+dependencies")
				throw new System.Exception("ABM: invalid manifest");
			dependencies_count = int.Parse(lines[i++]);
			for (int j = 0; j < dependencies_count; j++) {
				var host = lines[i++].Split(',');
				var depend = lines[i++].Split(',');
				var deps = new Bundle[depend.Length];
				for (int k = 0; k < depend.Length; k++)
					deps[k] = bundle_array[int.Parse(depend[i])];
				for (int k = 0; k < host.Length; k++)
					bundle_array[int.Parse(host[i])].dependencies = deps;
			}
			Debug.Log("ABM: parse manifest takes:" + sw.ElapsedMilliseconds + "ms");
			return;
		}

		public override void start()
		{
			build_bundleinfo();
		}
		public override void stop()
		{
			if (all_bundles == null)
				return;
			foreach (var item in all_bundles) {
				var bundle = item.Value;
				if (bundle.assetBundle != null)
					bundle.unload(true);
			}
		}
		List<Bundle> bundle_pending = new List<Bundle>();
		private void try_load_bundle(Bundle bundle)
		{
			++bundle.refn;
			if (bundle.refn > 1) { //loaded
				DBGPRINT("ABM: load_bundle:" + bundle.path + ":" + bundle.refn + ": ref");
				assert(bundle.assetBundle != null);
				return;
			}
			if (bundle.assetBundle == null) {
				assert(bundle.refn == 1);
				bundle.load();
				bundle_pending.Add(bundle);
				DBGPRINT("ABM: load_bundle:" + bundle.path + ":" + bundle.refn + ": pending");
			} else {
				lru_bundle.remove(bundle);
				DBGPRINT("ABM: load_bundle:" + bundle.path + ":" + bundle.refn + ": cache");
			}
			return;
		}
		private void try_unload_bundle(Bundle bundle)
		{
			DBGPRINT("ABM: unload_bundle:" + bundle.path + ":" + bundle.refn + ": ref");
			int refn = --bundle.refn;
			assert(refn >= 0);
			if (refn > 0)
				return;
			//put it into lru_cache for unload in future
			lru_bundle.add(bundle);
			DBGPRINT("ABM: unload_bundle:" + bundle.path + ":" + bundle.refn + ": cache");
			return;
		}
		private Bundle load_bundle_(Bundle bundle)
		{
			try_load_bundle(bundle);
			for (int i = 0; i < bundle.dependencies.Length; i++) {
				var b = bundle.dependencies[i];
				try_load_bundle(b);
				DBGPRINT("ABM: load_bundle:" + b.path + ":" + b.refn);
			}
			for (int i = 0; i < bundle_pending.Count; i++) {
				var b = bundle_pending[i];
				var ab = b.assetBundle;
				assert(ab != null);
			}
			bundle_pending.Clear();
			DBGPRINT("ABM: load_bundle:" + bundle.path + ":" + bundle.refn);
			return bundle;
		}
		private void unload_bundle_(Bundle bundle)
		{
			try_unload_bundle(bundle);
			for (int i = 0; i < bundle.dependencies.Length; i++) {
				var b = bundle.dependencies[i];
				try_unload_bundle(b);
			}
		}

		private void depend(Asset asset)
		{
			int refn = ++asset.refn;
			DBGPRINT("ABM: depend:" + asset.name + " refn:" + refn);
		}

		private void undepend(Asset asset)
		{
			int refn = --asset.refn;
			DBGPRINT("ABM: undepend:" + asset.name + " refn:" + refn);

			if (refn > 0) //not the last
				return;
			assert(asset.refn == 0);
			asset.refn = 0;
			unload_pending.Add(asset);
			return;
		}

		public override AssetRequest load_asset(string name, System.Type T)
		{
			if (!all_assets.TryGetValue(name, out Asset asset)) {
				Debug.LogWarningFormat("ABM: load_asset unknown resource of '{0}'", name);
				return null;
			}
			depend(asset);
			if (asset.request == null) {
				DBGPRINT("DEBUG:load_asset:" + asset.name + ":" + asset.refn);
				var ab = load_bundle_(asset.inbundle);
				asset.request = ab.assetBundle.LoadAssetAsync(name, T);
			}
			DBGPRINT("ABM: load_asset:" + name + " refn:" + asset.refn);
			return asset;
		}

		public override void load_asset_async(string name, System.Type T, load_cb_t cb, int ud)
		{
			var result = result_pool.Get();
			result.name = name;
			result.ud = ud;
			result.callback = cb;
			result.assets = ListPool<AssetRequest>.Get();
			result.assets.Add(load_asset(name, T));
			loading.Add(result);
			return ;
		}

		public override void load_asset_async(List<string> names, System.Type T, load_cb_t cb, int ud)
		{
			var result = result_pool.Get();
			result.names = names;
			result.ud = ud;
			result.callback = cb;
			result.assets = ListPool<AssetRequest>.Get();
			for (int i = 0; i < names.Count; i++) {
				var ar = load_asset(names[i], T);
				result.assets.Add(ar);
			}
			loading.Add(result);
			return ;
		}

		public override void unload_asset(AssetRequest o)
		{
			if (o is not Asset asset) {
				UnityEngine.Debug.LogWarningFormat("ABM: unload_asset '{0}' : invalid", o);
				return;
			}
			undepend(asset);
			DBGPRINT("ABM:unload_asset:" + asset.name + ":refn:" + asset.refn + " bundle:" + asset.inbundle.path + ":ref:" + asset.inbundle.refn);
			return;
		}
		public override void unload_asset(Object obj)
		{
			if (!object_to_asset.TryGetValue(obj, out AssetRequest ar)) {
				UnityEngine.Debug.LogWarningFormat("ABM: unload_asset '{0}' duplicated:", obj);
				return;
			}
			unload_asset(ar);
			return;
		}
		public override void unload_asset(string name)
		{
			if (!name_to_id.TryGetValue(name, out int id)) {
				UnityEngine.Debug.LogWarningFormat("ABM: unload_asset unknown resource of '{0}'", name);
				return;
			}
			unload_asset(all_assets[id]);
		}

		public override void load_scene(string name, LoadSceneMode mode)
		{
			if (!name_to_id.TryGetValue(name, out int id)) {
				UnityEngine.Debug.LogWarningFormat("ABM: load_scene unknown resource of '{0}'", name);
				return;
			}
			var asset = all_assets[id];
			depend(asset);
			load_bundle_(asset.inbundle);
			var scenename = Path.GetFileNameWithoutExtension(name);
			SceneManager.LoadScene(scenename, mode);
			DBGPRINT("load_scene:" + scenename);
			return;
		}

		public override AsyncOperation load_scene_async(string name, LoadSceneMode mode)
		{
			if (!name_to_id.TryGetValue(name, out int id)) {
				UnityEngine.Debug.LogWarningFormat("ABM: load_scene_async unknown resource of '{0}'", name);
				return null;
			}
			var asset = all_assets[id];
			depend(asset);
			load_bundle_(asset.inbundle);
			var scenename = Path.ChangeExtension(name, null);
			return SceneManager.LoadSceneAsync(scenename, mode);
		}
		public override AsyncOperation unload_scene_async(string name)
		{
			if (!name_to_id.TryGetValue(name, out int id)) {
				UnityEngine.Debug.LogWarningFormat("ABM: unload_scene_async unknown resource of '{0}'", name);
				return null;
			}
			var asset = all_assets[id];
			undepend(asset);
			unload_bundle_(asset.inbundle);
			var scenename = Path.GetFileNameWithoutExtension(name);
			return SceneManager.UnloadSceneAsync(scenename);
		}
		public override void set_active_scene(string scenepath)
		{
			var scenename = Path.GetFileNameWithoutExtension(scenepath);
			scene_activing.Add(scenename);
			DBGPRINT("set_active_scene:" + scenename);
		}
		private void update_operation()
		{
			var iter = scene_activing.GetEnumerator();
			while (iter.MoveNext()) {
				var scene = SceneManager.GetSceneByName(iter.Current);
				SceneManager.SetActiveScene(scene);
				DBGPRINT("set_active_scene really:" + iter.Current);
			}
			scene_activing.Clear();
		}
		private void update_load_pending()
		{
			var cb = load_cb[load_cb_ping];
			if (cb.Count == 0)
				return;
			load_cb_ping = (load_cb_ping + 1) % 2;
			var iter = cb.GetEnumerator();
			while (iter.MoveNext()) {
				var id = iter.Current.Key;
				var cblist = iter.Current.Value;
				var cbiter = cblist.GetEnumerator();
				var abr = all_assets[id];
				var res = abr.asset;
				if (res != null)
					object_to_asset[res] = abr;
				while (cbiter.MoveNext())
					cbiter.Current.execute(res);
			}
			cb.Clear();
		}
		private void update_unload_pending()
		{
			foreach (var x in unload_pending) {
				if (x.refn <= 0)
					drop_asset(x);
			}
			unload_pending.Clear();
		}
		public override void update()
		{
			update_operation();
			update_load_pending();
			update_unload_pending();
		}	
	}

}
