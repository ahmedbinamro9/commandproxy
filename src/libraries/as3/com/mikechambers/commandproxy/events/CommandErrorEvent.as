package com.mikechambers.commandproxy.events
{
	import flash.events.Event;

	public class CommandErrorEvent extends Event
	{
		public function CommandErrorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}