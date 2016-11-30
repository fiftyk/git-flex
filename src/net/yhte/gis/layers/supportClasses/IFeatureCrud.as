package net.yhte.gis.layers.supportClasses
{
    import com.esri.ags.Graphic;
    import com.esri.ags.Map;
    import com.esri.ags.layers.Layer;
    
    import flash.events.IEventDispatcher;
    
    [Event(name="append_success",type="net.yhte.gis.events.MpEvent")]
    [Event(name="append_failure",type="net.yhte.gis.events.MpEvent")]
    
    [Event(name="remove_success",type="net.yhte.gis.events.MpEvent")]
    [Event(name="remove_failure",type="net.yhte.gis.events.MpEvent")]
    
    [Event(name="update_success",type="net.yhte.gis.events.MpEvent")]
    [Event(name="update_failure",type="net.yhte.gis.events.MpEvent")]
    
    [Event(name="server_error",type="net.yhte.gis.events.MpEvent")]
    
    public interface IFeatureCrud extends IEventDispatcher
    {
        /**
         *	map引用 
         * @return 
         * 
         */		
        function get map():Map;
        function set map(value:Map):void;
        /**
         * Layer引用 
         * @return 
         * 
         */		
        function get layer():Layer;
        function set layer(value:Layer):void;
        
        /**
         * 添加元素 
         * @param graphic 元素
         * 
         */		
        function addFeature(graphic:Graphic):void;
        /**
         * 更新元素 
         * @param graphic 元素
         * 
         */	
        function updateFeature(graphic:Graphic):void;
        /**
         * 删除元素 
         * @param graphic 元素
         * 
         */	
        function removeFeature(graphic:Graphic):void;
        /**
         * 查询元素 
         * @param graphic 元素
         * 
         */	
        function searchFeature(graphic:Graphic):void;
    }
}