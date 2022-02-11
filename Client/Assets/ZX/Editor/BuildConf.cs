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
							nset.Add(v.ToString());
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
		readonly string path;
		readonly lan_map_t lans;
		List<FieldInfo> fields = new List<FieldInfo>();
		string output;
		StringBuilder keyStuff = new StringBuilder();
		StringBuilder keyAssign = new StringBuilder();
		lan_builder_t lanBuilder = new lan_builder_t();
		List<string> contents = new List<string>();
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
			switch (field.type) {
			case "string":
			return "\"" + s + "\"";
			case "float":
			case "int":
			if (s.Contains(';')) {
				StringBuilder sb = new StringBuilder();
				var l1 = s.Split(';');
				sb.Append("{");
				foreach (var x in l1) {
					sb.Append("{");
					sb.Append(x);
					sb.Append("}");
				}
				sb.Append("}");
				return sb.ToString();
			} else if (s.Contains(',')) {
				return "{" + s + "}";
			} else {
				return s;
			}
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
			this.output = output;
			this.contents = new List<string>();
			keyStuff.Clear();
			keyAssign.Clear();
			Dictionary<string, SubKey> key_root = new Dictionary<string, SubKey>();
			foreach (var item in lanBuilder) {
				item.Value.Clear();
			}
			contents.Clear();

			var fi = new FileInfo(path);
			using var pkg = new ExcelPackage(fi);
			var sheet = pkg.Workbook.Worksheets[1];

			for (int r = TYPE_ROW + 1; r <= sheet.Dimension.Rows; r++) {
				int n = 0;
				StringBuilder sb = new StringBuilder();
				string id = sheet.GetValue(r, 1).ToString();
				sb.AppendFormat("[{0}] = {{", id);
				for (int c = 1; c <= fields.Count; c++) {
					FieldInfo field = fields[c - 1];
					string v = sheet.GetValue(r, c).ToString();
					if (field.select == select || (field.select == "a" || select == "a")) {
						n++;
						sb.Append(field.name + "=" + BuildValue(c, ref field, v) + ",");
					}
				}
				sb.Append("},");
				if (n > 0) {
					var keys = key_root;
					for (int c = 2; c <= fields.Count; c++) {
						FieldInfo field = fields[c - 1];
						string v = sheet.GetValue(r, c).ToString();
						if (field.name == "key" && (field.select == select || select == "a")) {
							keyStuff.AppendFormat("\n[\"{0}\"] = nil,", v);
							keyAssign.AppendFormat("M[\"{0}\"]=M[{1}]\n", v, id);
						}
						if (field.iskey) {
							if (!keys.TryGetValue(v, out var sub)) {
								sub = new SubKey();
								keys.Add(v, sub);
							}
							sub.id = id;
							keys = sub.children;
						}
					}
					contents.Add(sb.ToString());
				}
			}
			var firstkeys = new List<string>(key_root.Keys);
			for (int i = 0; i < firstkeys.Count; i++) {
				var key = firstkeys[i];
				keyStuff.AppendFormat("\n[{0}] = nil,", key);
				keyAssign.AppendFormat("\nM[{0}]={1}\n", key, key_root[key].Format(""));
			}
			if (contents.Count > 0) {
				var filename = Path.GetFileNameWithoutExtension(output);
				File.WriteAllText(output, "");
				if (WriteLanFile())
					File.AppendAllText(output, string.Format("local lan = require (ZX_LAN .. \".{0}\")\n", filename));
				File.AppendAllText(output, "local M = {\n");
				for (int i = 0; i < contents.Count; i++)
					File.AppendAllText(output, contents[i] + "\n");
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
