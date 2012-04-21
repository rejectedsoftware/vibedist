import vibe.d;

import config;
import engine;

import std.process;

void showAdminHome(HttpServerRequest req, HttpServerResponse res)
{
	Config config;
	getConfig(config);

	res.renderCompat!("home.dt",
		HttpServerRequest, "req",
		Config*, "config",
		PublicInterface[], "interfaces")
		(Variant(req), Variant(&config), Variant(g_interfaces));
}

void startNode(HttpServerRequest req, HttpServerResponse res)
{
	auto path = Path(req.form["path"]);
	enforce(path.absolute, "The path to the vibe application must be absolute.");

	string[] args;
	args ~= "--disthost";
	args ~= "127.0.0.1";
	auto process = spawnProcess("vibe", args, path.toString());
	logInfo("Spawned %s as %d", path.toString(), process.id);

	res.redirect("/");
}

void reloadNode(HttpServerRequest req, HttpServerResponse res)
{

}
