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

@interface AirNetworkingSessionDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, readonly) FREContext context;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, readonly) NSMutableData *data;
@property (nonatomic, readonly) NSError *error;

@end


@implementation AirNetworkingSessionDelegate

- (id)initWithContext:(FREContext)context
{
    self = [super init];
    if (self) {

        _context = context;
        _data = [NSMutableData data];
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [_data appendData:data];
    FPANE_DispatchEvent(self.context, @"PROGRESS");
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {

        _error = error;
        FPANE_DispatchEvent(self.context, @"ERROR");
    }
    else {

        FPANE_DispatchEvent(self.context, @"COMPLETE");
    }

    [session flushWithCompletionHandler:^{}];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Utils

AirNetworkingSessionDelegate *sessionDelegateFromContext(FREContext context)
{
    CFTypeRef sessionDelegateRef;
    FREGetContextNativeData(context, (void *)&sessionDelegateRef);
    return (__bridge AirNetworkingSessionDelegate *)sessionDelegateRef;
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

    AirNetworkingSessionDelegate *sessionDelegate = sessionDelegateFromContext(context);

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:sessionDelegate delegateQueue:nil];
    sessionDelegate.session = session;

    NSURLSessionTask *task = [session dataTaskWithRequest:request];
    sessionDelegate.task = task;

    [task resume];

    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Close

DEFINE_ANE_FUNCTION(AirNetworking_close)
{
    AirNetworkingSessionDelegate *sessionDelegate = sessionDelegateFromContext(context);

    [sessionDelegate.session invalidateAndCancel];

    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get bytes loaded

DEFINE_ANE_FUNCTION(AirNetworking_getBytesLoaded)
{
    AirNetworkingSessionDelegate *sessionDelegate = sessionDelegateFromContext(context);

    return FPANE_IntToFREObject((NSUInteger)sessionDelegate.task.countOfBytesReceived);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get bytes total

DEFINE_ANE_FUNCTION(AirNetworking_getBytesTotal)
{
    AirNetworkingSessionDelegate *sessionDelegate = sessionDelegateFromContext(context);

    return FPANE_IntToFREObject((NSUInteger)sessionDelegate.task.countOfBytesExpectedToReceive);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get data

DEFINE_ANE_FUNCTION(AirNetworking_getData)
{
    AirNetworkingSessionDelegate *sessionDelegate = sessionDelegateFromContext(context);

    return FPANE_NSStringToFREObject([[NSString alloc] initWithData:sessionDelegate.data encoding:NSUTF8StringEncoding]);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get error

DEFINE_ANE_FUNCTION(AirNetworking_getError)
{
    AirNetworkingSessionDelegate *sessionDelegate = sessionDelegateFromContext(context);

    FREObject error;
    FREObject errorMessage = FPANE_NSStringToFREObject(sessionDelegate.error.localizedDescription);
    FREObject errorID = FPANE_IntToFREObject(sessionDelegate.error.code);
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

    AirNetworkingSessionDelegate *sessionDelegate = [[AirNetworkingSessionDelegate alloc] initWithContext: ctx];
    FRESetContextNativeData(ctx, (void *)CFBridgingRetain(sessionDelegate));
}

void AirNetworkingContextFinalizer(FREContext ctx)
{
    CFTypeRef sessionDelegateRef;
    FREGetContextNativeData(ctx, (void **)&sessionDelegateRef);
    CFBridgingRelease(sessionDelegateRef);
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
