using UnityEngine;

namespace ZX { 

public class Array<T> {
	private int capacity = 0;
	private T[] array = null;
	public int count {get; private set;}
	public T this[int i] {
		get { return array[i]; }
		set { array[i] = value; }
	}
	public Array(int cap) {
		Debug.Assert(cap > 0);
		capacity = cap;
		count = 0;
		array = new T[capacity];
	}
	public void push(T obj)  {
		if (count >= capacity) {
			capacity *= 2;
			var arr = new T[capacity];
			array.CopyTo(arr, 0);
			array = arr;
		}
		array[count++] = obj;
	}
	public void clear() {
		for (int i = 0; i < count; i++)
			array[i] = default(T);
		count = 0;
	}
	public void adjust(int count) {
		Debug.Assert(count <= this.capacity);
		this.count = count;
	}
};

}

