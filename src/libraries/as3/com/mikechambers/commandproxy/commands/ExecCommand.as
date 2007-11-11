package com.mikechambers.commandproxy.commands
{
	import flash.xml.XMLNode;
	
	
	
	public class ExecCommand implements IProxyCommand
	{
		public var path:String;
		public var arguments:Array;
		private var _responseData:String;
		public var captureOutput:Boolean = false;;
		
		public function ExecCommand(path:String = null, arguments:Array = null, captureOutput:Boolean = false)
		{
			this.path = path;
			this.arguments = arguments;
			this.captureOutput = captureOutput;
		}
		
		public function set responseData(data:String):void
		{
			_responseData = data;
		}
		
		public function get response():*
		{
			if(_responseData == null)
			{
				return null;
			}
			
			var x:XML;
			var response:ExecCommandResponse = new ExecCommandResponse();
				response.rawData = _responseData;
			
			try
			{
				x = new XML(_responseData);
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