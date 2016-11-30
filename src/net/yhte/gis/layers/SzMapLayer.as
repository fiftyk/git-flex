package net.yhte.gis.layers
{
	import com.esri.ags.SpatialReference;
	import com.esri.ags.events.ZoomEvent;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.layers.TiledMapServiceLayer;
	import com.esri.ags.layers.supportClasses.LOD;
	import com.esri.ags.layers.supportClasses.TileInfo;
	
	import flash.net.URLRequest;
    /**
     * 苏州地图网栅格底图 
     * @author liurongtao
     * 
     */	
	public class SzMapLayer extends TiledMapServiceLayer
	{
		private var _url:String;
		private var _lable:String;
		
		
		private var _tileInfo:TileInfo=new TileInfo();
		private var _baseURL:String="";
		
		public function SzMapLayer(url:String=null,label:String="SzMap")
		{
			super();
			if(url){
				_url = url;
				buildTileInfo();
				setLoaded(true);
			}
			_lable = label;
			
			
		}
		
		public function set url(value:String):void
		{
			_url = value;
			buildTileInfo();
			setLoaded(true);
		}

		public function get url():String
		{
			return _url;
		}

		public function get lable():String
		{
			return _lable;
		}

		public function set lable(value:String):void
		{
			_lable = value;
		}

		override public function get tileInfo():TileInfo
		{
			// TODO Auto Generated method stub
//			return super.tileInfo;
			return _tileInfo;
		}
		
		override protected function zoomUpdateHandler(event:ZoomEvent):void
		{
			// TODO Auto Generated method stub
			try{
				super.zoomUpdateHandler(event);
			}catch(e:Error){
				trace(e);
			}
		}
		
		
		override public function get initialExtent():Extent
		{
			// TODO Auto Generated method stub
//			return super.initialExtent;
			return new Extent(120.26370918274257, 31.005556101008523, 120.99087245256011, 31.462412605605934, new SpatialReference(4326));
		}
		
		override public function get spatialReference():SpatialReference
		{
			// TODO Auto Generated method stub
//			return super.spatialReference;
			return new SpatialReference(4326);
		}
		
		override public function get fullExtent():Extent
		{
			return new Extent(120.26370918274257, 31.005556101008523, 122.99087245256011, 32.462412605605934, new SpatialReference(4326));
		}
		
		override protected function getTileURL(level:Number, row:Number, col:Number):URLRequest
		{
			// TODO Auto Generated method stub
//			return super.getTileURL(level, row, col);
			//http://img2.sz-map.com/Layers20110423/_alllayers/L02/R00001d8e/C000029bd.png
			var tileurl:String =  url + "/_alllayers/L"+toZ(level)+"/R"+to16(row)+"/C"+to16(col)+".png";
			return new URLRequest(tileurl);
		}
		
		private function to16(x:Number):String
		{
			var s:String = "00000000" + x.toString(16);
			s = s.substr(s.length-8,8);
			return s;
		}
		
		private function toZ(z:Number):String
		{
			if(z < 10)
			{
				return "0" + z.toString();
			}else{
				return z.toString();
			}
		}
		
		private function buildTileInfo():void
		{
			_tileInfo.height=256;
			_tileInfo.width=256;
			_tileInfo.origin=new MapPoint(-400,400);
			_tileInfo.spatialReference=new SpatialReference(4326);
			_tileInfo.lods = [
				new LOD(0, 7.61427507662348E-04, 320000), 
				new LOD(1, 3.80713753831174E-04, 160000), 
				new LOD(2, 1.90356876915587E-04, 80000), 
				new LOD(3, 9.51784384577936E-05, 40000), 
				new LOD(4, 4.75892192288968E-05, 20000), 
				new LOD(5, 2.37946096144484E-05, 10000), 
				new LOD(6, 1.18973048072242E-05, 5000), 
				new LOD(7, 5.9486524036121E-06, 2500)]
		}
	}
}