package net.yhte.gis.utils
{
	import flash.utils.getQualifiedClassName;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	/**
	 * 日志工具 
	 * @author liurongtao
	 * 
	 */	
	public class LogUtil
	{
		public static function getLogger( obj:Object ) : ILogger
		{
			var nameParts : String = getQualifiedClassName( obj ).replace("::",".");
			return Log.getLogger( nameParts );
		}
	}
}