package net.yhte.gis.layers
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.SpatialReference;
	import com.esri.ags.events.ZoomEvent;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.geometry.Polygon;
	import com.esri.ags.layers.DynamicMapServiceLayer;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.symbols.Symbol;
	import com.esri.ags.utils.JSON;
	import com.esri.ags.utils.WebMercatorUtil;
	
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import net.yhte.gis.events.MpEvent;
	import net.yhte.gis.layers.supportClasses.Column;
	import net.yhte.gis.layers.supportClasses.IFeatureCrud;
	import net.yhte.gis.utils.GeomUtil;
	import net.yhte.gis.utils.GraphicUtil2;
	import net.yhte.logging.JsLogger;
	
	/**
	 * 图层数据加载成功后触发此事件  
	 */	
	[Event(name="jsonLoadSuccess",type="net.yhte.gis.events.MpEvent")]
	/**
	 * 怡和动态图层
	 * 
	 * @author 刘荣涛
	 * @version 2011.01.24
	 */
	public class YhDynamicLayer extends DynamicMapServiceLayer
	{
		private var _exportParams:URLVariables;//图片请求参数
		private var _urlRequest:URLRequest;
		private var _httpService:HTTPService;
		private var _queryParams:Object;//数据请求参数
		private var _url:String;//服务地址
		private var _mode:String;
		private var _loaded:Boolean = false;//标记请求是否成功响应
		private var _showBusy:Boolean = false;
		private var _refreshTime:Number;//自动刷新地图时间
		private var _intervalId:uint;
		private var _where:String;
		private var _outFields:Array;
		private var _extentFeatures:String;//当前区域范围内的元素
		private var _geometryType:String;//图层几何类型
		private var _pk:String;//主键字段
		private var _symbol:Symbol;
		private var _featureCrud:IFeatureCrud;
		/**
		 * 图层的缓冲区分析样式
		 */
		public static var bufferSymbol:Symbol;
		private var _bufferGeometry:Geometry;//待做缓冲区分析的graphic
		private var _bufferDistance:int;//缓冲区分析的长度
		private var _bufferSymbol:Symbol;//缓冲区分析的样式
		private var _bufferCallback:Function;//缓冲区分析的回调方法
		private var _bufferSense:int;//画缓冲圆的精细度
		private var _columns:Array;
		private var _logger:JsLogger;
		private var _isWMS:Boolean = false;
		
		/**
		 * 显示的图层集合
		 */
		public var wmsLayers:Array;
		/**
		 * 是否为wms服务
		 */
		public function get isWMS():Boolean
		{
			return _isWMS;
		}
		
		public function get columns():Array
		{
			return _columns;
		}
		/**
		 * 样式 
		 * @return 
		 * 
		 */		
		public function get symbol():Symbol
		{
			return _symbol;
		}
		/**
		 * @private
		 */
		public function set symbol(value:Symbol):void
		{
			_symbol = value;
		}
		/**
		 * 点位数据，当数据尚未加载成功时，该属性值可能没有及时更新（
		 * 与图片数据不同步）或为[]。
		 * @return 
		 * 
		 */		
		public function get graphicProvider():ArrayCollection
		{
			var features:Array=[];
			try
			{
				features = FeatureSet.convertFromJSON(_extentFeatures).features;
			}
			catch(e:Error)
			{
				try
				{
					features = GraphicUtil2.fromJSON(_extentFeatures);
				}
				catch(ee:Error)
				{
					trace(ee);
				}
			}
			var results:ArrayCollection = new ArrayCollection();
			for each(var g:Graphic in features)
			{
				if(symbol)
					g.symbol = symbol;
				results.addItem(g);
			}
			return results;
		}
		/**
		 *图层添删改查 
		 */
		public function get featureCrud():IFeatureCrud
		{
			return _featureCrud;
		}
		/**
		 * @private
		 */
		public function set featureCrud(value:IFeatureCrud):void
		{
			_featureCrud = value;
			_featureCrud.layer = this;
			_featureCrud.map = map;
		}
		/**
		 * 主键字段 
		 * @return 
		 * 
		 */		
		public function get pk():String
		{
			return _pk;
		}
		/**
		 *	图层几何类型 
		 * @return 
		 * 
		 */		
		public function get geometryType():String
		{
			return _geometryType;
		}
		/**
		 * @private
		 */
		public function set geometryType(value:String):void
		{
			_geometryType = value;
		}
		/**
		 *显示请求等待光标 
		 * @return 
		 * 
		 */		
		public function get showBusy():Boolean
		{
			return _showBusy;
		}
		/**
		 * @private
		 */
		public function set showBusy(value:Boolean):void
		{
			_showBusy = value;
		}
		/**
		 *图层数据请求模式 
		 * @return 
		 * 
		 */		
		public function get mode():String
		{
			return _mode;
		}
		/**
		 * @private
		 */
		public function set mode(value:String):void
		{
			_mode = value;
			if(value == "single"){
				_loaded = false;
			}
		}
		/**
		 *图层请求数据回传字段 
		 * @return 
		 * 
		 */		
		public function get outFields():Array
		{
			return _outFields;
		}
		/**
		 * @private
		 */
		public function set outFields(value:Array):void
		{
			_outFields = value;
			if(_outFields.length > 0){
				_queryParams.outFields = _outFields.join(',');
				try{refreshData();}catch(e:Error){}//刷新数据
			}
		}
		/**
		 *图层请求数据where子句 
		 * @return 
		 * 
		 */		
		public function get where():String
		{
			return _where;
		}
		/**
		 * @private
		 */
		public function set where(value:String):void
		{
			_loaded = false;//重置数据已经加载标记
			_where = value;
			if(_where){
				_exportParams["where"] = _where;
			}
			_queryParams["where"] = _where;
			if(where){
				try{refresh();}catch(e:Error){}//刷新数据以及图片
			}
		}
		
		/**
		 *	图层服务地址 
		 * <p>设置图层URL,将同时重置where=null,outfields=[],mode="multi",showbusy=false</p>
		 */		
		public function set url(value:String):void
		{
			value = value.replace(/\/$/,"");
			
			if(value.indexOf("wms@") == 0)
			{//如果url以wms@为前缀
				_isWMS = true;//设置图层为wms图层
				value = value.replace("wms@","");    
			}
			
			if(_url){
				where = null;
				outFields = [];
				mode="multi";
				showBusy = false;
			}
			
			if(_url != value){
				_url = value;
				
				if(isWMS)
				{//如果是wms图层
					_urlRequest = new URLRequest(_url);
					_urlRequest.method = "GET";
					_urlRequest.data = _exportParams;
				}
				else
				{
					getLayerInfo();
					_urlRequest = new URLRequest(_url+'/export');
					_urlRequest.method = "POST";
					_urlRequest.data = _exportParams;
				}
				
				try{refresh();}catch(e:Error){}//刷新数据以及图片
			}
		}
		/**
		 * @private
		 */
		public function get url():String
		{
			return _url;
		}
		/**
		 *	图层自动刷新时间 单位:毫秒
		 */		
		public function get refreshTime():Number
		{
			return _refreshTime;
		}
		/**
		 * @private
		 */
		public function set refreshTime(val:Number):void
		{
			if (val == -1)
			{
				clearInterval(_intervalId);
			}else{
				_refreshTime = val;
				_intervalId = setInterval(this.refresh,_refreshTime);			
			}
		}
		/**
		 *  刷新地图缓存数据，此方法在调用refresh方法的基础上，为请求添加了
		 *  real参数 
		 */        
		public function refresh_cache():void
		{
			_queryParams["real"] = true;
			_exportParams["real"] = true;
			this.refresh();
		}
		
		/**
		 * 创建一个YhDynamicLayer图层对象
		 * @param url 服务地址
		 * @param whereClause where子句
		 * @param outFields	返回字段
		 * @param mode	数据请求模式 可选值为:"multi"/"single"/"none"
		 * @param showBusy	
		 * 
		 */		
		public function YhDynamicLayer(url:String=null,whereClause:String=null,
									   outfields:Array=null,mod:String="multi",shwbusy:Boolean=false)
		{
			super();
			setLoaded(true);
			_exportParams = new URLVariables();
			_queryParams = new Object();
			
			if(url)
			{
				this.url = url;
			}
			
			if(mod)
			{
				mode = mod;
			}
			
			if(shwbusy)
			{
				showBusy = shwbusy;
			}
			
			if(whereClause)
			{
				where = whereClause;
			}
			
			if(outfields != null)
			{
				outFields = outfields;
			}
			_logger = JsLogger.getLogger(this);
			_logger.debug("初始化完成!");
		}
		
		/**
		 * 刷新数据
		 */
		public function refreshData(callback:Function=null):void
		{
			_loaded = false;//重置数据已经加载标记
			requestExtentFeature(map.extent,function(result:String):void
			{
				onRequestExtentFeatureHandler(result);
				if(callback != null){
					callback.call(null);
				}
			});
		}
		/**
		 * 坐标系 
		 * @return 
		 * 
		 */		
		override public function get spatialReference():SpatialReference
		{
			return map.spatialReference;
		}
		/**
		 * 单位 
		 * @return 
		 * 
		 */		
		override public function get units():String
		{
			return map.units;
		}
		
		override protected function zoomUpdateHandler(event:ZoomEvent):void
		{	
			try
			{
				super.zoomUpdateHandler(event);
			}
			catch(e:Error)
			{
				trace(e);
			}
		}
		
		override protected function loadMapImage(loader:Loader):void
		{
			if(isWMS)
			{//如果为WMS服务
				_logger.debug("load image from: " + url);
				_exportParams.BBOX = map.extent.xmin + "," + map.extent.ymin + "," 
					+ map.extent.xmax + "," + map.extent.ymax;
				_exportParams.BGCOLOR="0x000000";
				_exportParams.CRS="ESPG:4267";
				_exportParams.FORMAT="image/png";
				_exportParams.HEIGHT=map.height;
				_exportParams.WIDTH=map.width;
				_exportParams.LAYERS=wmsLayers.join(",");
				_exportParams.REQUEST="GetMap";
				_exportParams.SERVICE="WMS";
				_exportParams.TRANSPARENT="TRUE";
				_exportParams.VERSION="1.3.0";
				loader.load(_urlRequest);
				return;
			}
			_exportParams.bbox = map.extent.xmin + "," + map.extent.ymin + "," 
				+ map.extent.xmax + "," + map.extent.ymax;
			_exportParams.size = map.width + "," + map.height;
			
			var wkid:Number = map.spatialReference.wkid;
			_exportParams["inSR"] = wkid;
			_exportParams["outSR"] = wkid;
			_exportParams["timeId"] = new Date().time;
			
			loader.load(_urlRequest);
			delete _exportParams["real"];
			
			requestExtentFeature(map.extent,onRequestExtentFeatureHandler);
		}
		
		private function onRequestExtentFeatureHandler(result:String):void
		{		
			_loaded = true;
			_extentFeatures = result;//保存当前范围元素信息
			dispatchEvent(new MpEvent(MpEvent.JSON_LOAD_SUCCESS,result));
		};
		
		private function requestExtentFeature(value:Extent=null,
											  callback:Function=null):void
		{
			var extent:Extent;
			if(!value)
			{
				extent = map.extent;
			}
			else
			{
				extent = value;
			}
			
			if(_mode == "multi" )
			{
				_queryParams.bbox = extent.xmin + "," + extent.ymin + "," 
					+ extent.xmax + "," + extent.ymax;
				_queryParams.size = width + "," + height;
			}
			
			var wkid:Number = map.spatialReference.wkid;
			_queryParams["inSR"] = wkid;
			_queryParams["outSR"] = wkid;
			_queryParams["timeId"] = new Date().time;
			
			_httpService = new HTTPService();
			_httpService.method = "POST";
			_httpService.url = _url + '/query';
			_httpService.addEventListener(ResultEvent.RESULT,function(re:ResultEvent):void{
				if(callback != null)
				{
					callback.call(null,re.result.toString());
				}
			});
			_httpService.addEventListener(FaultEvent.FAULT,function(f:FaultEvent):void{
				dispatchEvent(new MpEvent(MpEvent.FEATURES_LOAD_ERROR,f));
			});
			
			_httpService.showBusyCursor = _showBusy;
			
			if(_mode == "multi" )
			{
				_httpService.send(_queryParams);
			}
			else if(_mode == "single" && !_loaded)
			{
				_httpService.send(_queryParams);
			}
			else if(_mode == "none")
			{
				
			}
			delete _queryParams["real"] ;
		}
		
		/**
		 * 缓存区分析
		 * @param geometry  待做缓存分析的图像
		 * @param distance  缓存分析的距离
		 * @param symbol    缓冲区样式
		 * @param callback  缓冲分析的回调方法
		 * @param sense     画缓冲圆的精细度
		 * 
		 */ 
		public function buffer(geometry:Geometry, distance:int, symbol:Symbol=null, callback:Function=null, sense:int=360):void{
			if(geometry == null || distance <= 0)
			{
				return;
			}
			_bufferDistance = distance;
			_bufferSense = sense;
			if(symbol != null)
			{
				_bufferSymbol =symbol;
			}
			else
			{
				_bufferSymbol =bufferSymbol;
			}			
			_bufferCallback = callback;
			if(geometry.type == "esriGeometryPoint")
			{//点缓冲
				_bufferGeometry = geometry;
				var centerPoint:MapPoint = geometry as MapPoint;
				var extent:Extent = new Extent(centerPoint.x-distance, centerPoint.y-distance, centerPoint.x+distance, centerPoint.y+distance, map.spatialReference);
				requestExtentFeature(extent,onBufferHandler);
			}
			else if(geometry.type == "esriGeometryPolyline")
			{//线缓冲
				throw new Error("暂不支持polyline类型做缓存分析");
				return;
				//				var pointsOne:Array = GeomUtil.parall(graphic.geometry as Polyline, distance);
				//				var pointsTwo:Array = GeomUtil.parall(graphic.geometry as Polyline, -distance);
				//				for(var i:int=pointsTwo.length-1; i>=0; i--){
				//					pointsOne.push(pointsTwo[i]);
				//				}
				//				pointsOne.push(pointsOne[0]);
				//				var mapPointArray:Array = [];
				//				for(var j:int=0; j<pointsOne.length; j++){
				//					mapPointArray.push(new MapPoint(pointsOne[j][0], pointsOne[j][1], map.spatialReference));
				//				}
				//				var rings:Array = [];
				//				rings.push(mapPointArray);
				//				var polygon:Polygon = new Polygon(rings, map.spatialReference);
				//				var graPolygon:Graphic = new Graphic(polygon);
				//				_bufferGraphic = graPolygon;
				//				var layer:GraphicsLayer = map.getLayer("clientLayer") as GraphicsLayer; 
				//				layer.add(_bufferGraphic);
				//				var extentAll:Extent = new Extent(-999999999, -999999999, 999999999, 999999999, map.spatialReference);
				//				requestExtentFeature(extent,onBufferLineHandler);
			}
		}
		
		/**
		 * 查询点位信息(点缓冲分析)响应方法
		 */ 
		private function onBufferHandler(result:String):void
		{
			var features:Array=[];
			try
			{
				features = FeatureSet.convertFromJSON(_extentFeatures).features;
			}
			catch(e:Error)
			{
				try
				{
					features = GraphicUtil2.fromJSON(_extentFeatures);
				}
				catch(ee:Error)
				{
					trace(ee);
				}
			}
			//画缓冲圆
			var bufPoint:MapPoint = _bufferGeometry as MapPoint;
			var xyArray:Array = GeomUtil.buffer(bufPoint, _bufferDistance, _bufferSense);
			var mapPointArray:Array = [];
			for(var i:int=0; i<xyArray.length; i++)
			{
				mapPointArray.push(new MapPoint(xyArray[i][0], xyArray[i][1], map.spatialReference));
			}
			var rings:Array = [];
			rings.push(mapPointArray);
			var polygon:Polygon = new Polygon(rings, map.spatialReference);
			var graPolygon:Graphic = new Graphic(polygon,_bufferSymbol);
			var layer:GraphicsLayer = map.getLayer("clientLayer") as GraphicsLayer;
			layer.add(graPolygon);
			//查找在缓存区内的点位
			var graphics:Array=[];
			var isMercator:Boolean = true;
			var x:Number = bufPoint.x;
			var y:Number = bufPoint.y;
			if(x<181 && y<91)
			{//84坐标系需要转换
				var tmpPoint:MapPoint = new MapPoint(x, y);
				var tmpMerPoint:MapPoint = WebMercatorUtil.geographicToWebMercator(tmpPoint) as MapPoint;
				x = tmpMerPoint.x;
				y = tmpMerPoint.y;
				isMercator = false;
			}
			for(var j:int=0; j<features.length;j++)
			{
				if(isMercator)
				{
					var point:MapPoint = features[j].geometry as MapPoint;
					if(((point.x-x)*(point.x-x)+(point.y-y)*(point.y-y))<=(_bufferDistance*_bufferDistance))
					{//在缓冲区内
						trace(point);
						graphics.push(point);
					}
				}
				else
				{//84坐标系需要转换
					var pointTmp:MapPoint = features[j].geometry as MapPoint;
					var point2:MapPoint = WebMercatorUtil.geographicToWebMercator(pointTmp) as MapPoint;
					if(((point2.x-x)*(point2.x-x)+(point2.y-y)*(point2.y-y))<=(_bufferDistance*_bufferDistance))
					{//在缓冲区内
						trace(point2);
						graphics.push(pointTmp);
					}
				}
				
			}
			if(_bufferCallback != null)
			{
				_bufferCallback.call(null, graphics, graPolygon);
			}
		}
		
		/**
		 * 查询点位信息(线缓冲分析)响应方法
		 */ 
		private function onBufferLineHandler(result:String):void{
			var features:Array=[];
			try
			{
				features = FeatureSet.convertFromJSON(_extentFeatures).features;
			}
			catch(e:Error)
			{
				try
				{
					features = GraphicUtil2.fromJSON(_extentFeatures);
				}
				catch(ee:Error)
				{
					trace(ee);
				}
			}
			var graphics:Array=[];
			var polygon:Polygon = _bufferGeometry as Polygon;
			var graPolygon:Graphic = new Graphic(polygon);
			for(var i:int=0; i<features.length;i++)
			{
				var point:MapPoint = features[i].geometry as MapPoint;
				if(polygon.contains(point))
				{//包含在面中
					trace(point);
					graphics.push(point);
				}
			}
			if(_bufferCallback != null)
			{
				_bufferCallback.call(null, graphics, graPolygon);
			}
		}
		
		//请求图层信息
		private function getLayerInfo():void
		{
			var http:HTTPService = new HTTPService();
			http.method = "POST";
			http.url = _url + '/info';
			http.addEventListener(ResultEvent.RESULT,function(re:ResultEvent):void{
				var t:String = re.result.toString();
				var info:Object = JSON.decode(t);
				var a:Array = [];
				_pk = info.primary_key;
				for each(var col:Object in info.columns)
				{
					var column:Column = new Column(col[0],col[1]);
					column.length = col[2];
					column.precision = col[3];
					column.scale = col[4];
					column.nullable = {"N":false,"Y":true}[col[5]];
					column.defaultVal = col[6];
					a.push(column);
				}
				_columns = a;
			});
			http.send();
		}
	}
}