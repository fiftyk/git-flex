package net.yhte.gis.layers
{
	import com.esri.ags.Graphic;
	import com.esri.ags.events.ExtentEvent;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.utils.JSON;
	import com.esri.ags.utils.WebMercatorUtil;
	
	import flash.events.Event;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import net.yhte.gis.cluster.Cluster;
	import net.yhte.gis.utils.AttrUtil;
	import net.yhte.gis.utils.TrackUtil;
	
	public class JsonLayer extends GraphicsLayer
	{
		private var _jsonData:Array;
		private var _url:String;
		private var _refreshTime:Number;
		private var intervalId:uint;
		
		public var xfield:String = "x";
		public var yfield:String = "y";
		public var dataRoot:String;
		public var srs:String="4326*00000";
		private var trackUtil:TrackUtil = new TrackUtil();
		private var cluster:Cluster;
		
		public var clusterLevel:int = 9;//禁用cluster的等级
		public var clusterCount:int = 250;//禁用cluster的元素数量
		public var clusterable:Boolean=false;//是否启用cluster
		public var trackable:Boolean = false;//是否启用track(轨迹)
		public var pk:String;//主键字段，用于track
		
		public function JsonLayer()
		{
			super();
		}
		
		public function get refreshTime():Number
		{
			return _refreshTime;
		}

		public function set refreshTime(value:Number):void
		{
			_refreshTime = value;
			clearInterval(intervalId);
			if(value > 0){
				intervalId = setInterval(function():void{
					refresh();
				},value*1000);
			}
		}

		public function get url():String
		{
			return _url;
		}

		public function set url(value:String):void
		{
			_url = value;
			getData();
		}
		
		override public function refresh():void
		{
			super.refresh();
			if(_url)
				getData();
		}
		
		public function loopAttribute(key:String,value:*):void
		{
			for each(var g:Graphic in graphicProvider)
			{
				g[key] = value;
			}
		}
		
		public function loopMethod(method:String,params:Array):void
		{
			for each(var g:Graphic in graphicProvider)
			{
				g[method].apply(null,params);
			}
		}
		
		private function getData():void{
			var http:HTTPService = new HTTPService();
			http.url = _url;
			http.addEventListener(ResultEvent.RESULT,onResult);
			http.addEventListener(FaultEvent.FAULT,onFault);
			http.send({timeId:new Date().getTime()});
		}
		
		private function onResult(e:ResultEvent):void{
			var data:Object = JSON.decode(e.result.toString());
			if(dataRoot){
				jsonData = AttrUtil.getVal(data,dataRoot);
			}else{
				jsonData = data as Array;
			}
			dispatchEvent(new Event("RDataLoaded"));
		}
		
		private function onFault(e:Event):void{
			trace(e);
		}
		
		public function get jsonData():Array
		{
			return _jsonData;
		}

		public function set jsonData(value:Array):void
		{
			_jsonData = value;
			if( !(_jsonData is Array) ){//如果不是array，立即返回
				return;
			}
			var len:Number = _jsonData.length;
			var features:Array = [];
			for(var i:int=0;i<len;i++){
				var row:Object = _jsonData[i];
				var g:Graphic = obj2Graphic(row);
				g.autoMoveToTop = false;
				features.push(g);
			}
			
			if(len < 250 || map.level > 9)
			{
				this.graphicProvider =features;
			}
			else
			{
				cluster = new Cluster(map,features)
				this.graphicProvider = cluster.getClusteredGraphics();
				map.addEventListener(ExtentEvent.EXTENT_CHANGE,onExtentChanged);
			}
			if(trackable && pk)
			{
				trackUtil.addPoints(this.graphicProvider.source,pk).getTrackLines(this);
			}
			
			dispatchEvent(new Event("GraphicsAdded"));
		}
		
		public function Get(key:String,val:Object):Graphic
		{
			var len:int = this.graphicProvider.length
			for(var i:int=0;i<len;i++){
				var value:Object = this.graphicProvider[i].attributes[key];
				if(value == val){
					return this.graphicProvider[i];
				}
			}
			return null;
		}
		
		private function onExtentChanged(e:ExtentEvent):void
		{
			if(e.levelChange){//如果地图等级发生变化
				var features:Array = cluster.graphics;
				var len:int = features.length;
				if(len < clusterCount || map.level > clusterLevel)
				{
					this.graphicProvider =features;
				}
				else
				{
					this.graphicProvider =cluster.getClusteredGraphics();
				}
				if(trackable && pk)
				{
					trackUtil.addPoints(this.graphicProvider.source,pk).getTrackLines(this);
				}
			}
			trace(this.graphicProvider.length)
		}
		
		private function obj2Graphic(row:Object):Graphic{
			var x:Number = AttrUtil.getVal(row,this.xfield);
			var y:Number = AttrUtil.getVal(row,this.yfield);
			var g:Graphic = new Graphic();
			if(srs == "4326*00000"){
				g.geometry = WebMercatorUtil.geographicToWebMercator(new MapPoint(x/100000,y/100000));
			}
			else if(srs == "102113"){
				g.geometry = new MapPoint(x,y);
			}
			g.attributes = row;
			g.symbol = this.symbol;
			
			return g;
		}
	}
}