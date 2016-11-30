package net.yhte.gis.module
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.core.FlexGlobals;
	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;
	
	import net.yhte.gis.module.baseModule.IMapModule;
	import net.yhte.gis.tools.LayerTool;
	
	public class ModuleTool extends EventDispatcher
	{
		private static var instance:ModuleTool;
		private var _layerTool:LayerTool;
		
		private var _moduleInfo:IModuleInfo;
		private var _moduleInfoArray:Array = new Array();
		private var isLoading:Boolean = false;
		
		private var _config:*;
		private var _moduleName:String;
		private var _callFun:Function;
		private static var moduleStore:Dictionary = new Dictionary();
		
		public function get layerTool():LayerTool
		{
			return _layerTool;
		}
		
		public function set layerTool(value:LayerTool):void
		{
			_layerTool = value;
		}
		/**
		 * 构造方法
		 * @param layerTool
		 */ 
		public function ModuleTool(layerTool:LayerTool)
		{
			super();
			if(instance != null){
				throw new Error("请使用getInstance方法初始化！");
			}
			this.layerTool = layerTool;
		}
		/**
		 * 获取TraceTool实例
		 * @param layerTool
		 */
		public static function getInstance(layerTool:LayerTool):ModuleTool
		{
			if(instance == null){
				instance = new ModuleTool(layerTool);
			}
			return instance;
		}
		
		public function addModule(moduleName:String, config:*=null, callFun:Function=null):void{
			if(isLoading){//正在加载其他module时需要等待
				var o:Object = new Object();
				o.moduleName = moduleName;
				o.config = config;
				_moduleInfoArray.push(o);
			}else{
				_config = config;
				_moduleName = moduleName;
				_callFun = callFun;
				trace(FlexGlobals.topLevelApplication.url);
				var baseUrl:String = FlexGlobals.topLevelApplication.url;
				baseUrl = baseUrl.replace("map.swf","");
				_moduleInfo = ModuleManager.getModule(baseUrl+"modules/"+moduleName+".swf");
				_moduleInfo.addEventListener( ModuleEvent.READY,moduleLoadHandler );   
				_moduleInfo.addEventListener( ModuleEvent.PROGRESS,onModuleProgress);
				_moduleInfo.addEventListener(ModuleEvent.ERROR,onModuleError);
				_moduleInfo.load();
				isLoading = true;
			}
		}
		
		private function moduleLoadHandler(event:ModuleEvent):void   
		{   
			var module:IMapModule = event.module.factory.create() as IMapModule;
			module.map = layerTool.map;
			module.layerTool = layerTool;
			module.config = _config;
			module.init();
			if(_callFun != null)
			{
				_callFun.call(null,module);
			}
			moduleStore[_moduleName] = module;
			isLoading = false;
			
			if(_moduleInfoArray.length>0){//加载等待中的module
				var o:Object = _moduleInfoArray.shift();
				var moduleName:String = o.moduleName;
				var config:* = o.config;
				addModule(moduleName, config);
			}
		}
		
		private function onModuleError(event:ModuleEvent):void
		{
			trace(event);
		}
		
		public function getModule(name:String):IMapModule
		{
			return moduleStore[name];
		}
		
		
		protected function onModuleProgress (e:ModuleEvent) : void {      
			trace(e);
		} 

		
	}
}