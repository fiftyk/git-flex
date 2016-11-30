package net.yhte.gis.layers
{
	import com.esri.ags.Graphic;

	public interface IDataLayer
	{
		function objToGraphic():Graphic;
	}
}