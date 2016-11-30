package net.yhte.gis.layers.supportClasses
{
    import com.esri.ags.Graphic;
    import com.esri.ags.Map;
    import com.esri.ags.layers.Layer;
    
    import flash.events.EventDispatcher;
    
    public class BaseCrud extends EventDispatcher implements IFeatureCrud
    {
        private var _map:Map;
        private var _layer:Layer;
        
        public function BaseCrud()
        {
        }
        
        public function get map():Map
        {
            return _map;
        }
        
        public function set map(value:Map):void
        {
            _map = value;
        }
        
        public function get layer():Layer
        {
            return _layer;
        }
        
        public function set layer(value:Layer):void
        {
            _layer = value;
        }
        
        public function addFeature(graphic:Graphic):void
        {
        }
        
        public function updateFeature(graphic:Graphic):void
        {
        }
        
        public function removeFeature(graphic:Graphic):void
        {
        }
        
        public function searchFeature(graphic:Graphic):void
        {
        }
    }
}