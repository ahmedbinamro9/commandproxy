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
	
	import flash.filesystem.File;

	//command that can take a screenshot of the entire desktop and return the
	//path to that screenshot
	public class ScreenshotCommand implements IProxyCommand
	{
		
		/*
			<screenshot format="">
				<path></path>
			</screenshot>		
		*/
		
		//A File reference specifing the name and location of the file that the
		//screenshot should be save at. 
		//If this is not specified, then the command will choose a location and
		//return it
		public var file:File;
		
		//the ImageFormat specifying the file format that the file should be saved
		//as
		public var format:String;
		
		//generates the XML for the ScreenshotCommand instance
		public function generateCommand():XML
		{
			//create stub XML for command
			var x:XML =
				<screenshot>
				</screenshot>;	
			
			//check if format is specified	
			//if not, the default format is PNG
			if(format != null)
			{
				//if it is, set the format
				x.@format = format;
			}	
				
			//check if the file is specified.
			//if not, a default location will be used and returned
			if(file != null)
			{
				//create the xml to specify the path
				var p:XML = 
					<path>{file.nativePath}</path>;
				x.appendChild(p);
			}
			
			//return command xml
			return x;
		}
		
		//parses the XML returned from the proxy into a ScreenshotCommandResponse instance
		public function  parseResponse(data:String):Response
		{
			//if data is null
			if(data == null)
			{
				//return null
				return null;
			}
			
			//create ScreenshotCommandResponse to hold response information
			var r:ScreenshotCommandResponse = new ScreenshotCommandResponse();
			
			//xml to hold response
			var x:XML;
			try
			{
				//parse into xml
				x = new XML(data);
			}
			catch(e:Error)
			{
				//response was not valid XML, return response
				//note, we should never get here
				return r;
			}
			
			//get the path to the screenshot
			var pathNodeList:XMLList = x.path;
			var pathNode:XML = pathNodeList[0];
			
			//if it is null
			if(pathNode == null)
			{
				//todo: should we return an Error here?
				//return response
				return r;
			}
			
			//add the screen shot path to the Response instance
			r.path = pathNode.toString();
			
			//return the response
			return r;
		}
		
	}
}