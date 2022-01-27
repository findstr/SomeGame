using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character : MonoBehaviour
{
	public enum Mode {
		LOCAL = 0,
		REMOTE = 1,
	};
	public enum SKILL
	{
		ATK1 = 1,
		ATK2 = 2,
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
	public bool IsFiring { get; private set; }
	public TeamSide Team {get; set; }
	private Character HitTarget = null;
	private float HitAdjustTime = 0.0f;
	private int atk_layer = 0;
	private DeadReckoning dr;
	private Animator animator;
	private Mode mode = Mode.REMOTE;
	private Vector3 moveDir = Vector3.zero;
	private void Awake()
	{
		dr = GetComponent<DeadReckoning>();
		animator = GetComponent<Animator>();
		atk_layer = animator.GetLayerIndex("Attack");
	}
	public void SetMode(Mode m = Mode.REMOTE) {
		mode = m;
	}
	public float Dist(Character c) {
		var a = new Vector2(transform.position.x, transform.position.z);
		var b = new Vector2(c.transform.position.x, c.transform.position.z);
		return (a-b).magnitude;
	}
	public void Fire(SKILL s, Character c)
	{
		if (IsFiring == true)
			return ;
		IsFiring = true;
		HitTarget = c;
		fireState = FireState.ROT;
		HitAdjustTime = 0.0f;
		animator.SetTrigger("ATK1");
	}
	public void Move(float x, float z) {
		moveDir = new Vector3(x, 0, z);
	}
	// Update is called once per frame
	void LateUpdate()
	{
		switch (fireState) {
		case FireState.FIRE:
			if (animator.GetCurrentAnimatorStateInfo(atk_layer).IsName("Idle")) {
				IsFiring = false;
				fireState = FireState.NOP;
				break;
			}
			return ;
		case FireState.ROT:
			HitAdjustTime += Time.deltaTime * 10f;
			HitAdjustTime = Mathf.Min(HitAdjustTime, 1.0f);
			transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(HitTarget.transform.position - transform.position), HitAdjustTime);
			if (HitAdjustTime >= 1.0f) 
				fireState = FireState.WAIT;
			return ;
		case FireState.WAIT:
			if (animator.GetCurrentAnimatorStateInfo(atk_layer).IsName("ATK1"))
				fireState = FireState.FIRE;
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
}
