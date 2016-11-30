////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 
//  All Rights Reserved.
//
//
////////////////////////////////////////////////////////////////////////////////

package net.yhte.gis.layers
{
	import com.esri.ags.SpatialReference;
	import com.esri.ags.Units;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.layers.TiledMapServiceLayer;
	import com.esri.ags.layers.supportClasses.LOD;
	import com.esri.ags.layers.supportClasses.TileInfo;
	
	import flash.net.URLRequest;
	
	/**
	 * 用于访问Baidu在线地图。
	 * @author zhumin
	 * 
	 */	
	public class BMapLayer extends TiledMapServiceLayer
	{
		private var _tileInfo:TileInfo=new TileInfo();
		
		public static const SEMI_CYCLE:Number = 33554432;

		public function BMapLayer()
		{
			super();
			buildTileInfo();
			setLoaded(true);
		}
		
		override public function get fullExtent():Extent
		{
			return new Extent(-SEMI_CYCLE, -SEMI_CYCLE, SEMI_CYCLE, SEMI_CYCLE,
				new SpatialReference(102113));
		}
		
//		override public function get initialExtent():Extent
//		{
//			return new Extent(13246282.26290625, 3587772.2866300615, 13632747.877915915, 3710071.5318862842, 
//				new SpatialReference(102113));
//		}
		
		override public function get spatialReference():SpatialReference
		{
			return new SpatialReference(102113);
		}
		
		override public function get tileInfo():TileInfo
		{
			return _tileInfo;
		}
		
		override public function get units():String
		{
			return Units.METERS;
		}
		
		override protected function getTileURL(level:Number, row:Number, 
											   col:Number):URLRequest
		{
			var x:Number = col - Math.pow(2,level-1);
			var y:Number = -row + Math.pow(2,level-1)-1;
			var url:String = "http://q"+ (col%8+1) + ".baidu.com/it/u=";
 			url += "x=" + x + ";" +"y=" + y + ";" + "z=" + level+ ";v=009;type=web&fm=44";
			return new URLRequest(url);
		}
				
		
		private function buildTileInfo():void
		{
			_tileInfo.height=256;
			_tileInfo.width=256;
			_tileInfo.origin=new MapPoint(-SEMI_CYCLE-1328.180770908, SEMI_CYCLE+21887.870652815);
			_tileInfo.spatialReference=new SpatialReference(102113);
			_tileInfo.lods = [
				new LOD(3, 32768, 123847559.05511811), 
				new LOD(4, 16384, 61923779.52755906), 
				new LOD(5, 8192, 30961889.76377953), 
				new LOD(6, 4096, 15480944.881889764), 
				new LOD(7, 2048, 7740472.440944882), 
				new LOD(8, 1024, 3870236.220472441), 
				new LOD(9, 512, 1935118.1102362205), 
				new LOD(10, 256, 967559.0551181103), 
				new LOD(11, 128, 483779.52755905513), 
				new LOD(12, 64, 241889.76377952757), 
				new LOD(13, 32, 120944.88188976378), 
				new LOD(14, 16, 60472.44094488189), 
				new LOD(15, 8, 30236.220472440946),
				new LOD(16, 4, 15118.110236220473), 
				new LOD(17, 2, 7559.055118110236), 
				new LOD(18, 1, 3779.527559055118),
				new LOD(19, 0.5, 1889.763779527559)
			];
		}
	}
}