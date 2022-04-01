using UnityEngine;

public class Skill: MonoBehaviour
{
	enum State {
		IDLE = 0,
		START = 1,
		HIT = 1,
	};
	private State state = State.IDLE;
        public Vector3 FlyOffset;
        public Color HealColor;
        public Color HurtColor;
	private Animator animator;
	private float hp_delta = 0.0f;
	private Movement target = null;
	private void Fly(Movement t, float delta)
	{
		TextFly.Instance.Fly(t.transform.position + FlyOffset, delta.ToString(), delta < 0.0 ? HurtColor : HealColor);
	}
	public bool IsFiring { get { return state != State.IDLE; } }
	public void Awake()
	{
		animator = GetComponent<Animator>();
	}
	public bool FireStart(int skill, Movement t)
	{
		if (state != State.IDLE)
			return false;
		state = State.START;
		target = null;
		hp_delta = 0.0f;
		animator.SetTrigger("ATK1");
		return true;
	}
	public void FireEffect(Movement t, float hp) 
	{
		if (state == State.START) {
			target = t;
			hp_delta = hp;
		} else {
			Fly(t, hp);
		}
	}
	public void OnFireHit()
	{
		if (target != null) {
			Fly(target, hp_delta);
			target = null;
		}
		state = State.HIT;
		Debug.Log("FireHit");
	}
	public void OnFireFinish() 
	{
		state = State.IDLE;
		Debug.Log("FireFinish");
	}
}

