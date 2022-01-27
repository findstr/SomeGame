using FairyGUI;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static ZX.IRL;

[XLua.LuaCallCSharp]
public class CharacterManager : MonoBehaviour
{
        public enum Team {
                RED = 1,
                BLUE = 2,
        };
        class Player {
                public Team team;
                public GObject hud;
                public Character c;
                public DeadReckoning dr;
        };
        struct Transform {
                public GObject hud;
                public Team team;
                public Character.Mode m;
                public Vector3 position;
                public Quaternion rotation;
        };
        public Camera cam;
        public Vector3 HudOffset;
        public Vector3 FlyOffset;
        public Color HealColor;
        public Color HurtColor;
        CameraFollow follow;
        TextFly flyText;
        Dictionary<uint, Player> players = new Dictionary<uint, Player>();
        Dictionary<uint, Transform> creating = new Dictionary<uint, Transform>();
        ZX.IRL.load_cb_t load_cb = null;

        void load_cb_(LoadResult result) {
                uint uid = (uint)result.ud;
                var trs = creating[uid];
                creating.Remove(uid);
                GameObject go = Instantiate(result.assets[0].asset, trs.position, trs.rotation, transform) as GameObject;
                var p = new Player {
			team = trs.team,
			hud = trs.hud,
			c = go.GetComponent<Character>(),
			dr = go.GetComponent<DeadReckoning>(),
                };
                players.Add(uid, p);
                Debug.Log("AddHud:" + p.hud);
                GRoot.inst.AddChild(p.hud);
                p.c.SetMode(trs.m);
                if (trs.m != Character.Mode.LOCAL) 
                        return ;
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

        public void Create(uint uid, string path, GObject hud, float x, float z, int t, Character.Mode m = Character.Mode.REMOTE) 
        {
                var trs = new Transform {
                        m = m,
                        team = (Team)t,
                        hud = hud,
                        position = new Vector3(x, 0, z),
                        rotation = Quaternion.identity,
                };
                creating.Add(uid, trs);
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

        private Vector3 ScreenPointOfCharacter(Character c, Vector3 offset) 
        {
                var pos = cam.WorldToScreenPoint(c.transform.position + offset);
                pos.y = Screen.height - pos.y;
                return pos;
        }

        private void TextFly(uint uid, int text, Color c) 
        {
                if (players.TryGetValue(uid, out Player p)) {
                        var offset = FlyOffset.x * cam.transform.right + FlyOffset.y * cam.transform.up;
                        flyText.Fly(ScreenPointOfCharacter(p.c, offset), string.Format("{0}", text), c);
                }
        }

        public void HP(uint uid, int text) 
        {
                if (text < 0)
                        TextFly(uid, text, HurtColor);
                else
                        TextFly(uid, text, HealColor);
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

        public void Fire(uint attacker, Character.SKILL skill, uint target)
        {
                players[attacker].c.Fire(skill, players[target].c);
        }

        void LateUpdate()
        {
                var iter = players.GetEnumerator();
                var offset = HudOffset.x * cam.transform.right + HudOffset.y * cam.transform.up;
                while (iter.MoveNext()) {
                        var p = iter.Current.Value;
                        var pos = ScreenPointOfCharacter(p.c, offset); 
                        p.hud.SetPosition(pos.x, pos.y, pos.z);
                }
        }
}
