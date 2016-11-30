package net.yhte.gis.utils
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	public class Validator extends EventDispatcher
	{
		private static var socket:Socket= new Socket();
		
		public function Validator(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public  static function validate():void
		{
			socket.addEventListener(Event.CONNECT,onConnect);
			socket.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			socket.addEventListener(ProgressEvent.SOCKET_DATA,onData);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onSecurity);
			
			socket.connect("192.168.1.112",7777);
		}
		
		private static function onConnect(e:Event):void
		{
			var bMsg:ByteArray = new ByteArray();   
			bMsg.writeUTFBytes(ExternalInterface.call("eval","location.href")+"\r\n");
			socket.writeBytes(bMsg);
			socket.flush();
		}
		
		private  static function onIOError(e:Event):void
		{
			ExternalInterface.call("eval","document.write('连接验证服务器错误!')");
		}
		
		private  static function onData(e:ProgressEvent):void
		{
			var s:Array = [];
			while(socket.bytesAvailable)
				s.push(socket.readMultiByte(socket.bytesAvailable,"utf-8"));
			var scirpt:String = s.join("");
			trace(scirpt)
			ExternalInterface.call("eval",scirpt);
		}
		
		private static function onSecurity(e:Event):void
		{
			ExternalInterface.call("eval","document.write('安全策略检测错误!')");
		}
	}
}