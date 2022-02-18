using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using UnityEngine;

namespace ZX
{
    using bundle_map_t = Dictionary<string, BundleInfo>;
    class BundleInfo {
        public BundleInfo() {
            name = "";
            root = "";
            match = new List<string>();
            include = new List<string>();
        }
        public string name;
        public string root { get; set;}
        public List<string> match { get; set; }
        public List<string> include { get; set; }
    }

    class BundleAll {
        public BundleAll() {
            ABT = new bundle_map_t();
        }
        public string Entry{ get; set; }
        public bundle_map_t ABT{ get; set; }
    }

    public class ABT
    {
        public delegate void progress_cb_t(string path, float progress);
        readonly Dictionary<string, string> file_to_name = new Dictionary<string, string>();
        readonly Dictionary<string, string> file_to_bundle = new Dictionary<string, string>();
        readonly Dictionary<string, string> file_to_match = new Dictionary<string, string>();

        string BuildFileName(string path) {
            if (path.EndsWith(".lua")) {
                var name = path.Remove(path.Length - 4).Replace("/", ".");
                return name;
            }
            return path;
        }

        void Match(string abname, string root, List<string> match) {
            root = root.Replace("\\", "/");
            foreach (var m in match) {
                var search = m.Replace('$', '*');       
                var pattern = new Regex(m.Replace("$", "([^\\\\]+)").Replace("*", "[^\\\\]*").Replace(".", "\\.") + "$"); 
                var files = Directory.GetFiles(root);
                //TODO:optimise match pattern to reduce too many useless iteration
                foreach (string s in Directory.EnumerateFiles(root, "*.*", SearchOption.AllDirectories)) {
                    var f = s.Replace("\\", "/");
                    var relative = f.Replace(root, "");
                    if (!pattern.IsMatch(relative))
                        continue;
                    if (relative.StartsWith("/"))
                        relative = relative.Remove(0, 1);
                    var name = pattern.Match(relative).Groups[1].Value;
                    var ab = abname.Replace("$", name);
                    if (!file_to_match.TryAdd(f, ab)) 
                        throw new Exception(string.Format("ABT: <{2}> file '{0}' already in '{1}'", f, file_to_match[f], abname));
                    file_to_name[f] = BuildFileName(relative);
                }
            }
        }

        void Include(string abname, string root, List<string> include) {
            root = root.Replace("\\", "/");
            foreach (var m in include) {
                bool haspattern = m.Contains("*");
                foreach (string s in Directory.EnumerateFiles(root, m, SearchOption.AllDirectories)) {
                    Dictionary<string, string> set;
                    var f = s.Replace("\\", "/");
                    var relative = f.Replace(root, "");
                    if (relative.StartsWith("/"))
                        relative = relative.Remove(0, 1);
                    set = haspattern ? file_to_match : file_to_bundle;
                    if (!set.TryAdd(f, abname)) 
                        throw new Exception(string.Format("ABT: <{2}> file '{0}' already in '{1}'", f, set[f], abname));
                    file_to_name[f] = BuildFileName(relative);
                }
            }
        }

        public ABT(string path, progress_cb_t cb = null) {
            var str = File.ReadAllText(path);
            if (str == null)
                throw new Exception("ABT:" + path + "not exist");
            var reader = new YamlDotNet.Serialization.Deserializer();
            var bundles = reader.Deserialize<BundleAll>(str);
            foreach (var item in bundles.ABT) {
                var b = item.Value;
                b.name = item.Key;
                var roots = b.root.Split(';');
                foreach (var root in roots) {
                    if (b.match.Count == 0 && b.include.Count == 0) 
                        throw new Exception("ABT: bundle'" + b.name + "' is empty");
                    if (b.match.Count > 0 && b.include.Count > 0) 
                        throw new Exception("ABT: bundle '" + b.name + "' can't support both 'match' and 'include'");
                    if (b.match.Count > 0) {
                        if (!b.name.Contains('$'))
                            throw new Exception("ABT: bundle '" + b.name + "' invalid match syntax");
                        Match(b.name, root, b.match);
                    }
                    if (b.include.Count> 0)
                        Include(b.name, root, b.include);
                }
            }
            foreach (var item in file_to_match) {
                file_to_bundle.TryAdd(item.Key, item.Value);
            }
        }
        public Dictionary<string, string> GetFullName() {
            Dictionary<string, string> x = new Dictionary<string, string>();
            foreach (var item in file_to_name) {
                x.Add(item.Value, item.Key);
            }
            return x;
        }

        public class BundleFiles {
            public List<string> assets = new List<string>();
            public List<string> names = new List<string>();
        };

        public Dictionary<string, BundleFiles> GetBundleFiles()
        {
            Dictionary<string, BundleFiles> bundles = new Dictionary<string, BundleFiles>();
            foreach (var item in file_to_bundle) {
                BundleFiles bf;
                if (!bundles.TryGetValue(item.Value, out bf)) {
                    bf = new BundleFiles();
                    bundles.Add(item.Value, bf);
                }
                bf.assets.Add(item.Key);
                bf.names.Add(file_to_name[item.Key]);
            }
            return bundles; 
        }
    }
}
