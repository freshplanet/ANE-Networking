////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "AirNetworking.h"
#import "FPANEUtils.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Connection delegate

@interface AirNetworkingConnectionDelegate : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, readonly) FREContext context;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, readonly) NSURLResponse *response;
@property (nonatomic, readonly) NSMutableData *data;
@property (nonatomic, readonly) NSError *error;

@end


@implementation AirNetworkingConnectionDelegate

- (id)initWithContext:(FREContext)context
{
    self = [super init];
    if (self) {

        _context = context;
        _data = [NSMutableData data];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
    FPANE_DispatchEvent(self.context, @"PROGRESS");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    FPANE_DispatchEvent(self.context, @"COMPLETE");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _error = error;
    FPANE_DispatchEvent(self.context, @"ERROR");
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Utils

AirNetworkingConnectionDelegate *connectionDelegateFromContext(FREContext context)
{
    CFTypeRef connectionDelegateRef;
    FREGetContextNativeData(context, (void *)&connectionDelegateRef);
    return (__bridge AirNetworkingConnectionDelegate *)connectionDelegateRef;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Load

DEFINE_ANE_FUNCTION(AirNetworking_load)
{
    NSString *rawURL = FPANE_FREObjectToNSString(argv[0]);
    NSString *cleanURL = [rawURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedURL = [cleanURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.URL = [NSURL URLWithString:encodedURL];
    request.HTTPMethod = FPANE_FREObjectToNSString(argv[1]);

    if (argc > 2) {

        NSLog(@"DATA: %@", FPANE_FREObjectToNSString(argv[2]));
        request.HTTPBody = [FPANE_FREObjectToNSString(argv[2]) dataUsingEncoding:NSUTF8StringEncoding];
    }

    AirNetworkingConnectionDelegate *connectionDelegate = connectionDelegateFromContext(context);

    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:connectionDelegate];
    connectionDelegate.connection = connection;

    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Close

DEFINE_ANE_FUNCTION(AirNetworking_close)
{
    AirNetworkingConnectionDelegate *connectionDelegate = connectionDelegateFromContext(context);

    [connectionDelegate.connection cancel];

    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get bytes loaded

DEFINE_ANE_FUNCTION(AirNetworking_getBytesLoaded)
{
    AirNetworkingConnectionDelegate *connectionDelegate = connectionDelegateFromContext(context);

    return FPANE_IntToFREObject(connectionDelegate.data.length);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get bytes total

DEFINE_ANE_FUNCTION(AirNetworking_getBytesTotal)
{
    AirNetworkingConnectionDelegate *connectionDelegate = connectionDelegateFromContext(context);

    return FPANE_IntToFREObject((NSUInteger)connectionDelegate.response.expectedContentLength);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get data

DEFINE_ANE_FUNCTION(AirNetworking_getData)
{
    AirNetworkingConnectionDelegate *connectionDelegate = connectionDelegateFromContext(context);

    return FPANE_NSStringToFREObject([[NSString alloc] initWithData:connectionDelegate.data encoding:NSUTF8StringEncoding]);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get error

DEFINE_ANE_FUNCTION(AirNetworking_getError)
{
    AirNetworkingConnectionDelegate *connectionDelegate = connectionDelegateFromContext(context);

    FREObject error;
    FREObject errorMessage = FPANE_NSStringToFREObject(connectionDelegate.error.localizedDescription);
    FREObject errorID = FPANE_IntToFREObject(connectionDelegate.error.code);
    FREObject args[] = {errorMessage, errorID};

    FRENewObject((const uint8_t *)"Error", 2, args, &error, NULL);

    return error;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Context initializer/finalizer

void AirNetworkingContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet)
{
    static FRENamedFunction functions[] = {
        MAP_FUNCTION(AirNetworking_load, NULL),
        MAP_FUNCTION(AirNetworking_close, NULL),
        MAP_FUNCTION(AirNetworking_getBytesLoaded, NULL),
        MAP_FUNCTION(AirNetworking_getBytesTotal, NULL),
        MAP_FUNCTION(AirNetworking_getData, NULL),
        MAP_FUNCTION(AirNetworking_getError, NULL),
    };
    *numFunctionsToTest = sizeof(functions) / sizeof(FRENamedFunction);
    *functionsToSet = functions;

    AirNetworkingConnectionDelegate *connectionDelegate = [[AirNetworkingConnectionDelegate alloc] initWithContext: ctx];
    FRESetContextNativeData(ctx, (void *)CFBridgingRetain(connectionDelegate));
}

void AirNetworkingContextFinalizer(FREContext ctx)
{
    CFTypeRef connectionDelegateRef;
    FREGetContextNativeData(ctx, (void **)&connectionDelegateRef);
    CFBridgingRelease(connectionDelegateRef);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Extension initializer/finalizer

void AirNetworkingInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet)
{
	*extDataToSet = NULL;
    *ctxInitializerToSet = &AirNetworkingContextInitializer;
    *ctxFinalizerToSet = &AirNetworkingContextFinalizer;
}

void AirNetworkingFinalizer(void *extData) {}
