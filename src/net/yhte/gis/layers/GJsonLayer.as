package net.yhte.gis.layers
{
	import com.esri.ags.Graphic;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.utils.JSON;
	
	import flash.events.Event;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import net.yhte.gis.utils.AttrUtil;
	import net.yhte.gis.utils.GraphicUtil2;
	
	public class GJsonLayer extends GraphicsLayer
	{
		private var _jsonData:Array;
		private var _url:String;
		public var dataRoot:String = "items";
		public var gfield:String = "G";
		public function GJsonLayer()
		{
			super();
		}

		public function get jsonData():Array
		{
			return _jsonData;
		}

		public function set jsonData(value:Array):void
		{
			_jsonData = value;
			var len:Number = _jsonData.length;
			var features:Array = [];
			for(var i:int=0;i<len;i++){
				var row:Object = _jsonData[i];
				features.push( obj2Graphic(row));
			}
			this.graphicProvider = features;
			dispatchEvent(new Event("GraphicsAdded"));
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
		
		private function obj2Graphic(row:Object):Graphic{
			var g:Graphic = new Graphic();
			var G:* = AttrUtil.getVal(row,gfield);
			g = GraphicUtil2.JSON2Graphic(G);
			if(!g.attributes){
				g.attributes = {};
			}
			for(var key:String in row){
				if(key != gfield){
					g.attributes[key] = row[key];
				}
			}
			return g;
		}
	}
}