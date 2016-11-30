package net.yhte.gis.module.baseModule
{
    import com.esri.ags.Map;
    
    import mx.modules.ModuleBase;
    
    import net.yhte.gis.tools.LayerTool;
    
	[Bindable]
    public class BaseMapModule extends ModuleBase implements IMapModule
    {
        private var _map:Map;
        private var _layerTool:LayerTool;
		private var _config:*;
        /**
         * 地图Module基类 
         * 
         */        
        public function BaseMapModule()
        {
            super();
        }
        public function get map():Map
        {
            return _map;
        }
        public function set map(value:Map):void
        {
            _map = value;
        }
        public function get layerTool():LayerTool
        {
            return _layerTool;
        }
        public function set layerTool(value:LayerTool):void
        {
            _layerTool = value;
        }
		public function get config():*
		{
			return _config;
		}
		public function set config(value:*):void
		{
			_config = value;
		}
		
		public function init():void{
		
		}
    }
}