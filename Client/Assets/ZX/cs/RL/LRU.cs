using System;
using System.Collections.Generic;

namespace ZX { 

public class LRU<T> {
	class node {
		public node prev = null;
		public node next = null;
		public T obj = default(T);
	};
	public delegate void finalizer_t (T obj);
	private finalizer_t finalizer = null;
	private node free = null;
	private node head = null;
	private node tail = null;
	private Dictionary<T, node> map = new Dictionary<T, node>();
	private void assert(bool x) {
#if UNITY_EDITOR_WIN || UNITY_STANDALONE_WIN
		System.Diagnostics.Debug.Assert(x);
#endif
	}
	private void put(node n) {
		map.Remove(n.obj);
		n.prev = null;
		n.obj = default(T);
		n.next = free;
		free = n;
	}
	private void eliminate() {
		if (head == null)
			return ;
		node n = head;
		assert(n.prev == null);
		head = n.next;
		if (head != null) {
			head.prev = null;
		} else {
			assert(n == tail);
			tail = null;
		}
		finalizer(n.obj);
		put(n);
		return ;
	}
	private void remove_list(node n) {
		if (n.prev != null) {
			n.prev.next = n.next;
		} else {//head
			head = n.next;
		}
		if (n.next != null) {
			n.next.prev = n.prev;
		} else { //tail
			tail = n.prev;
		}
	}
	private node get(T obj) {
		node n;
		if (!map.TryGetValue(obj, out n)) {//nonexist, new it
			if (free == null)
				eliminate();
			n = free;
			n.obj = obj;
			free = n.next;
			n.next = null;
			map[obj] = n;
		} else { //exist, remove from list
			remove_list(n);
		}
		return n;
	}
	public LRU(int cap, finalizer_t finalizer) {
		assert(cap > 0);
		this.finalizer = finalizer;
		free = new node();
		for (int i = 0; i < cap - 1; i++) {
			node n = new node();
			n.next = free;
			free = n;
		}
	}
	public void remove(T obj) {
		node n;
		if (map.TryGetValue(obj, out n)) {
			remove_list(n);
			put(n);
		}
		return ;
	}
	public void add(T obj) {
		node n = get(obj);
		assert(n.prev == null);
		assert(n.next == null);
		if (head == null) {
			head = tail = n;
		} else {
			n.prev = tail;
			tail.next = n;
			tail = n;
		}
	}
	public void clear() {
		node n = head;
		assert(head == null || head.prev == null);
		assert(tail == null || tail.next == null);
		while (n != null) {
			node tmp = n.next;
			finalizer(n.obj);
			put(n);
			n = tmp;
		}
		head = tail = null;
	}
};

}

