//
//  NNManager.mm
//
//

#import <vector>
#import "NNManager.h"

#define pathToResource(path) [[NSBundle mainBundle] pathForResource: path ofType: nil]
#define arrSize(arr)  sizeof(arr) / sizeof(arr[0])

#define MEAN_R 117.0f
#define MEAN_G 117.0f
#define MEAN_B 117.0f

//width=224 and height=224 - default size of input image (tensor) for inception-bn network
#define kDefaultWidth 224
#define kDefaultHeight 224
//color channels (rgb without alpha)
#define kDefaultChannels 3
#define kDefaultImageSize (kDefaultWidth * kDefaultHeight * kDefaultChannels)

@interface NNManager () {
    PredictorHandle predictor;
    NSMutableArray *model_synset;
}
@end

@implementation NNManager

+ (instancetype) shared {
    static NNManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] initMxnet];
    });
    return shared;
}

- (id) initMxnet {
    if (self = [super init]) {
        NSLog(@"creating mxnet instance.....");
    
        NSString *jsonPath      = pathToResource(@"symbol.json");
        NSString *paramsPath    = pathToResource(@"params");
        NSString *synsetPath    = pathToResource(@"synset.txt");
                                    
        NSString *model_symbol = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:jsonPath] encoding:NSUTF8StringEncoding];
        NSData *model_params = [[NSFileManager defaultManager] contentsAtPath: paramsPath];
        
        //loading synset...
        model_synset = [NSMutableArray new];
        NSString* synsetText = [NSString stringWithContentsOfFile:synsetPath
                                                         encoding:NSUTF8StringEncoding error:nil];
        NSArray* lines = [synsetText componentsSeparatedByCharactersInSet:
                          [NSCharacterSet newlineCharacterSet]];
        for (NSString *l in lines) {
            NSArray *parts = [l componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([parts count] > 1) {
                [model_synset addObject:[parts subarrayWithRange:NSMakeRange(1, [parts count]-1)]];
            }
        }
        
        //predictor params
        NSString *input_name = @"data";
        const char *input_keys[1];
        input_keys[0] = [input_name UTF8String];
        const mx_uint input_shape_indptr[] = {0, 4};
        //shape of input tensor, image -  (1 x 3 color channels x Width x Height)
        const mx_uint input_shape_data[] = {1, kDefaultChannels, kDefaultWidth, kDefaultHeight};
    
        bool modelsNotLoaded = model_symbol == nil || model_symbol.length == 0 || model_params == nil || model_synset.count == 0;
        
        if (modelsNotLoaded) {
            NSException *e = [NSException
                              exceptionWithName: @"NullPreTrainedModelException"
                              reason: @"*** Pre-trained model  is null, cannot load it! Check model name and path!"
                              userInfo:nil];
            @throw e;
        }
        
        //create predictor
        MXPredCreate([model_symbol UTF8String],     // structure of network (json file)
                     [model_params bytes],          // pre-trained model
                     (int)[model_params length],
                     1, 0, 1,
                     input_keys,
                     input_shape_indptr,
                     input_shape_data,
                     &predictor);
        NSLog(@"mxnet predictor has been created...");
    }
    return self;
}

