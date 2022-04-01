using UnityEngine;

public class DeadReckoning : MonoBehaviour
{
	public bool isAway = false;
	public bool IsMaster = true;
	private Vector3 target = Vector3.zero;
	private Vector3 velocity = Vector3.zero;
	private Skill skill = null;
	private Movement move = null;
	// Start is called before the first frame update
	void Awake()
	{
		skill = GetComponent<Skill>();
		move = GetComponent<Movement>();
		velocity = Vector3.zero;
		target = transform.position;
	}
	void FixedUpdate()
	{
		if (skill.IsFiring)
			return ;
		target = target + velocity * Time.deltaTime;
		if (IsMaster)
			move.MoveTo(target.x, target.z); 
	}
	public void MoveTo(float x, float z, float speed_x, float speed_z)
	{
		target = new Vector3(x, 0, z);
		velocity = new Vector3(speed_x, 0, speed_z);
	}
	public bool ShouldSync(float th) {
		Vector3 dist = target - transform.position;
		dist.y = 0;
		isAway = dist.sqrMagnitude >= (th * th);
		return isAway;
	}
}
