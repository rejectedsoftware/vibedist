/**
	REST interface implementation.

	Copyright: © 2012-2013 RejectedSoftware e.K.
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Sönke Ludwig
*/
module vibedist.rest;

import vibedist.controller;
import vibedist.engine;

import vibe.web.rest;
import vibe.http.server;
import vibe.stream.tls;


interface VibeDistNodeAPI {
	@path("/") string getInfo();
	void register(string host_name, ushort port, string local_address, ushort local_port, string ssl_settings, int pid);
}

class VibeDistNodeAPIImpl : VibeDistNodeAPI
{
	private {
		VibeDistController m_ctrl;
	}
	
	this(VibeDistController ctrl)
	{
		m_ctrl = ctrl;
	}

	@path("/") string getInfo() { return "This is the VibeDist API."; }

	void register(string host_name, ushort port, string local_address, ushort local_port, string ssl_settings, int pid)
	{
		Config cfg;
		m_ctrl.getConfig(cfg);

		TLSContext ssl_context; // TODO: add proper support

		foreach (intf; g_interfaces) {
			auto s = intf.settings;
			if (s.hostName != host_name || s.port != port || s.tlsContext !is ssl_context)
				continue;

			foreach (n; intf.nodes) {
				if (n.address == local_address && n.port == local_port)
					return;
			}

			intf.nodes ~= new Node(local_address, local_port, pid);
			return;
		}

		auto settings = new HTTPServerSettings;
		settings.hostName = host_name;
		settings.port = port;
		settings.bindAddresses = cfg.publicInterfaces;
		settings.tlsContext = ssl_context;

		auto intf = new PublicInterface;
		intf.settings = settings;
		intf.nodes ~= new Node(local_address, local_port, pid);

		listenHTTP(settings, intf);
		g_interfaces ~= intf;
	}
}
