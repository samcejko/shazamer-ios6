#import <Foundation/Foundation.h>

typedef void (^SZHTTPHeadersBlock)(NSInteger status, NSDictionary *headers);
typedef void (^SZHTTPDataBlock)(NSData *chunk);
typedef void (^SZHTTPCompleteBlock)(NSInteger status, NSData *body, NSError *error);

// Minimal HTTP/1.1 client over SZTLSSocket: one request per connection, chunked transfer
// decoding, optional incremental body delivery. All callbacks run on the main thread.
@interface SZHTTPRequest : NSObject

@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSString *host;
@property (nonatomic) NSInteger port;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSData *body;
@property (nonatomic) NSTimeInterval connectTimeout;    // seconds, default 15
@property (nonatomic) NSTimeInterval readTimeout;       // seconds, default 120
@property (nonatomic) BOOL verifyTLS;
@property (nonatomic) BOOL secure;                      // YES = TLS (default), NO = plain HTTP
@property (nonatomic) BOOL streamBody;                  // deliver body through onData instead of completion

@property (nonatomic, copy) SZHTTPHeadersBlock onHeaders;
@property (nonatomic, copy) SZHTTPDataBlock onData;
@property (nonatomic, copy) SZHTTPCompleteBlock onComplete;

@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSDictionary *responseHeaders;
@property (nonatomic, readonly) NSString *tlsInfo;          // "TLSv1.2 TLS-ECDHE-..." once connected
@property (nonatomic, readonly) BOOL isCancelled;
@property (nonatomic, readonly) BOOL isFinished;

+ (instancetype)requestWithMethod:(NSString *)method host:(NSString *)host path:(NSString *)path;
- (void)start;
- (void)cancel;

@end


