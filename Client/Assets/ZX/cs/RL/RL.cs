using XLua;
namespace ZX { 

[LuaCallCSharp]
public class RL {
	public enum Mode {
		RM = 1,
		ABM = 2,
	};
	private static IRL _instance = null;
	public static void Start(Mode m) {
		if (_instance != null)
			_instance.stop();
		if (m == Mode.RM)
			_instance = new RM();
		else
			_instance = new ABM();
		return ;
	}
	public static IRL Instance { get {
		return _instance;
	}}
};

}
