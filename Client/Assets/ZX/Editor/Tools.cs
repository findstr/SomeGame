﻿using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.AssetImporters;
using UnityEngine;

namespace ZX
{
    [ScriptedImporter(1, ".lua")]
    public class LuaImporter : ScriptedImporter
    {
        public override void OnImportAsset(AssetImportContext ctx)
        {
            //读取文件内容
            var luaTxt = File.ReadAllText(ctx.assetPath);
            //转成TextAsset（Unity可识别类型）
            var assetsText = new TextAsset(luaTxt);
            //将对象assetText添加到导入操作(AssetImportContext)的结果中。
            ctx.AddObjectToAsset("main obj", assetsText);
            //将对象assetText作为导入操作的主要对象。
            ctx.SetMainObject(assetsText);
        }
    }

    class Tools : EditorWindow {
        [MenuItem("ZX/BuildConfig")]
        static void BuildConfig()
        {
            GetWindow(typeof(BuildConf));
        }
        [MenuItem("ZX/BuildAssetBundle")]
        static void BuildAB()
        {
            GetWindow(typeof(BuildBundle));
        }
    }
}
