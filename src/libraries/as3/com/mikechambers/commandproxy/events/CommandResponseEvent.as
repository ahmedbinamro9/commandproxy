package com.mikechambers.commandproxy.events
{
	import flash.events.Event;

	public class CommandResponseEvent extends Event
	{
		public function CommandResponseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}