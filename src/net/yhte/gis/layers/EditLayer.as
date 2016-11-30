package net.yhte.gis.layers
{
	import com.esri.ags.Graphic;
	import com.esri.ags.events.ExtentEvent;
	import com.esri.ags.events.LayerEvent;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.symbols.Symbol;
	import com.esri.ags.utils.JSON;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import net.yhte.gis.events.MpEvent;
	import net.yhte.gis.layers.supportClasses.Column;
	import net.yhte.gis.layers.supportClasses.IFeatureCrud;
	import net.yhte.gis.utils.AttrUtil;
	import net.yhte.gis.utils.GraphicUtil2;
	
	public class EditLayer extends GraphicsLayer
	{
		private var _url:String;
		private var _symbol:Symbol;
		private var _featureCrud:IFeatureCrud;
		private var _pk:String;//主键字段
		private var _columns:Array;
		public function get columns():Array
		{
			return _columns;
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
		 * 样式 
		 * @return 
		 * 
		 */		
		override public function get symbol():Symbol
		{
			return _symbol;
		}
		/**
		 * @private
		 */
		override public function set symbol(value:Symbol):void
		{
			_symbol = value;
		}
		
		public function EditLayer(url:String=null)
		{
			//TODO: implement function
			super();
			if(url){
				this.url = url;
			}
			addEventListener(Event.ADDED,onAddedHandler);
		}
		
		protected function onAddedHandler(event:Event):void
		{
			if(_url != null){
				getLayerInfo();
				if(map != null){
					loadData();
				}
			}
			removeEventListener(Event.ADDED,onAddedHandler);
		}
		
		public function set url(value:String):void{
			value = value.replace(/\/$/,"");
			if(_url != value){
				_url = value;
			}
		}
		
		public function get url():String{
			return _url;
		}
		
		override protected function addMapListeners():void{
			if(map!=null && _url != null){
				map.addEventListener(ExtentEvent.EXTENT_CHANGE, extentChangeHandler);
				//				map.addEventListener(ZoomEvent.ZOOM_START, this.zoomStartHandler);
				//				map.addEventListener(ZoomEvent.ZOOM_UPDATE, this.zoomUpdateHandler);
				//				map.addEventListener(ZoomEvent.ZOOM_END, this.zoomEndHandler);
				//				getLayerInfo();
				//				loadData();
			}
		} 
		
		private function loadData():void{
			//			var extent:Extent = map.extent;
			
			var _queryParams:Object = {};
			//			_queryParams.bbox = extent.xmin + "," + extent.ymin + "," 
			//				+ extent.xmax + "," + extent.ymax;
			//			_queryParams.size = map.width + "," + map.height;
			
			var wkid:Number = map.spatialReference.wkid;
			_queryParams["inSR"] = 4326;
			_queryParams["outSR"] = wkid;
			_queryParams["outFields"] = "*";
			_queryParams["timeId"] = new Date().time;
			
			var _httpService:HTTPService = new HTTPService();
			_httpService.method = "POST";
			_httpService.url = _url + '/query';
			_httpService.addEventListener(ResultEvent.RESULT,function(re:ResultEvent):void{
				var records:Object = JSON.decode(re.result as String);
				var fields:Array = records.fields as Array;
				var graphics:Array = [];
				if(symbol){
					if(records.type === "linestring")
					{
						for each(var feature:Object in records.features)
						{
							var g:Graphic = getGraphic(feature, fields);
							g.symbol = symbol;
							graphics.push(g);
						}
					}
					graphicProvider = graphics;
				}else{
					if(records.type === "linestring")
					{
						for each(var feature2:Object in records.features)
						{
							graphics.push(getGraphic(feature2, fields));
						}
					}
					graphicProvider = graphics;
				}
			});
			_httpService.addEventListener(FaultEvent.FAULT,function(f:FaultEvent):void{
				dispatchEvent(new MpEvent(MpEvent.FEATURES_LOAD_ERROR,f));
			});
			
			_httpService.send(_queryParams);
		}
		
		private function getGraphic(features:Object, fields:Array):Graphic
		{
			var pk:* = features[1];
			var g:Graphic;
			if(_graphicsPool.hasOwnProperty(pk))
			{
				g =  _graphicsPool[pk] as Graphic;
			}
			else
			{
				g = new Graphic();
				_graphicsPool[pk] = g;
			}
			g.geometry = GraphicUtil2.linestring2polyline(features[0]);
			var attrValue:Array = features as Array;
			attrValue = attrValue.splice(1);
			var attrName:Array = fields.slice(1);
			g.attributes =  AttrUtil.zip(attrName, attrValue);
			return g;
		}
		private var _graphicsPool:Dictionary = new Dictionary();
		
		override protected function extentChangeHandler(e:ExtentEvent):void{
			loadData();
			dispatchEvent(new LayerEvent(LayerEvent.UPDATE_END, this, null, true));
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