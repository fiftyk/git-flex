package net.yhte.logging
{
    import flash.external.ExternalInterface;
    import flash.utils.getQualifiedClassName;
    
    public class JsLogger
    {
        private var _category:String;
        private var _className:String;
        
        public function JsLogger(obj:Object)
        {
            if(!ExternalInterface.available)
            {
                throw new Error("不支持");
            }
            var nameParts : Array = getQualifiedClassName( obj ).split("::");
            _className = nameParts[ nameParts.length - 1 ];
            
            callJS("eval",'try{logger}catch(e){logger={};logger.logs=[];logger.show = function(){var n = window.open();var l = logger.logs.length;for(var i=0;i<l;i++){try{console.log(logger.logs[i]);}catch(e){};var p = "<p>"+logger.logs[i]+"</p><br/>";n.document.writeln(p);}}}');
        }
        
        public static function  getLogger(obj:Object):JsLogger
        {
              var logger:JsLogger = new JsLogger(obj);
              return logger;
        }
        
        public function debug(msg:String, ... rest):void
        {
            for (var i:int = 0; i < rest.length; i++)
            {
                msg = msg.replace(new RegExp("\\{"+i+"\\}", "g"), rest[i]);
            }
            
            msg = "DEBUG " + new Date().toString() + " " + _className +" : " +msg;
            trace(msg);
            callJS("logger.logs.push",msg);
        }
        
        private function callJS(functionname:String,parameters:*):*
        {
            try
            {
                return ExternalInterface.call(functionname,parameters);
            }
            catch(e:Error)
            {
                ExternalInterface.call("eval",'alert( "'+e.message[0]+'")');
            }
        }
    }
}