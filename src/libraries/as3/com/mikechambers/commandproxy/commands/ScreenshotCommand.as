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