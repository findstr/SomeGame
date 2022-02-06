using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using UnityEditor;
using UnityEngine;

public class RemoteD : EditorWindow
{
    class Client { 
        public TcpClient sock;
        public string addr;
	};

    [MenuItem("ZX/Test")]
    static void foo() { 
        GetWindow(typeof(RemoteD));
	}

    TcpListener server = null;
    private List<Thread> threads = null;
    void command_thread(object o) {
        Client c = o as Client;
        using var reader = new StreamReader(c.sock.GetStream()); 
        using var writer = new StreamWriter(c.sock.GetStream());
	    string line;
        while ((line = reader.ReadLine()) != null) {
            if (line == "GET") { 
                var filename = reader.ReadLine();
                if (filename == null)
                    break;
                if (File.Exists(filename)) { 
                    var bytes = File.ReadAllBytes(filename);
					writer.WriteLine("+OK");
					writer.WriteLine(bytes.Length.ToString());
			        writer.Flush();
                    writer.BaseStream.Write(bytes, 0, bytes.Length);
                    Debug.Log(string.Format("Remote<{0}>: GET {1} OK", c.addr, filename)); 
                } else { 
                    writer.WriteLine("-Fail");
                    Debug.Log(string.Format("Remote<{0}>: GET {1} Fail", c.addr, filename)); 
		        }
			    writer.Flush();
		    } else if (line == "LOG") {
                var txt = reader.ReadLine();
                Debug.Log(string.Format("Remote<{0}>:{1} {2}", c.addr, line, txt));
            } else { 
                Debug.Log(string.Format("Remote<{0}>: unsupport cmd: {1}", c.addr, line));
	    	}
        }
        c.sock.Close();
    }

    void listen_thread(object o) { 
        TcpListener server = o as TcpListener;
        server.Start();
        try {
            while (true) {
                var client = new Client();
                client.sock = server.AcceptTcpClient();
                client.addr = client.sock.Client.RemoteEndPoint.ToString();
                Thread th = new Thread(command_thread) {
                    IsBackground = true
                };
                th.Start(client);
            }
        }  catch (SocketException e) {
            server.Stop();
            Debug.Log("RemoteD:" + e.Message);
        }
	}

    void OnGUI()
    {
        GUILayout.BeginVertical(); 
        if(server == null) {
            if (GUILayout.Button("Start")) { 
                server = new TcpListener(IPAddress.Parse("0.0.0.0"), 8888);
                threads = new List<Thread>();
                var th = new Thread(listen_thread) {
                    IsBackground = true
                };
                th.Start(server);
                threads.Add(th);
	    	} 
	    } else { 
            if (GUILayout.Button("Stop")) { 
                server.Stop();
                foreach (var th in threads) { 
                    th.Abort();
		        }
                server = null;
	    	} 
	    }
        GUILayout.EndVertical();
    }

}
