package net.yhte.gis.utils
{
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.geometry.Polyline;
	import com.esri.ags.utils.WebMercatorUtil;
	
	public class GeomUtil
	{
		//public var map:Map;
		
		/**已知直线上一点的坐标和该直线的斜率
		 * 求：该直线方程
		 *
		 * @param point 点
		 * @param k 斜率 (k!=0)
		 * @return 一个包含属性k（代表斜率）和属性b（代表与y轴交点坐标）的对象 ; 如果 k 不存在,b代表与x轴交点坐标的x值
		 *
		 */
		public static function getLineFromPointAndK(point:Array, in_k:Number):Array
		{
			var k:Number;
			var b:Number;
			if (isNaN(in_k))
			{
				b=point[0];
			}
			else
			{
				b=point[1] - in_k * point[0];
			}
			return [in_k, b];
		}
		
		/**
		 * 求直角坐标系中两点的距离
		 * @param Pnt1 点1
		 * @param Pnt2 点2
		 * @return 距离
		 * @example
		 * <listing version="3.0">
		 *  GeomUtil.getDistanceBy2Pt(Array,Array);
		 * 
		 *  GeomUtil.getDistanceBy2Pt(MapPoint,MapPoint);
		 * </listing>
		 */
		public static function getDistanceBy2Pt(p0:*, p1:*):Number
		{
			if(p0 is Array && p1 is Array)
			{
				return Math.sqrt(Math.pow((p0[0] - p1[0]),2) + Math.pow((p0[1] - p1[1]),2));
			}
			else if(p0.hasOwnProperty("x") && p0.hasOwnProperty("y") && p1.hasOwnProperty("x") && p1.hasOwnProperty("y"))
			{
				return Math.sqrt(Math.pow((p0.x - p1.x),2) + Math.pow((p0.y - p1.y),2));
			}
			else
			{
				return Infinity;
			}
		}
		
		/**求点到直线的距离
		 *
		 * @param point 点
		 * @param line 直线 包含属性k（代表斜率）和属性b（代表与y轴交点坐标）的对象
		 * @return 距离
		 *
		 */
		public static function getDistanceByPtAndLine(pt:Array, line:Array):Number
		{
			/**垂线*/
			var lineTmp:Array=getLineFromPointAndK(pt, -1 / line[0]);
			/**交点*/
			var ptTmp:Array=getLinesIntersection(line, lineTmp);
			return getDistanceBy2Pt(pt, ptTmp);
		}
		
		/**求点到线段的距离
		 *
		 * @param point 点
		 * @param segment [[st.x,st.y][ed.x,ed.y]]
		 * @return 距离
		 *
		 */
		public static function getDistanceByPtAndSegment(pt:Array, segment:Array):Number
		{
			/**直线*/
			var line:Array=getLineFormula(segment[0], segment[1]);
			/**垂线 判断k是否等于0*/
			var verticalLine:Array;
			if (line[0] == 0)
			{
				verticalLine=getLineFromPointAndK(pt, NaN);
			}
			else
			{
				verticalLine=getLineFromPointAndK(pt, -1 / line[0]);
			}
			/**交点*/
			var ptIntersection:Array=getLinesIntersection(line, verticalLine);
			/**交点到两端点的距离*/
			var distanceSeg0:Number=getDistanceBy2Pt(ptIntersection, segment[0]);
			var distanceSeg1:Number=getDistanceBy2Pt(ptIntersection, segment[1]);
			/**线段长度*/
			var distanceLine:Number=getDistanceBy2Pt(segment[0], segment[1]);
			
			/**垂线在线段的延长线上*/
			if ((distanceSeg0 + distanceSeg1) > distanceLine)
			{
				/**外点到线段两端点的距离*/
				distanceSeg0=getDistanceBy2Pt(pt, segment[0]);
				distanceSeg1=getDistanceBy2Pt(pt, segment[1]);
				if (distanceSeg1 > distanceSeg0)
					return distanceSeg0;
				return distanceSeg1;
			}
			else
			{
				return getDistanceBy2Pt(pt, ptIntersection);
			}
		}
		
		/**根据直角坐标系中两点坐标求由这两点确定的直线的方程
		 *
		 * @param Pnt1 点1
		 * @param Pnt2 点2
		 * @return 一个包含属性k（代表斜率）和属性b（代表与y轴交点坐标）的对象
		 *
		 */
		public static function getLineFormula(p0:Array, p1:Array):Array
		{
			var k:Number;
			var b:Number;
			if (p0[0] != p1[0])
			{
				k=(p0[1] - p1[1]) / (p0[0] - p1[0]);
				b=p0[1] - k * p0[0];
			}
			else
			{
				k=NaN;
				b=p0[0];
			}
			
			return [k, b];
		}
		
		/**根据两条直线求交点
		 *
		 * @param f1 直线一 包含k,b
		 * @param f2 直线二 包含k,b
		 * @return 返回交点坐标,若没有交点则返回null
		 *
		 */
		public static function getLinesIntersection(line0:Array, line1:Array):Array
		{
			var x:Number;
			var y:Number;
			if (isNaN(line0[0]) && isNaN(line1[0]))
			{
				return null;
			}
			else if (isNaN(line0[0]))
			{
				x=line0[1];
				y=line1[0] * x + line1[1];
				return [x, y]
			}
			else if (isNaN(line1[0]))
			{
				x=line1[1];
				y=line0[0] * x + line0[1];
				return [x, y]
			}
			else if (line0[0] == line1[0])
			{
				return null;
			}
			else
			{
				x=(line1[1] - line0[1]) / (line0[0] - line1[0]);
				y=line1[0] * x + line1[1];
				return [x, y];
			}
		}
		
		/**
		 *
		 */
		public static function extent_line(extent:Extent, p0:Array, p1:Array):Array
		{
			var intersection:Array=new Array();
			//如果extend包含点
			if (extent.contains(new MapPoint(p0[0], p0[1])))
			{
				intersection.push(p0);
				return intersection;
			}
			if (extent.contains(new MapPoint(p1[0], p1[1])))
			{
				intersection.push(p1);
				return intersection;
			}
			var p0_p1:Object=new Object();
			p0_p1['formula']=getLineFormula(p0, p1)
			var xrange:Array=[Math.min(p0[0], p1[0]), Math.max(p0[0], p1[0])] //x值区间
			var yrange:Array=[Math.min(p0[1], p1[1]), Math.max(p0[1], p1[1])] //y值区间
			
			var pois:Array=[[extent.xmin, extent.ymin], [extent.xmin, extent.ymax], [extent.xmax, extent.ymax], [extent.xmax, extent.ymin], [extent.xmin, extent.ymin]]
			
			for (var i:int=0; i < pois.length - 1; i++)
			{
				var xrange1:Array=[Math.min(pois[i][0], pois[i + 1][0]), Math.max(pois[i][0], pois[i + 1][0])] //x值区间
				var yrange1:Array=[Math.min(pois[i][1], pois[i + 1][1]), Math.max(pois[i][1], pois[i + 1][1])] //y值区间
				
				var formula:Array=getLineFormula(pois[i], pois[i + 1]); //extent边线方程
				//求extent边线与两点连线的交点坐标
				var poi:Array=getLinesIntersection(formula, p0_p1['formula']);
				if (poi != null)
				{ //如果交点存在，且交点在线段p0_p1上也在extent边线上则extent与线段相交
					if (poi[0] <= xrange[1] + 1 && poi[0] >= xrange[0] - 1 && poi[1] <= yrange[1] + 1 && poi[1] >= yrange[0] - 1 && poi[0] <= xrange1[1] + 1 && poi[0] >= xrange1[0] - 1 && poi[1] <= yrange1[1] + 1 && poi[1] >= yrange1[0] - 1)
					{
						intersection.push(poi);
					}
				}
			}
			return intersection;
		}
		
		/**
		 * 已知A，B，C三点坐标，求AB到BC的转向角
		 * A,B,C可以是数组，型如[x1,y1] [经度,纬度]；
		 * 或者经纬度值包含于x属性和y属性，型如{x:，y:}
		 * @param A
		 * @param B
		 * @param C
		 * 
		 */        
		public static function angleOfTurn(A:Object,B:Object,C:Object):Number
		{
			var result:Number;
			var c:Number = GeomUtil.getDistanceBy2Pt(A,B);
			var b:Number = GeomUtil.getDistanceBy2Pt(A,C);
			var a:Number = GeomUtil.getDistanceBy2Pt(B,C);
			
			var  cos:Number 
			= (Math.pow(a,2) + Math.pow(c,2) - Math.pow(b,2)) / (2 * a * c);
			
			var angle:Number = Math.acos(cos) / Math.PI * 180;
			//            trace("acos:"+angle);
			
			//求最大边
			var max:Number = Math.max(a,b,c);
			
			//c边的斜率
			var k_c:Number = (A.y - B.y) / (A.x - B.x);
			
			if(k_c == -Infinity)
			{//如果c边的斜率不存在，即c边垂直于x轴
				if(C.x < A.x )
				{//C点位于第2或3象限
					result = 360 - angle;
				}
				else if(C.x > A.x)
				{//C点位于第1或4象限
					result = angle;
				}
				else
				{//A,B.C三点位于同一直线上
					if(C.y > Math.max(A.y,B.y))
					{
						result = 180;
					}
					else
					{
						result = 360;
					}
				}
				return result;
			}
			
			//c边的斜率
			var k_a:Number = (B.y - C.y) / (B.x - C.x);
			
			var temp:Number = 1 + k_c * k_a;
			
			//c边到a边的转向角
			//            var angle_ab_bc:Number 
			//                =   Math.atan((k_a - k_c) / temp) / Math.PI * 180;
			//只需要知道征正负即可
			var angle_ab_bc:Number  = Math.atan((k_a - k_c) / temp);
			
			//            trace("转向角:"+angle_ab_bc);
			
			if(angle < 90)
			{
				if(angle_ab_bc  > 0)
				{
					//                    trace("第4象限");
					result = angle;
				}
				else
				{
					//                    trace("第3象限");
					result = 360 - angle;
				}
			}
			else if(angle > 90)
			{
				if(angle_ab_bc  > 0)
				{
					//                    trace("第2象限");
					result = 360 - angle;
				}
				else
				{
					//                    trace("第1象限");
					result = angle;
				}
			}
			else if(angle == 90)
			{
				
			}
			else if(angle == 0)
			{
				
			}
			//            trace("角度:"+result);
			return result;
		}
		
		public static function buffer(coord:*,distance:Number, sense:int=360):Array
		{
			var x:Number;
			var y:Number;
			var isMercator:Boolean = true;
			
			if(coord is Array)
			{
				x = coord[0];
				y = coord[1];
			}
			else
			{
				x = coord.x;
				y = coord.y;
			}
			
			if(x<181 && y<91){
				var tmpPoint:MapPoint = new MapPoint(x, y);
				var tmpMerPoint:MapPoint = WebMercatorUtil.geographicToWebMercator(tmpPoint) as MapPoint;
				x = tmpMerPoint.x;
				y = tmpMerPoint.y;
				isMercator = false;
			}
			
			var result:Array = [];
			for(var i:int = 0;i<= sense;i++)
			{
				var sin:Number = Math.sin(i * Math.PI / (sense/2));
				var cos:Number = Math.cos(i * Math.PI / (sense/2));
				var lat:Number =  distance * sin + x;
				var lng:Number = distance * cos + y;
				
				if(!isMercator){//84坐标系需要转换
					var tmpMerPoint2:MapPoint = new MapPoint(lat, lng);
					var tmpPoint2:MapPoint = WebMercatorUtil.webMercatorToGeographic(tmpMerPoint2) as MapPoint; 
					result.push([tmpPoint2.x,tmpPoint2.y]);
				}else{
					result.push([lat,lng]);
				}
			}
			return result;
		}
		
		/**
		 * 求平行线
		 * @param polyline 一条线段
		 * @param distance 偏移量
		 * @return Polyline 平行线
		 */ 
		public static function parall(polyline:Polyline,distance:int):Array
		{
			if(distance == 0){
				return polyline.paths[0];
			}
			var st:Array = [];
			var ed:Array = [];
			var parall:Array = [];
			var length:int = polyline.paths[0].length;
			if(length == 2){
				var line:Array = getLineFormulaBuff(polyline.paths[0][0], polyline.paths[0][1]);
				st = offPoint(polyline.paths[0][0], line[0], distance);
				ed = offPoint(polyline.paths[0][1], line[0], distance);
				return [st, ed];	
			}
			
			for(var i:int=0; i<length-2; i++){
				var p0:MapPoint =  polyline.paths[0][i];
				var p1:MapPoint =  polyline.paths[0][i+1];
				var p2:MapPoint =  polyline.paths[0][i+2];
				var line0:Array = getLineFormulaBuff(p0, p1);
				var line1:Array = getLineFormulaBuff(p1, p2);
				var parallLine0:Array = getBuffLine(line0, distance);
				var parallLine1:Array = getBuffLine(line1, distance);
				var interPoint:Array = getLinesIntersection(parallLine0,parallLine1);
				if(interPoint == null){
					
				}else{
					parall.push(interPoint);
				}
			}
			
			var point0:MapPoint = polyline.paths[0][0] as MapPoint;
			var point1:MapPoint = polyline.paths[0][1] as MapPoint;
			if(point1.x - point0.x < 0){
				st = offPoint(point0, getLineFormulaBuff(point0,point1)[0], -distance);
			}else{
				st = offPoint(point0, getLineFormulaBuff(point0,point1)[0], distance);
			}
			var pointLast1:MapPoint = polyline.paths[0][length-1];
			var pointLast2:MapPoint = polyline.paths[0][length-2];
			if(pointLast1.x - pointLast2.x < 0 ){
				ed = offPoint(pointLast1, getLineFormulaBuff(pointLast2, pointLast1)[0], -distance);
			}else{
				ed = offPoint(pointLast1, getLineFormulaBuff(pointLast2, pointLast1)[0], distance);
			}
			parall.splice(0, 0, st);
			parall.push(ed);
			
			return parall;
		}
		
		/**根据直角坐标系中两点坐标求由这两点确定的直线的方程
		 *
		 * @param Pnt1 点1
		 * @param Pnt2 点2
		 * @return 一个包含属性k（代表斜率）和属性b（代表与y轴交点坐标）以及 属性XX 的数组
		 *
		 */
		public static function getLineFormulaBuff(p0:MapPoint, p1:MapPoint):Array{
			var k:Number;
			var b:Number;
			if (p0.x != p1.x)
			{
				k=(p0.y - p1.y) / (p0.x - p1.x);
				b=p0.y - k * p0.x;
			}
			else
			{
				k=NaN;
				b=p0.x;
			}
			var xx:Array = [p1.x-p0.x,p1.y-p0.y]
			return [k, b, xx];
		}
		
		/**
		 * 根据偏移量求平行线方程
		 * @param line (k,b)
		 * @param bufVal  偏移量
		 * @return  Array 平行线方程(k,b)
		 */ 
		public static function getBuffLine(line:Array, bufVal:int):Array{
			if(line[2][0] > 0){
				bufVal = - bufVal;
			}
			
			var k:Number = line[0];
			var b:Number;
			//判断line的方向
			if(isNaN(k)){
				b = line[1] + bufVal;	
			}else{
				b = bufVal * Math.sqrt(1 + k * k) + line[1];
			}
			
			
			return [k,b];
		}
		
		/**
		 *给定偏移量,求偏移后点的位置
		 * @param pnt 原始点
		 * @param k 偏移方向
		 * @param val 偏移量 '
		 * @return 偏移后的点
		 */
		public static function offPoint(pnt:MapPoint, k:Number, val:Number):Array{
			var off_x:Number;
			var off_y:Number;
			
			val = 2 * val;
			if(isNaN(k)){
				off_x = val
				off_y = 0
			}else{
				off_x = (k * val) /(Math.sqrt(1 + k*k));
				off_y = val/Math.sqrt(1 + k*k);
			}
			return [pnt.x+(off_x/2), pnt.y-(off_y/2)];
		}
		
	}
}