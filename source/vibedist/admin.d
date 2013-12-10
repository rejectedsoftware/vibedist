/**
	Provides a web based administration interface.

	Copyright: © 2012-2013 RejectedSoftware e.K.
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Sönke Ludwig
*/
module vibedist.admin;

import vibedist.controller;
import vibedist.engine;

import std.exception;
import std.file;
import std.functional : toDelegate;
import std.process : spawnProcess;
import vibe.crypto.passwordhash;
import vibe.core.log;
import vibe.http.auth.basic_auth;
import vibe.http.router;
import vibe.http.server;
import vibe.inet.path;


private AdminWebInterface s_interface;

void startAdminWebInterface(VibeDistController ctrl)
{
	s_interface = new AdminWebInterface(ctrl);
}

class AdminWebInterface {
	private {
		VibeDistController m_ctrl;
	}

	this(VibeDistController ctrl)
	{
		Config config;
		ctrl.getConfig(config);

		// setup admin interface
		auto settings = new HTTPServerSettings;
		settings.bindAddresses = [config.adminInterface];
		settings.port = config.adminPort;
		//settings.sslCertFile = "admin.crt";
		//settings.sslKeyFile = "admin.key";

		auto router = new URLRouter;
		router.get("*", performBasicAuth("VibeDist Admin Interface", toDelegate(&testPassword)));
		router.get("/", &showAdminHome);
		router.post("/restart_node", &reloadNode);
		router.post("/start_node", &startNode);

		listenHTTP(settings, router);
	}

	void showAdminHome(HTTPServerRequest req, HTTPServerResponse res)
	{
		Config config;
		m_ctrl.getConfig(config);

		res.renderCompat!("home.dt",
			HTTPServerRequest, "req",
			Config*, "config",
			PublicInterface[], "interfaces")
			(req, &config, g_interfaces);
	}

	void startNode(HTTPServerRequest req, HTTPServerResponse res)
	{
		auto path = Path(req.form["path"]);
		enforce(path.absolute, "The path to the vibe application must be absolute.");

		string[] args;
		args ~= "dub";
		args ~= "--";
		args ~= "--disthost";
		args ~= "127.0.0.1";
		auto cwd = getcwd();
		chdir(path.toNativeString());
		scope(exit) chdir(cwd);
		auto process = spawnProcess(args);
		logInfo("Spawned %s as %d", path.toString(), process);

		res.redirect("/");
	}

	void reloadNode(HTTPServerRequest req, HTTPServerResponse res)
	{

	}

	private bool testPassword(string username, string password)
	{
		if( username != "root" ) return false;
		Config cfg;
		m_ctrl.getConfig(cfg);
		auto pwhash = cfg.rootPasswordHash;
		return testSimplePasswordHash(pwhash, password);
	}
}
