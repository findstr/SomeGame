using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace ZX { 

public abstract class IRE {
	public abstract void load(IRL.AssetRequest ar);
};

public abstract class IRL {
	public class LoadResult {
		public int ud;
		public string name;
		public load_cb_t callback;
		public List<string> names = null;
		public List<AssetRequest> assets = null;
	};
	public abstract class BundleRequest {
		abstract public AssetBundle assetBundle { get; }
	};
	public abstract class AssetRequest {
		abstract public Object asset { get; }
		abstract public Object[] allAssets { get; }
	};
	public delegate void load_cb_t(LoadResult result);

	public abstract void start();
	public abstract void stop();

	public abstract AssetRequest load_asset(int id, System.Type T = null);

	public abstract AssetRequest load_asset(string name, System.Type T = null);
	public abstract void load_asset_async(string name, System.Type T, load_cb_t cb, int ud);
	public abstract void load_asset_async(List<string> names, System.Type T, load_cb_t cb, int ud);

	public abstract void unload_asset(string name);
	public abstract void unload_asset(AssetRequest o);
	public abstract void unload_asset(Object obj);

	public abstract void load_scene(string name, LoadSceneMode mode);
	public abstract AsyncOperation load_scene_async(string name, LoadSceneMode mode);
	public abstract AsyncOperation unload_scene_async(string name);

	public abstract void set_active_scene(string scenepath);
	public abstract void update();
};

}
