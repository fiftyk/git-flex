package net.yhte.gis.module.baseModule
{
    import com.esri.ags.Map;
    
    import flash.events.IEventDispatcher;
    
    import net.yhte.gis.tools.LayerTool;
    /**
     * 地图Module接口 
     * 
     */   
    public interface IMapModule extends IEventDispatcher
    {
        /**
         * 地图对象 
         * @return 
         * 
         */ 
        function get map():Map;
        /**
        * @private
        */
        function set map(value:Map):void;
        /**
         * 图层管理工具 
         * @return 
         * 
         */ 
        function get layerTool():LayerTool;
        /**
         * @private
         */
        function set layerTool(value:LayerTool):void;
		
		function get config():*;
		function set config(value:*):void;
		
		function init():void;
    }
}