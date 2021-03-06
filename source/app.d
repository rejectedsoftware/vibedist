/**
	Contains the application entry point.

	Copyright: © 2012-2013 RejectedSoftware e.K.
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Sönke Ludwig
*/
module app;

import vibe.d;
import vibe.crypto.passwordhash;

import vibedist.admin;
import vibedist.controller;
import vibedist.rest;


shared static this()
{
	auto ctrl = new VibeDistController;
	Config cfg;
	ctrl.getConfig(cfg);

	{ // setup node interface
		auto settings = new HTTPServerSettings;
		settings.bindAddresses = cfg.nodeInterfaces;
		settings.port = cfg.nodePort;

		auto router = new URLRouter;
		registerRestInterface(router, new VibeDistNodeAPIImpl(ctrl));

		listenHTTP(settings, router);
	}

	startAdminWebInterface(ctrl);
}
