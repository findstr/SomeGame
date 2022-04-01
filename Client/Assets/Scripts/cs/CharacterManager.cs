using FairyGUI;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static ZX.IRL;

[XLua.LuaCallCSharp]
public class CharacterManager : MonoBehaviour
{
	public enum Team
	{
		NONE = 0,
		RED = 1,
		BLUE = 2,
	};
	class Player
	{
		public Team team;
		public Movement movement;
		public Skill skill;
		public DeadReckoning dr;
	};
	public Camera cam;
	CameraFollow follow;
	Dictionary<uint, Player> players = new Dictionary<uint, Player>();
	Dictionary<uint, Player>[] teams = new Dictionary<uint, Player>[]  {
		null,
		new Dictionary<uint, Player>(),
		new Dictionary<uint, Player>(),
	};
	private void Awake()
	{
		follow = cam.GetComponent<CameraFollow>();
	}

	public void Reset()
	{
		follow.target = null;
		foreach (var iter in players) 
			Destroy(iter.Value.movement.gameObject);
		teams[1].Clear();
		teams[2].Clear();
		foreach (var x in players) 
			Destroy(x.Value.movement.gameObject);
		players.Clear();
	}

	public void Create(uint uid, AssetRequest asset, GObject hud, float x, float z)
	{
		var pos = new Vector3(x, 0, z);
		GameObject go = Instantiate(asset.asset,  pos, Quaternion.identity, transform) as GameObject;
		var p = new Player {
			team = Team.NONE,
			movement = go.GetComponent<Movement>(),
			skill = go.GetComponent<Skill>(),
			dr = go.GetComponent<DeadReckoning>(),
		};
		p.movement.Init(cam,  hud);
		players.Add(uid, p);
	}

	public void Join(uint uid, int team)
	{
		if (!players.TryGetValue(uid, out Player p))
			return ;
		p.team = (Team)team;
		teams[team].Add(uid, p);
	}

	public void SetHost(uint uid) {
		if (!players.TryGetValue(uid, out Player p))
			return ;
		p.movement.SetMode(Movement.Mode.LOCAL);
		follow.target = p.movement.gameObject;
		if (p.team == Team.BLUE)
			follow.transform.rotation = Quaternion.Euler(cam.transform.eulerAngles.x, 180, cam.transform.eulerAngles.z);
	}

	public void RemoteSync(uint uid, float sx, float sz)
	{
		var p = players[uid];
		ZX.Core.result.Set(1, p.movement.transform.position.x);
		ZX.Core.result.Set(2, p.movement.transform.position.z);
		var pos = new Vector2(p.movement.transform.position.x, p.movement.transform.position.z);
		p.dr.MoveTo(pos.x, pos.y, sx, sz);
	}

	public void RemoteMove(uint uid, float x, float z, float sx, float sz)
	{
		players[uid]?.dr.MoveTo(x, z, sx, sz);
	}

	public bool LocalMove(uint uid, float sx, float sz, float threshold)
	{
		if (players.TryGetValue(uid, out Player p)) {
			Debug.Log("LocalMove:" + sx + ":" + sz);
			p.movement.Move(sx, sz);
			return p.dr.ShouldSync(threshold);
		}
		return false;
	}

	public void Follow(uint uid, GameObject go, float x, float z)
	{
		if (players.TryGetValue(uid, out Player p)) {
			go.transform.position = p.movement.transform.position + new Vector3(x, 0, z);
		}
	}

	public uint SelectNearestEnemy(uint uid, float radius)
	{
		if (!players.TryGetValue(uid, out var owner))
			return 0;
		uint id = 0;
		float lastdist = Mathf.Infinity;
		var origin = new Vector2(owner.movement.transform.position.x, owner.movement.transform.position.z);
		var iter = teams[(int)owner.team % 2 + 1].GetEnumerator();
		while (iter.MoveNext()) {
			var p = iter.Current.Value;
			float dist = (origin - new Vector2(p.movement.transform.position.x, p.movement.transform.position.z)).magnitude;
			if (dist < radius && dist < lastdist) {
				id = iter.Current.Key;
				lastdist = dist;
			}
		}
		return id;
	}

	public bool Fire(uint attacker, int skill, uint target)
	{
		if (players.TryGetValue(attacker, out Player p) && players.TryGetValue(target, out Player t)) {
			p.movement.LookDir(t.movement.transform.position - p.movement.transform.position);
			return p.skill.FireStart(skill, t.movement);
		}
		return false;
	}
	public void SkillEffect(uint atk, uint target, float deltahp)
	{
		if (players.TryGetValue(atk, out Player p) && players.TryGetValue(target, out Player t)) {
			p.skill.FireEffect(t.movement, deltahp);
		}
	}
}
