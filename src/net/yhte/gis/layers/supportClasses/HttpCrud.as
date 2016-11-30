package net.yhte.gis.layers.supportClasses
{
    import com.esri.ags.Graphic;
    import com.esri.ags.utils.JSON;
    
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    import mx.rpc.http.HTTPService;
    
    import net.yhte.gis.events.MpEvent;
    import net.yhte.gis.utils.GraphicUtil2;
    
    public class HttpCrud extends BaseCrud
    {
        public function HttpCrud()
        {
            super();
        }
        
        private function getHttpService(action:String,callback:Function=null):HTTPService
        {
            var http:HTTPService = new HTTPService();
            http.method = "POST";
            http.addEventListener(FaultEvent.FAULT,onFaultHandler);
            http.url = layer["url"] + "/" +action;
            if(callback != null)
            {
                http.addEventListener(ResultEvent.RESULT,function(e:ResultEvent):void{
                    callback.call(null,action,JSON.decode(e.result.toString()));
                });
            }
            return http;
        }
        
        private function onFaultHandler(event:FaultEvent):void
        {
            dispatchEvent(new MpEvent("server_error",event.toString()));
        }
        
        override public function addFeature(graphic:Graphic):void
        {
            var http:HTTPService = getHttpService("append",resultHandler);
            var params:Object = {};
            var obj:Object = GraphicUtil2.Graphic2JSON(graphic);
            params["features"] = JSON.encode(obj);
            params["pk"] = graphic.attributes[layer["pk"]];
            params["inSR"] = map.spatialReference.wkid;
            http.send(params);
        }
        
        override public function removeFeature(graphic:Graphic):void
        {
            var http:HTTPService = getHttpService("remove",resultHandler);
            var params:Object = {};
            params["pk"] = graphic.attributes[layer["pk"]];
            http.send(params);
        }
        
        override public function updateFeature(graphic:Graphic):void
        {
            var http:HTTPService = getHttpService("update",resultHandler);
            var params:Object = {};
            var obj:Object = GraphicUtil2.Graphic2JSON(graphic);
            params["features"] = JSON.encode(obj);
            if(graphic.attributes.hasOwnProperty(layer["pk"]))
            {
                params["pk"] = graphic.attributes[layer["pk"]];
            }
            params["inSR"] = map.spatialReference.wkid;
            http.send(params);
        }
        
        private function resultHandler(type:String,result:Object):void
        {
            if(result.success == true)
            {
                dispatchEvent(new MpEvent(type + "_success"));
            }
            else
            {
                dispatchEvent(new MpEvent(type + "_failure",result.message));
            }
        }
        
    }
}