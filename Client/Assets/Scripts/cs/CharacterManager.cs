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
		RED = 1,
		BLUE = 2,
	};
	class Player
	{
		public Team team;
		public Character c;
		public DeadReckoning dr;
	};
	struct CreateCtx
	{
		public GObject hud;
		public GProgressBar hp;
		public Team team;
		public Character.Mode m;
		public Vector3 position;
		public Quaternion rotation;
	};
	public Camera cam;
	TextFly flyText;
	CameraFollow follow;
	Dictionary<uint, Player> players = new Dictionary<uint, Player>();
	Dictionary<uint, CreateCtx> creating = new Dictionary<uint, CreateCtx>();
	ZX.IRL.load_cb_t load_cb = null;

	void load_cb_(LoadResult result)
	{
		uint uid = (uint)result.ud;
		var ctx = creating[uid];
		creating.Remove(uid);
		GameObject go = Instantiate(result.assets[0].asset, ctx.position, ctx.rotation, transform) as GameObject;
		var p = new Player {
			team = ctx.team,
			c = go.GetComponent<Character>(),
			dr = go.GetComponent<DeadReckoning>(),
		};
		p.c.Init(cam, flyText, ctx.hud, ctx.hp, ctx.m);
		players.Add(uid, p);
		if (ctx.m != Character.Mode.LOCAL)
			return;
		follow.target = p.c.gameObject;
		if (p.team == Team.BLUE)
			follow.transform.rotation = Quaternion.Euler(cam.transform.eulerAngles.x, cam.transform.eulerAngles.y + 180, cam.transform.eulerAngles.z);
	}

	private void Awake()
	{
		load_cb = load_cb_;
		flyText = GetComponent<TextFly>();
		follow = cam.GetComponent<CameraFollow>();
	}

	public void Reset()
	{
		follow.target = null;
		creating.Clear();
		foreach (var iter in players) 
			GameObject.Destroy(iter.Value.c.gameObject);
		players.Clear();
	}

	public void Create(uint uid, string path, GObject hud, GProgressBar hp, float x, float z, int t, Character.Mode m = Character.Mode.REMOTE)
	{
		var ctx = new CreateCtx {
			m = m,
			team = (Team)t,
			hud = hud,
			hp = hp,
			position = new Vector3(x, 0, z),
			rotation = Quaternion.identity,
		};
		creating.Add(uid, ctx);
		ZX.RL.Instance.load_asset_async(path, typeof(GameObject), load_cb, (int)uid);
	}

	public void RemoteMove(uint uid, float x, float z, float sx, float sz)
	{
		players[uid].dr.MoveTo(x, z, sx, sz);
	}

	public void RemoteSync(uint uid, float sx, float sz)
	{
		var p = players[uid];
		ZX.Core.result.Set(1, p.c.transform.position.x);
		ZX.Core.result.Set(2, p.c.transform.position.z);
		var pos = new Vector2(p.c.transform.position.x, p.c.transform.position.z);
		p.dr.MoveTo(pos.x, pos.y, sx, sz);
	}

	public bool LocalMove(uint uid, float sx, float sz, float threshold)
	{
		if (players.TryGetValue(uid, out Player p)) {
			p.c.Move(sx, sz);
			return p.dr.ShouldSync(threshold);
		}
		return false;
	}

	public int Collect(uint uid, float radius)
	{
		int n = 0;
		var owner = players[uid];
		var iter = players.GetEnumerator();
		radius *= radius;
		var origin = new Vector2(owner.c.transform.position.x, owner.c.transform.position.z);
		while (iter.MoveNext()) {
			var p = iter.Current.Value;
			if (owner.team == p.team)
				continue;
			if ((origin - new Vector2(p.c.transform.position.x, p.c.transform.position.z)).magnitude < radius)
				ZX.Core.result.Set(++n, iter.Current.Key);
		}
		return n;
	}

	public bool Fire(uint attacker, int skill, uint target)
	{
		return players[attacker].c.Fire(skill, players[target].c);
	}

	public void SkillEffect(uint attacker, uint target, int skill, int targethp)
	{
		players[attacker].c.SkillEffect(players[target].c, skill, targethp);
	}
}
