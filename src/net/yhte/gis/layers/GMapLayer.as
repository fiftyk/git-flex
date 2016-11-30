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
	 * 用于访问Google在线地图或与Google Tile System相同的TileLayer,如MapABC在线
	 * 地图。
	 * @author liurongtao
	 * 
	 */	
	public class GMapLayer extends TiledMapServiceLayer
	{
		private var _tileInfo:TileInfo=new TileInfo();
		private var _baseURL:String="";
		
		public static const MAP_STYLE_STREET:String = "street";
		public static const MAP_STYLE_SATELLITE:String = "satellite";
		public static const MAP_STYLE_ANNOTATION:String = "annotation";
		public static const MAP_STYLE_TERRAIN:String = "terrain";
		public static const MAP_STYLE_TRAFFIC:String = "traffic";
		public static const MAP_STYLE_MAPABC:String = "mapabc";
		public static const MAP_STYLE_SATELLITE_MAP:String = "satelliteMap";
		public static const SEMI_CYCLE:Number = 20037508.342787;
        public static const ZERO_LOD:LOD = 
            new LOD(0, 156543.033928, 591657527.591555);
		
		private var _remoteTiles:Object = {//默认外网瓦片服务地址配置
			"street":"http://mt{random}.google.cn/vt/lyrs=m@169000000&hl=zh-CN&gl=cn&",
			"satellite":"http://khm{random}.google.com/kh/v=104&",
			//http://mt0.google.com/vt/lyrs=h@179000000&hl=zh-CN&src=app
			"annotation":"http://mt{random}.google.com/vt/lyrs=h@179000000&hl=zh-CN&src=app&",
			"terrain":"http://mt{random}.google.cn/vt/lyrs=t@126,r@145&hl=zh-CN&gl=cn&",
			"traffic":"http://mt{random}.google.com/vt?hl=zh-CN&gl=cn&lyrs=h@169000000,traffic|seconds_into_week:-1&",
			"mapabc":"http://emap{random}.mapabc.com/mapabc/maptile?v=w2.61&",
			"satelliteMap":"http://khm{random}.google.com/kh/v=105&"
		};
		
		private var _format:String = "png";//瓦片文件格式;默认格式为png
		private var _mapStyle:String;
        private var _minlv:int = 0;
        private var _maxlv:int = 19;
//        private var _originX:Number = -SEMI_CYCLE;
//        private var _originY:Number = SEMI_CYCLE;
        /**
         * 原始纬度
         * @return 
         * 
         */
//        public function get originY():Number
//        {
//            return _originY;
//        }
        /**
         * @private
         */
//        public function set originY(value:Number):void
//        {
//            _originY = value;
//        }
        /**
         * 原始经度 
         * @return 
         * 
         */        
//        public function get originX():Number
//        {
//            return _originX;
//        }
        /**
         * @private
         */
//        public function set originX(value:Number):void
//        {
//            _originX = value;
//        }

        /**
         * 最大等级 
         * @return 
         * 
         */ 
        public function get maxlv():int
        {
            return _maxlv;
        }
        /**
         * @private
         */
//        public function set maxlv(value:int):void
//        {
//            _maxlv = value;
//        }
        /**
         * 最小等级 
         * @return 
         * 
         */        
        public function get minlv():int
        {
            return _minlv;
        }
        /**
         * @private
         */
//        public function set minlv(value:int):void
//        {
//            _minlv = value;
//        }

		/**
		 *	当前瓦片服务地址配置
		 * Google、MapABC的瓦片服务地址可能随时间的推移,发生更改,这样硬编码
		 * 在GMapLayer类中的瓦片地址可能失效。在这种情况下，
		 * 可以通过调用该方法重新设置外网瓦片服务地址。
		 * 
		 */
		public function get remoteTiles():Object
		{
			return _remoteTiles;
		}
		
		public function set remoteTiles(value:Object):void
		{
			for(var key:String in value)
            {
				if(_remoteTiles.hasOwnProperty(key))
                {
					_remoteTiles[key] = value[key];
				}
			}
            refresh();
		}
		
		/**
		 * 瓦片文件格式
		 * 当指定的mapStyle是
		 * @default "png"
		 * 
		 */
		public function get format():String
		{
			return _format;
		}
		
		/**
		 *  @private
		 */
		public function set format(value:String):void
		{
			_format = value;
		}
		
		/**
		 *	图层类型可以是"street"(default),"satellite","annotation","terrain","traffic",
		 * "mapabc"；也可以是以"pic@"为前缀的url路径，这个路径指向ArcGIS Cache 
		 * 目录，如："pic:http://localhost/pathto/arcgiscache/service/layers/
         * _alllayers"；Google和MapABC的外网地址可能发生变化，此时可以直接指
         * 定外网的URL,如"url@http://mt{random}.google.cn/vt/lyrs=m@
         * 169000000&hl=zh-CN&gl=cn&"；还可以访问类似
         * "http://somedomain/tiles/x/y/z/"这样的tile路径，此时可以将mapStyle=
         * "pic2@http://somedomain/tiles"
         * 
		 * 
		 * @default "street"
		 */
		public function get mapStyle():String{
			return _mapStyle;
		}
		
		/**
		 *  @private
		 */
		public function set mapStyle(value:String):void{
			_mapStyle = value;
			refresh();
		}
		
		public function GMapLayer(type:String="street",options:Object=null)
		{
			super();
			mapStyle = type;
            if(options)
            {
                _minlv = options["minlv"] || 0;
                _maxlv = options["maxlv"] || 19;
//                _originX = options["originX"] || _originX;
//                _originY = options["originY"] || _originY;
            }
			buildTileInfo();
			setLoaded(true);
		}
		
		override public function get fullExtent():Extent
		{
			return new Extent(-SEMI_CYCLE, -SEMI_CYCLE, SEMI_CYCLE, SEMI_CYCLE,
				new SpatialReference(102113));
		}
		
		override public function get initialExtent():Extent
		{
			return new Extent(-SEMI_CYCLE, -SEMI_CYCLE, SEMI_CYCLE, SEMI_CYCLE, 
				new SpatialReference(102113));
		}
		
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
			var url:String = "";
			if([MAP_STYLE_STREET,MAP_STYLE_SATELLITE,MAP_STYLE_TERRAIN,
				MAP_STYLE_MAPABC,MAP_STYLE_TRAFFIC,MAP_STYLE_ANNOTATION,MAP_STYLE_SATELLITE_MAP]
				.indexOf(mapStyle) != -1)
			{
				url = remoteTiles[mapStyle].replace("{random}",(col%4));
			}
            else if(mapStyle.indexOf("url@") == 0)
            {
                url = mapStyle.replace(/url@/,"").replace(/{random}/,(col%4));
            }
			else if(mapStyle.indexOf("pict@") == 0)
			{//直接访问ArcGIS Cache 目录，如pict@http://localhost:9000/_alllayers
				url = mapStyle.replace("pict@","")+"/L"+toZ(level)+"/R"+
                    to16(row)+"/C"+to16(col)+"."+format;
			}
            else if(mapStyle.indexOf("pict2@") == 0)
            {
                url = mapStyle.replace("pict2@","")
                    +"/"+col+"/"+row+"/"+level+"/";
            }
			
			if(mapStyle.indexOf("pict@") != 0 
                && mapStyle.indexOf("pict2@") != 0
				&& mapStyle.indexOf("satelliteMap")!= 0 )
            {
				url += "x=" + col + "&" +"y=" + row + "&" + "z=" + level+ "&s=";
			}
			
			if(mapStyle.indexOf("satelliteMap") == 0){
				url += "x=" + col + "&" +"y=" + row + "&" + "z=" + level;
			}
			
			return new URLRequest(url);
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
			}
            else
            {
				return z.toString();
			}
		}
		
        private function getLods():Array
        {
            var lods:Array = [];
            for(var i:int=minlv;i<=maxlv;i++)
            {
                var resolution:Number = ZERO_LOD.resolution;
                var scale:Number = ZERO_LOD.scale;
                var pow:int = Math.pow(2,i);
                var lod:LOD = new LOD(i,resolution/pow,scale/pow);
                lods.push(lod);
            }
            return lods;
        }
        
		private function buildTileInfo():void
		{
			_tileInfo.height=256;
			_tileInfo.width=256;
            _tileInfo.origin=new MapPoint(-SEMI_CYCLE, SEMI_CYCLE);
			_tileInfo.spatialReference=new SpatialReference(102113);
            
			_tileInfo.lods = getLods();
		}
	}
}