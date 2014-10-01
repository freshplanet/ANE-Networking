package
{
	import com.freshplanet.ane.AirNetworking.NativeURLLoader;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	public class AirNetworkingSample extends Sprite
	{
		private var as3Loader: URLLoader = new URLLoader();
		private var nativeLoader: NativeURLLoader = new NativeURLLoader();
		
		public function AirNetworkingSample()
		{
			super();
			
			// Test GET
			var data: Object = {}; // <-- INSERT YOUR DATA HERE
			var request: URLRequest = new URLRequest(""); // <-- INSERT YOUR URL HERE
			request.method = URLRequestMethod.GET;
			
			// Test POST
//			var data: Object = {}; // <-- INSERT YOUR DATA HERE
//			var request: URLRequest = new URLRequest(""); // <-- INSERT YOUR URL HERE
//			request.method = URLRequestMethod.POST;
//			request.data = new URLVariables();
//			for (var key: String in data) { request.data[key] = data[key]; }
			
			as3Loader.addEventListener(Event.COMPLETE, function(event: Event): void {
				trace("AS3 loader complete - " + as3Loader.data);
			});
			as3Loader.addEventListener(ProgressEvent.PROGRESS, function(event: ProgressEvent): void {
				trace("AS3 loader progress - Loaded " + event.bytesLoaded + " bytes");
			});
			as3Loader.addEventListener(IOErrorEvent.IO_ERROR, function(event: IOErrorEvent): void {
				trace("AS3 loader IO error - " + event.text + " - " + event.errorID);
			});
			
			nativeLoader.addEventListener(Event.COMPLETE, function(event: Event): void {
				trace("Native loader complete - " + nativeLoader.data);
			});
			nativeLoader.addEventListener(ProgressEvent.PROGRESS, function(event: ProgressEvent): void {
				trace("Native loader progress - Loaded " + event.bytesLoaded + " bytes");
			});
			nativeLoader.addEventListener(IOErrorEvent.IO_ERROR, function(event: IOErrorEvent): void {
				trace("Native loader IO error - " + event.text + " - " + event.errorID);
			});
			
			as3Loader.load(request);
			nativeLoader.load(request);
		}
	}
}