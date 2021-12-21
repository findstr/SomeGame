#if UNITY_IOS
#define LOAD_BLOCK
#else
#define LOAD_ASYNC
#endif

using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace ZX {

public class ABM : IRL {
	private class Bundle : BundleRequest {
		public Bundle (string path) {
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
		public void load () {
			request = AssetBundle.LoadFromFileAsync (path);
		}
		public void unload (bool all) {
			assetBundle.Unload (all);
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
		public Bundle[] dependcies = null;
	};
	private class Asset : AssetRequest {
		public Asset (Bundle bundle, string name) {
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
					UnityEngine.Debug.LogWarning ("ABM:" + name + ":is droped");
				}
				return null;
			}
		}
		public override Object[] allAssets { get { return request.allAssets; } }
	};
	private struct callback {
		public load_cb_t cb;
		public int ud;
		public string name;
		public callback (load_cb_t cb, int x, string n) {
			this.cb = cb;
			this.ud = x;
			this.name = n;
		}
	}
	private static void DBGPRINT (string str) {
		//UnityEngine.Debug.Log(str);
	}
	private init_cb_t init_cb = null;
	public int progress_total { get; private set; }
	public int progress_current { get; private set; }
	private LRU<Bundle> lru_bundle = null;
	private int load_cb_ping = 0;
	private bool dependcy_ok = false;
	private Dictionary<string, Bundle> all_bundles = new Dictionary<string, Bundle> ();
	private Dictionary<string, Asset> name_to_asset = new Dictionary<string, Asset> ();
	private Dictionary<Object, AssetRequest> object_to_asset = new Dictionary<Object, AssetRequest> ();
	private Dictionary<string, List<callback>>[] load_cb = new Dictionary<string, List<callback>>[2];
	private List<string> scene_activing = new List<string> ();
	private List<Asset> unload_pending = new List<Asset> ();
	private void assert (bool x) {
#if UNITY_EDITOR_WIN || UNITY_STANDALONE_WIN
		UnityEngine.Debug.Assert (x);
#endif
	}
	public ABM () {
		load_cb[0] = new Dictionary<string, List<callback>> ();
		load_cb[1] = new Dictionary<string, List<callback>> ();
		lru_bundle = new LRU<Bundle> (8, drop_bundle);
	}
	private string determine_path (string name) {
#if UNITY_STANDALONE_WIN
		var abspath = Application.persistentDataPath + "/windows/" + name;
#elif UNITY_IOS
		var abspath = Application.persistentDataPath + "/ios/" + name;
#elif UNITY_ANDROID
		var abspath = Application.persistentDataPath + "/android/" + name;
#elif UNITY_STANDALONE_OSX
		var abspath = Application.persistentDataPath + "/windows/" + name;
#endif
		if (!File.Exists (abspath)) {
#if UNITY_STANDALONE_WIN
			abspath = Application.streamingAssetsPath + "/windows/" + name;
#elif UNITY_IOS
			abspath = Application.streamingAssetsPath + "/ios/" + name;
#elif UNITY_ANDROID
			abspath = Application.streamingAssetsPath + "/android/" + name;
#elif UNITY_STANDALONE_OSX
			abspath = Application.persistentDataPath + "/windows/" + name;
#endif
		}
		return abspath;
	}

	private Stopwatch sw = new Stopwatch ();
	static private void drop_bundle (Bundle obj) {
		DBGPRINT ("ABM: drop_bundle:" + obj.path);
		obj.unload (true);
	}
	private void drop_asset(Asset obj) {
		DBGPRINT("ABM: drop_asset:" + obj.name);		

		if (obj.request == null)
			return ;
		//UnityEngine.Debug.LogWarning("drop_asset:" + obj.name);
		
		/*if (dependcy_ok == true) {
			foreach (var x in obj.request.allAssets) {
				if (!(x is GameObject || x is Component))
					Resources.UnloadAsset(x);
			}
		}*/
		obj.request = null;
		unload_bundle_ (obj.inbundle);
	}
	private void build_bundleinfo() {
		var path = determine_path("main");
		var ab = AssetBundle.LoadFromFile(path);
		var MANIFEST = ab.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
		var all = MANIFEST.GetAllAssetBundles();
		all_bundles = new Dictionary<string,Bundle>();
		for (int i = 0; i < all.Length; i++) {
			var name = all[i];
			var bundle = new Bundle (determine_path (name));
			all_bundles[name] = bundle;
		}
		var iter = all_bundles.GetEnumerator ();
		while (iter.MoveNext ()) {
			var bundle = iter.Current.Value;
			var depend = MANIFEST.GetAllDependencies(iter.Current.Key);
			bundle.dependcies = new Bundle[depend.Length];
			for (int j = 0; j < depend.Length; j++)
				bundle.dependcies[j] = all_bundles[depend[j]];
		}
		ab.Unload (true);
		return;
	}
	private void build_assetinfo() {
		int i = 0;
		sw.Restart();
		var iter = all_bundles.GetEnumerator();
		while (iter.MoveNext()) {
			var bundle = iter.Current.Value;
			bundle.load();
		}
		sw.Start();
		iter = all_bundles.GetEnumerator();
		while (iter.MoveNext()) {
			var bundle = iter.Current.Value;
			var ab = bundle.assetBundle;
			var asset_child = ab.GetAllAssetNames();
			var scene_child = ab.GetAllScenePaths();
			for (int j = 0; j < asset_child.Length; j++) {
				var s = asset_child[j];
				var a = new Asset(bundle, s);
				name_to_asset[s] = a;
			}
			for (int j = 0; j < scene_child.Length; j++) {
				var s = scene_child[j];
				var a = new Asset(bundle, s);
				UnityEngine.Debug.Log("Scene:" + s);
				name_to_asset[s] = a;
			}
			bundle.unload(true);
		}
		sw.Stop();
		DBGPRINT("LoadAll:takes:" + sw.ElapsedMilliseconds);
	}
	public override void start (init_cb_t cb) {
		build_bundleinfo ();
		build_assetinfo ();
		init_cb = cb;
	}
	public override void stop () {
		if (all_bundles == null)
			return;
		var iter = all_bundles.GetEnumerator ();
		while (iter.MoveNext ()) {
			var bundle = iter.Current.Value;
			if (bundle.assetBundle != null)
				bundle.unload (true);
		}
	}
	List<Bundle> bundle_pending = new List<Bundle>();
	private void try_load_bundle(Bundle bundle) {
		++bundle.refn;
		if (bundle.refn > 1) { //loaded
			DBGPRINT ("ABM: load_bundle:" + bundle.path + ":" + bundle.refn + ": ref");
			assert(bundle.assetBundle != null);
			return ;
		}
		if (bundle.assetBundle == null) {
			assert(bundle.refn == 1);
			bundle.load ();
			bundle_pending.Add(bundle);
			DBGPRINT ("ABM: load_bundle:" + bundle.path + ":" + bundle.refn + ": pending");
		} else {
			lru_bundle.remove(bundle);
			DBGPRINT ("ABM: load_bundle:" + bundle.path + ":" + bundle.refn + ": cache");
		}
		return ;
	}
	private void try_unload_bundle(Bundle bundle) {
		DBGPRINT("ABM: unload_bundle:" + bundle.path + ":" + bundle.refn + ": ref");
		int refn = --bundle.refn;
		assert (refn >= 0);
		if (refn > 0)
			return;
		//put it into lru_cache for unload in future
		lru_bundle.add(bundle);
		DBGPRINT("ABM: unload_bundle:" + bundle.path + ":" + bundle.refn + ": cache");
		return ;
	}
	private Bundle load_bundle_(Bundle bundle) {
		try_load_bundle(bundle);
		for (int i = 0; i < bundle.dependcies.Length; i++) {
			var b = bundle.dependcies[i];
			try_load_bundle(b);
			DBGPRINT("ABM: load_bundle:" + b.path + ":" + b.refn);
		}
		for (int i = 0; i < bundle_pending.Count; i++) {
			var b = bundle_pending[i];
			var ab = b.assetBundle;
			assert (ab != null);
		}
		bundle_pending.Clear();
		DBGPRINT ("ABM: load_bundle:" + bundle.path + ":" + bundle.refn);
		return bundle;
	}
	private void unload_bundle_(Bundle bundle) {
		try_unload_bundle(bundle);
		for (int i = 0; i < bundle.dependcies.Length; i++) {
			var b = bundle.dependcies[i];
			try_unload_bundle(b);
		}
	}
	private void depend(Asset asset) {
		int refn = ++asset.refn;
		DBGPRINT("ABM: depend:" + asset.name + " refn:" + refn);

		
	}
	private void undepend(Asset asset) {
		int refn = --asset.refn;
		DBGPRINT("ABM: undepend:" + asset.name + " refn:" + refn);

		if (refn > 0) //not the last
			return ;
		assert(asset.refn == 0);
		asset.refn = 0;
		unload_pending.Add(asset);
		return ;
	}
	public override AssetRequest load_asset (string name, System.Type T) {
		Asset asset = null;
		name = name.ToLower ();
		if (!name_to_asset.TryGetValue (name, out asset)) {
			UnityEngine.Debug.LogWarningFormat ("ABM: load_asset unknown resource of '{0}'", name);
			return null;
		}
		depend(asset);
		if (asset.request == null) {
			DBGPRINT("DEBUG:load_asset:" + asset.name + ":" + asset.refn);
			var ab = load_bundle_ (asset.inbundle);
			asset.request = ab.assetBundle.LoadAssetAsync (name, T);
		}
		DBGPRINT ("ABM: load_asset:" + name + " refn:" + asset.refn);
		return asset;
	}

	public override AssetRequest load_asset<T> (string name) {
		return load_asset (name, typeof (T));
	}
	public override AssetRequest load_asset (string name) {
		return load_asset (name, typeof (UnityEngine.Object));
	}
	public override void unload_asset (AssetRequest o) {
		Asset asset = o as Asset;
		if (asset == null) {
			UnityEngine.Debug.LogWarningFormat ("ABM: unload_asset '{0}' : invalid", o);
			return;
		}
		undepend(asset);
		DBGPRINT("ABM:unload_asset:" + asset.name + ":refn:" + asset.refn + " bundle:" + asset.inbundle.path + ":ref:" + asset.inbundle.refn);
		return;
	}
	public override void load_asset_async (string name, System.Type T, load_cb_t cb, int ud) {
		var lower = name.ToLower ();
		AssetRequest ar = load_asset (lower, T);
		if (ar == null) {
			lower = "Viewport.png";
			ar = load_asset (lower, T);
			if (ar == null) {
				cb (null, name, ud);
				return;
			}
		}
		List<callback> list = null;
		if (!load_cb[load_cb_ping].TryGetValue (lower, out list)) {
			list = new List<callback> ();
			load_cb[load_cb_ping].Add (lower, list);
		}
		list.Add (new callback (cb, ud, name));
	}
	public override void unload_asset (Object obj) {
		AssetRequest ar;
		if (!object_to_asset.TryGetValue (obj, out ar)) {
			UnityEngine.Debug.LogWarningFormat ("ABM: unload_asset '{0}' duplicated:", obj);
			return;
		}
		unload_asset (ar);
		return;
	}
	public override void unload_asset(string name) {
		Asset asset;
		name = name.ToLower();
		if (!name_to_asset.TryGetValue(name, out asset)) {
			UnityEngine.Debug.LogWarningFormat ("ABM: unload_asset unknown resource of '{0}'", name);
			return;
		}
		unload_asset(asset);
	}

	public override BundleRequest load_bundle (string name) {
		Bundle b;
		if (!all_bundles.TryGetValue (name, out b)) {
			UnityEngine.Debug.LogWarningFormat ("ABM: load_bundle_async '{0}' duplicated:", name);
			return null;
		}
		return load_bundle_ (b);
	}
	public override void unload_bundle (BundleRequest br) {
		Bundle b = (Bundle) br;
		unload_bundle_ (b);
	}

	public override void LoadScene (string name, LoadSceneMode mode) {
		Asset asset;
		if (!name_to_asset.TryGetValue (name, out asset)) {
			UnityEngine.Debug.LogWarningFormat ("ABM: load_scene unknown resource of '{0}'", name);
			return;
		}
		depend(asset);
		load_bundle_ (asset.inbundle);
		var scenename = Path.GetFileNameWithoutExtension (name);
		SceneManager.LoadScene (scenename, mode);
		DBGPRINT ("load_scene:" + scenename);
		return;
	}
	public override AsyncOperation load_scene_async (string name, LoadSceneMode mode) {
		Asset asset;
		if (!name_to_asset.TryGetValue (name, out asset)) {
			UnityEngine.Debug.LogWarningFormat ("ABM: load_scene_async unknown resource of '{0}'", name);
			return null;
		}
		depend(asset);
		load_bundle_ (asset.inbundle);
		var scenename = Path.ChangeExtension (name, null);
		return SceneManager.LoadSceneAsync (scenename, mode);
	}
	public override AsyncOperation unload_scene_async (string name) {
		Asset asset;
		if (!name_to_asset.TryGetValue (name, out asset)) {
			UnityEngine.Debug.LogWarningFormat ("ABM: unload_scene_async unknown resource of '{0}'", name);
			return null;
		}
		undepend(asset);
		unload_bundle_ (asset.inbundle);
		var scenename = Path.GetFileNameWithoutExtension (name);
		return SceneManager.UnloadSceneAsync (scenename);
	}
	public override void set_active_scene (string scenepath) {
		var scenename = Path.GetFileNameWithoutExtension (scenepath);
		scene_activing.Add (scenename);
		DBGPRINT ("set_active_scene:" + scenename);
	}
	private void update_operation () {
		var iter = scene_activing.GetEnumerator ();
		while (iter.MoveNext ()) {
			var scene = SceneManager.GetSceneByName (iter.Current);
			SceneManager.SetActiveScene (scene);
			DBGPRINT ("set_active_scene really:" + iter.Current);
		}
		scene_activing.Clear();
	}
	private void update_load_pending () {
		var cb = load_cb[load_cb_ping];
		if (cb.Count == 0)
			return;
		load_cb_ping = (load_cb_ping + 1) % 2;
		var iter = cb.GetEnumerator ();
		while (iter.MoveNext ()) {
			var name = iter.Current.Key;
			var cblist = iter.Current.Value;
			var cbiter = cblist.GetEnumerator ();
			var abr = name_to_asset[name];
			var res = abr.asset;
			if (res != null)
				object_to_asset[res] = abr;
			while (cbiter.MoveNext ())
				cbiter.Current.cb (res, cbiter.Current.name, cbiter.Current.ud);
		}
		cb.Clear ();
	}
	private void update_unload_pending() {
		foreach (var x in unload_pending) {
			if (x.refn <= 0)
				drop_asset(x);
		}
		unload_pending.Clear ();
	}
	public override void update () {
		if (init_cb != null) {

			init_cb ();
			init_cb = null;
		}
		update_operation ();
		update_load_pending ();
		update_unload_pending();
	}
}

}
