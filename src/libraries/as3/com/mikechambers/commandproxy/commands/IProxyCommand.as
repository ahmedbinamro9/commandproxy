package com.mikechambers.commandproxy.commands
{
	import com.mikechambers.commandproxy.Response;
	
	public interface IProxyCommand
	{
		function generateCommand():XML;
		
		function parseResponse(s:String):Response;
	}
}