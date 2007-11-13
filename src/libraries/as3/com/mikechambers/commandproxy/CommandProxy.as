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

//todo: queue up command calls sent before socket is connected?
//todo: send commands over a frame loop (in case a lot of commands are sent in
//same frame ?

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
	
	/*
		Class that provides primary interface to the native command proxy.
	*/
	public class CommandProxy extends EventDispatcher
	{	
		//socket used to connect to the proxy
		private var socket:Socket;
		
		//dictionary we use to store commands between request and response
		private var commandHash:Dictionary = new Dictionary();
		
		//authorization token to pass to the proxy
		private var authtoken:String;
		
		
		//constructor - takes a string which represents an authorization token.
		//this token is normally passed to the AIR app via the command line (from
		//the proxy app)
		public function CommandProxy(authtoken:String)
		{
			this.authtoken = authtoken;
		}
		
		//returns whether the the class is still connected to the proxy
		public function get connected():Boolean
		{
			if(socket == null)
			{
				return false;
			}
			
			return socket.connected;
		}
		
		//connects to the proxy. Takes two arguments
		//port - port to connect on (usually passed in via command line when app
		//is launched.
		//host - the host that the proxy is on. This is almost always going to be
		//the default value of 127.0.0.1 (localhost)
		public function connect(port:int, host:String = "127.0.0.1"):void
		{
			//create the socket
			socket = new Socket();
			
			//socket close
			socket.addEventListener(Event.CLOSE, onClose);
			
			//socket connect
        	socket.addEventListener(Event.CONNECT, onConnect);
        	
        	//IOError (i.e. cant connect)
        	socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
        	
        	//security error (shouldnt get this)
        	socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
        	
        	//called when data is received over socket
        	socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			
			//connect to the proxy
			socket.connect(host, port);

		}
		
		/*
			Executes a command by sending it to the proxy.
			
			Take a single IProxyCommand argument which represents the command
			being sent.
		*/
		public function execute(command:IProxyCommand):void
		{
			//generate a key to store the command between request and response
			var key:Number = (new Date().getTime());
			
			//loop through until we find a key that is not in use already
			while(commandHash[key] != null)
			{
				key++;
			}
			
			//store the command in the dictionary
			commandHash[String(key)] = command;
			
			//pass the generated command XML to the proxy
			socket.writeUTFBytes(generateCommandWrapper(command, key));
			
			//we might need to queue these over frames
			//flush the socket
			socket.flush();
		}
		
		/*********** Event Handlers *************/
		
		//called when data is received on the socket
		private function onSocketData(e:ProgressEvent):void
		{
			//read the bytes sent into a string
			var str:String = socket.readUTFBytes(socket.bytesAvailable);
			
			trace(str);
			
			var x:XML;
			
			//create error event incase something goes wrong
			var errorEvent:CommandErrorEvent = new CommandErrorEvent(CommandErrorEvent.RESPONSE_NOT_UNDERSTOOD);
			try
			{
				//try and parse the response into XML
				x = new XML(str);
			}
			catch(e:Error)
			{
				//was not valid XML
				errorEvent.text = "Response was not valid XML.";
				
				//send error and abort
				dispatchEvent(errorEvent);
				return;
			}

			//make sure that first element is the response element
			if(x.name() != "response")
			{
				//if not, we dont understand the response
				errorEvent.text = "Top level element not recognized.";
				
				//send error and abort
				dispatchEvent(errorEvent);
				return;
			}
			
			//the command that was executed
			var command:IProxyCommand;
			
			//the string where the command is stored in the Dictionary
			var key:String;
			
			//find out the type of response
			switch((x.@type).toString())
			{
				//type="error" : command request was not sucessful
				case ResponseType.ERROR:
				{
					//set the errorEvent to a CommandErrorEvent
					errorEvent = new CommandErrorEvent(CommandErrorEvent.COMMAND_ERROR);
					
					//get the string from the response
					key = (x.@id).toString();
					
					//use the key to grab the command that was used to send the
					//command
					command = commandHash[key];
					
					//set the rawResponse on the event
					errorEvent.rawResponse = x;
					
					//set the command on the event
					errorEvent.command = command;	
					
					//set the error message
					errorEvent.text = x.message.toString();
					
					//dispatch event
					dispatchEvent(errorEvent);
					
					//remove command from dictionary
					removeFromHash(key);
		
					break;
				}
				
				//type="success" - command executed sucessfuly
				case ResponseType.SUCCESS:
				{
					
					//CommandResponseEvent for the response
					var outEvent:CommandResponseEvent  =
					 					new CommandResponseEvent(
					 							CommandResponseEvent.COMMAND_RESPONSE);
					
					////get the key from the response
					key = (x.@id).toString();
					
					//grab the command associated with the response
					command = commandHash[key];
					
					//set the raw response on the event
					outEvent.rawResponse = x;
					
					//set the command on the event
					outEvent.command = command;	
					
					//remove the command from the dictionary
					removeFromHash(key);
					
					//make sure command is not null (in case key got messed up)
					if(command != null)
					{
						//send the raw data to the command to be parsed into a
						//Response Instance
						outEvent.response = command.parseResponse(x);
					}
					
					//send the event
					dispatchEvent(outEvent);
					
					break;
				}
				
				//type is not set, or we dont recognize its value
				default:
				{
					//set error text
					errorEvent.text = "Response type not recognized";
					
					//send error event
					dispatchEvent(errorEvent);
					break;
				}
			}
		}
		
		//called when a security error is thrown by the socket
		private function onSecurityError(e:SecurityErrorEvent):void
		{
			//send error event
			//note you must listen for this or it will bubble up to a UI in the 
			//debug player
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.text));
		}
		
		//called when there is a problem connecting to the socket proxy.
		//usually when the socket is not open
		private function onIOError(e:IOErrorEvent):void
		{	
			//send error event
			//note you must listen for this or it will bubble up to a UI in the 
			//debug player
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.text));
		}
		
		//called when the socket connection is closed.
		private function onClose(e:Event):void
		{
			//send close event
			dispatchEvent(new Event(Event.CLOSE));
		}
		
		//called when a connection is make to the socket
		//you should not send any commands until this is received
		private function onConnect(e:Event):void
		{
			//send a connect event
			dispatchEvent(new Event(Event.CONNECT));
		}		
		
		/**************** General Functions ***********************/
		
		//remove the command in the dictionary for the specified key
		private function removeFromHash(key:String):void
		{
			//delete command from dictionary
			delete commandHash[key];
		}
		
		//takes output from the command and wraps it in the appropriate XML
		private function generateCommandWrapper(command:IProxyCommand, id:Number):XML
		{
			//create the top level command element
			var x:XML =
					<command />;
					
			//set the id on the response
			x.@id = id;
			
			//set the authtoken
			x.@authtoken = authtoken;
					
			//add the output from the command		
			x.appendChild(command.generateCommand());
			
			//return this
			return x;
		}
		
	}
}