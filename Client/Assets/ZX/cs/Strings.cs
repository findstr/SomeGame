using System.Collections.Generic;
using UnityEngine;

namespace ZX
{
	class Strings {
		Dictionary<string, int> StrToId = new Dictionary<string, int>();
		readonly List<string> IdToStr = new List<string>();
		public int New(string s) {
			if (StrToId.TryGetValue(s, out int id))
				return id;
			id = IdToStr.Count;
			IdToStr.Add(s);
			return id;
		}
		public string Get(int id) {
			if (IdToStr.Count <= id) {
				Debug.LogWarning("ZX.Strings.Get invalid string id:" + id);
				return "";
			}
			return IdToStr[id];
		}
	}
}

