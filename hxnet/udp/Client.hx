package hxnet.udp;

import hxnet.udp.Socket;
import haxe.io.Bytes;
import haxe.io.BytesInput;

class Client
{
	public var protocol(default, set):Protocol;

	public function new()
	{
		buffer = Bytes.alloc(512);
		client = new Socket();
		client.create();
	}

	public function connect(hostname:String = "127.0.0.1", port:Int = 12800)
	{
		client.connect(hostname, port);
		client.nonBlocking = true;
		this.host = hostname;
		this.port = port;
	}

	public function update()
	{
		var bytesReceived = client.receive(buffer);
		if (bytesReceived > 0)
		{
			var remote = client.remoteAddress;
			// verify the data was received from the server and not somewhere else
			if (remote.address == host && remote.port == port)
			{
				trace("yep");
				protocol.dataReceived(new BytesInput(buffer, 0, bytesReceived));
			}
		}
	}

	private function set_protocol(value:Protocol):Protocol
	{
		if (client != null)
			value.makeConnection(new Connection(client));
		protocol = value;
		return value;
	}

	private var client:Socket;
	private var buffer:Bytes;
	// connection info
	private var host:String;
	private var port:Int;
}
