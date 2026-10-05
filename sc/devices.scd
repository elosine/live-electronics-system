// devices.scd — what SuperCollider can open on this machine: the ASIO devices, and whether ReaRoute is among them.
//   node electronics/tools/sc.js devices
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var asio;
(dir +/+ "boot.scd").load;
asio = ServerOptions.devices.select({ |d| d.contains("ASIO") });
asio.do({ |d| ~le.say("LE_INFO", d) });
~le.say("LE_RESULT", ~le.json((asio: asio, reaRoute: asio.any({ |d| d.toLower.contains("rearoute") }))));
~le.leave(0);
)
