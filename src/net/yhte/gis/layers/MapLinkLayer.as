package net.yhte.gis.layers
{
	import com.esri.ags.SpatialReference;
	import com.esri.ags.Units;
	import com.esri.ags.events.ZoomEvent;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.layers.DynamicMapServiceLayer;
	import com.esri.ags.utils.WebMercatorUtil;
	
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	/**
	 * MapLink图层
	 */
	public class MapLinkLayer extends DynamicMapServiceLayer
	{
		private var _url:String;
		private var _format:String = "jpg";
		private var _xid:String = "0";
		private var _options:Object;
		private var _urlRequest:URLRequest;
		
		public function MapLinkLayer(url:String="", optionsValue:Object=null, id:String="0",format:String="jpg")
		{
			super();
			setLoaded(true);
			
			if(optionsValue)
				this.options = optionsValue;
			this.url = url;
			this.xid = id;
			this.format = format;
			
		}
		
		public function get options():Object
		{
			return _options;
		}

		public function set options(value:Object):void
		{
			_options = value;
		}

		/**
		 * 序号
		 */
		public function get xid():String
		{
			return _xid;
		}
		
		/**
		 * @private
		 */
		public function set xid(value:String):void
		{
			_xid = value;
		}
		
		/**
		 * 图片格式 
		 */
		public function get format():String
		{
			return _format;
		}
		
		/**
		 * @private
		 */
		public function set format(value:String):void
		{
			_format = value;
		}
		
		/**
		 * 地址
		 */
		public function get url():String
		{
			return _url;
		}
		
		/**
		 * @private
		 */
		public function set url(value:String):void
		{
			_url = value;
			_urlRequest = new URLRequest(_url);
			_urlRequest.method = "GET";
		}
		
		override protected function loadMapImage(loader:Loader):void
		{
			var extent:Extent = WebMercatorUtil.webMercatorToGeographic(map.extent) as Extent;
			var rb:Number = -1 * 100000 * extent.ymin;
			var rl:Number = 100000 * extent.xmin;
			var rr:Number = 100000 * extent.xmax;
			var rt:Number = -1 * 100000 * extent.ymax;
			var sc:Number = map.width/(rr - rl);
			
			var optStr:String = "";
			if(_options){
				for(var key:String in _options){
					optStr += "&" + key + "=" + _options[key]; 
				}
			}
			
			_urlRequest.url = this.url +
				"?method=getimg" +
				"&ch="+map.height.toString() + 
				"&cw=" + map.width.toString() + 
				"&id=" + this.xid +
				"&rl=" + rl +
				"&rr=" + rr +
				"&rt=" + rt +
				"&rb=" + rb +
				"&sc=" + sc +
				"&format=" + this.format +
				optStr
			trace(_urlRequest.url);	
			loader.load(_urlRequest);
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
		
		override public function get spatialReference():SpatialReference
		{
			return new SpatialReference(102113);
		}
		
		override public function get units():String
		{
			return Units.METERS;
		}
		
		
		
	}
}