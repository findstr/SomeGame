using FairyGUI;
using UnityEngine;

namespace ZX{
static partial class Core {
	static public Vector2 WorldToFGUI(Camera cam, Vector3 pos) 
        {
		Vector3 screenPos = cam.WorldToScreenPoint(pos);
		screenPos.y = Screen.height - screenPos.y;
		return GRoot.inst.GlobalToLocal(screenPos);
        }
	static public void SetPosition(GameObject go, float x, float y, float z) {
		go.transform.position = new Vector3(x, y, z);	
	}
	static public void GetPosition(GameObject go) {
		var pos = go.transform.position;
		result.Set(1, pos.x);
		result.Set(2, pos.y);
		result.Set(3, pos.z);
	}
	static public void SetScale(GameObject go, float x, float y, float z) {
		go.transform.localScale = new Vector3(x, y, z);
	}
	static public void SetPosition(GameObject go) {
		var scale = go.transform.localScale;
		result.Set(1, scale.x);
		result.Set(2, scale.y);
		result.Set(3, scale.z);
	}
}}
