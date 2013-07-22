/**
	Provides abstract database access.

	Copyright: © 2012-2013 RejectedSoftware e.K.
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Sönke Ludwig
*/
module vibedist.controller;

import vibe.db.mongo.mongo;
import vibe.crypto.passwordhash;

import vibedist.admin;

MongoCollection configs;

struct Config {
	BsonObjectID _id;
	string name;

	string adminInterface;
	ushort adminPort;

	string[] nodeInterfaces;
	ushort nodePort;

	string[] publicInterfaces;

	string rootPasswordHash;
}

void getConfig(ref Config cfg, string name = "default")
{
	// load or create default config
	auto bcfg = configs.findOne(["name": name]);
	if( bcfg.isNull() ){
		cfg._id = BsonObjectID.generate();
		cfg.name = name;
		cfg.adminInterface = "127.0.0.1";
		cfg.adminPort = 8080;
		cfg.nodeInterfaces = ["127.0.0.1"];
		cfg.publicInterfaces = ["0.0.0.0"];
		cfg.nodePort = 11000;
		cfg.rootPasswordHash = generateSimplePasswordHash("admin");
		configs.insert(cfg);
	} else deserializeBson(cfg, bcfg);
}

static this()
{
	auto db = connectMongoDB("localhost").getDatabase("vibedist");
	configs = db["configs"];
}
