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

	public class ScreenshotCommand implements IProxyCommand
	{
		
		/*
<screenshot format="">
	<path></path>
</screenshot>		
		*/
		public var file:File;
		public var format:String;
		
		public function ScreenshotCommand()
		{
		}
		
		public function generateCommand():XML
		{
			var x:XML =
				<screenshot>
				</screenshot>;	
				
			if(format != null)
			{
				x.@format = format;
			}	
				
			if(file != null)
			{
				var p:XML = 
					<path>{file.nativePath}</path>;
				x.appendChild(p);
			}
			return x;
		}
		
		public function  parseResponse(data:String):Response
		{
			if(data == null)
			{
				return null;
			}
			
			var r:ScreenshotCommandResponse = new ScreenshotCommandResponse();
			
			var x:XML;
			try
			{
				x = new XML(data);
			}
			catch(e:Error)
			{
				return r;
			}
			
			var pathNodeList:XMLList = x.path;
			var pathNode:XML = pathNodeList[0];
			
			if(pathNode == null)
			{
				return r;
			}
			
			r.path = pathNode.toString();
			
			return r;
		}
		
	}
}