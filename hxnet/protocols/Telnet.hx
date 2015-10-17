package hxnet.protocols;

import haxe.ds.IntMap;
import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

using StringTools;

/**
 * Telnet protocol
 */
class Telnet extends hxnet.base.Protocol
{
    public static inline var SE     = 0xF0;     //Subnegotiation End
    public static inline var NOP    = 0xF1;     //No Operation
    public static inline var DM     = 0xF2;     //Data Mark
    public static inline var BRK    = 0xF3;     //Break
    public static inline var IP     = 0xF4;     //Interrupt Process
    public static inline var AO     = 0xF5;     //Abort Output
    public static inline var AYT    = 0xF6;     //Are You There
    public static inline var EC     = 0xF7;     //Erase Character
    public static inline var EL     = 0xF8;     //Erase Line
    public static inline var GA     = 0xF9;     //Go Ahead
    public static inline var SB     = 0xFA;     //Subnegotiation
    public static inline var WILL   = 0xFB;     //Will Perform
    public static inline var WONT   = 0xFC;     //Won't Perform
    public static inline var DO     = 0xFD;     //Do Perform
    public static inline var DONT   = 0xFE;     //Don't Perform
    public static inline var IAC    = 0xFF;     //Interpret As Command

	/**
	 * Upon receiving data this method is called
	 * @param input The input to read from
	 */
	override public function dataReceived(input:Input)
	{
		var line = input.readAll().toString();

		// strip out IAC codes
		var buffer = "";
		var i = 0, last = 0;
		while (i < line.length)
		{
			if (line.charCodeAt(i) == IAC)
			{
				buffer += line.substr(last, i - last);

				var command = line.charCodeAt(++i);
				if (command == NOP) { }
				else if (command == SB)
				{
					var code = line.charCodeAt(++i);
					var data = new BytesOutput();
					while (!(line.charCodeAt(i) == IAC && line.charCodeAt(i+1) == SE))
					{
						data.writeByte(line.charCodeAt(++i));
					}
					handleIACData(code, data.getBytes());
					i += 1;
				}
				else
				{
					handleIAC(command, line.charCodeAt(++i));
				}
				last = i + 1;
			}
			i += 1;
		}
		buffer += line.substr(last, line.length - last);

		buffer = buffer.trim();
		if (buffer != "")
		{
			if (promptCallback != null)
			{
				// save current callback for comparison
				var callback = promptCallback;
				if (callback(buffer))
				{
					// don't set to null if a different prompt has been set
					if (promptCallback == callback)
						promptCallback = null;
				}
				else
				{
					cnx.writeBytes(promptBytes);
				}
				return;
			}

            var result = buffer.split("\n");
            for(line in result)
			    lineReceived(line.charCodeAt(line.length-1) == 13       //If it uses DOS end line \r\n
                             ? line.substr(0, line.length-1) : line);
		}
	}

	private inline function iacSend(command:Int, code:Int):Void
	{
		var out = new BytesOutput();
		out.writeByte(IAC);
		out.writeByte(command);
		out.writeByte(code);
		cnx.writeBytes(out.getBytes());
	}

	private function handleIACData(code:Int, data:Bytes) { }
	private function handleIAC(command:Int, code:Int) { }

	/**
	 * Send a line of text over the connection
	 * @param data The string data to write
	 */
	public function writeLine(data:String):Void
	{
		cnx.writeBytes(Bytes.ofString(data + "\r\n"));
	}

	/**
	 * Turns echo on/off on the remote side. Useful for password entry.
	 * @param show Whether to show keyboard output on the remote connection.
	 */
	public function echo(show:Bool = true) { iacSend(show ? WONT : WILL, 0x01); }

	/**
	 * Prompt the user for feedback and return answer to callback
	 * @param prompt    The line of text to prompt user for input
	 * @param callback  The method to return the user's response
	 */
	public function prompt(prompt:String, callback:String->Bool)
	{
		promptBytes = Bytes.ofString(prompt + " ");
		promptCallback = callback;
		cnx.writeBytes(promptBytes);
	}

	private var promptBytes:Bytes;
	private var promptCallback:String->Bool;

	/**
	 * Overridable method when a line is received. Used in subclasses.
	 */
	private function lineReceived(line:String) { }
}
