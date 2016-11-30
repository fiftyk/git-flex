package net.yhte.gis.cluster
{
	import com.esri.ags.Graphic;
	import com.esri.ags.Map;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.symbols.MarkerSymbol;
	import com.esri.ags.symbols.TextSymbol;
	
	import flash.geom.Point;
	
	import net.yhte.gis.utils.GeomUtil;
	
	public class Cluster
	{
		private var _map:Map;
		private var _graphics:Array = new Array();
		private var _cluster_pixel:Number;
		private var _result:Array = [];
		
		private var _inCluster:Array = [];
		private var _outCluster:Array = [];
		
		public function Cluster(mp:Map,gs:Array=null,pixel:Number=25)
		{
			map = mp;
			graphics = gs;
			cluster_pixel = pixel;
		}
		
		public function get cluster_pixel():Number
		{
			return _cluster_pixel;
		}

		public function set cluster_pixel(value:Number):void
		{
			_cluster_pixel = value;
		}
		
		public function getClusteredGraphics(value:Array=null):Array
		{
			compute(graphics);
			return _result;
		}

		public function get map():Map
		{
			return _map;
		}

		public function set map(value:Map):void
		{
			_map = value;
		}

		public function get graphics():Array
		{
			return _graphics;
		}

		public function set graphics(value:Array):void
		{
			_graphics = value;
		}
		
		private function compute(graphics:Array):void
		{
			for each(var graphic:Graphic in graphics){
				if(_inCluster.length==0 || distance(Graphic(_inCluster[0]),graphic) <= cluster_pixel){
					_inCluster.push(graphic);
				}else{
					_outCluster.push(graphic);
				}
			}
			_result.push(fusion(_inCluster));
			_inCluster  =  [];
			if(_outCluster.length>0){
				var t:Array = _outCluster.concat();
				_outCluster =[];
				compute(t);
			}
		}
		
		/**
		 * 合并相互靠经的点位
		 * @param incluster
		 */
		private function fusion(incluster:Array):Graphic
		{
			var num:Number = incluster.length;
			var totalX:Number = 0;
			var totalY:Number = 0;
			
			var attributes:Object = {};
			attributes["__graphics__"] = [];
			attributes["__points__"] = [];
			for each(var graphic:Graphic in incluster){
				var mp:MapPoint = MapPoint(graphic.geometry);
				totalX += mp.x;
				totalY += mp.y;
				attributes["__graphics__"].push(graphic);
				attributes["__points__"].push(mp);
			}
			attributes["__total__"] = num;
			var attr:Object = Graphic(incluster[num-1]).attributes
			for(var key:String in attr){
				attributes[key] = attr[key];
			}
			var geom:MapPoint = new MapPoint(totalX/num,totalY/num);
			var gra:Graphic = new Graphic(geom);
			gra.attributes = attributes;
			return gra;
		}
		
		private function distance(g1:Graphic,g2:Graphic):Number
		{
			var p1:MapPoint = g1.geometry as MapPoint;
			var p2:MapPoint = g2.geometry as MapPoint;
			var sp1:Point = map.toScreen(p1);
			var sp2:Point = map.toScreen(p2);
			var result:Number = GeomUtil.getDistanceBy2Pt([sp1.x,sp1.y],[sp2.x,sp2.y]);
			return result;
		};
	}
}