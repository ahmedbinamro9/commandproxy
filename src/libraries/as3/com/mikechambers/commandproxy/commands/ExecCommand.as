package com.mikechambers.commandproxy.commands
{
	import com.mikechambers.commandproxy.Response;
	
	public class ExecCommand implements IProxyCommand
	{
		public var path:String;
		public var arguments:Array;
		private var _responseData:String;
		
		public function ExecCommand(path:String = null, arguments:Array = null)
		{
			this.path = path;
			this.arguments = arguments;
		}
		
		public function get responseData():String
		{
			return _responseData;
		}
		
		public function set responseData(data:String):void
		{
			_responseData = data;
		}
		
		public function get response():Response
		{
			return null;
		}
		
		public function generateCommand():String
		{
			var command:XML =
				<command authtoken="">
					<exec>
						<path />
						<arguments />
					</exec>
				</command>;

			if(path != null)
			{
				command.exec.path.appendChild(path);
			}
			
			if(this.arguments != null && this.arguments.length > 0)
			{	
				for each(var s:String in this.arguments)
				{	
					command.exec.arguments.appendChild(<arg>{s}</arg>);
				}
			}

			return command.toXMLString();
		}
	}
}