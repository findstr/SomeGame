using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

[XLua.LuaCallCSharp]
public class Joystick : MonoBehaviour
{
	public InputActionAsset asset;
	public string actionName;
	public GameObject stick;
	public Camera cam;
	private InputAction action;
	void Start()
	{
		action = asset.FindAction(actionName);
		action.Enable();
	}

	void Update()
	{

	}
	public bool Read()
	{
		var value = action.ReadValue<Vector2>();
		bool moving = Mathf.Abs(value.x) > Mathf.Epsilon || Mathf.Abs(value.y) > Mathf.Epsilon;
		if (moving) {
			var angle = Vector2.Angle(Vector2.up, value);
			if (value.x > 0.0)
				angle *= -1;
			stick.transform.rotation = Quaternion.AngleAxis(angle, Vector3.forward);
			var dir = Quaternion.AngleAxis(angle, Vector3.down) * cam.transform.forward;
			value = new Vector2(dir.x, dir.z);
		} else {
			stick.transform.rotation = Quaternion.identity;
			value = Vector2.zero;
		}
		ZX.Core.result.Set(1, value.x);
		ZX.Core.result.Set(2, value.y);
		return moving;
	}
}

