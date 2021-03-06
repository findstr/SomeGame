using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class Node {
	public string name;
	public bool isobstacle;
	public int close = 0;
	public Vector3Int coord;
	public Vector3 position;
	public Node next = null;
	public bool CanEnter() {
		return isobstacle == false;
	}
};

public class OpenList {
	private Dictionary<Node, int> score = new Dictionary<Node, int>();
	public bool Pop(out Node n, out int cost) {
		n = null;
		cost = 99999999;
		if (score.Count == 0)
			return false;
		foreach (var iter in score) {
			if (iter.Value < cost) {
				cost = iter.Value;
				n = iter.Key;
			}
		}
		score.Remove(n);
		return true;
	}
	public bool Push(Node n, int cost) {
		if (score.TryGetValue(n, out int s) && s <= cost) 
			return false;
		score[n] = cost;
		return true;
	}
	public bool IsEmpty() {
		return score.Count == 0;
	}
}


public class PathFinder : MonoBehaviour
{
	[SerializeField]
	public float cellSize = 0.1f;
	public LayerMask ObstacleLayer;
	public Node[,] grids;
	public Vector2Int grid_range = Vector2Int.zero;
	public Vector2Int goal = Vector2Int.zero;
	private Vector3 target_position = Vector3.zero;
	private OpenList open = new OpenList();
	public int close_idx = 1;
	// Start is called before the first frame update
	void Awake()
	{
		float xsize = 100.0f;
		float ysize = 100.0f;
		int xn = (int)(xsize / cellSize);
		int yn = (int)(ysize / cellSize);
		grid_range = new Vector2Int(xn, yn);
		grids = new Node[yn, xn];
		for (int y = 0; y < yn; y++) {
			for (int x = 0; x < xn; x++) {
				Vector2 pos = GridPosition(x, y);
				var collider = Physics2D.OverlapBox(pos, new Vector2(cellSize, cellSize), 0, ObstacleLayer);
				grids[y,x] = new Node() {
					name = collider != null ? collider.name : "",
					isobstacle = collider != null,
					position = new Vector3(pos.x, pos.y, 0),
					coord = new Vector3Int(x, y, 0),
				};
			}
		}
		Debug.Log("xn:" + xn + " yn:" + yn);
	}

	public Vector3 GridPosition(int x, int y) {
		if (goal.x == x && goal.y == y)
			return target_position;
		else
			return new Vector3(x * -cellSize, 0, y * -cellSize) + new Vector3(cellSize / 2, 0, cellSize / 2);
	}
	public Vector2Int WhichGrid(Vector3 pos) {
		Vector2Int coord = new()
		{
			x = (int)(-pos.x / cellSize),
			y = (int)(-pos.z / cellSize)
		};
		return coord;
	}
	public Node WhichGridNode(Vector3 pos) {
		Vector2Int coord = WhichGrid(pos);
		return grids[coord.y, coord.x];
	}

	public Vector3Int[] around = new Vector3Int[] {
		new Vector3Int(-1, -1, 15), new Vector3Int(0, -1, 10), new Vector3Int(1, -1, 15),
		new Vector3Int(-1,  0, 10),				new Vector3Int(1, 0, 10),
		new Vector3Int(-1,  1, 15), new Vector3Int(0, 1, 10), new Vector3Int(1, 1, 15),
	};

	public Vector3 Collider(Vector3 pos, float size) {
		var pp = new Vector2(pos.x, pos.y);
		var hit = Physics2D.OverlapBox(pp, new Vector2(size, size), 0, ObstacleLayer);
		if (hit == null)
			return Vector3.zero;
		var dir = (pos - hit.gameObject.transform.position);
		return dir.normalized;
	}
	public void Bake(Vector3 point) {
		++close_idx;
		target_position = point;
		var target = WhichGridNode(point);
		if (target.isobstacle)
			return ;
		open.Push(target, 0);
		target.next = null;
		while (!open.IsEmpty()) {
			open.Pop(out Node p, out int cost);
			p.close = close_idx;
			for (int i = 0; i < around.Length; i++) {
				var x = around[i];
				var coord = new Vector3Int(x.x, x.y, 0) + p.coord;
				if (coord.x >= 0 && coord.x < grid_range.x && coord.y >=0 && coord.y < grid_range.y) {
					var n = grids[coord.y, coord.x];
					if (n.close != close_idx) {
						if(n.CanEnter()) {
							if (open.Push(n, cost + x.z))
								n.next = p;
						} else {
							n.next = p;
							n.close = close_idx;
						}
					}
				}
			}
		}
	}

	public bool Next(Vector3 point, out Vector3 t) {
		t = Vector3.zero;
		var start = WhichGridNode(point);
		if (start.close != close_idx)
			return false;
		var target = WhichGridNode(target_position);
		if (start == target) {
			if ((target_position - point).magnitude > 0.1f)  {
				t = target_position;
				return true;
			}
			return false; 
		}
		t = start.next.position;
		return true;
	}
}


[CustomEditor(typeof(PathFinder))]
class PathFinderEx : Editor {
	void OnSceneGUI()
	{
	        var self = target as PathFinder;
                if (self.grids == null)
                        return ;
		for (int y = 0; y < self.grid_range.y; y++) {
			for (int x = 0; x < self.grid_range.x; x++) {
				var n = self.grids[y,x];
				if (n == null) 
					continue;
				var p1 = new Vector2(n.position.x, n.position.y);
				var size = new Vector2(self.cellSize, self.cellSize) / 2.0f;
				Handles.Label(p1 - new Vector2(self.cellSize / 2, 0), string.Format("x:{0} y:{1}", x, y));
				Handles.DrawLine(p1 + size * new Vector2(-1,-1), p1 + size * new Vector2(1, -1));
				Handles.DrawLine(p1 + size * new Vector2(-1,1), p1 + size * new Vector2(1, 1));
				Handles.DrawLine(p1 + size * new Vector2(-1,-1), p1 + size * new Vector2(-1, 1));
				Handles.DrawLine(p1 + size * new Vector2(1,-1), p1 + size * new Vector2(1, 1));
				if (n.next != null && n.next.close == self.close_idx) {
					var p2 = n.next.position;
					Handles.DrawLine(p1, p2);
				}
			}
		}
		var cp = self.grids[self.goal.y, self.goal.x].position;
		Rect rt = new Rect {
			center = new Vector2(cp.x, cp.y) - new Vector2(self.cellSize / 2, self.cellSize / 2),
			size = new Vector2(self.cellSize, self.cellSize)
		};
		Handles.DrawSolidRectangleWithOutline(rt, Color.red, Color.red);
	}
}
