import vibe.d;
import vibe.crypto.passwordhash;

import admin;
import config;
import engine;

void apiIndex(HttpServerRequest req, HttpServerResponse res)
{
	res.writeJsonBody(["message": "This is the VibeDist API."]);
}

void registerNode(HttpServerRequest req, HttpServerResponse res)
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

	foreach( intf; g_interfaces ){
		auto s = intf.settings;
		if( s.hostName != hostname || s.port != port || s.sslCertFile != ssl_cert || s.sslKeyFile != ssl_key )
			continue;

		foreach( n; intf.nodes ){
			if( n.address == local_address && n.port == local_port )
				return;
		}

		intf.nodes ~= new Node(local_address, local_port, pid);
		return;
	}

	auto settings = new HttpServerSettings;
	settings.hostName = hostname;
	settings.port = port;
	settings.bindAddresses = cfg.publicInterfaces;
	settings.sslKeyFile = ssl_key;
	settings.sslCertFile = ssl_cert;

	auto intf = new PublicInterface;
	intf.settings = settings;
	intf.nodes ~= new Node(local_address, local_port, pid);

	listenHttp(settings, intf);
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
		auto settings = new HttpServerSettings;
		settings.bindAddresses = cfg.nodeInterfaces;
		settings.port = cfg.nodePort;

		auto router = new UrlRouter;
		router.get("/", &apiIndex);
		router.post("/register", &registerNode);

		listenHttp(settings, router);
	}

	{ // setup admin interface
		auto settings = new HttpServerSettings;
		settings.bindAddresses = [cfg.adminInterface];
		settings.port = cfg.adminPort;
		//settings.sslCertFile = "admin.crt";
		//settings.sslKeyFile = "admin.key";

		auto router = new UrlRouter;
		router.get("*", performBasicAuth("VibeDist Admin Interface", toDelegate(&testPassword)));
		router.get("/", &showAdminHome);
		router.post("/restart_node", &reloadNode);
		router.post("/start_node", &startNode);

		listenHttp(settings, router);
	}
}
