package com.mikechambers.commandproxy
{
	import com.mikechambers.commandproxy.commands.IProxyCommand;
	import com.mikechambers.commandproxy.events.CommandErrorEvent;
	import com.mikechambers.commandproxy.events.CommandResponseEvent;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.Dictionary;
	
	public class CommandProxy extends EventDispatcher
	{	
		private var socket:Socket;
		
		//todo: need to pass an id with each call
		private var commandHash:Dictionary = new Dictionary();
		private var authtoken:String;
		
		public function CommandProxy(authtoken:String)
		{
			this.authtoken = authtoken;
		}
		
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
			var key:Number = (new Date().getTime());
			
			while(commandHash[key] != null)
			{
				key++;
			}
			
			commandHash[String(key)] = command;
			
			//todo: insert wrapper xml with id and auth token
			//todo: dont forget to remove item from hash
			
			socket.writeUTFBytes(generateCommandWrapper(command, key));
			//we might need to queue these over frames
			socket.flush();
		}
		
		/*********** Event Handlers *************/
		
		private function onSocketData(e:ProgressEvent):void
		{
			var str:String = socket.readUTFBytes(socket.bytesAvailable);

			var x:XML;
			var errorEvent:CommandErrorEvent = new CommandErrorEvent(CommandErrorEvent.RESONSE_NOT_UNDERSTOOD);
			try
			{
				x = new XML(str);
			}
			catch(e:Error)
			{
				errorEvent.text = "Response was not valid XML.";
				dispatchEvent(errorEvent);
				return;
			}

			if(x.name() != "response")
			{
				errorEvent.text = "Top level element not recognized.";
				dispatchEvent(errorEvent);
				return;
			}
			
			var outEvent:Event;
			var command:IProxyCommand;
			
			switch((x.@type).toString())
			{
				case ResponseType.ERROR:
				{
					outEvent = new CommandErrorEvent(CommandErrorEvent.COMMAND_ERROR);
					
					command = commandHash[x.@id];
					command.responseData = x;
					
					CommandErrorEvent(outEvent).command = command;					
					break;
				}
				case ResponseType.SUCCESS:
				{
					outEvent = new CommandResponseEvent(CommandResponseEvent.COMMAND_RESPONSE);
					
					var s:String = (x.@id).toString();
					command = commandHash[s];
					
					if(command != null)
					{
						command.responseData = x;
					}
					
					CommandResponseEvent(outEvent).command = command;	
					break;
				}
				default:
				{
					errorEvent.text = "Response type not recognized";
					dispatchEvent(errorEvent);
					return;
				}
			}
		
			dispatchEvent(outEvent);
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
		
		private function generateCommandWrapper(command:IProxyCommand, id:Number):XML
		{
			var x:XML =
					<command />;
					
			x.@id = id;
			x.@authtoken = authtoken;
					
			x.appendChild(command.generateCommand());
			
			return x;
		}
		
	}
}