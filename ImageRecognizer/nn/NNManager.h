//
//  NNManager.h
//
//
//

#import <UIKit/UIKit.h>
#import "c_predict_api.h"


typedef void(^RecognitionCallback) (NSString *recognResult);

@interface NNManager: NSObject {
    PredictorHandle predictor;
    NSMutableArray *model_synset;
}

+ (instancetype)      shared;
- (void)    recognizeImage:     (UIImage *)image callback: (RecognitionCallback) callback;
- (void)    visualizeMeanData:  (void (^)(UIImage *meanImage)) callback;

@end
