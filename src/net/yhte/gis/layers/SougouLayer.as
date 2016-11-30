package net.yhte.gis.layers
{
    import com.esri.ags.SpatialReference;
    import com.esri.ags.geometry.Extent;
    import com.esri.ags.geometry.MapPoint;
    import com.esri.ags.layers.TiledMapServiceLayer;
    import com.esri.ags.layers.supportClasses.LOD;
    import com.esri.ags.layers.supportClasses.TileInfo;
    
    import flash.net.URLRequest;
    /**
     * sougou栅格地图服务图层
     * 
     * @author 刘荣涛
     * @version 2011.12.06
     */
    public class SougouLayer extends TiledMapServiceLayer
    {
        private var _tileInfo:TileInfo = new TileInfo();  
        private var tileUrls:Array = [
            "http://p0.go2map.com/seamless1/0/174/", 
            "http://p1.go2map.com/seamless1/0/174/",
            "http://p2.go2map.com/seamless1/0/174/", 
            "http://p3.go2map.com/seamless1/0/174/"];
        
        public function SougouLayer()
        {
            super();
            buildTileInfo();
            setLoaded(true);
        }
        
        override public function get fullExtent():Extent   
        {   
            return new Extent(-180,-90,180,90, new SpatialReference(4326));   
        }   
        
        override public function get initialExtent():Extent   
        {   
            return new Extent(-180,-90,180,90, new SpatialReference(4326));  
        }   
        
        override public function get spatialReference():SpatialReference   
        {   
            return new SpatialReference(4326);   
        }   
        
        override public function get tileInfo():TileInfo   
        {   
            return _tileInfo;   
        }   
        
        override protected function getTileURL(zoom:Number, row:Number, col:Number):URLRequest   
        {   
            
            zoom = zoom - 2;
            
            var offsetX:Number = Math.pow(2,zoom);
            var offsetY:Number = offsetX - 1;
            
            var numX:Number = col - offsetX;
            var numY:Number = (-row) + offsetY;
            
            zoom = zoom + 1;
            
            var l:int = 729 - zoom;
            if (l == 710) l = 792;
            
            var blo:Number = Math.floor(numX / 200);
            var bla:Number = Math.floor(numY / 200);
            
            var blos:String,blas:String;
            if (blo < 0) 
                blos = "M" + ( - blo);
            else 
                blos = "" + blo;
            if (bla < 0) 
                blas = "M" + ( - bla);
            else 
                blas = "" + bla;
            
            var x:String = numX.toString().replace("-","M");
            var y:String = numY.toString().replace("-","M");
            
            var num:int = (row+col) % tileUrls.length;
            
            var strURL:String = "";
            strURL = tileUrls[num] + l + "/" + blos + "/" + blas + "/" + x + "_" + y + ".GIF";
            
            var urlRequest:URLRequest;
            urlRequest =  new URLRequest(strURL); 
            
            return urlRequest;
        }
        
        private function buildTileInfo():void  
        {   
            _tileInfo.height=256;   
            _tileInfo.width=256;  
            _tileInfo.origin=new MapPoint(0,0); 
            _tileInfo.lods = [];
            for(var i:int = 1;i<19;i++)
            {
                var multiple:Number = Math.pow(2,i-1);
                _tileInfo.lods.push(
                    new LOD(i,0.702359682/multiple,295828763.795777/multiple));
            }
        } 
    }
}