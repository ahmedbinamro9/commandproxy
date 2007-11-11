package com.mikechambers.commandproxy.commands
{
	import com.mikechambers.commandproxy.Response;
	
	public interface IProxyCommand
	{
		function generateCommand():XML;
		
		function set responseData(s:String):void;
		
		function get response():*;
	}
}