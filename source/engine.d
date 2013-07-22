import vibe.d;

version(Posix)
{
	import core.sys.posix.signal;
}

class Node : HTTPServerRequestHandler {
	string address;
	ushort port;
	HTTPServerRequestDelegate requestHandler;
	int pendingRequests = 0;
	int pid;
	bool active = true;


	this(string address, ushort port, int pid)
	{
		this.address = address;
		this.port = port;
		this.pid = pid;
		requestHandler = reverseProxyRequest(address, port);
	}

	void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
	{
		pendingRequests++;
		scope(exit) pendingRequests--;
		requestHandler(req, res);
	}

	void kill()
	{
		version(Posix){
			.kill(pid, SIGTERM);
		} else {
			assert(false);
		}
	}
}

class PublicInterface : HTTPServerRequestHandler {
	HTTPServerSettings settings;
	string path;
	Node[] nodes;

	void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
	{
		nodes[0].handleRequest(req, res);
	}
}

PublicInterface[] g_interfaces;

