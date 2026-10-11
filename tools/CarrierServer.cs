// A dependency-free local HTTP server for the Windows browser package.
// .NET Framework 4.x, loopback only. No install, URL reservation, or admin rights.
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Diagnostics;
using System.Threading;
class CarrierServer {
    static string root;
    static void Main(string[] args) {
        int port = 1942;
        bool open = true;
        foreach (string arg in args) {
            if (arg == "--no-browser") open = false;
            else if (arg.StartsWith("--port=")) port = int.Parse(arg.Substring(7));
        }
        root = Path.GetFullPath(AppDomain.CurrentDomain.BaseDirectory);
        if (!File.Exists(Path.Combine(root, "index.html"))) {
            Console.WriteLine("Bitte CarrierServer.exe im entpackten Webordner starten.");
            Environment.ExitCode = 1; return;
        }
        var listener = new TcpListener(IPAddress.Loopback, port);
        try { listener.Start(); }
        catch (SocketException) { Console.WriteLine("Port belegt. Start mit --port=1943 versuchen."); Environment.ExitCode = 1; return; }
        string url = "http://127.0.0.1:" + port + "/";
        Console.WriteLine("Carrier Ace: " + url + " | Beenden mit Strg+C");
        if (open) Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
        while (true) {
            TcpClient client = listener.AcceptTcpClient();
            ThreadPool.QueueUserWorkItem(delegate { Serve(client); });
        }
    }
    static void Serve(TcpClient client) {
        using (client) {
            client.ReceiveTimeout = 5000; client.SendTimeout = 10000;
            try {
                using (var stream = client.GetStream()) {
                    var reader = new StreamReader(stream, Encoding.ASCII, false, 1024, true);
                    string first = reader.ReadLine();
                    if (first == null) return;
                    string line;
                    do { line = reader.ReadLine(); } while (!string.IsNullOrEmpty(line));
                    string[] parts = first.Split(' ');
                    if (parts.Length < 2) return;
                    string relative = Uri.UnescapeDataString(parts[1].Split('?')[0]).TrimStart('/');
                    if (relative == "") relative = "index.html";
                    string path = Path.GetFullPath(Path.Combine(root, relative.Replace('/', Path.DirectorySeparatorChar)));
                    bool found = path.StartsWith(root, StringComparison.OrdinalIgnoreCase) && File.Exists(path);
                    long length = found ? new FileInfo(path).Length : 0;
                    string extension = Path.GetExtension(path);
                    string type = extension == ".html" ? "text/html; charset=utf-8" : extension == ".js" ? "text/javascript" : extension == ".wasm" ? "application/wasm" : extension == ".png" ? "image/png" : "application/octet-stream";
                    string header = "HTTP/1.1 " + (found ? "200 OK" : "404 Not Found") + "\r\nContent-Type: " + type + "\r\nContent-Length: " + length + "\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n";
                    byte[] bytes = Encoding.ASCII.GetBytes(header);
                    stream.Write(bytes, 0, bytes.Length);
                    if (found && parts[0] != "HEAD") using (var f = File.OpenRead(path)) f.CopyTo(stream);
                }
            } catch (IOException) { } catch (SocketException) { } catch (ArgumentException) { }
        }
    }
}
