package net.yhte.gis.utils
{
    /**
     * 对象属性工具
     */
    public class AttrUtil
    {
        /**
         * 获取对象的属性链的值，若属性链存在则返回改属性链对应的值，不存在则返回参数def的值
         * @param obj 对象
         * @param keyChain 属性链
         * @param def 默认值
         * @param showError 没有找到属性(链),是否抛出异常，默认false，不抛出
         * @example 
         * <listing version="3.0">
         *      var obj:Object = {a:{b:{c:1}}};
         * 
         *      AttrUtil.getVal(obj,"a");//>> {b:{c:1}};
         *      AttrUtil.getVal(obj,"a.b.c");//>> 1;
         *      AttrUtil.getVal(obj,"a.b.c.d");//>> null;
         *      AttrUtil.getVal(obj,"a.b.c.d",2);//>> 2;
         * </listing> 
         */		
        public static function getVal(obj:Object,keyChain:String,def:*=null,
                                      showError:Boolean = false):*{
            var keys:Array = keyChain.split(".");
            var child:Object;
            var parent:Object = obj;
            try{
                for each(var property:String in keys){
                    child = parent[property];
                    parent = child;
                }
            }catch(e:Error){
                if(showError)
                    throw new Error("对象不存在属性(链):"+keyChain);
                return def;
            }
            return child;
        }
        /**
         * 获取对象键和键值列表
         * @param value:对象
         * @return 键和键值列表
         * @example 
         * <listing version="3.0">
         *  var obj:Object = {"a":1,"b":2};
         *  AttrUtil.getKeys(obj);
         *  >> [["a","b"],[1,2]]
         * </listing>
         */        
        public static function getKeys(value:Object):Array
        {
            var keys:Array = [],values:Array = [];
            
            for(var key:String in value)
            {
                keys.push(key);
                values.push(value[key]);
            }
            return [keys,values];
        }
        /**
         * 构造Object 
         * @param keys
         * @param values
         * @return 
         * 
         */        
        public static function zip(keys:Array,values:Array):Object
        {
            var len:int = keys.length;
            var len1:int = values.length;
            if(len != len1)
            {
                throw new Error("两个数组长度必须一致");
            }
            var value:Object = {};
            for(var i:int = 0;i<len;i++)
            {
                value[keys[i]] = values[i];
            }
            return value;
        }
    }
}