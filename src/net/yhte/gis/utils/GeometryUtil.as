package net.yhte.gis.utils
{
	import com.esri.ags.geometry.MapPoint;

	public class GeometryUtil
	{
		public static const EARTH_RADIUS:Number = 6378.137;
		
		private static function rad(d:Number):Number  
		{  
			return d * Math.PI / 180.0;  
		} 
		
		public static function getDistance(p1:MapPoint,p2:MapPoint):Number  
		{  
			var radLat1:Number = rad(p1.y);  
			var radLat2:Number = rad(p2.y);  
			var a:Number = radLat1 - radLat2;  
			var b:Number = rad(p1.x) - rad(p2.x);  
			var s:Number= 2 * Math.asin(Math.sqrt(Math.pow(Math.sin(a/2),2) + Math.cos(radLat1)*Math.cos(radLat2)*Math.pow(Math.sin(b/2),2)));  
			s = s * EARTH_RADIUS;  
			s = Math.round(s * 10000) / 10000;  
			return s; 
		}
		
		public static function geodesicLengths(polylines:Array,lengthUnit:String):Array
		{
			var results:Array = [];
			for each(var path:Array in polylines[0].paths)
			{
				var len:int = path.length;
				var length:Number = 0;
				for(var i:int=0;i<len-1;i++)
				{
					var s:MapPoint = path[i];
					var e:MapPoint = path[i+1];
					length += getDistance(s,e)*1000;
				}
				results.push(length);
			}
			return results;
		}
	}
}