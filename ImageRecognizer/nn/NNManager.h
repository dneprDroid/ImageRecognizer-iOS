
#import <UIKit/UIKit.h>
#import "MxNet.h"

typedef void(^RecognitionCallback) (NSString *recognResult);

@interface NNManager: NSObject

+ (instancetype)      shared;

- (void) recognizeImage:    (UIImage *)image callback: (RecognitionCallback) callback;
- (void) visualizeMeanData: (void (^)(UIImage *meanImage)) callback;

@end
