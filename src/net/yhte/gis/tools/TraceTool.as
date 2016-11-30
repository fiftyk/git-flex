package net.yhte.gis.tools
{
	import com.esri.ags.Graphic;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.geometry.Polyline;
	import com.esri.ags.symbols.CompositeSymbol;
	import com.esri.ags.symbols.PictureMarkerSymbol;
	import com.esri.ags.symbols.SimpleMarkerSymbol;
	import com.esri.ags.symbols.TextSymbol;
	import com.esri.ags.utils.GraphicUtil;
	import com.esri.ags.utils.WebMercatorUtil;
	
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import net.yhte.gis.events.MpEvent;
	
	public class TraceTool extends EventDispatcher
	{
		private static var instance:TraceTool;
		private var _layerTool:LayerTool;
		
		private var _graphicArray:Array;
		private var i:Number = 0;
		private var j:Number = 0;
		private var interval:uint;
		private var num:Number;
		private var addX:Number;
		private var addY:Number;
		private var startPoint:MapPoint;
		private var endPoint:MapPoint;
		private var pointGra:Graphic;
		private var carGra:Graphic;
		
		/**
		 * 动态刻画轨迹的时间间隔（单位：毫秒）
		 */
		public var traceTime:int = 2000;
		/**
		 * 动态刻画轨迹每次刻画的长度（单位：米）
		 */
		public var traceLength:int = 2000;
		/**
		 * 动态刻画轨迹小车图片的路径
		 */ 
		public var carImageSouce:String;
		/**
		 * 重合点闪烁时间间隔（单位：毫秒）
		 */
		public var refreshTime:int = -1;
		/**
		 * 动态刻画轨迹计数器id
		 */
		public var MyInterval:uint;
		/**
		 * 动态刻画轨迹计数器数组
		 */ 
		public var intervalArray:Array = new Array();
		/**
		 * 重合点数组
		 */
		public var refreshArray:Array = new Array();
		
		public var refreshColorArray:Array = [0xFF3030, 0x0000FF, 0x66CDAA, 0xFF4040, 0x0D0D0D, 0x6495ED, 0xFF7256, 0x1E90FF, 0x54FF9F, 0xFF0000, 0x00E5EE, 0x4EEE94, 0xFF00FF]
		
		public function get layerTool():LayerTool
		{
			return _layerTool;
		}
		
		public function set layerTool(value:LayerTool):void
		{
			_layerTool = value;
		}
		/**
		 * 构造方法
		 * @param layerTool
		 */ 
		public function TraceTool(layerTool:LayerTool)
		{
			super();
			if(instance != null){
				throw new Error("请使用getInstance方法初始化！");
			}
			this.layerTool = layerTool;
		}
		/**
		 * 获取TraceTool实例
		 * @param layerTool
		 */
		public static function getInstance(layerTool:LayerTool):TraceTool
		{
			if(instance == null){
				instance = new TraceTool(layerTool);
			}
			return instance;
		}
		
		/**
		 * 添加动态路径.
		 * 安装graphicArray中顺序动态展示，如果是线状Graphic,并且长度较长时，将进行分段展示
		 * @param {} graphicArray 待动态展示的Graphic数组
		 */
		public function addTrace(graphicArray:Array):int
		{
			if(!checkGraArray(graphicArray)){
				throw new Error("传入参数graphicArray格式不对");
				return;
			}
			//停止正在刻画的轨迹
			stopTrace();
			i=0;
			_graphicArray = graphicArray;
			
			if(carImageSouce){
				var picSymbol:PictureMarkerSymbol = new PictureMarkerSymbol(carImageSouce);
				carGra = new Graphic(new MapPoint(0,0),picSymbol);
				_layerTool.clientLayer.add(carGra);
			}
			
			if(traceTime<=0){//立即显示
				addGraphcImme();
				return -1;	
			}else{
				MyInterval=setInterval(addGra,traceTime);
				intervalArray.push(MyInterval);
				return MyInterval;	
			}
			
			
		}
		
		/**
		 * 停止动态刻画轨迹
		 * @param {} traceId 轨迹ID
		 */ 
		public function stopTrace():void{
			//清除小车图标
			_layerTool.clientLayer.remove(carGra);
			for(var i:int=0;i<intervalArray.length;i++){
				clearInterval(intervalArray.pop());
			}
		}
		
		/**
		 * 立即刻画轨迹
		 */ 
		private function addGraphcImme():void{
			if(_graphicArray.length == 1){
				var e2:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
				e2.runGraphic = _graphicArray[0];
				dispatchEvent(e2);
			}
			for(var i:int=0; i<_graphicArray.length; i++){
				var activeGra:Graphic = _graphicArray[i];
				if(_graphicArray[i].geometry.type == "esriGeometryPolyline"){
					activeGra.autoMoveToTop = false;
				}
				_layerTool.clientLayer.add(activeGra);
				if(_graphicArray[i].geometry.type == "esriGeometryPolyline"){
					pointGra = _graphicArray[i-1];
					_layerTool.clientLayer.moveToTop(pointGra);
				}
				if(activeGra.geometry.type == "esriGeometryPoint"){
					addRefreshArray(activeGra);
				}
				
			}
			var extent:Extent = GraphicUtil.getGraphicsExtent(_graphicArray);
			if(extent){
				var g:Graphic = new Graphic(extent.center);
				var e:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
				e.runGraphic = g;
				dispatchEvent(e);
			}else{//范围为null时，直接返回第一个点
				var event:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
				event.runGraphic = _graphicArray[0];
				dispatchEvent(event);
			}
		}
		
		
		private function addGra():void{
			if(i>=_graphicArray.length-1){
				clearInterval(MyInterval);
				setTimeout(function():void{
					_layerTool.clientLayer.remove(carGra);
				}, 3000);
			}
			var graphic:Graphic = _graphicArray[i];
			if(graphic.geometry.type == "esriGeometryPolyline"){
				pointGra = _graphicArray[i-1];
				var geom:Polyline = graphic.geometry as Polyline;
				startPoint = geom.getPoint(0, 0);
				endPoint = geom.getPoint(0, 1);
				if(_layerTool.map.spatialReference.wkid == 4326){//84坐标系需要转换比较
					var tmpStart:MapPoint = WebMercatorUtil.geographicToWebMercator(startPoint) as MapPoint;
					var tmpEnd:MapPoint = WebMercatorUtil.geographicToWebMercator(endPoint) as MapPoint;
					var length:Number = (tmpStart.x-tmpEnd.x)*(tmpStart.x-tmpEnd.x)+(tmpStart.y-tmpEnd.y)*(tmpStart.y-tmpEnd.y);
					trace("length2="+length+"  traceLength*traceLength="+traceLength*traceLength);
					num = Math.floor(Math.sqrt(length/(traceLength*traceLength)));
					trace("num="+num);
					
					var k:Number = (endPoint.y-startPoint.y)/(endPoint.x-startPoint.x);
					var flagX:Number = endPoint.x>startPoint.x?1:-1;
					var flagY:Number = endPoint.y>startPoint.y?1:-1;
					addX = (endPoint.x - startPoint.x)/num;
					addY = (endPoint.y - startPoint.y)/num;
				}else{
					var length2:Number = (startPoint.x-endPoint.x)*(startPoint.x-endPoint.x)+(startPoint.y-endPoint.y)*(startPoint.y-endPoint.y);
					trace("length2="+length2+"  traceLength*traceLength="+traceLength*traceLength);
					num = Math.floor(Math.sqrt(length2/(traceLength*traceLength)));
					trace("num="+num);
					
					var k2:Number = (endPoint.y-startPoint.y)/(endPoint.x-startPoint.x);
					var flagX2:Number = endPoint.x>startPoint.x?1:-1;
					var flagY2:Number = endPoint.y>startPoint.y?1:-1;
					addX = Math.sqrt((traceLength*traceLength)/(1+k2*k2))*flagX2;
					addY = Math.sqrt((traceLength*traceLength)/(1+1/(k2*k2)))*flagY2;
				}
				
				
				if(num < 2){//不需要分段，直接将整段线段添加
					graphic.autoMoveToTop = false; 
					_layerTool.clientLayer.add(graphic);
					var e:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
					e.runGraphic = graphic;
					e.runNum = i;
					dispatchEvent(e);
				}else{//需要分段
					clearInterval(MyInterval);
					j=1;
					addPath(graphic, num);
					interval = setInterval(function():void{addPath(graphic, num);}, traceTime);
					intervalArray.push(interval);
				}
				_layerTool.clientLayer.moveToTop(_graphicArray[i-1]);
			}else{
				_layerTool.clientLayer.add(graphic);
				//加入重合点数组
				addRefreshArray(graphic);
				//汽车图标刷新
				updateCar(graphic.geometry as MapPoint);
				
				var e2:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
				e2.runGraphic = graphic;
				e2.runNum = i;
				dispatchEvent(e2);
				
			}
			i++;
		}
		
		private function callBackHandler(g:Graphic):Object{
			var attr:Object = g.attributes;	
			var geom:Geometry = g.geometry;
			var screen:Point;
			if(geom.type == "esriGeometryPoint"){
				screen = _layerTool.map.toScreen(geom as MapPoint);
			}else{//geometry不是点时，返回范围的中心点
				var centerPoint:MapPoint = geom.extent.center;
				screen = _layerTool.map.toScreen(centerPoint);
				geom = centerPoint;
			}
			return{
				geometry:geom,
				screenXY:{x:screen.x,y:screen.y},
				attributes:attr
			}
		}
		
		private function addPath(redrawGra:Graphic, num:Number):void{
			var mpline:Polyline;
			var geom:Geometry = redrawGra.geometry;
			if(j>=num){
				MyInterval= setInterval(addGra,traceTime);
				intervalArray.push(MyInterval);
				clearInterval(interval);
			}
			if(j==1){
				var pointArray:Array = new Array();
				pointArray.push(startPoint);
				var mppoi1:MapPoint
				var x1:Number = addX + startPoint.x;
				var y1:Number = addY + startPoint.y;
				mppoi1 = new MapPoint(x1,y1);
				
				pointArray.push(mppoi1);
				mpline = new Polyline([pointArray]);
				redrawGra.geometry = mpline;
				redrawGra.autoMoveToTop = false;
				_layerTool.clientLayer.add(redrawGra);
				_layerTool.clientLayer.moveToTop(pointGra);
				
				//汽车图标刷新
				trace(mppoi1+"   j=="+ j);
				updateCar(mppoi1);
				
				var e:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
				e.runGraphic = redrawGra;
				e.runNum = i;
				dispatchEvent(e);
			}
			else if(j == num){
				mpline = redrawGra.geometry as Polyline;
				mpline.insertPoint(0, mpline.paths[0].length, endPoint);
				redrawGra.refresh();
				
				//汽车图标刷新
				trace(endPoint+"   j=="+ j);
				updateCar(endPoint);
				
				var e2:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
				e2.runGraphic = redrawGra;
				e2.runNum = i;
				dispatchEvent(e2);
			}else{
				var mppoi:MapPoint;
				var x:Number = addX*j + startPoint.x;
				var y:Number = addY*j + startPoint.y;
				mppoi = new MapPoint(x,y);
				
				mpline = redrawGra.geometry as Polyline;
				mpline.insertPoint(0, mpline.paths[0].length, mppoi);
				redrawGra.refresh();
				
				//汽车图标刷新
				trace(mppoi+"   j=="+ j);
				updateCar(mppoi);
				
				var e3:MpEvent = new MpEvent(MpEvent.TRACE_RUN);
				e3.runGraphic = redrawGra;
				e3.runNum = i;
				dispatchEvent(e3);
			}
			j++;
		};
		
		private function updateCar(mppoint:MapPoint):void{
			if(carImageSouce){
				carGra.geometry = mppoint;
				carGra.refresh();
				_layerTool.clientLayer.moveToTop(carGra);
			}
		}
		
		/**
		 * 验证传入参数是否正确，正确参数格式应为:[点,线，点*,*点，线，点]
		 *  @param {} graphicArray 待验证的Graphic数组
		 */ 
		private function checkGraArray(graphics:Array):Boolean{
			//验证传入参数是否正确
			if(graphics != null && graphics.length >0){
				var num:Number = graphics.length;
				if(graphics[0].geometry.type == "esriGeometryPolyline" || graphics[num-1].geometry.type == "esriGeometryPolyline"){
					return false;
				}
				return true;
			}else{
				return false;
			}
		}
		
		//加入重合点数组
		private function addRefreshArray(graphic:Graphic):void{
			var symbol:CompositeSymbol = graphic.symbol as CompositeSymbol;
			var simpleSymbol:SimpleMarkerSymbol = symbol.symbols[0];
			var size:Number = simpleSymbol.size;
			for each(var array:Array in refreshArray){
				for each(var g:Graphic in array){
					var p:MapPoint = g.geometry as MapPoint;
					var point:MapPoint = graphic.geometry as MapPoint;
					var screenP1:Point = _layerTool.map.toScreen(point);
					var screenP2:Point = _layerTool.map.toScreen(p);
					trace((screenP1.x-screenP2.x)*(screenP1.x-screenP2.x) + (screenP1.y-screenP2.y)*(screenP1.y-screenP2.y)+"   "+2*size*2*size);
					if((screenP1.x-screenP2.x)*(screenP1.x-screenP2.x) + (screenP1.y-screenP2.y)*(screenP1.y-screenP2.y) <= 2*size*2*size){
						array.push(graphic);
						if(array.length == 2 && refreshTime>0){
							setInterval(function():void{refreshGraArray(array);}, refreshTime);
						}
						return;
					}
				}
			}
			var a:Array = new Array();
			a.push(graphic);
			refreshArray.push(a);
		}
		
		//闪烁图像数组
		private function refreshGraArray(graArray:Array):void{
			if(graArray.length<2){
				return;
			}
			var g:Graphic = graArray.shift();
			var color:uint = refreshColorArray.shift() as uint;
			var symbol:CompositeSymbol = g.symbol as CompositeSymbol;
			var textSymbol:TextSymbol = symbol.symbols[1] as TextSymbol;
			textSymbol.color = color;
			_layerTool.clientLayer.moveToTop(g);
			graArray.push(g);
			refreshColorArray.push(color);
			trace("闪烁：         "+color);
		}
		
	}
}