package net.yhte.gis.tools
{
	import com.esri.ags.Graphic;
	import com.esri.ags.Map;
	import com.esri.ags.events.DrawEvent;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.layers.ArcGISTiledMapServiceLayer;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.layers.Layer;
	import com.esri.ags.tools.DrawTool;
	import com.esri.ags.tools.EditTool;
	import com.esri.ags.tools.NavigationTool;
	
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.logging.ILogger;
	import mx.managers.CursorManager;
	
	import net.yhte.gis.events.MpEvent;
	import net.yhte.gis.layers.BMapLayer;
	import net.yhte.gis.layers.GMapLayer;
	import net.yhte.gis.layers.MapLinkLayer;
	import net.yhte.gis.layers.PGisTileLayer;
	import net.yhte.gis.layers.YhDynamicLayer;
	import net.yhte.gis.utils.LogUtil;

    /**
     * layerTool激活框选后，框选操作结束后出发此事件 
     */    
	[Event(name="lyr_query", type="net.yhte.gis.events.MpEvent")]
    /**
     * layerTool激活点选后，点选图层元素时触发此事件
     */    
	[Event(name="lyr_identify_click", type="net.yhte.gis.events.MpEvent")]
    /**
     * layerTool激活点选后，悬停在图层元素时触发此事件
     */ 
	[Event(name="lyr_identify_over", type="net.yhte.gis.events.MpEvent")]
    
    /**
     *  图层工具，提供图层点选、框选、元素查询等功能 
     * @author liurongtao
     * 
     */    
	public class LayerTool extends EventDispatcher
	{
		/**
		 * 框选模式 
		 */		
		public static const SEL_MODE_EXT:String = "extent";
		/**
		 * 点选模式 
		 */		
		public static const SEL_MODE_PNT:String = "point";
		/**
		 * 用于聚合时标记聚合对象位置的属性字段 ,默认值为"_geom"
		 */		
		public static var geomKey:String = "_geom";
		
		[Embed(source="assets/cur_pointer.png")]
		private var _myCursor:Class;
		private var _myCursorId:int;
		
		private var _map:Map;
		
		private var _drawTool:DrawTool;
		private var _naviTool:NavigationTool;
		private var _editTool:EditTool;
		private var _clientLayer:GraphicsLayer;
		private var _identifyGraphic:Graphic;
		/**
		 *用于悬停的延迟函数返回的变量
		 */		
		private var _identifyTimeOut:uint;

		private var _onExtQueryDrawEnd:Function;
		private var _onIdentifyMove:Function;
		private var _onIdentifyClick:Function;
		private var _baseLayerAdded:Boolean;
        
        //客户端图层集合，用于去除点选时注册的监听事件 
        private var _graphicLayerArray:ArrayCollection = new ArrayCollection();
        //客户端图层点选时注册的相应方法：鼠标点击，鼠标移动，鼠标移出 
        private var _onGraphicMouseClick:Function;
        private var _onGraphicMouseOver:Function;
        private var _onGraphicMouseOut:Function;
        
        private var _layersOnRect:Array = [];//被框选图层集合
        private var _layersOnIdentify:Array = [];//被Identify的图层
        
		private static var _instance:LayerTool;
        /**
         * 区分元素的最小像素，单位：像素
         * 激活图层点选时，如果图层为YhDynamicLayer，此属性用于设置点选搜索范围
         */		
        public var identifyPixel:int = 15;
        /**
        * 区分元素的延迟时间，单位：毫秒
        * 激活图层点选时，如果图层为YhDynamicLayer，此属性用于设置点选搜索延时
        */
		public var identifyTime:int = 200;
		/**
		 * 是否启用聚合，当该属性值设置为true时，点选YhDynamicLayer将启用聚合。
         * 注册元素点选或悬停事件获得的<code>identifyGraphic</code>的attributes属性
         * 将包含属性<code>identifyPixel</code>指定范围内的所有元素的attributes属性
		 */
		public var clustered:Boolean = false;
		private var _logger:ILogger;
        /**
         * 点选状态的图层 
         * @return 
         * 
         */        
        public function get layersOnIdentify():Array
        {
            return _layersOnIdentify;
        }
        /**
         * 框选状态的图层 
         * @return 
         * 
         */        
        public function get layersOnRect():Array
        {
            return _layersOnRect;
        }
		/**
		 * 绘图工具 
		 * @return 
		 * 
		 */		
		public function get drawTool():DrawTool
		{
			if( !_drawTool )
			{
				_drawTool = new DrawTool(map);
				_drawTool.showDrawTips = false;
			}
			return _drawTool;
		}
		/**
		 * 导航工具 
		 * @return 
		 * 
		 */		
		public function get naviTool():NavigationTool
		{
			if( !_naviTool )
				_naviTool = new NavigationTool(map);
			return _naviTool;
		}
		/**
		 * 	编辑工具
		 * @return 
		 * 
		 */	
		public function get editTool():EditTool
		{
			if( !_editTool )
				_editTool = new EditTool(map);
			return _editTool;
		}
		/**
		 * 客户端层
         * 该图层会默认添加至地图，图层id为“clientLayer”。
		 * @return 
		 * 
		 */		
		public function get clientLayer():GraphicsLayer
		{
			if(map.layerIds.length == 0){//当没有底图图层时，不允许添加客户端层
				throw new Error("当前没有底图图层，请先添加底图图层，再添加客户端层");
				return null;
			}
			if( !_clientLayer )
			{	
				_clientLayer = new GraphicsLayer();
				_clientLayer.id = "clientLayer";
				map.addLayer(_clientLayer);
			}
				
			return _clientLayer;
		}
		/**
		 * 地图对象
		 * @return 
		 * 
		 */		
		public function get map():Map
		{
			return _map;
		}
        /**
         * @private
         */        
		public function set map(value:Map):void
		{
			_map = value;
			map.contextMenu = new ContextMenu();
			map.contextMenu.hideBuiltInItems();
			map.logoVisible = false;
			map.zoomSliderVisible = false;
		}

		/**
		 * 构造方法
		 * @param map 地图对象引用
         * @param config 配置文件
		 * @private
		 */		
		public function LayerTool(map:Map,config:String=null)
		{
			super();
			if ( _instance != null)
				throw new Error("请使用getInstance方法初始化！");
			this.map = map;
			_logger = LogUtil.getLogger(this);
		}
		/**
		 *  获得LayerTool实例  
		 * @param map 地图对象
         * @param config 配置文件
		 * @return 
		 * 
		 */		
		public static function  getInstance(map:Map=null,config:String=null):LayerTool
		{
			if (_instance == null)
				_instance = new LayerTool(map,config);
			return _instance;
		}
		
		/**
		 *  销毁LayerTool实例
		 * 用于map重新创建后，需要重新创建LayerTool实例  
		 * @param 
		 * @return 
		 * 
		 */
		public static function destroy():void{
			_instance = null;
		}
		
		/**
		 * 激活点选或框选模式 
		 * @param layer 图层或图层数组
		 * @param modeType 模式,SEL_MODE_EXT或SEL_MODE_PNT,默认为框选
		 * 
         * @example 激活点选示例:
         *  <listing version="3.0">
         *      //注册点击事件
         *      layerTool.addEventListener(MpEvent.LYR_IDENTIFY_CLICK,
         *          function(e:MpEvent){
         *              trace(e.identifyGraphic);
         *          });
         *      //注册悬停事件
         *      layerTool.addEventListener(MpEvent.LYR_IDENTIFY_OVER,
         *          function(e:MpEvent){
         *              trace(e.identifyGraphic);
         *          });
         *      //激活点选功能
         *      layerTool.activate(layer,LayerTool.SEL_MODE_PNT);
         *      
         *      //另外可以同时针对多个图层激活点选或框选
         *      layerTool.activate([layer1,layer2],LayerTool.SEL_MODE_PNT);
         *      //执行下面两行代码的作用等同于上上面的代码
         *      layerTool.activate(layer1,LayerTool.SEL_MODE_PNT);
         *      layerTool.activate(layer2,LayerTool.SEL_MODE_PNT);
         *      
         *  </listing>
		 */		
		public function activate(layer:*,modeType:String="extent"):void
		{
            if(layer is Layer)
            {
                if(modeType == SEL_MODE_EXT)
                {
                    var idx1:int = _layersOnRect.indexOf(layer); 
                    if(idx1 == -1)
                    {
                        _layersOnRect.push(layer);
                    }
                    _deactivate();
                    _logger.debug("框选图层个数为:",_layersOnRect.length);
                    rectQuery(_layersOnRect);
                }
                else if(modeType == SEL_MODE_PNT)
                {
                    var idx2:int = _layersOnIdentify.indexOf(layer); 
                    if(idx2 == -1)
                    {
                        _layersOnIdentify.push(layer);
                    }
                    _deactivate();
					_logger.debug("点选图层个数为:",_layersOnIdentify.length);
                    pointQuery(_layersOnIdentify);
                }
            }
            else if(layer is Array)
            {
                if((layer as Array).length == 0)
                {
                    _deactivate();   
                }
                for each(var lyr:Layer in layer)
                {
                    activate(lyr,modeType);
                }
            }
		}
		
        /**
         * 禁用图层的点选或框选功能 
         * @param layer 图层或图层数组
         * @param modeType "point"/"extent"
         * 
         * @example 激活点选示例:
         *  <listing version="3.0">
         *      //禁用layer1的点选功能
         *      layerTool.deactivate(layer1,"point");
         *      
         *      //禁用layer1,layer2的点选功能
         *      layerTool.deactivate([layer1,layer2],"point");
         * 
         *      //禁用所有图层的点选功能
         *      layerTool.deactivate(null,"point");
         *      //禁用所有图层的框选功能
         *      layerTool.deactivate(null,"extent");
         *      
         * </listing>
         */				
		public function deactivate(layer:*=null,modeType:String="point"):void
        {
            if(layer is Layer)
            {
                if(modeType == SEL_MODE_PNT)
                {
                    var i1:int = _layersOnIdentify.indexOf(layer);
                    if(i1 != -1)
                    {
                        _layersOnIdentify.splice(i1,1);
                    }
                }
                else if(modeType == SEL_MODE_EXT)
                {
                    var i2:int = _layersOnRect.indexOf(layer);
                    if(i2 != -1)
                    {
                        _layersOnRect.splice(i2,1);
                    }
                }
            }
            else if(layer is Array)
            {
                for each(var lyr:Layer in layer)
                {
                    deactivate(lyr,modeType);
                }
            }
            else
            {
                if(modeType == SEL_MODE_EXT)
                {
                    _layersOnRect = [];    
                }
                else if(modeType == SEL_MODE_PNT)
                {
                    _layersOnIdentify = [];    
                }
            }
            activate(_layersOnRect,SEL_MODE_EXT);
            activate(_layersOnIdentify,SEL_MODE_PNT);
        }
        
        private function _deactivate():void
		{
			drawTool.deactivate();//使绘图功能无效
            if(_layersOnIdentify.length == 0 && _layersOnRect.length == 0)
            {
                drawTool.deactivate();
            }
			if(_onExtQueryDrawEnd != null)//去除框选查询时可能注册是事件监听
				drawTool.removeEventListener(DrawEvent.DRAW_END,_onExtQueryDrawEnd);
			if(_onIdentifyMove != null)//去除点选查询时注册的事件监听
				map.removeEventListener(MouseEvent.MOUSE_MOVE,_onIdentifyMove);
			if(_onIdentifyClick != null)//去除点选查询时注册的事件监听
				map.removeEventListener(MouseEvent.CLICK,_onIdentifyClick);
			if(_onGraphicMouseClick != null && _onGraphicMouseOver != null && _onGraphicMouseOut != null && _graphicLayerArray.length >0){
				for each(var layer:GraphicsLayer in _graphicLayerArray){
					var features:*;
					if(layer.hasOwnProperty("graphicProvider") && layer["graphicProvider"] != null)
						features = layer["graphicProvider"];
					
					for each(var g:Graphic in  features)
					{
						g.removeEventListener(MouseEvent.MOUSE_OVER, _onGraphicMouseOver);
						g.removeEventListener(MouseEvent.MOUSE_OUT, _onGraphicMouseOut);
						g.removeEventListener(MouseEvent.CLICK, _onGraphicMouseClick);
					}
				}
			}
			_identifyGraphic = null;
		}
		
		/**
		 * 查询图层上满足过滤条件的元素 
		 * @param layer 待查询的图层或图层数组
		 * @param filter 过滤函数
		 * @param action 处理函数
		 * @param immediately 是否立即返回满足filter的第一个结果
		 * @param filterToken 用于filter函数
		 * @param actionToken 用于action函数
         * @return 满足filter的图层元素
		 */		
		public function query(layer:*,filter:Function,action:Function=null
			,immediately:Boolean=false,filterToken:*=null,
			actionToken:*=null):Array
		{
			if(layer is Array)
			{//增加同时查询多个图层的支持
				var totals:Array=[];
				for each(var lyr:Layer in layer)
					totals = totals.concat(query(lyr,filter,action,immediately,filterToken,actionToken));
				return totals;
			}
			var results:Array = [];
			
			var features:*;
			if(map.layerIds.indexOf(layer.id) == -1)//判断图层是否添加到地图上
				return results;
			if(layer.hasOwnProperty("graphicProvider") && layer["graphicProvider"] != null)
				features = layer["graphicProvider"];
			else
				return results;
			
			for each(var g:Graphic in  features)
			{
				var bool:Boolean;
				if(filterToken)
					bool= filter.apply(null,[g.attributes,g,filterToken]);
				else
					bool= filter.apply(null,[g.attributes,g]);
				if(bool)
				{	
                    if(!g.attributes)
                    {
                        g.attributes = {};
                    }
                    
                    g.attributes["_layer"] = layer;
					
                    results.push(g);
					if(immediately)//是否立即返回第一个结果
					{
						if(action != null)
							action.call(null,g);
						return results;
					}
				}
			}
			
			if(action != null)
			{//对满足条件的元素执行action操作
				for each(var gra:Graphic in results)
				{
					if(actionToken)
						action.apply(null,[gra,actionToken]);
					else
						action.apply(null,[gra]);
				}
			}
			return results;
		}
		
        /**
         * 地图范围过滤函数
         * @param attr 图层元素属性
         * @param g 图层元素
         * @param extent 地图范围
         * @return 
         * 
         */        
		public static function extentFilter(attr:Object,g:Graphic,extent:Extent):Boolean
		{
			var geo:Geometry = g.geometry;
			if(extent.contains(geo)||extent.intersects(geo))
				return true;
			return false;
		}
		//用于activate方法,框选
		private function rectQuery(layer:*):void
		{
            if(layer is Array && (layer as Array).length == 0)
            {}
            else
            {
			    drawTool.activate(DrawTool.EXTENT);//激活画框功能
            }
			
			_onExtQueryDrawEnd = function(event:DrawEvent):void
			{
//				trace(layer.id,"_onExtQueryDrawEnd");
				var extent:Extent = event.graphic.geometry as Extent;
				
				//发送查询完成事件
				var results:Array = query(layer,extentFilter,null,false,extent);
				var e:MpEvent = new MpEvent(MpEvent.LYR_QUERY);
				e.queryResults = results;
				dispatchEvent(e);
			};
			drawTool.removeEventListener(DrawEvent.DRAW_END,_onExtQueryDrawEnd);
			drawTool.addEventListener(DrawEvent.DRAW_END,_onExtQueryDrawEnd);
		}
		//用于activate方法,点选
		private function pointQuery(layer:*):void
		{
			if(layer is YhDynamicLayer || layer is Array){//动态图层处理方式
				_onIdentifyMove = function(event:MouseEvent):void
				{
					CursorManager.removeCursor(_myCursorId);
                    
					if(_onIdentifyClick != null)
						map.removeEventListener(MouseEvent.CLICK,_onIdentifyClick);
					
					_onIdentifyClick = function (event:MouseEvent):void
					{
						if(_identifyGraphic)
						{
							//发送查询完成事件
							var e:MpEvent = new MpEvent(MpEvent.LYR_IDENTIFY_CLICK);
							e.identifyGraphic = _identifyGraphic;
							map.removeEventListener(MouseEvent.CLICK,_onIdentifyClick);
                            dispatchEvent(e);
						}
					}
					
					if(_identifyTimeOut)
						clearTimeout(_identifyTimeOut);
					_identifyTimeOut = setTimeout(function():void{
						indentifyGraphics(layer);
					},identifyTime);
				}
				map.removeEventListener(MouseEvent.MOUSE_MOVE,_onIdentifyMove );
				map.addEventListener(MouseEvent.MOUSE_MOVE,_onIdentifyMove );
			}
            else if(layer is GraphicsLayer)
            {//客户端图层处理方式
				_graphicLayerArray.addItem(layer);//添加进客户端图层集合
				
				_onGraphicMouseOver = function(e:MouseEvent):void{//鼠标移入
					_identifyGraphic = e.currentTarget as Graphic;
					
					if(clustered)
                    {//聚合时，需要查询出周围点位
						var extent:Extent = new Extent;
						var x:Number = map.mouseX;//屏幕坐标
						var y:Number = map.mouseY;
						
						var min:MapPoint = map.toMap(new Point(x-identifyPixel,y+identifyPixel));
						var max:MapPoint = map.toMap(new Point(x+identifyPixel,y-identifyPixel));
						
						extent.xmin = min.x;
						extent.ymin = min.y;
						extent.xmax = max.x;
						extent.ymax = max.y;
						
						var results:Array = query(layer,extentFilter,null,false,extent);
						var graphic:Graphic = new Graphic();
						graphic.geometry = _identifyGraphic.geometry;
						graphic.attributes = [];
						for each(var clusterGra:Graphic in results)
                        {
							if(clusterGra.attributes != null)
                            {
								var attr:Object = clusterGra.attributes;
								if(attr.hasOwnProperty(geomKey))
								{
									_logger.fatal("属性中已经包含{0}键",geomKey);
								}
								else
								{
									attr[geomKey]=clusterGra.geometry;
								}
								graphic.attributes.push(attr);
							}
						}
						_identifyGraphic = graphic;
					}
					
					var lyrEvent:MpEvent = new MpEvent(MpEvent.LYR_IDENTIFY_OVER);
					lyrEvent.identifyGraphic = _identifyGraphic;
					_myCursorId = CursorManager.setCursor(_myCursor,-10,-10);
					dispatchEvent(lyrEvent);
				};
				
				_onGraphicMouseOut = function(e:MouseEvent):void
                {//鼠标移出
					CursorManager.removeCursor(_myCursorId);
				};
				
				
				_onGraphicMouseClick = function(e:MouseEvent):void
                {//鼠标点击
					var lyrEvent:MpEvent = new MpEvent(MpEvent.LYR_IDENTIFY_CLICK);
					lyrEvent.identifyGraphic = _identifyGraphic;
					dispatchEvent(lyrEvent);
				};
				
				var features:*;
				if(layer.hasOwnProperty("graphicProvider") && layer["graphicProvider"] != null)
					features = layer["graphicProvider"];
				
				for each(var g:Graphic in  features)
				{
					g.addEventListener(MouseEvent.MOUSE_OVER, _onGraphicMouseOver);
					g.addEventListener(MouseEvent.MOUSE_OUT, _onGraphicMouseOut);
					g.addEventListener(MouseEvent.CLICK, _onGraphicMouseClick);
				}
			}
		}
        
		//用于pointQuery
		private function indentifyGraphics(layer:*):void
		{
			var extent:Extent = new Extent();
			var x:Number = map.mouseX;//屏幕坐标
			var y:Number = map.mouseY;
			
			var min:MapPoint = map.toMap(new Point(x-identifyPixel,y+identifyPixel));
			var max:MapPoint = map.toMap(new Point(x+identifyPixel,y-identifyPixel));
			
			extent.xmin = min.x;
			extent.ymin = min.y;
			extent.xmax = max.x;
			extent.ymax = max.y;
			
			var results:Array;
			
			var action:Function = function(g:Graphic):void
			{
				_identifyGraphic = g;
				//发送查询完成事件
				var e:MpEvent = new MpEvent(MpEvent.LYR_IDENTIFY_OVER);
                e.identifyGraphic = g;
				_myCursorId = CursorManager.setCursor(_myCursor,-10,-10);
				
				map.removeEventListener(MouseEvent.CLICK,_onIdentifyClick);
				map.addEventListener(MouseEvent.CLICK,_onIdentifyClick);
                
                dispatchEvent(e);
			};
			
			if(clustered)
            {
				results = query(layer,extentFilter,null,false,extent);
				if(results.length == 0)
					return;
				var graphic:Graphic = new Graphic();
				graphic.attributes = [];
				for each(var g:Graphic in results)
                {
					graphic.geometry = g.geometry;
					if(g.attributes != null)
                    {
						var attr:Object = g.attributes;
						if(attr.hasOwnProperty(geomKey))
						{
							_logger.fatal("属性中已经包含{0}键",geomKey);
						}
						else
						{
							attr[geomKey]=g.geometry;
						}
						graphic.attributes.push(attr);
					}
				}
				action(graphic);
			}
            else
            {
				results = query(layer,extentFilter,action,true,extent,layer);
			}
		}
        /**
         * 为地图添加底图
         * @param url 底图类型或服务地址
         * @param options 
         * @private
         */        
		public function load(url:String,options:Object=null):void
		{
			if(_baseLayerAdded || url == "null")
				return;
			if(_clientLayer){
				map.removeLayer(_clientLayer);
			}
			var urls:Array = url.split("|");
			var baseLayer:Layer;
			var index:int = 0;
			for each(var url:String in urls)
            {
 				if((["street","satellite","terrain","mapabc","traffic",
                    "annotation"].indexOf(url) != -1) || 
                    url.indexOf("pict@") == 0 || 
                    url.indexOf("url@") == 0)
                {
					baseLayer = new GMapLayer(url,options==null?null:options[index++]);//satellite
                }
				else if(url.indexOf("pgis@") == 0)
                {
					baseLayer = new PGisTileLayer(url.replace(/pgis@/,""),options==null?null:options[index]);
                }
				else if(url.toUpperCase().indexOf("bmap@") == 0)
                {
					baseLayer = new BMapLayer();
                }
				else if(url.toLowerCase().indexOf("maplink@") == 0)
				{
					baseLayer = new MapLinkLayer(url.replace(/maplink@/,""),options==null?null:options[index]);
				}	
				else
                {
					baseLayer = new ArcGISTiledMapServiceLayer(url);
                }
                baseLayer.id = url;//为图层添加自定义编号
				map.addLayer(baseLayer);
				baseLayer.refresh();
			}
			for(var i:int=0; i<map.layerIds.length-1; i++){
				var layer:Layer = map.layers[i] as Layer;
				layer.visible = false;
			}
//			map.addLayer(clientLayer);
		}
	}
}