- (void) recognizeImage:(UIImage *)image callback: (RecognitionCallback) callback {
    
    const int numForRendering = kDefaultWidth * kDefaultHeight * (kDefaultChannels + 1);
    const int numForComputing = kDefaultWidth * kDefaultHeight * kDefaultChannels;
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
     
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        uint8_t *imageData = new uint8_t[numForRendering];
        CGContextRef contextRef = CGBitmapContextCreate(imageData,
                                                        kDefaultWidth,
                                                        kDefaultHeight,
                                                        8,
                                                        kDefaultWidth * (kDefaultChannels + 1),
                                                        colorSpace,
                                                        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
        CGContextDrawImage(contextRef, CGRectMake(0, 0, kDefaultWidth, kDefaultHeight), image.CGImage);
        CGContextRelease(contextRef);
        CGColorSpaceRelease(colorSpace);
        
        // Subtract the mean and copy to the input buffer
        float *input_buffer = new float[numForComputing];
        
        for (int i = 0; i < numForRendering; i += 4) {
            int j = i / 4;
            input_buffer[0 * kDefaultWidth * kDefaultHeight + j] = (imageData[i + 0] & 0xFF) - MEAN_R; // red
            input_buffer[1 * kDefaultWidth * kDefaultHeight + j] = (imageData[i + 1] & 0xFF) - MEAN_G; // green
            input_buffer[2 * kDefaultWidth * kDefaultHeight + j] = (imageData[i + 2] & 0xFF) - MEAN_B; // blue
        }
        
        mx_uint *shape = nil;
        mx_uint shape_len = 0;
        MXPredSetInput(predictor, "data", input_buffer, numForComputing);
        MXPredForward(predictor);
        
        delete[] input_buffer;
        delete[] imageData;
        
        MXPredGetOutputShape(predictor, 0, &shape, &shape_len);
        
        //output tensor size
        mx_uint tt_size = 1;
        for (mx_uint i = 0; i < shape_len; i++) {
            tt_size *= shape[i];
        }

        std::vector<float> outputs(tt_size);
        MXPredGetOutput(predictor, 0, outputs.data(), tt_size);
        
        size_t max_idx = std::distance(outputs.begin(), std::max_element(outputs.begin(), outputs.end()));
        NSArray *result = [model_synset objectAtIndex:max_idx];
        outputs.clear();
        
        if(result != nil) {
            NSString * description = [result componentsJoinedByString:@" "];
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                callback(description);
            });
        }
    });
}

//debug
- (void) visualizeMeanData: (void (^)(UIImage *meanImage)) callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        // Visualize the Mean Data
        float model_mean[kDefaultImageSize];

        NSString *meanPath  = pathToResource(@"mean_224.bin");
        
        NSData *meanData = [[NSFileManager defaultManager] contentsAtPath:meanPath];
        [meanData getBytes:model_mean length:[meanData length]];
        
        std::vector<uint8_t> mean_with_alpha(kDefaultWidth * kDefaultHeight * (kDefaultChannels + 1), 0);
        float *p_mean[3] = {
            model_mean + kDefaultWidth * kDefaultHeight * 0,
            model_mean + kDefaultWidth * kDefaultHeight * 1,
            model_mean + kDefaultWidth * kDefaultHeight * 2
        };
        
        for (int i = 0, map_idx = 0, glb_idx = 0; i < kDefaultHeight; i++) {
            for (int j = 0; j < kDefaultWidth; j++) {
                mean_with_alpha[glb_idx++] = p_mean[0][map_idx]; // red
                mean_with_alpha[glb_idx++] = p_mean[1][map_idx]; // green
                mean_with_alpha[glb_idx++] = p_mean[2][map_idx]; // blue
                mean_with_alpha[glb_idx++] = 0; // alpha
                map_idx++;
            }
        }
        
        NSData *mean_data = [NSData dataWithBytes:mean_with_alpha.data() length:mean_with_alpha.size() * sizeof(float)];
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)mean_data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        // Creating CGImage from cv::Mat
        CGImageRef imageRef = CGImageCreate(kDefaultWidth,
                                            kDefaultHeight,
                                            8,
                                            8 * (kDefaultChannels + 1),
                                            kDefaultWidth * (kDefaultChannels + 1),
                                            colorSpace,
                                            kCGImageAlphaNone | kCGBitmapByteOrderDefault,
                                            provider,
                                            NULL,
                                            false,
                                            kCGRenderingIntentDefault);
        UIImage *meanImage = [UIImage imageWithCGImage: imageRef];
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        dispatch_async(dispatch_get_main_queue(), ^(){
            callback(meanImage);
        });
    });
}


@end
