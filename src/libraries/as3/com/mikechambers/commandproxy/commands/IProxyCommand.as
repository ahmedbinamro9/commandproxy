package com.mikechambers.commandproxy.commands
{
	import com.mikechambers.commandproxy.Response;
	
	public interface IProxyCommand
	{
		function generateCommand():String;
		
		function get responseData():String;
		function set responseData(s:String):void;
		
		function get response():Response;
	}
}