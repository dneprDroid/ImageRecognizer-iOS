//
//  NNManager.h
//
//
//

#import <UIKit/UIKit.h>
#import "c_predict_api.h"

// width = 224 and height = 224 - default size of input image (tensor) in inception-bn network
#define kDefaultWidth 224
#define kDefaultHeight 224
//color channels
#define kDefaultChannels 3
#define kDefaultImageSize (kDefaultWidth * kDefaultHeight * kDefaultChannels)

typedef void(^RecognitionCallback) (NSString *recognResult);

@interface NNManager: NSObject {
    
    PredictorHandle predictor;
    
    NSString *model_symbol;
    NSData *model_params;
    NSMutableArray *model_synset;
    float model_mean[kDefaultImageSize];
    //UIImage *meanImage;
}

+ (instancetype)      shared;
- (void)    recognizeImage:     (UIImage *)image callback: (RecognitionCallback) callback;
- (void)    visualizeMeanData:  (void (^)(UIImage *meanImage)) callback;

@end
