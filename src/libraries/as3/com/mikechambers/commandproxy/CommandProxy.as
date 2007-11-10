package com.mikechambers.commandproxy
{
	import com.mikechambers.commandproxy.commands.IProxyCommand;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	
	public class CommandProxy extends EventDispatcher
	{	
		private var socket:Socket;
		
		//todo: need to pass an id with each call
		private var commandHash:Dictionary = new Dictionary();
		
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
			//we might need to queue these over frames
			socket.flush();
		}
		
		/*********** Event Handlers *************/
		
		private function onSocketData(e:ProgressEvent):void
		{
			var str:String = socket.readUTFBytes(socket.bytesAvailable);
			//todo: impliment
			trace(str);
		}
		
		private function onSecurityError(e:SecurityErrorEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.text));
		}
		
		private function onIOError(e:IOErrorEvent):void
		{	
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.text));
		}
		
		private function onClose(e:Event):void
		{
			dispatchEvent(new Event(Event.CLOSE));
		}
		
		private function onConnect(e:Event):void
		{
			dispatchEvent(new Event(Event.CONNECT));
		}
		
	}
}