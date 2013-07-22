import vibe.db.mongo.mongo;
import vibe.crypto.passwordhash;

import admin;

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
