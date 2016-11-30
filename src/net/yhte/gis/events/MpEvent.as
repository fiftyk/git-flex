package net.yhte.gis.events
{
	import com.esri.ags.Graphic;
	import com.esri.ags.layers.Layer;
	
	import flash.events.Event;
	
	public class MpEvent extends Event
	{
        /**
         * 图层数据加载成功后触发此事件 
         */        
		public static const JSON_LOAD_SUCCESS:String = "jsonLoadSuccess";
        /**
         * 图层数据加载失败后触发此事件 
         */ 
		public static const FEATURES_LOAD_ERROR:String = "featuresLoadError";
		/**
		 * 图层框选查询完成事件
		 */		
		public static const LYR_QUERY:String = "lyr_query";
		/**
		 * 图层点选MouseClick事件
		 */		
		public static const LYR_IDENTIFY_CLICK:String = "lyr_identify_click";
		/**
		 * 图层点选MouseOver事件
		 */		
		public static const LYR_IDENTIFY_OVER:String = "lyr_identify_over";
		/**
		 * 动态轨迹刻画事件
		 */ 
		public static const TRACE_RUN:String = "trace_run";
		/**
		 * 轨迹演示中
		 */
		public static const TRACE_MOVING:String = "moving";
		
		public var data:Object = null;
		
		public var layer:Layer;
        /**
         * 图层框选时，被选中点集合
         */
		public var queryResults:Array;
        /**
        * 图层点选时，被选中点
        */
		public var identifyGraphic:*;
		/**
		 * 动态刻画轨迹
		 */ 
		public var runGraphic:*;
		public var runNum:Number;
		
		
		public function MpEvent(type:String, val:Object=null)
		{
			data = val;
			super(type, false, false);
		}
		
	}
}