using FairyGUI;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character : MonoBehaviour
{
	public enum Mode {
		LOCAL = 0,
		REMOTE = 1,
	};
	public enum TeamSide {
		BLUE = 1,
		RED = 2,
	};
	public enum FireState {
		NOP = 0,
		ROT = 1,
		WAIT = 2,
		FIRE = 3,
	};
	public FireState fireState = FireState.NOP;
	public bool IsFiring { get { return skillid != 0; } }
	public TeamSide Team {get; set; }
	private int skillid = 0;
	private Character target;
	private int targetDeltaHP = 0;
	private float HitAdjustTime = 0.0f;
	private Character HitTarget = null;
	private DeadReckoning dr;
	private Animator animator;
	private TextFly textFly;
	private Camera cam;
	private GObject hud;
	private Mode mode = Mode.REMOTE;
	private Vector3 moveDir = Vector3.zero;
        public Vector3 HudOffset;
        public Vector3 FlyOffset;
        public Color HealColor;
        public Color HurtColor;
	private void Awake()
	{
		dr = GetComponent<DeadReckoning>();
		animator = GetComponent<Animator>();
	}
	public void Init(Camera cam, TextFly textFly, GObject hud, Mode m)
	{
		this.cam = cam;
		this.hud = hud;
		this.textFly = textFly;
		this.mode = m;
                GRoot.inst.AddChild(hud);
	}
	public float Dist(Character c) {
		var a = new Vector2(transform.position.x, transform.position.z);
		var b = new Vector2(c.transform.position.x, c.transform.position.z);
		return (a-b).magnitude;
	}
	public void FireFinish() 
	{
		target = null;
		skillid = 0;
		targetDeltaHP = 0;
		fireState = FireState.NOP;
		Debug.Log("FireFinish");
	}
	public void FireHit()
	{
		if (targetDeltaHP != 0) {
			target.TextFly(targetDeltaHP);
			targetDeltaHP = 0;
			target = null;
		}
		Debug.Log("FireHit");
	}
	public bool Fire(int s, Character c)
	{
		if (skillid != 0)
			return false;
		skillid = s;
		HitTarget = c;
		fireState = FireState.ROT;
		HitAdjustTime = 0.0f;
		animator.SetTrigger("ATK1");
		Debug.Log("Fire:" + skillid);
		return true;
	}
	public void Move(float x, float z) {
		moveDir = new Vector3(x, 0, z);
	}
        private Vector3 ScreenPointOfCharacter(Vector3 offset) 
        {
                var off = offset.x * cam.transform.right + offset.y * cam.transform.up;
                var pos = cam.WorldToScreenPoint(transform.position + off);
                pos.y = Screen.height - pos.y;
                return pos;
        }

        public void TextFly(int text) 
        {
                Color c = (text < 0) ? HurtColor : HealColor;
		textFly.Fly(ScreenPointOfCharacter(FlyOffset), string.Format("{0}", text), c);
        }

        public void SkillEffect(Character target, int skill, int text) 
        {
		Debug.Log("HP:" + skill + ":" + skillid);
		if (skillid == skill) {
			this.target = target;
			targetDeltaHP = text;
		}  else {
                        target.TextFly(text);
		}
        }
	void UpdateAnimation() 
	{
		switch (fireState) {
		case FireState.ROT:
			HitAdjustTime += Time.deltaTime * 10f;
			HitAdjustTime = Mathf.Min(HitAdjustTime, 1.0f);
			transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.LookRotation(HitTarget.transform.position - transform.position), HitAdjustTime);
			if (HitAdjustTime >= 1.0f) 
				fireState = FireState.FIRE;
			return ;
		case FireState.FIRE:
			return ;
		case FireState.NOP:
			break;
		}
		if (mode == Mode.REMOTE) {
			if ((transform.position - dr.position).magnitude < 0.001f) {
				animator.SetInteger("Run", 0);
				return ;
			}
			animator.SetInteger("Run", 1);
			transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.LookRotation(dr.position - transform.position), Time.deltaTime * 10);
			transform.position = Vector3.Lerp(transform.position, dr.position, Time.deltaTime * 10);  
		} else {
			if (Mathf.Abs(moveDir.x) < Mathf.Epsilon && Mathf.Abs(moveDir.z) < Mathf.Epsilon) {
				animator.SetInteger("Run", 0);
				return ;
			}
			animator.SetInteger("Run", 1);
			transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(moveDir), Time.deltaTime * 10);
			transform.position = Vector3.Lerp(transform.position, transform.position + moveDir, Time.deltaTime);  
		}

	}
	void UpdateHud()
	{
                var pos = ScreenPointOfCharacter(HudOffset); 
                hud.SetPosition(pos.x, pos.y, pos.z);
	}
	// Update is called once per frame
	void LateUpdate()
	{
		UpdateAnimation();
		UpdateHud();
	}
}
