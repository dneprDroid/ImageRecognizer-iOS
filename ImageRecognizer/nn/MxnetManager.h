//
//  MxnetManager.h
//
//
//

#import <UIKit/UIKit.h>
#import "c_predict_api.h"

#define kDefaultWidth 224
#define kDefaultHeight 224
#define kDefaultChannels 3
#define kDefaultImageSize (kDefaultWidth * kDefaultHeight * kDefaultChannels)

typedef void(^RecognitionCallback) (NSString *recognResult);

@interface MxnetManager: NSObject {
    
    PredictorHandle predictor;
    
    NSString *model_symbol;
    NSData *model_params;
    NSMutableArray *model_synset;
    float model_mean[kDefaultImageSize];
    UIImage *meanImage;
}

+ (id) shared;
- (void)predictImage:(UIImage *)image callback: (RecognitionCallback) callback;

@end
