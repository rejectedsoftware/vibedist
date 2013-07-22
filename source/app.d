import vibe.d;
import vibe.crypto.passwordhash;

import admin;
import config;
import engine;

void apiIndex(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeJsonBody(["message": "This is the VibeDist API."]);
}

void registerNode(HTTPServerRequest req, HTTPServerResponse res)
{
	Config cfg;
	getConfig(cfg);
	auto jreq = req.json;

	string hostname = jreq.hostName.get!string;
	ushort port = jreq.port.get!ushort;
	string local_address = req.peer;
	ushort local_port = jreq.localPort.get!ushort;
	string ssl_cert = jreq.sslCertFile.get!string;
	string ssl_key = jreq.sslKeyFile.get!string;
	int pid = jreq.pid.get!int;

	SSLContext ssl_context; // TODO: add proper support

	foreach( intf; g_interfaces ){
		auto s = intf.settings;
		if (s.hostName != hostname || s.port != port || s.sslContext !is ssl_context)
			continue;

		foreach( n; intf.nodes ){
			if( n.address == local_address && n.port == local_port )
				return;
		}

		intf.nodes ~= new Node(local_address, local_port, pid);
		return;
	}

	auto settings = new HTTPServerSettings;
	settings.hostName = hostname;
	settings.port = port;
	settings.bindAddresses = cfg.publicInterfaces;
	settings.sslContext = ssl_context;

	auto intf = new PublicInterface;
	intf.settings = settings;
	intf.nodes ~= new Node(local_address, local_port, pid);

	listenHTTP(settings, intf);
	g_interfaces ~= intf;

	res.writeJsonBody(["message": "Successfully registered."]);
}

bool testPassword(string username, string password)
{
	if( username != "root" ) return false;
	Config cfg;
	getConfig(cfg);
	auto pwhash = cfg.rootPasswordHash;
	return testSimplePasswordHash(pwhash, password);
}

static this()
{
	Config cfg;
	getConfig(cfg);

	{ // setup node interface
		auto settings = new HTTPServerSettings;
		settings.bindAddresses = cfg.nodeInterfaces;
		settings.port = cfg.nodePort;

		auto router = new URLRouter;
		router.get("/", &apiIndex);
		router.post("/register", &registerNode);

		listenHTTP(settings, router);
	}

	{ // setup admin interface
		auto settings = new HTTPServerSettings;
		settings.bindAddresses = [cfg.adminInterface];
		settings.port = cfg.adminPort;
		//settings.sslCertFile = "admin.crt";
		//settings.sslKeyFile = "admin.key";

		auto router = new URLRouter;
		router.get("*", performBasicAuth("VibeDist Admin Interface", toDelegate(&testPassword)));
		router.get("/", &showAdminHome);
		router.post("/restart_node", &reloadNode);
		router.post("/start_node", &startNode);

		listenHTTP(settings, router);
	}
}
