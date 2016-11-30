package net.yhte.gis.components
{
    import com.esri.ags.Graphic;
    import com.esri.ags.Map;
    import com.esri.ags.events.ExtentEvent;
    import com.esri.ags.events.MapEvent;
    import com.esri.ags.geometry.Extent;
    import com.esri.ags.geometry.MapPoint;
    import com.esri.ags.layers.GraphicsLayer;
    import com.esri.ags.layers.Layer;
    import com.esri.ags.layers.TiledMapServiceLayer;
    import com.esri.ags.symbols.SimpleFillSymbol;
    import com.esri.ags.symbols.SimpleLineSymbol;
    
    import flash.events.MouseEvent;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
    public class OverViewMap extends Map
    {
        private const lineSym:SimpleLineSymbol = new SimpleLineSymbol("solid", 0xFF0000, 0.7, 2);
        private const currentExtentSym:SimpleFillSymbol = new SimpleFillSymbol("solid", 0xFF0000, 0.2, lineSym);
        
        private var xOff:Number;
        private var yOff:Number;
        
        private var _mainMap:Map;
        private var ovGraphic:Graphic = new Graphic();
        private var graphicsLayer:GraphicsLayer = new GraphicsLayer();
        
        
        public function OverViewMap(map:Map=null)
        {
            super();
            if(map)
            {
                mainMap = map;
            }
        }
        
        public function get mainMap():Map
        {
            return _mainMap;
        }
        
        public function set mainMap(value:Map):void
        {
            _mainMap = value;
            logoVisible = false;
            scaleBarVisible = false;
            zoomSliderVisible = false;
            clickRecenterEnabled=false;
            doubleClickZoomEnabled=false;
            keyboardNavigationEnabled=false;
            panArrowsVisible=false;
            panEnabled=false;
            rubberbandZoomEnabled=false;
            scrollWheelZoomEnabled=false;
            
            mainMap.addEventListener(MapEvent.LAYER_REORDER,onLayerReorderHandler);
            
            if(mainMap.loaded)//如果主地图已经加载
            {
                loadOvMap();
            }
            else
            {
                mainMap.addEventListener(MapEvent.LOAD,onMainMapLoadedHandler);
            }
        }
        
        private function onLayerReorderHandler(event:MapEvent):void
        {
            loadOvMap();
        }
        
        //获取顶层tile图层，tile图层一般作为底图
        private function getTopTileLayer():TiledMapServiceLayer
        {
//            for each(var layer:Layer in mainMap.layers)
            for(var i:int = mainMap.layerIds.length-1;i>=0;i--)
            {
                var layer:Layer = mainMap.layers[i];
                if(layer is TiledMapServiceLayer)
                {
                    return layer as TiledMapServiceLayer;
                }
            }
            return null;
        }
        
        private function onMainMapLoadedHandler(event:MapEvent):void
        {
            loadOvMap();
        }
        
        private var newLayer:Layer;
        
        private function loadOvMap():void
        {
            addEventListener(MapEvent.LOAD,onOverViewMapLoadedHandler);
            var baseLayer:Layer = getTopTileLayer();
            var klass:Class = getDefinitionByName(getQualifiedClassName(baseLayer)) as Class;
            newLayer = new klass();
            try
            {
                newLayer["url"] = baseLayer["url"];
            }catch(e:Error)
            {//hack gmap layer
                newLayer["mapStyle"] = baseLayer["mapStyle"];
            }
            this.removeAllLayers();
            this.addLayer(newLayer);
            this.addLayer(graphicsLayer);
        }
        
        protected function onOverViewMapLoadedHandler(event:MapEvent):void
        {
            this.addLayer(graphicsLayer);
            graphicsLayer.symbol = currentExtentSym;
            ovGraphic.geometry = mainMap.extent;
            
            ovGraphic.geometry = mainMap.extent;
            ovGraphic.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            ovGraphic.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
            ovGraphic.useHandCursor = true;
            addEventListener(MouseEvent.MOUSE_OUT, mouseUpHandler);
            
            graphicsLayer.add(ovGraphic);//添加
            
            mainMap.addEventListener(ExtentEvent.EXTENT_CHANGE, setOverviewExtent);
            updateOverviewExtent();
        }
        
        private function setOverviewExtent(event:ExtentEvent):void
        {
            updateOverviewExtent();
        }
        
        private function updateOverviewExtent():void
        {
            extent = mainMap.extent.expand(3);
            ovGraphic.geometry = mainMap.extent;
        }
        
        private function mouseDownHandler(event:MouseEvent):void
        {
            var ext:Extent = ovGraphic.geometry as Extent;
            var mPt:MapPoint = this.toMapFromStage(event.stageX, event.stageY);
            xOff = ext.center.x - mPt.x;
            yOff = ext.center.y - mPt.y;
            ovGraphic.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
        }
        
        private function mouseMoveHandler(event:MouseEvent):void
        {
            var mPt:MapPoint = this.toMapFromStage(event.stageX, event.stageY);
            var tempX:Number = mPt.x + xOff;
            var tempY:Number = mPt.y + yOff;
            var ext:Extent = ovGraphic.geometry as Extent;
            var newext:Extent = new Extent(tempX - ext.width / 2, tempY - ext.height / 2, tempX + ext.width / 2, tempY + ext.height / 2);
            ovGraphic.geometry = newext;
            if (!event.buttonDown)
            {
                ovGraphic.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
            }
        }
        
        private function mouseUpHandler(event:MouseEvent):void
        {
            mainMap.extent = ovGraphic.geometry as Extent;
            ovGraphic.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
        }
    }
}