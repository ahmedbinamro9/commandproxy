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

	//Command that can execute applications, and return the output from those
	//applications	
	public class ExecCommand implements IProxyCommand
	{
		//a string representing the path to the application to be launched
		public var path:String;
		
		//and array or arguments to be passed to the application when it is started
		public var arguments:Array;
		
		//Whether to capture the output from the application. If this is set to true
		//the the proxy will not return a response until the application returns data
		//or exits (usually both)
		public var captureOutput:Boolean = false;;
		
		/*
			constructor for the command, options takes:
			path : path to the application to be run
			arguments : Array of arguments to be passed to the application when it
						is executed
			captureOutput : Boolean value specifying whether any output from the application
						should be captued and returned
		*/
		public function ExecCommand(path:String = null, arguments:Array = null, captureOutput:Boolean = false)
		{
			//set the properties
			this.path = path;
			this.arguments = arguments;
			this.captureOutput = captureOutput;
		}
		
		//parses the XML returned from the proxy into a ExecCommandResponse instance
		public function parseResponse(data:String):Response
		{
			//no data? return
			if(data == null)
			{
				return null;
			}
			
			//create the xml instance
			var x:XML;
			
			//create the ExecCommandResponse instance
			var response:ExecCommandResponse = new ExecCommandResponse();
			
			try
			{
				//parse data into XML
				x = new XML(data);
			}
			catch(e:Error)
			{
				//todo: should we return null here?
				//if not valid XML, then return the response
				return response;
			}
			
			//begin to parse the response
			
			//get the <output> element in the response
			var outputNodeList:XMLList = x.output;
			var outputNode:XML = outputNodeList[0];
			
			//if it is null, then return the response
			//it just means there was nothing returned
			if(outputNode == null)
			{
				return response;
			}
			
			//if it is not null, then grab the response data and set it on the
			//ExecCommandResponse instance.
			//This contains any output from the program if captureOutput is set
			//to true
			response.output = outputNode.toString();
			
			return response;
		}
		
		//generates the XML for the ExecCommand instance
		public function generateCommand():XML
		{
			//stub out the xml
			var command:XML =
					<exec>
						<path />
						<arguments />
					</exec>;

			//if path is not null
			if(path != null)
			{
				//set path value
				command.path.appendChild(path);
			}
			
			//if arguments have been specified
			if(this.arguments != null && this.arguments.length > 0)
			{	
				//loop through them
				for each(var s:String in this.arguments)
				{	
					//and create arg elements for each one
					command.arguments.appendChild(<arg>{s}</arg>);
				}
			}

			//set the value for the capture element
			command.@capture = captureOutput;

			//return command XML
			return command;
		}
	}
}