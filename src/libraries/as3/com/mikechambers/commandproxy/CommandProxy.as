package com.mikechambers.commandproxy
{
	import com.mikechambers.commandproxy.commands.IProxyCommand;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	
	public class CommandProxy extends EventDispatcher
	{	
		private var socket:Socket;
		
		public function connect(port:int, host:String = "127.0.0.1"):void
		{
			socket = new Socket();
			
			socket.addEventListener(Event.CLOSE, onClose);
        	socket.addEventListener(Event.CONNECT, onConnect);
        	socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
        	socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
        	socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
        	
			socket.connect(host, port);
		}
		
		public function execute(command:IProxyCommand):void
		{
			socket.writeUTFBytes(command.generateCommand());
			socket.flush();
		}
		
		/*********** Event Handlers *************/
		
		private function onSocketData(e:ProgressEvent):void
		{
			var str:String = socket.readUTFBytes(socket.bytesAvailable);
			trace(str);
		}
		
		private function onSecurityError(e:SecurityErrorEvent):void
		{
			trace("security error");
		}
		
		private function onIOError(e:IOErrorEvent):void
		{	
			trace("ioerror");
		}
		
		private function onClose(e:Event):void
		{
			trace("close");	
		}
		
		private function onConnect(e:Event):void
		{
			dispatchEvent(new Event(Event.CONNECT));
		}
		
	}
}