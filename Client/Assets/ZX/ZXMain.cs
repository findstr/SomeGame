using System;
using UnityEngine;
using UnityEngine.InputSystem.EnhancedTouch;

public class ZXMain : MonoBehaviour
{

	public bool UseAB = false;
	public int LogicHZ = 15;
	private void OnEnable()
	{
		EnhancedTouchSupport.Enable();
	}
	void Awake()
	{
		ZX.Core.Prepare(UseAB, LogicHZ);
	}

	public void Start()
	{
		ZX.Core.Start();
	}

	public void Restart()
	{
		Awake();
		Start();
	}

	public void FixedUpdate()
	{
		ZX.Core.FixedUpdate();
	}

	public void Update()
	{
		ZX.Core.Update();
	}

	public void LateUpdate()
	{
		ZX.Core.LateUpdate();
	}

#if ZX_DEBUG
	private GUIStyle guiStyle = new GUIStyle();
	private void OnGUI()
	{
		GUI.color = Color.yellow;
		Rect rt = new Rect { x = Screen.width - 200, y = 50, width = 180, height = 30 };
		GUI.Label(rt, "fps.render:" + ZX.Core.debug.render_fps);
		rt.y += 20;
		GUI.Label(rt, "fps.logic:" + ZX.Core.debug.logic_fps);
		rt.y += 20;
		string s = String.Format("{0:0.00}", ZX.Core.debug.send_size / 1024.0f);
		GUI.Label(rt, "socket.send:" + s + " KiB");
		rt.y += 20;
		s = String.Format("{0:0.00}", ZX.Core.debug.recv_size / 1024.0f);
		GUI.Label(rt, "socket.recv:" + s + " KiB");
	}
#endif

}

