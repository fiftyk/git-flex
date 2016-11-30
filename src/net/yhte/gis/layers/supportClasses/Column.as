package net.yhte.gis.layers.supportClasses
{
    public class Column extends Object
    {
        public static const NUMBER:String = "NUMBER";
        public static const VARCHAR2:String = "VARCHAR2";
        
        public var name:String;
        public var type:String;
        public var length:int;
        public var precision:int;
        public var scale:int;
        public var nullable:Boolean;
        public var defaultVal:*;
        
        public function Column(name:String,type:String="String")
        {
            this.name = name;
            this.type = type;
        }
    }
}