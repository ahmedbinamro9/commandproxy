package com.mikechambers.commandproxy.events
{
	import com.mikechambers.commandproxy.commands.IProxyCommand;
	
	import flash.events.ErrorEvent;
	
	public class CommandErrorEvent extends ErrorEvent
	{
		public static const COMMAND_ERROR:String = "onCommandError";
		public static const RESONSE_NOT_UNDERSTOOD:String = "onResponseNotUnderstood";
		
		public var command:IProxyCommand;
		
		public function CommandErrorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}