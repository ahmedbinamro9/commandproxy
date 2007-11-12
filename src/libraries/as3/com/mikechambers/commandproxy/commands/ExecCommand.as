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

package com.mikechambers.commandproxy.commands
{
	import com.mikechambers.commandproxy.Response;
	
	
	
	
	
	public class ExecCommand implements IProxyCommand
	{
		public var path:String;
		public var arguments:Array;
		public var captureOutput:Boolean = false;;
		
		public function ExecCommand(path:String = null, arguments:Array = null, captureOutput:Boolean = false)
		{
			this.path = path;
			this.arguments = arguments;
			this.captureOutput = captureOutput;
		}
		
		
		public function parseResponse(data:String):Response
		{
			if(data == null)
			{
				return null;
			}
			
			var x:XML;
			var response:ExecCommandResponse = new ExecCommandResponse();
			
			try
			{
				x = new XML(data);
			}
			catch(e:Error)
			{
				return response;
			}
			
			var outputNodeList:XMLList = x.output;
			var outputNode:XML = outputNodeList[0];
			
			if(outputNode == null)
			{
				return response;
			}
			
			response.output = outputNode.toString();
			
			return response;
		}
		
		public function generateCommand():XML
		{
			var command:XML =
					<exec>
						<path />
						<arguments />
					</exec>;

			if(path != null)
			{
				command.path.appendChild(path);
			}
			
			if(this.arguments != null && this.arguments.length > 0)
			{	
				for each(var s:String in this.arguments)
				{	
					command.arguments.appendChild(<arg>{s}</arg>);
				}
			}

			command.@capture = captureOutput;

			return command;
		}
	}
}