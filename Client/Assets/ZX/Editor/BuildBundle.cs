using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEngine;
using UnityEngine.Build.Pipeline;

namespace ZX
{
	class BuildBundle : EditorWindow
	{
		readonly string keyTarget = "zx.buildab.target";
		readonly string keyGroup = "zx.buildab.group";
		readonly string keyCompression = "zx.buildab.compression";
		readonly string keyConfig = "zx.buildab.config";
		readonly string keyOutput = "zx.buidlab.output";

		string configPath = "";
		string outputPath = "";
		public BuildTarget target;
		public BuildTargetGroup group;
		public CompressionType compression;

		void OnEnable()
		{
			target = (BuildTarget)(int.Parse(EditorUserSettings.GetConfigValue(keyTarget)));
			group = (BuildTargetGroup)(int.Parse(EditorUserSettings.GetConfigValue(keyGroup)));
			compression = (CompressionType)(int.Parse(EditorUserSettings.GetConfigValue(keyCompression)));
			configPath = EditorUserSettings.GetConfigValue(keyConfig);
			outputPath = EditorUserSettings.GetConfigValue(keyOutput);
		}

		string CreateManifest(Dictionary<string, ABT.BundleFiles> bundles, IBundleBuildResults results)
		{
			int bundle_idx = 0;
			List<string> sb = new List<string>();
			List<int> buf = new List<int>();
			Dictionary<string, int> bundle_to_id = new Dictionary<string, int>();
			SortedDictionary<string, List<int>> bundle_depended_by = new SortedDictionary<string, List<int>>();
			sb.Add("zx.manifest 1.0");
			sb.Add(bundles.Count.ToString());
			sb.Add("+bundles");
			foreach (var biter in bundles) {
				var bname = biter.Key;
				var bundle = biter.Value;
				var bid = bundle_idx++;
				bundle_to_id.Add(bname, bid);
				sb.Add(bname);
			}

			sb.Add("+assets");
			foreach (var biter in bundles) {
				var bundle = biter.Value;
				sb.Add(bundle_to_id[biter.Key].ToString());
				sb.Add(bundle.names.Count.ToString());
				foreach (var name in bundle.names)
					sb.Add(name);
			}

			sb.Add("+dependencies");
			foreach (var biter in results.BundleInfos) {
				List<int> hosts;
				var name = biter.Key;
				var bundle = biter.Value;
				var bundle_id = bundle_to_id[name];
				buf.Clear();
				foreach (var dname in bundle.Dependencies) {
					var id = bundle_to_id[dname];
					buf.Add(id);
				}
				if (buf.Count == 0)
					continue;
				buf.Sort();
				var s = string.Join(',', buf);
				if (!bundle_depended_by.TryGetValue(s, out hosts)) {
					hosts = new List<int>();
					bundle_depended_by[s] = hosts;
				}
				hosts.Add(bundle_id);
			}
			sb.Add(bundle_depended_by.Count.ToString());
			foreach (var iter in bundle_depended_by) {
				var host = string.Join(',', iter.Value);
				var depend = iter.Key;
				sb.Add(host);
				sb.Add(depend);
			}
			return string.Join('\n', sb);
		}

		void Build()
		{
			EditorUserSettings.SetConfigValue(keyTarget, ((int)target).ToString());
			EditorUserSettings.SetConfigValue(keyGroup, ((int)group).ToString());
			EditorUserSettings.SetConfigValue(keyCompression, ((int)compression).ToString());
			var abt = new ABT(configPath);
			var bundleFiles = abt.GetBundleFiles();
			List<AssetBundleBuild> abbs = new List<AssetBundleBuild>();
			foreach (var item in bundleFiles) {
				abbs.Add(new AssetBundleBuild {
					assetBundleName = item.Key,
					assetBundleVariant = "",
					addressableNames = item.Value.names.ToArray(),
					assetNames = item.Value.assets.ToArray(),
				});
			}
			var buildContent = new BundleBuildContent(abbs);
			var buildParams = new BundleBuildParameters(target, group, outputPath);
			switch (compression) {
			case CompressionType.None:
			buildParams.BundleCompression = BuildCompression.Uncompressed;
			break;
			case CompressionType.Lzma:
			buildParams.BundleCompression = BuildCompression.LZMA;
			break;
			case CompressionType.Lz4:
			case CompressionType.Lz4HC:
			buildParams.BundleCompression = BuildCompression.LZ4;
			break;
			}

			IBundleBuildResults results;
			ReturnCode exitCode;

			Directory.Delete(outputPath, true);
			Directory.CreateDirectory(outputPath);
			exitCode = ContentPipeline.BuildAssetBundles(buildParams, buildContent, out results);
			if (exitCode < ReturnCode.Success)
				throw new Exception("ABT: BuildAssetBundles " + exitCode);

			{
				var a = CreateInstance<CompatibilityAssetBundleManifest>();
				a.SetResults(results.BundleInfos);
				File.WriteAllText(buildParams.GetOutputFilePathForIdentifier(Path.GetFileName(outputPath) + ".manifest"), a.ToString());
			}

			var manifest_path = Path.Combine("Assets/", ("manifest" + ".asset"));
			TextAsset ta = new TextAsset(CreateManifest(bundleFiles, results));
			File.WriteAllText(Path.Combine(outputPath, "manifest.txt"), ta.text);
			AssetDatabase.CreateAsset(ta, manifest_path);
			AssetBundleBuild abb_manifest = new AssetBundleBuild {
				assetBundleName = "main",
				assetBundleVariant = "",
				addressableNames = new string[] { "manifest" },
				assetNames = new string[] { manifest_path },
			};
			var manifest_content = new BundleBuildContent(new List<AssetBundleBuild> { abb_manifest, });
			exitCode = ContentPipeline.BuildAssetBundles(buildParams, manifest_content, out results);
			Debug.Log("Build Finish:" + exitCode + ":" + results);
		}

		void OnGUI()
		{
			GUILayout.BeginVertical();
			GUILayout.Space(10);
			GUI.skin.label.fontSize = 24;
			GUI.skin.label.alignment = TextAnchor.MiddleCenter;
			GUILayout.Label("Build AssetBundle");
			GUI.skin.label.fontSize = 12;
			GUI.skin.label.alignment = TextAnchor.MiddleLeft;

			target = (BuildTarget)EditorGUILayout.EnumPopup("BuildTarget", target);
			group = (BuildTargetGroup)EditorGUILayout.EnumPopup("BuildTargetGroup", group);
			compression = (CompressionType)EditorGUILayout.EnumPopup("CompressionType", compression);

			GUILayout.BeginHorizontal();
			GUILayout.Label("Config file path:");
			GUILayout.FlexibleSpace();
			GUILayout.TextField(configPath);
			if (GUILayout.Button("Select")) {
				var path = EditorUtility.OpenFilePanel("Config file path", configPath, "yaml");
				if (path != "") {
					configPath = path;
					EditorUserSettings.SetConfigValue(keyConfig, configPath);
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal();
			GUILayout.Label("Asset Bundle Output Path:");
			GUILayout.FlexibleSpace();
			GUILayout.TextField(outputPath);
			if (GUILayout.Button("Select")) {
				var path = EditorUtility.OpenFolderPanel("Asset Bundle Output Path:", outputPath, "");
				if (path != "") {
					outputPath = path;
					EditorUserSettings.SetConfigValue(keyOutput, outputPath);
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal();
			if (GUILayout.Button("BuildAssetBundle"))
				Build();
			GUILayout.EndHorizontal();

			GUILayout.EndVertical();

		}
	}
}
