/*    
	The MIT License

    Copyright (c) 2007 Mike Chambers

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

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
		
		public function get connected():Boolean
		{
			if(socket == null)
			{
				return false;
			}
			
			return socket.connected;
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
trace(str);
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
			
			var outEvent:CommandResponseEvent;
			var command:IProxyCommand;
			var key:String;
			switch((x.@type).toString())
			{
				case ResponseType.ERROR:
				{
					errorEvent = new CommandErrorEvent(CommandErrorEvent.COMMAND_ERROR);
					
					key = (x.@id).toString();
					command = commandHash[key];
					errorEvent.rawResponse = x;
					errorEvent.command = command;	
					errorEvent.text = x.message.toString();
					dispatchEvent(errorEvent);
					
					removeFromHash(key);
					return;				
					break;
				}
				case ResponseType.SUCCESS:
				{
					outEvent = new CommandResponseEvent(CommandResponseEvent.COMMAND_RESPONSE);
					
					key = (x.@id).toString();
					command = commandHash[key];
					outEvent.rawResponse = x;
					removeFromHash(key);
					if(command != null)
					{
						outEvent.response = command.parseResponse(x);
					}
					
					outEvent.command = command;	
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
		
		private function removeFromHash(key:String):void
		{
			delete commandHash[key];
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