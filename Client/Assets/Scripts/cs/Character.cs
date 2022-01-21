using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character : MonoBehaviour
{
	public enum Mode {
		Local = 0,
		Remote = 1,
	};
	public enum SKILL
	{
		ATK1 = 1,
		ATK2 = 2,
	};
	/*
	private float rot_speed = 10f;
	private float move_speed = 3f;
	private Vector3 forward;
	*/
	private DeadReckoning dr;
	private Animator animator;
	private Mode mode = Mode.Remote;
	private Vector3 moveDir = Vector3.zero;
	private void Awake()
	{
		dr = GetComponent<DeadReckoning>();
		animator = GetComponent<Animator>();
	}
	public void SetMode(Mode m) {
		mode = m;
	}
	public void FireSkill(SKILL s)
	{
		switch (s) {
		case SKILL.ATK1:
			animator.SetTrigger("ATK1");
		break;
		case SKILL.ATK2:
			animator.SetTrigger("ATK2");
		break;
		}
	}
	public void Move(float x, float z) {
		moveDir = new Vector3(x, 0, z);
	}
	// Update is called once per frame
	void LateUpdate()
	{
		if (mode == Mode.Remote) {
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
