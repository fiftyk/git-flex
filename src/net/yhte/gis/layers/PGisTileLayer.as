/**
 * PGIS栅格地图服务图层
 * 
 * @author 刘荣涛
 * @version 2011.10.22
 */
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
    
    import net.yhte.logging.JsLogger;
    
    /**
     * PGIS栅格底图
     * 支持的协议有:pgis@,pgis2@,pgis3@
     * @example
     * <listing version="3.0">
     *  //访问arcgis server cache directory:
     *  var layer:Layer = new PGisTileLayer(pict@http://192.168.16.25:8888/arcgisserver/arcgiscache/gmap/Layers/_alllayers");
     *  layer.zoomOffset="11";
     *  layerformat="png";
     * 
     *  //访问pgis cache directory style1:
     *  //图片请求:http://192.168.16.25:8888/path/0/484/125.png
     *  //即:level/row/col
     *  var layer:Layer = new PGisTileLayer("pict2@http://192.168.16.25:8888/pathToPgisCacheDir");
     *  layer.zoomOffset="11";
     *  layerformat="png";
     *  
     *  //访问pgis cache directory style2:
     *  //图片请求:http://192.168.16.25:8888/path/0/484/125.png
     *  //即:level/col/row
     *  var layer:Layer = new PGisTileLayer("pict3@http://192.168.16.25:8888/pathToPgisCacheDir");
     *  layer.zoomOffset="11";
     *  layerformat="png";
     * </listing>
     * @author liurongtao
     */
    public class PGisTileLayer extends TiledMapServiceLayer
    {
        private var _tileInfo:TileInfo=new TileInfo();
        
        private var _url:String;
        private var _paramService:String = "getImage";
        private var _paramType:String = "RGB";
        private var _zoomOffset:int = 11;
        private var _paramV:String = "0.3";
		private var _options:Object;
        private var _logger:JsLogger;
        
        /**
        * pict@,pict2@,pict3@协议时,指定瓦片图片文件格式
        */
        public var format:String = "jpg";
        
        /**
         *  构造函数
         * @param value 瓦片底图URL
         * 
         */        
        public function PGisTileLayer(value:String=null, optionsValue:Object=null)
        {
            super();
			if(optionsValue)
				options = optionsValue;
            if(value)
                url = value;
            _logger = JsLogger.getLogger(this);
        }
        
        /**
         * 图层名称
         */
        public var label:String;
        /**
         * 接口参数-版本 默认值为“0.3”
         */
        public function get paramV():String
        {
            return _paramV;
        }
        
        public function set paramV(value:String):void
        {
            _paramV = value;
        }
        
        /**
         * 接口参数-缩放等级偏移量 默认值为“0”
         */
        public function get zoomOffset():int
        {
            return _zoomOffset;
        }
        
        public function set zoomOffset(value:int):void
        {
            _zoomOffset = value;
        }
        
        /**
         * 接口参数-图片格式 默认值为“RGB”
         */
        public function get paramType():String
        {
            return _paramType;
        }
        
        public function set paramType(value:String):void
        {
            _paramType = value;
        }
        
        /**
         * 接口参数-服务类型 默认值为“getImage”
         */
        public function get paramService():String
        {
            return _paramService;
        }
        
        public function set paramService(value:String):void
        {
            _paramService = value;
        }
        
        /**
         * 栅格地图服务地址
         */ 
        public function get url():String
        {
            return _url;
        }
		
        public function set url(value:String):void
        {
            _url = value;
            buildTileInfo();
            setLoaded(true);
        }
		
		/**
		 * 栅格地图服务选项参数
		 */ 
		public function get options():Object
		{
			return _options;
		}
		
		public function set options(value:Object):void
		{
			_options = value;
			if(_options.hasOwnProperty("format")){
				format = _options.format;
			}
			if(_options.hasOwnProperty("zoomOffset")){
				zoomOffset = _options.zoomOffset;
			}
		}
		
        
        override protected function zoomUpdateHandler(event:ZoomEvent):void{
            try{
                super.zoomUpdateHandler(event);
            }
            catch(e:Error){
                trace(e.message);
            }
        }
        
        override public function get fullExtent():Extent
        {
            return new Extent(-180, -80, 180, 80, new SpatialReference(4326));
        }
        
        override public function get initialExtent():Extent
        {
			return new Extent(-180, -80, 180, 80, new SpatialReference(4326));
        }
        
        override public function get spatialReference():SpatialReference
        {
            return new SpatialReference(4326);
        }
        
        override public function get tileInfo():TileInfo
        {
            return _tileInfo;
        }
        
        //获取瓦片
        override protected function getTileURL(level:Number, row:Number, col:Number):URLRequest
        {
            var temp:String;
            level = level - zoomOffset;
            row = 360 * Math.pow(2,level) - row - 1;
            
            if(url.indexOf("pict@") == 0)
            {
                temp = url.replace("pict@","")
                    + "/L" + toZ(level)
                    + "/R"+ to16(row)
                    + "/C"+to16(col)
                    + "." + format;
            }
            else if(url.indexOf("pict2@") == 0)
            {
                temp = url.replace("pict2@","")
                    + "/" + level.toString()
                    + "/" + row.toString()
                    + "/" + col.toString()
                    + "." + format;
            }
            else if(url.indexOf("pict3@") == 0)
            {
                temp = url.replace("pict3@","")
                    + "/" + level.toString()
                    + "/" + col.toString()
                    + "/" + row.toString()
                    + "." + format;
            }
            else
            {
                temp =  url 
                    + "?Service=" + paramService
                    + "&Type=" + paramType
                    + "&ZoomOffset=" + zoomOffset
                    + "&Col=" + col.toString()
                    + "&Row=" + row.toString()
                    + "&Zoom=" + level.toString()
                    + "&V=0.3";
            }
            _logger.debug(temp);
            return new URLRequest(temp);
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
        
        private function buildTileInfo():void
        {
            _tileInfo.height=256;
            _tileInfo.width=256;
            if(url.indexOf("pict@") == 0)
            {
                _tileInfo.origin = new MapPoint(119,32.5);
            }
            else
            {
                _tileInfo.origin = new MapPoint(0,90);
            }
            
            _tileInfo.spatialReference=new SpatialReference(4326);
            
            if(url.indexOf("pict@") == 0)
            {
                _tileInfo.lods = [
                    new LOD(1, 9.76566472125915E-04, 384764.063144), 
                    new LOD(2, 4.88283236062957E-04, 192382.031572), 
                    new LOD(3, 2.44141618031479E-04, 96191.015786), 
                    new LOD(4, 1.22070809015739E-04, 48095.507893), 
                    new LOD(5, 6.10354045091387E-05, 24047.753947), 
                    new LOD(6, 3.05177022533003E-05, 12023.876973), 
                    new LOD(7, 1.52588511279192E-05, 6011.938487), 
                    new LOD(8, 7.62942556269056E-06, 3005.969243),
                    new LOD(9, 3.81471278261432E-06, 1502.984622)
                ];
            }
            else
            {
                _tileInfo.lods = [
                    new LOD(11, 9.76566472125915E-04, 384764.063144), 
                    new LOD(12, 4.88283236062957E-04, 192382.031572), 
                    new LOD(13, 2.44141618031479E-04, 96191.015786), 
                    new LOD(14, 1.22070809015739E-04, 48095.507893), 
                    new LOD(15, 6.10354045091387E-05, 24047.753947), 
                    new LOD(16, 3.05177022533003E-05, 12023.876973), 
                    new LOD(17, 1.52588511279192E-05, 6011.938487), 
                    new LOD(18, 7.62942556269056E-06, 3005.969243),
                    new LOD(19, 3.81471278261432E-06, 1502.984622)
                ];
            }
        }
    }
}