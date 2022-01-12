using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace ZX
{
    class Tools : EditorWindow {
        [MenuItem("ZX/BuildConfig")]
        static void BuildConfig()
        {
            GetWindow(typeof(BuildConf));
        }

    }
}
