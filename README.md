Air Native Extension for Networking on iOS
======================================

This is an [Air native extension](http://www.adobe.com/devnet/air/native-extensions-for-air.html) that implements networking calls natively on iOS. It has been developed by [FreshPlanet](http://freshplanet.com) and is used in the game [SongPop](http://songpop.fm).


Installation
------

The ANE binary (AirNetworking.ane) is located in the *bin* folder. You should add it to your application project's Build Path and make sure to package it with your app (more information [here](http://help.adobe.com/en_US/air/build/WS597e5dadb9cc1e0253f7d2fc1311b491071-8000.html)).


Usage
-----

A sample project is located in the ```sample``` folder.

```NativeURLLoader``` behave the same way as ```URLLoader```, except for the following:

* ```dataFormat``` can only be ```text``` (the default)
* some events are not dispatched (```httpResponseStatus```, ```httpStatus``` and ```open```)
* error messages and codes dispatched with ```ioError``` are specific to the iOS SDK
* the request's ```data``` property can only be an instance of ```URLVariables```
* you must call ```dispose()``` once you are done with the loader, or you will leak memory


Build from source
---------

Should you need to edit the extension source code and/or recompile it, you will find an ant build script (build.xml) in the *build* folder:
    
```bash
cd /path/to/the/ane

# Setup build configuration
cd build
mv example.build.config build.config
# Edit build.config file to provide your machine-specific paths

# Build the ANE
ant
```


Authors
------

This ANE has been written by [Alexis Taugeron](http://alexistaugeron.com). It belongs to [FreshPlanet Inc.](http://freshplanet.com) and is distributed under the [Apache Licence, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).