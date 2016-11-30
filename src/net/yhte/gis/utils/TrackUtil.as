package net.yhte.gis.utils
{
	import com.esri.ags.Graphic;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.geometry.Polyline;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.symbols.CompositeSymbol;
	import com.esri.ags.symbols.SimpleLineSymbol;
	import com.esri.ags.symbols.SimpleMarkerSymbol;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	public class TrackUtil extends EventDispatcher
	{
		private var _store:Dictionary = new Dictionary();
		
		private var _maxstop:int = 5;
		
		public function get max_stop():int
		{
			return _maxstop;
		}
		
		public function set max_stop(value:int):void
		{
			_maxstop = value; 
		}
		
		public function TrackUtil(value:int=5)
		{
			super();
			max_stop = value;
		}
		
		/**
		 * 添加轨迹点
		 */
		public function addPoints(points:Array,key:String):TrackUtil
		{
			var size:int = points.length;
			for(var i:int=0;i<size;i++)
			{
				var point:Graphic;
				point = points[i] as Graphic;
				var geom:Geometry = point.geometry;
				if(!(geom is MapPoint))
				{//如果不是点元素
					continue;
				}
				var keyValue:* = AttrUtil.getVal(point.attributes,key);
				if(_store.hasOwnProperty(keyValue))
				{
					if(_store[keyValue].length == 5)
					{
						_store[keyValue].splice(0,1);
					}
					_store[keyValue].push(geom);
				}
				else
				{
					_store[keyValue] = [geom];
				}
			}
			return this;
		}
		
		/**
		 * 返回轨迹线
		 */
		public function getTrackLines(layer:GraphicsLayer=null):Array
		{
			var result:Array = [];
			for(var key:String in _store)
			{
				var count:int = _store[key].length;
				if(count > 1)
				{
					var line:Polyline = new Polyline([]);
					line.paths.push(_store[key]);
					if(layer)
					{
						var g:Graphic = new Graphic(line);
						g.symbol = new CompositeSymbol([
							new SimpleLineSymbol("solid",0x00ff00,0.8),
							new SimpleMarkerSymbol(SimpleMarkerSymbol.STYLE_SQUARE,5,0x00ff00,0.8)
						]);
						layer.add(g);
					}
					result.push(line);
				}
			}
			trace("track count：",result.length);
			return result;
		}
	}
}