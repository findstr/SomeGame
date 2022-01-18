using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ZX{
static partial class Core {
	static private Strings Strings = null;
	static void InitStrings() {
		Strings = new Strings();
	}
	static public int StringNew(string s) {
		return Strings.New(s);
	}
}}
