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

package com.mikechambers.commandproxy.events
{
	import com.mikechambers.commandproxy.Response;
	import com.mikechambers.commandproxy.commands.IProxyCommand;
	
	import flash.events.Event;
	
	//Event that is broadcast when a response is received from the proxy after
	//a command has sucessfuly been executed
	public class CommandResponseEvent extends Event
	{
		//sucessful command response received
		public static const COMMAND_RESPONSE:String = "onCommandResponse";
		
		//the command that initiated the request
		public var command:IProxyCommand;
		
		//the raw response sent from the proxy
		public var rawResponse:String;
		
		//a Response instance with data returned from the command. This should be
		//a subclass of Response with information specific to the command that was
		//executed
		public var response:Response;
				
		//event constructor
		public function CommandResponseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}