using FairyGUI;
using UnityEngine;

public class Movement: MonoBehaviour
{
	public enum Mode {
		LOCAL = 0,
		REMOTE = 1,
	};
	public GObject hud;
	private DeadReckoning dr;
	private Skill skill;
	private Camera cam;
	private Mode mode = Mode.REMOTE;
	private Animator animator;
	private Quaternion orientation;
        public Vector3 HudOffset;
	public bool UpdateHudx = true;

	private void Awake()
	{
		dr = GetComponent<DeadReckoning>();
		skill = GetComponent<Skill>();
		animator = GetComponent<Animator>();
		orientation = transform.rotation;
	}
	public void Init(Camera cam,  GObject hud)
	{
		this.cam = cam;
		this.hud = hud;
                GRoot.inst.AddChild(hud);
	}
	public void SetMode(Mode m) 
	{
		this.mode = m;
	}
	public float Dist(Movement c) 
	{
		var a = new Vector2(transform.position.x, transform.position.z);
		var b = new Vector2(c.transform.position.x, c.transform.position.z);
		return (a-b).magnitude;
	}

	public void Move(float x, float z) 
	{
		if (Mathf.Abs(x) < Mathf.Epsilon && Mathf.Abs(z) < Mathf.Epsilon || skill.IsFiring) {
			animator.SetInteger("Run", 0);
		} else {
			animator.SetInteger("Run", 1);
			var dir = new Vector3(x, 0, z);
			transform.position += dir;
			LookDir(dir);
		}
	}
	float angleSpeed = 360.0f * 2.0f;
	float rotateTime = 0.0f;
	public void LookDir(Vector3 dir)
	{
		orientation = Quaternion.LookRotation(dir, Vector3.up);
		var angle = Quaternion.Angle(transform.rotation, orientation);
		rotateTime = angle / angleSpeed;
	}
	void UpdateDirection() 
	{
		if (rotateTime < Mathf.Epsilon) 
			return ;
		rotateTime -= Time.deltaTime;
		if (rotateTime < Mathf.Epsilon) {
			transform.rotation = orientation;
			return ;
		}
		transform.rotation = Quaternion.Lerp(transform.rotation, orientation, Time.deltaTime / rotateTime);
	}
	void UpdateHud()
	{
		if (hud == null)
			return ;
                var npos = ZX.Core.WorldToFGUI(cam, transform.position + HudOffset); 
                hud.SetXY(npos.x, npos.y);
	}
	// Update is called once per frame
	void FixedUpdate()
	{
		UpdateDirection();
		UpdateHud();
	}
}
