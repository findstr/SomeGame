using System.Collections;
using System.Collections.Generic;
using FairyGUI;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.OnScreen;

[XLua.LuaCallCSharp]
public class Joystick : MonoBehaviour
{
	public InputActionAsset asset;
	public string actionName;
	public OnScreenStickEx stick;
	public Camera cam;
	private InputAction action;
	void Start()
	{
		action = asset.FindAction(actionName);
		action.Enable();
	}
	public void TouchBegin(float x, float y)
	{
		y = Screen.height - y;
		stick.OnPress(x, y);
	}
	public void TouchMove(float x, float y)
	{
		y = Screen.height - y;
		stick.OnMove(x, y);
	}
	public void TouchEnd()
	{
		stick.OnRelax();
	}
	private bool ReadValue(out Vector2 value, out Vector2 movedir)
	{
		value = action.ReadValue<Vector2>();
		bool moving = Mathf.Abs(value.x) > Mathf.Epsilon || Mathf.Abs(value.y) > Mathf.Epsilon;
		if (moving) {
			var angle = Vector2.Angle(Vector2.up, value);
			if (value.x > 0.0)
				angle *= -1;
			stick.transform.rotation = Quaternion.AngleAxis(angle, Vector3.forward);
			var dir = Quaternion.AngleAxis(angle, Vector3.down) * cam.transform.forward;
			movedir = new Vector2(dir.x, dir.z);
			movedir = movedir.normalized;
		} else {
			stick.transform.rotation = Quaternion.identity;
			value = Vector2.zero;
			movedir = Vector2.zero;
		}
		return moving;
	}
	public bool ReadN()
	{
		var moving = ReadValue(out Vector2 value, out Vector2 movedir);
		ZX.Core.result.Set(1, movedir.x);
		ZX.Core.result.Set(2, movedir.y);
		return moving;
	}
	public bool Read()
	{
		var moving = ReadValue(out Vector2 value, out Vector2 movedir);
		movedir *= value.magnitude;
		ZX.Core.result.Set(1, movedir.x);
		ZX.Core.result.Set(2, movedir.y);
		return moving;
	}
}

