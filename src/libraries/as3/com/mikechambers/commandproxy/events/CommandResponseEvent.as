package com.mikechambers.commandproxy.events
{
	import com.mikechambers.commandproxy.Response;
	import com.mikechambers.commandproxy.commands.IProxyCommand;
	
	import flash.events.Event;
	
	public class CommandResponseEvent extends Event
	{
		public static const COMMAND_RESPONSE:String = "onCommandResponse";
		
		public var command:IProxyCommand;
		public var rawResponse:String;
		public var response:Response;
		
				
		public function CommandResponseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}