using UnityEngine;
using UnityEngine.SceneManagement;

namespace ZX { 

public abstract class IRE {
	public abstract void load(IRL.AssetRequest ar);
};

public abstract class IRL {
	public abstract class BundleRequest {
		abstract public AssetBundle assetBundle { get; }
	};
	public abstract class AssetRequest {
		abstract public Object asset { get; }
		abstract public Object[] allAssets { get; }
	};
	public delegate void init_cb_t();
	public delegate void load_cb_t(Object obj, string name, int ud);
	public abstract void start(init_cb_t cb);
	public abstract void stop();
	public abstract AssetRequest load_asset(string name, System.Type T);
	public abstract AssetRequest load_asset(string name);
	public abstract AssetRequest load_asset<T>(string name) where T : UnityEngine.Object;

	public abstract void load_asset_async(string name, System.Type T, load_cb_t cb, int ud);
	public abstract void unload_asset(string name);
	public abstract void unload_asset(AssetRequest o);
	public abstract void unload_asset(Object obj);
	public abstract BundleRequest load_bundle(string name);
	public abstract void unload_bundle(BundleRequest br);
	public abstract void LoadScene(string name, LoadSceneMode mode);
	public abstract AsyncOperation load_scene_async(string name, LoadSceneMode mode);
	public abstract AsyncOperation unload_scene_async(string name);
	public abstract void set_active_scene(string scenepath);
	public abstract void update();
};

}
