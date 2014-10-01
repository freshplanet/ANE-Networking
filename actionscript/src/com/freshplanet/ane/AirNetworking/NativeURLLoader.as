//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  
//////////////////////////////////////////////////////////////////////////////////////

package com.freshplanet.ane.AirNetworking
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;

	public class NativeURLLoader extends URLLoader
	{
		// --------------------------------------------------------------------------------------//
		//																						 //
		// 									   PUBLIC API										 //
		// 																						 //
		// --------------------------------------------------------------------------------------//
		
		/** AirNetworking is supported on iOS devices. */
		public static function get isSupported(): Boolean
		{
			var isIOS: Boolean = (Capabilities.manufacturer.indexOf("iOS") != -1);
			return isIOS;
		}
		
		public static var logEnabled: Boolean = true;
		
		/**
		 * NativeURLLoader behave the same way as URLLoader, except for the following:
		 * <ul>
		 * 	<li><code>dataFormat</code> can only be "text" (the default)</li>
		 * 	<li>some events are not dispatched (<code>httpResponseStatus</code>, <code>httpStatus</code> and <code>open</code>)</li>
		 * 	<li>error messages and codes dispatched with <code>ioError</code> are specific to the iOS SDK</li>
		 * 	<li>the request's <code>data</code> property can only be an instance of <code>URLVariables</code>
		 * 	<li>you must call <code>dispose()</code> once you are done with the loader, or you will leak memory</li>
		 * </ul>
		 */
		public function NativeURLLoader(request: URLRequest = null)
		{	
			_context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
			if (!_context)
			{
				log("ERROR - Extension context is null. Please check if extension.xml is setup correctly.");
				return;
			}			
			_context.addEventListener(StatusEvent.STATUS, onStatus);
			
			if (isSupported && request) load(request);
		}
		
		override public function load(request: URLRequest): void
		{
			if (!isSupported) return;
			
			if (dataFormat != URLLoaderDataFormat.TEXT)
			{
				throw new Error("NativeURLLoader only supports URLLoaderDataFormat.TEXT (for now)");
			}
			
			if (request.data && !(request.data is URLVariables))
			{
				throw new Error("NativeURLLoader only supports URLVariables (for now)");
			}
			
			if (request.method == URLRequestMethod.GET && request.data)
			{
				request.url += "?" + request.data.toString();
				request.data = null;
			}
			
			if (request.data)
			{
				_context.call("AirNetworking_load", request.url, request.method, request.data.toString());	
			}
			else
			{	
				_context.call("AirNetworking_load", request.url, request.method);				
			}
		}
		
		override public function close(): void
		{
			if (!isSupported) return;
			
			_context.call("AirNetworking_close");
		}
		
		public function dispose(): void
		{
			if (!isSupported) return;
			
			_context.dispose();
		}

		
		// --------------------------------------------------------------------------------------//
		//																						 //
		// 									 	PRIVATE API										 //
		// 																						 //
		// --------------------------------------------------------------------------------------//
		
		private static const EXTENSION_ID: String = "com.freshplanet.AirNetworking"; 
		
		private var _context: ExtensionContext;
		
		private function get _bytesLoaded(): uint 
		{	
			return _context.call("AirNetworking_getBytesLoaded") as uint; 
		}
		
		private function get _bytesTotal(): uint 
		{	
			return _context.call("AirNetworking_getBytesTotal") as uint;
		}
		
		private function get _data(): String 
		{	
			return _context.call("AirNetworking_getData") as String;
		}
		
		private function get _error(): Error 
		{
			return _context.call("AirNetworking_getError") as Error;
		}

		private function onStatus(event: StatusEvent): void
		{
			if (event.code == "LOGGING") // Simple log message
			{
				log(event.level);
			}
			else if (event.code == "COMPLETE")
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
			else if (event.code == "PROGRESS")
			{
				bytesLoaded = _bytesLoaded;
				bytesTotal = _bytesTotal;
				data = _data;
				dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, bytesLoaded, bytesTotal));
			}
			else if (event.code == "ERROR")
			{
				var error: Error = _error;
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, error.message, error.errorID));
			}
		}
		
		private static function log(message: String): void
		{
			if (logEnabled) trace("[Networking] " + message);
		}
	}
}