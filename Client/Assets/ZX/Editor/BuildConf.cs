using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace ZX
{
	using lan_builder_t = Dictionary<string, StringBuilder>;
	using lan_map_t = Dictionary<string, Dictionary<string, string>>;
	struct FieldInfo
	{
		public string name;
		public string type;
		public string select;
		public bool iskey;
		private static readonly Regex parseExp = new Regex("([^(]+)\\(([^\\)]+)\\)(\\*?)");
		public void Parse(string s)
		{
			var o = parseExp.Match(s);
			type = o.Groups[1].Value.ToLower();
			select = o.Groups[2].Value.ToLower();
			iskey = o.Groups[3].Value == "*";
			Debug.Log("Parse:" + s + ":" + type + ":" + select + ":" + iskey);
		}
		public bool IsMatch(string s) 
		{
			return (s == "a") || (select == "a") || select == s;
		}
	};
	class SubKey
	{
		public string id;
		public Dictionary<string, SubKey> children = new Dictionary<string, SubKey>();
		public string Format(string tab)
		{
			if (children.Count == 0)
				return String.Format("M[{0}],", id);
			List<string> keys = new List<string>(children.Keys);
			keys.Sort();
			StringBuilder sb = new StringBuilder();
			sb.AppendFormat("{0}{{\n", tab);
			for (int i = 0; i < keys.Count; i++) {
				var c = children[keys[i]];
				sb.AppendFormat("\t{3}[{0}] = {2}{1}{2}{4}{2}", keys[i], c.Format(tab + "\t"), c.children.Count > 0 ? "\n" : "", tab, c.children.Count > 0 ? tab : "");
			}
			sb.AppendFormat("\n{0}}}", tab);
			return sb.ToString();
		}
	};

	class ExportLan : EditorWindow
	{
		readonly string excelPath;
		readonly string lanPath;
		readonly string lanDefault;

		public const int NAME_ROW = 2;
		public const int TYPE_ROW = 3;
		HashSet<string> nset = new HashSet<string>();

		public ExportLan(string excel_path, string lan_path, string lan_default)
		{
			excelPath = excel_path;
			lanPath = lan_path;
			lanDefault = lan_default;
		}

		void Collect(string path)
		{
			var fi = new FileInfo(path);
			using var pkg = new ExcelPackage(fi);
			var sheet = pkg.Workbook.Worksheets[1];
			for (int c = 1; c <= sheet.Dimension.Columns; c++) {
				var s = sheet.GetValue(TYPE_ROW, c);
				Debug.Log("LanCollect:" + c + ":" + s);
				if (s != null) {
					FieldInfo t = new FieldInfo();
					t.Parse(s.ToString());
					if (t.type == "lan") {
						for (int r = TYPE_ROW + 1; r <= sheet.Dimension.Rows; r++) {
							var v = sheet.GetValue(r, c);
							var x = v.ToString();
							if (x != "nil")
								nset.Add(x);
						}
					}
				}
			}
		}

		void Update()
		{
			var fi = new FileInfo(lanPath);
			using var pkg = new ExcelPackage(fi);
			int rows = 0;
			ExcelWorksheet sheet;
			if (pkg.Workbook.Worksheets.Count == 0) {
				sheet = pkg.Workbook.Worksheets.Add("Lan");
				rows = 1;
				sheet.InsertRow(rows, 1);
				sheet.Cells[rows++, 1].Value = lanDefault;
			} else {
				sheet = pkg.Workbook.Worksheets[1];
				for (int r = 1; r <= sheet.Dimension.Rows; r++) {
					var s = sheet.GetValue(r, 1).ToString();
					nset.Remove(s);
				}
				rows = sheet.Dimension.Rows + 1;
			}
			foreach (var s in nset) {
				sheet.InsertRow(rows, 1);
				sheet.Cells[rows++, 1].Value = s;
			}
			pkg.Save();
		}


		public void Execute()
		{
			var files = Directory.GetFiles(excelPath, "*.xlsx");
			int n = files.Length;
			for (int i = 0; i < n; i++) {
				var f = files[i];
				EditorUtility.DisplayProgressBar("ExportLan", f, (float)i / n);
				Collect(f);
			}
			Update();
			EditorUtility.ClearProgressBar();
		}
	}

	class LanContent
	{
		public lan_map_t lans = new lan_map_t();
		public LanContent(string lanPath)
		{
			var fi = new FileInfo(lanPath);
			using (var pkg = new ExcelPackage(fi)) {
				var sheet = pkg.Workbook.Worksheets[1];
				for (int c = 1; c <= sheet.Dimension.Columns; c++) {
					string lan_name = sheet.GetValue(1, c).ToString();
					Dictionary<string, string> dict = new Dictionary<string, string>();
					lans[lan_name] = dict;
					for (int r = 2; r <= sheet.Dimension.Rows; r++) {
						dict[sheet.GetValue(r, 1).ToString()] = sheet.GetValue(r, c).ToString();
					}
				}
			}
		}
	};

	class ExportLua
	{
		public const int NAME_ROW = ExportLan.NAME_ROW;
		public const int TYPE_ROW = ExportLan.TYPE_ROW;
		string output;
		readonly string path;
		readonly lan_map_t lans;
		List<FieldInfo> fields = new List<FieldInfo>();
		StringBuilder keyStuff = new StringBuilder();
		StringBuilder keyAssign = new StringBuilder();
		lan_builder_t lanBuilder = new lan_builder_t();
		void ParseFieldInfo()
		{
			var fi = new FileInfo(path);
			using var pkg = new ExcelPackage(fi);
			var sheet = pkg.Workbook.Worksheets[1];
			for (int c = 1; c <= sheet.Dimension.Columns; c++) {
				var s = sheet.GetValue(NAME_ROW, c);
				if (s == null)
					break;
				FieldInfo finfo = new FieldInfo();
				finfo.name = s.ToString();
				finfo.Parse(sheet.GetValue(TYPE_ROW, c).ToString());
				fields.Add(finfo);
			}
		}

		public ExportLua(string path, lan_map_t lans)
		{
			this.lans = lans;
			this.path = path;
			foreach (var item in lans) {
				lanBuilder[item.Key] = new StringBuilder();
			}
			ParseFieldInfo();
		}

		string BuildValue(int rowid, ref FieldInfo field, string s)
		{
			if (s.Contains(',')) {
				var sb = new StringBuilder();
				var list = s.Split(',');
				sb.Append("{");
				foreach (var x in list) { 
					if (x != "") 
						sb.AppendFormat("{0},", BuildValue(rowid, ref field, x));
				}
				sb.Append("}");
				return sb.ToString();
			}
			if (s.Contains(':')) {
				var sb = new StringBuilder();
				var list = s.Split(':');
				sb.Append("{");
				foreach (var x in list) 
					sb.AppendFormat("{0},", BuildValue(rowid, ref field, x));
				sb.Append("}");
				return sb.ToString();
			}
			if (s == "nil")
				return s;
			switch (field.type) {
			case "string":
				return "\"" + s + "\"";
			case "number":
				return  s;
			case "lan":
				string variable = field.name + "_" + rowid;
				foreach (var item in lanBuilder) {
					if (!lans[item.Key].TryGetValue(s, out string translation))
						throw new Exception(string.Format("BuildConf: now translation of row {0} in File {1}", rowid, path));
					item.Value.Append(variable + "=\"" + translation + "\",\n");
				}
				return "lan." + variable;
			default:
				throw new Exception("BuildConf:Unspport field type:" + field.type);
			}
		}

		bool WriteLanFile()
		{
			bool exist_lan_file = false;
			string file = Path.GetFileName(output);
			foreach (var item in lanBuilder) {
				var txt = item.Value.ToString();
				if (txt.Length != 0) {
					var dir = Path.Combine(Path.GetDirectoryName(output), item.Key);
					Directory.CreateDirectory(dir);
					var path = Path.Combine(dir, file);
					File.WriteAllText(path, "local M = {\n");
					File.AppendAllText(path, txt);
					File.AppendAllText(path, "}\n return M\n");
					exist_lan_file = true;
				}
			}
			return exist_lan_file;
		}
		public void Execute(string select, string output)
		{
			bool export_kv = false;
			this.output = output;
			keyStuff.Clear();
			keyAssign.Clear();
			Dictionary<string, SubKey> key_root = new Dictionary<string, SubKey>();
			foreach (var item in lanBuilder) {
				item.Value.Clear();
			}
			int select_count = 0;
			var fi = new FileInfo(path);
			using var pkg = new ExcelPackage(fi);
			var sheet = pkg.Workbook.Worksheets[1];
			string[] row = new string[fields.Count];
			for (int c = 0; c < fields.Count; c++) {
					var field = fields[c];
					if (!field.IsMatch(select)) 
						continue;
					select_count++;
					if (field.name.ToLower() == "@key")
						export_kv = true;
			}
			Debug.Log("Rows:" + sheet.Dimension.Rows + ":" + select_count + ":" + output);
			if (select_count == 0)
				return ;
			for (int r = TYPE_ROW + 1; r <= sheet.Dimension.Rows; r++) {
				StringBuilder sb = new StringBuilder();
				var field = fields[0];
				var cell = sheet.GetValue(r, 1);	
				if (cell == null) 
					Debug.LogError(string.Format("{0}[{1}][{2}] not exist", output, r, 1));
				string id = BuildValue(1, ref field, cell.ToString());
				for (int c = 1; c <= fields.Count; c++) {
					field = fields[c - 1];
					cell = sheet.GetValue(r, c);	
					if (cell == null) 
						Debug.LogError(string.Format("{0}[{1}][{2}] not exist", output, r, c));
					string s = cell.ToString();
					if (field.IsMatch(select)) {
						string v = BuildValue(r, ref field, s);
						row[c-1] = v;
					}
				}
				if (export_kv) {
					for (int c = 1; c <= fields.Count; c++) {
						field = fields[c - 1];
						string v = row[c - 1];
						if (field.name.ToLower() == "@key" && field.IsMatch(select)) {
							keyStuff.AppendFormat("\n[{0}] = ", v);
						}
						if (field.name.ToLower() == "@value" && field.IsMatch(select)) {
							keyStuff.Append(v);
						}
					}
				} else {
					keyStuff.AppendFormat("[{0}] = {{", id);
					var keys = key_root;
					for (int c = 1; c <= fields.Count; c++) {
						field = fields[c - 1];
						string v = row[c - 1];
						if (field.IsMatch(select)) {
							keyStuff.AppendFormat("{0} = {1},", field.name, v);
							if (field.iskey) {
								if (!keys.TryGetValue(v, out var sub)) {
									sub = new SubKey();
									keys.Add(v, sub);
								}
								sub.id = id;
								keys = sub.children;
							}
						}
					}
					keyStuff.Append("}");
				}
				keyStuff.Append(",\n");
			}
			var firstkeys = new List<string>(key_root.Keys);
			for (int i = 0; i < firstkeys.Count; i++) {
				var key = firstkeys[i];
				keyStuff.AppendFormat("\n[{0}] = nil,", key);
				keyAssign.AppendFormat("\nM[{0}]={1}\n", key, key_root[key].Format(""));
			}
			if (select_count > 0) {
				var filename = Path.GetFileNameWithoutExtension(output);
				File.WriteAllText(output, "");
				if (WriteLanFile())
					File.AppendAllText(output, string.Format("local lan = require (ZX_LAN .. \".{0}\")\n", filename));
				File.AppendAllText(output, "local M = {\n");
				File.AppendAllText(output, keyStuff.ToString());
				File.AppendAllText(output, "\n}\n");
				File.AppendAllText(output, keyAssign.ToString());
				File.AppendAllText(output, "return M\n");
			}
		}
	}


	class BuildConf : EditorWindow
	{
		private const string keyLan = "zx.buildconf.defaultlan";
		private const string keyLanPath = "zx.buildconf.lanpath";
		private const string keyExcel = "zx.buildconf.excel";
		private const string keyClient = "zx.buildconf.client";
		private const string keyServer = "zx.buildconf.server";
		private const string keyTime = "zx.buildconf.timestamp";

		private string lanDefault = "CN";
		private string excelPath = "";
		private string lanPath = "";
		private string clientOutput = "";
		private string serverOutput = "";

		private const int NAME_ROW = 2;
		private const int TYPE_ROW = 3;

		void OnEnable()
		{
			lanDefault = EditorUserSettings.GetConfigValue(keyLan);
			excelPath = EditorUserSettings.GetConfigValue(keyExcel);
			lanPath = EditorUserSettings.GetConfigValue(keyLanPath);
			clientOutput = EditorUserSettings.GetConfigValue(keyClient);
			serverOutput = EditorUserSettings.GetConfigValue(keyServer);
		}

		void Export(long time)
		{
			long newest = time;
			var lan = new LanContent(lanPath);
			var files = Directory.GetFiles(excelPath, "*.xlsx");
			int n = files.Length;
			DateTime origin = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
			for (int i = 0; i < n; i++) {
				var f = files[i];
				DateTime date = File.GetLastWriteTime(f);
				TimeSpan diff = date.ToUniversalTime() - origin;
				if (diff.TotalSeconds > time) {
					var exporter = new ExportLua(f, lan.lans);
					if (diff.TotalSeconds > newest)
						newest = (long)diff.TotalSeconds;
					exporter.Execute("c", Path.Combine(clientOutput, Path.GetFileNameWithoutExtension(f) + ".lua"));
					exporter.Execute("s", Path.Combine(serverOutput, Path.GetFileNameWithoutExtension(f) + ".lua"));
				}
				EditorUtility.DisplayProgressBar("ExportConf", f, (float)i / n);
			}
			EditorUtility.ClearProgressBar();
			EditorUserSettings.SetConfigValue(keyTime, newest.ToString());
		}

		void ExportConf()
		{
			long t = 0;
			var ts = EditorUserSettings.GetConfigValue(keyTime);
			if (ts != null)
				t = long.Parse(ts);
			Export(t);
		}

		void ExportAll()
		{
			Export(0);
		}

		void OnGUI()
		{
			GUILayout.BeginVertical();
			GUILayout.Space(10);
			GUI.skin.label.fontSize = 24;
			GUI.skin.label.alignment = TextAnchor.MiddleCenter;
			GUILayout.Label("Build Config file");
			GUI.skin.label.fontSize = 12;
			GUI.skin.label.alignment = TextAnchor.MiddleLeft;

			GUILayout.BeginHorizontal();
			GUILayout.Label("Excel path:");
			GUILayout.TextField(excelPath);
			GUILayout.FlexibleSpace();
			if (GUILayout.Button("Select")) {
				var path = EditorUtility.OpenFolderPanel("Excel path", excelPath, "");
				if (path != "") {
					path = Path.GetRelativePath(Application.dataPath + "/../", path);
					excelPath = path;
					EditorUserSettings.SetConfigValue(keyExcel, excelPath);
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal();
			GUILayout.Label("Default Language:");
			lanDefault = GUILayout.TextField(lanDefault);
			if (GUILayout.Button("Save")) {
				EditorUserSettings.SetConfigValue(keyLan, lanDefault);
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal();
			GUILayout.Label("Language file path:");
			GUILayout.TextField(lanPath);
			GUILayout.FlexibleSpace();
			if (GUILayout.Button("Select")) {
				var path = EditorUtility.SaveFilePanel("Language file path", lanPath, "Lan", "xlsx");
				if (path != "") {
					path = Path.GetRelativePath(Application.dataPath + "/../", path);
					lanPath = path;
					EditorUserSettings.SetConfigValue(keyLanPath, lanPath);
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal();
			GUILayout.Label("Client output:");
			GUILayout.TextField(clientOutput);
			GUILayout.FlexibleSpace();
			if (GUILayout.Button("Select")) {
				var path = EditorUtility.OpenFolderPanel("Client output", clientOutput, "");
				if (path != "") {
					path = Path.GetRelativePath(Application.dataPath + "/../", path);
					clientOutput = path;
					EditorUserSettings.SetConfigValue(keyClient, clientOutput);
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal();
			GUILayout.Label("Server output:");
			GUILayout.TextField(serverOutput);
			GUILayout.FlexibleSpace();
			if (GUILayout.Button("Select")) {
				var path = EditorUtility.OpenFolderPanel("Server output", serverOutput, "");
				if (path != "") {
					path = Path.GetRelativePath(Application.dataPath + "/../", path);
					serverOutput = path;
					EditorUserSettings.SetConfigValue(keyServer, serverOutput);
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal();
			if (GUILayout.Button("ExportLan")) {
				var ex = new ExportLan(excelPath, lanPath, lanDefault);
				ex.Execute();
			}
			if (GUILayout.Button("ExportConfig(incremental)"))
				ExportConf();
			if (GUILayout.Button("ExportConfig(full)"))
				ExportAll();
			GUILayout.EndHorizontal();


			GUILayout.EndVertical();
		}
	}
}
