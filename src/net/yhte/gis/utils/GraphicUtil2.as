package net.yhte.gis.utils
{
    import com.esri.ags.Graphic;
    import com.esri.ags.geometry.Geometry;
    import com.esri.ags.geometry.MapPoint;
    import com.esri.ags.geometry.Polygon;
    import com.esri.ags.geometry.Polyline;
    import com.esri.ags.symbols.CompositeSymbol;
    import com.esri.ags.symbols.PictureMarkerSymbol;
    import com.esri.ags.symbols.SimpleFillSymbol;
    import com.esri.ags.symbols.SimpleLineSymbol;
    import com.esri.ags.symbols.SimpleMarkerSymbol;
    import com.esri.ags.symbols.Symbol;
    import com.esri.ags.symbols.TextSymbol;
    import com.esri.ags.utils.JSON;
    
    import flash.text.TextFormat;
    
    import mx.collections.ArrayCollection;
    
    public class GraphicUtil2
    {
        public static function LS2JSON(symbol:SimpleLineSymbol):Object
        {
            var obj:Object = {
                LS:{
                    a:symbol.alpha,
                        c:symbol.color,
                        s:symbol.style,
                        w:symbol.width
                }
            };
            return obj;
        }
        
        public static function MS2JSON(symbol:SimpleMarkerSymbol):Object
        {
            return {
                MS:{
                    a:symbol.alpha,
                        g:symbol.angle,
                        c:symbol.color,
                        o:symbol.outline?LS2JSON(symbol.outline):null,
                        s:symbol.style,
                        z:symbol.size,
                        x:symbol.xoffset,
                        y:symbol.yoffset
                }
            };
        }
        
        /**
         * SimpleFillSymbol转换为JSON表示
         */
        public static function FS2JSON(symbol:SimpleFillSymbol):Object
        {
            return {
                FS:{
                    o:LS2JSON(symbol.outline),
                    c:symbol.color,
                        a:symbol.alpha,
                        s:symbol.style
                }
            };
        }
        
        public static function PMS2JSON(symbol:PictureMarkerSymbol):Object
        {
            return {
                PMS:{
                    g:symbol.angle,
                        x:symbol.xoffset,
                        y:symbol.yoffset,
                        w:symbol.width,
                        h:symbol.height,
                        s:symbol.source
                }
            };
        }
        
        public static function TS2JSON(symbol:TextSymbol):Object
        {
            var result:Object = {
                TS:{
                    t:symbol.text,
                        c:symbol.color
                }
            };
            if(symbol.textFormat){
                result.TS.s = symbol.textFormat.size
            }
            return result;
        }
        
        public static function CS2JSON(symbol:CompositeSymbol):Object
        {
            var obj:Object = {"CS":[]};
            var symbols:* = symbol.symbols;
            if(symbols){
                var len:int = ArrayCollection(symbols).length;
                for(var i:int=0;i<len;i++)
                {
                    obj["CS"].push(Symbol2JSON(symbols[i]));
                }
            }
            return obj;
        }
        
        public static function Symbol2JSON(symbol:Symbol):Object
        {
            if(symbol is SimpleLineSymbol){
                return LS2JSON(symbol as SimpleLineSymbol);
            }else if(symbol is SimpleMarkerSymbol){
                return MS2JSON(symbol as SimpleMarkerSymbol);
            }else if(symbol is SimpleFillSymbol){
                return FS2JSON(symbol as SimpleFillSymbol);
            }else if(symbol is PictureMarkerSymbol){
                return PMS2JSON(symbol as PictureMarkerSymbol);
            }else if(symbol is TextSymbol){
                return TS2JSON(symbol as TextSymbol);
            }else if(symbol is CompositeSymbol){
                return CS2JSON(symbol as CompositeSymbol);
            }else{
                return null;
            }
        }
        
        public static function MapPoint2JSON(point:MapPoint):Object
        {
            var x:Number  = parseFloat(point.x.toFixed(8));
            var y:Number  = parseFloat(point.y.toFixed(8));
            return {"point":[x,y]};
        }
        
        public static function Polyline2JSON(line:Polyline):Object
        {
            var paths:Array = [];
            for(var i:int=0;i<line.paths.length;i++)
            {
                var path:Array = [];
                for(var j:int=0;j<line.paths[i].length;j++)
                {
                    path.push(MapPoint2JSON(line.paths[i][j] as MapPoint)["point"]);
                }
                paths.push(path);
            }
            return {"polyline":paths};
        }
        
        public static function Polygon2JSON(line:Polygon):Object
        {
            var paths:Array = [];
            for(var i:int=0;i<line.rings.length;i++)
            {
                var path:Array = [];
                for(var j:int=0;j<line.rings[i].length;j++)
                {
                    path.push(MapPoint2JSON(line.rings[i][j] as MapPoint)["point"]);
                }
                paths.push(path);
            }
            return {"polygon":paths};
        }
        
        public static function Geometry2JSON(geometry:Geometry):Object
        {
            if(geometry.type == Geometry.MAPPOINT){
                return MapPoint2JSON(geometry as MapPoint);
            }else if(geometry.type == Geometry.POLYLINE){
                return Polyline2JSON(geometry as Polyline);
            }else if(geometry.type == Geometry.POLYGON){
                return Polygon2JSON(geometry as Polygon);
            }else{
                return null;
            }
        }
        
        public static function Graphic2JSON(graphic:Graphic,
                                            convert_symbol:Boolean=false):Object
        {
            var obj:Object = {};
            obj["G"] = Geometry2JSON(graphic.geometry);
            obj["A"] = graphic.attributes;
            if(convert_symbol)
            {
                obj["S"] = Symbol2JSON(graphic.symbol);
            }
            return obj;
        }
        
        public static function JSON2MS(obj:Object):SimpleMarkerSymbol
        {
            var s:SimpleMarkerSymbol =  new SimpleMarkerSymbol();
            s.alpha = AttrUtil.getVal(obj,"MS.a",1);
            s.angle = AttrUtil.getVal(obj,"MS.g",0);
            s.color = AttrUtil.getVal(obj,"MS.c",0x000000 );
            s.outline = JSON2LS(AttrUtil.getVal(obj,"MS.o"));
            s.style = AttrUtil.getVal(obj,"MS.s","solid");
            s.size = AttrUtil.getVal(obj,"MS.z",15);
            s.xoffset = AttrUtil.getVal(obj,"MS.x",0);
            s.yoffset = AttrUtil.getVal(obj,"MSy",0); 
            return s;
        }
        
        public static function JSON2LS(obj:Object):SimpleLineSymbol
        {
            var s:SimpleLineSymbol =  new SimpleLineSymbol();
            s.alpha = AttrUtil.getVal(obj,"LS.a",1);
            s.color = AttrUtil.getVal(obj,"LS.c",0x000000 );
            s.style = AttrUtil.getVal(obj,"LS.s","solid");
            s.width = AttrUtil.getVal(obj,"LS.w",1);
            return s;
        }
        
        public static function JSON2FS(obj:Object):SimpleFillSymbol
        {
            var s:SimpleFillSymbol =  new SimpleFillSymbol();
            s.alpha = AttrUtil.getVal(obj,"FS.a",1);
            s.color = AttrUtil.getVal(obj,"FS.c",0x000000 );
            s.style = AttrUtil.getVal(obj,"FS.s","solid");
            s.outline = JSON2LS(AttrUtil.getVal(obj,"FS.o"));
            return s;
        }
        
        public static function JSON2PMS(obj:Object):PictureMarkerSymbol
        {
            var s:PictureMarkerSymbol =  new PictureMarkerSymbol();
            s.angle = AttrUtil.getVal(obj,"PMS.g",0);
            s.height = AttrUtil.getVal(obj,"PMS.h");
            s.width = AttrUtil.getVal(obj,"PMS.w");
            s.xoffset = AttrUtil.getVal(obj,"PMS.x",0);
            s.yoffset = AttrUtil.getVal(obj,"PMS.y",0);
            s.source = AttrUtil.getVal(obj,"PMS.s");
            return s;
        }
        
        public static function JSON2TS(obj:Object):TextSymbol
        {
            var s:TextSymbol =  new TextSymbol();
            s.color = AttrUtil.getVal(obj,"TS.c",0x000000);
            s.text = AttrUtil.getVal(obj,"TS.t");
            var size:Number  = AttrUtil.getVal(obj,"TS.s");
            if(size){
                s.textFormat = new TextFormat();
                s.textFormat.size = size;
            }
            return s;
        }
        
        public static function JSON2CS(value:Object):CompositeSymbol
        {
            var symbol:CompositeSymbol = new CompositeSymbol();
            var array:Array = [];
            if(value.hasOwnProperty("CS")){
                for(var i:int=0;i<value["CS"].length;i++)
                {
                    array.push(JSON2Symbol(value["CS"][i]));
                }
            }
            symbol.symbols = array;
            return symbol;
        }
        
        public static function JSON2Symbol(value:Object):Symbol
        {
            if(!value){
                return null;
            }else if(value.hasOwnProperty("LS")){
                return JSON2LS(value);
            }else if(value.hasOwnProperty("MS")){
                return JSON2MS(value);
            }else if(value.hasOwnProperty("FS")){
                return JSON2FS(value);
            }else if(value.hasOwnProperty("PMS")){
                return JSON2PMS(value);
            }else if(value.hasOwnProperty("TS")){
                return JSON2TS(value);
            }else if(value.hasOwnProperty("CS")){
                return JSON2CS(value);
            }else{
                return null;
            }
        }
        
        public static function JSON2MapPoint(value:Object):MapPoint
        {
            return new MapPoint(value.point[0],value.point[1]);	
        }
        
        public static function JSON2Polyline(value:Object):Polyline
        {
            var paths:Array = value.polyline;
            var line:Polyline = new Polyline([]);
            for(var i:int=0;i<paths.length;i++){
                var path:Array = [];
                for(var j:int=0;j<paths[i].length;j++)
                {
                    path.push(JSON2MapPoint({"point":paths[i][j]}));
                }
                line.paths.push(path);
            }
            return line;
        }
        
        public static function JSON2Polygon(value:Object):Polygon
        {
            var paths:Array = value.polygon;
            var line:Polygon = new Polygon([]);
            for(var i:int=0;i<paths.length;i++){
                var path:Array = [];
                for(var j:int=0;j<paths[i].length;j++)
                {
                    path.push(JSON2MapPoint({"point":paths[i][j]}));
                }
                line.rings.push(path);
            }
            return line;
        }
        
        public static function JSON2Geometry(value:Object):Geometry
        {
            if(!value){
                return null;
            }else if(value.hasOwnProperty("point")){
                return JSON2MapPoint(value);
            }else if(value.hasOwnProperty("polyline")){
                return JSON2Polyline(value);
            }else if(value.hasOwnProperty("polygon")){
                return JSON2Polygon(value);
            }else{
                return null;
            }
        }
        
        public static function JSON2Graphic(value:Object):Graphic
        {
            var g:Graphic = new Graphic();
            if(value.hasOwnProperty("A"))
            {
                g.attributes = value.A;
            }
            if(value.hasOwnProperty("G"))
            {
                g.geometry = JSON2Geometry(value.G);
            }
            if(value.hasOwnProperty("S"))
            {
                g.symbol = JSON2Symbol(value.S);
            }
            return g;
        }
        /**
         * 从JSON字符串获取Graphic集合 
         * @param json  JSON字符串
         * @return Graphic集合
         * 
         */        
        public static function fromJSON(value:String):Array
        {
            var obj:Object = JSON.decode(value);
            //检查是否包含fields，features，type属性
            var results:Array = [];
            
            var fields:Object = AttrUtil.getVal(obj, "fields",null,true);
            var aliases:Object = AttrUtil.getVal(obj, "aliases",null,true);
            var type:Object = AttrUtil.getVal(obj, "type",null,true);
            var features:Object = AttrUtil.getVal(obj, "features",null,true);
            
            var aliases_len:int = aliases.length;
            for each(var feature:Array in features)
            {
                var gra:Graphic = new Graphic();
                gra.attributes = {};
                for(var i:int=0;i<aliases_len;i++)
                {
                    var key:String = aliases[i];
                    var val:Object = feature[i];
                    if(key === "shape" || key === "SHAPE")
                    {
                        var geom:Geometry;
                        if(type === "linestring")
                        {
                            geom = linestring2polyline(val as Array);
                        }
                        else if(type === "point")
                        {
                            geom = new MapPoint(val[0],val[1]);
                        }
                        gra.geometry = geom;
                    }
                    else
                    {
                        gra.attributes[key] = val;
                    }
                }
                results.push(gra);
            }
            return results;
        }
        
        public static function linestring2polyline(coords:Array):Polyline
        {
            var line:Polyline = new Polyline([]);
            var len:int = coords.length,path:Array = [];
            for(var i:int=0;i<len-1;i++)
            {
                path.push(
                    new MapPoint(coords[i],coords[i+1]));
//                    new MapPoint(coords[i]/1000000.0,coords[i+1]/1000000.0));
                i++;
            }
            line.paths.push(path);
            return line;
        }
        /**
         * 将型如[x,y]的数组，转化为MapPoint对象 
         * @param coord 经纬度[x,y]
         * @param convert 转化函数
         * 
         * @example
         * <listing version="3.0">
         *  var coord:Array = [120000,31000];
         *  var convert:Function = function(x:Number,y:Number):Array
         *  {
         *      x = x / 1000.0;
         *      y = y / 1000.0;
         *      return [x,y];   
         *  };
         *  var point:MapPoint = coord2MapPoint(coord,);
         * </listing>
         * @return 
         * 
         */        
        public static function coord2MapPoint(coord:Array,
                                              convert:Function=null):MapPoint
        {
            var point:MapPoint = new MapPoint();
            if(convert == null)
            {
                point.x = coord[0];
                point.y = coord[1];
            }
            else
            {
                var xy:Array = convert.call(null,coord[0],coord[1]);
                point.x = xy[0];
                point.y = xy[1];
            }
            return point;
        }
    }
}