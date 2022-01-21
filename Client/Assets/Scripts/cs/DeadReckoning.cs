using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DeadReckoning : MonoBehaviour
{
	public bool isAway = false;
	public Vector3 debug_pos = Vector3.zero;
	public Vector3 position = Vector3.zero;
	private Vector3 velocity = Vector3.zero;
	private Vector3 dr_p = Vector3.zero;
	private Vector3 dr_v = Vector3.zero;
	private Vector3 syn_p = Vector3.zero;
	private Vector3 syn_v = Vector3.zero;
	private readonly float t_delta = 1.0f / 10.0f; 
	private float t_elapse = 0.0f;
	// Start is called before the first frame update
	void Start()
	{
		position = transform.position;
		dr_p = position;
		syn_p = position;
	}
	void LateUpdate()
	{
		if (syn_v == Vector3.zero)
			return ;
		t_elapse += Time.deltaTime;
		float t = Mathf.Clamp01(t_elapse / t_delta);
		Vector3 v = Vector3.Lerp(dr_v, syn_v, t);
		Vector3 p0 = dr_p + v * t_elapse;
		Vector3 p1 = syn_p + syn_v * t_elapse;
		Vector3 p = (1.0f - t) * p0 + t * p1;
		velocity = (p - position) / Time.deltaTime;
		position = p;
	}
	public void MoveTo(float x, float z, float speed_x, float speed_z)
	{
		if (Mathf.Abs(speed_x) < 0.0001f && Mathf.Abs(speed_z) < 0.0001f) {
			position = dr_p = new Vector3(x, transform.position.y, z);
			dr_v = syn_v = Vector3.zero;
		} else {
			Vector3 v = new Vector3(speed_x, 0, speed_z);
			if (dr_v == Vector3.zero)
				dr_v = v;
			else
				dr_v = velocity;
			dr_p = position;
			syn_v = v;
			syn_p = new Vector3(x, transform.position.y, z);
		}
		t_elapse = 0;
	}
	public bool ShouldSync(float th) {
		debug_pos = transform.position;
		Vector3 dist = position - transform.position;
		dist.y = 0;
		isAway = dist.magnitude >= (th * th);
		return isAway;
	}
}
