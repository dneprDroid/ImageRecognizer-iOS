//
//  NNManager.mm
//
//

#import <vector>
#import "NNManager.h"

#define pathToResource(path) [[NSBundle mainBundle] pathForResource: path ofType: nil]

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
    NSMutableArray *modelSynset;
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
                                    
        NSString *modelSymbol = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:jsonPath] encoding:NSUTF8StringEncoding];
        NSData *modelParams = [[NSFileManager defaultManager] contentsAtPath: paramsPath];
        
        //loading synset...
        modelSynset = [NSMutableArray new];
        NSString* synsetText = [NSString stringWithContentsOfFile:synsetPath
                                                         encoding:NSUTF8StringEncoding error:nil];
        NSArray* lines = [synsetText componentsSeparatedByCharactersInSet:
                          [NSCharacterSet newlineCharacterSet]];
        for (NSString *l in lines) {
            NSArray *parts = [l componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([parts count] > 1) {
                [modelSynset addObject:[parts subarrayWithRange:NSMakeRange(1, [parts count]-1)]];
            }
        }
        
        //predictor params
        NSString *inputName = @"data";
        const char *inputKeys[1];
        inputKeys[0] = [inputName UTF8String];
        const mx_uint inputShapeIndptr[] = {0, 4};
        //shape of input tensor, image -  (1 x 3 color channels x Width x Height)
        const mx_uint inputShapeData[] = {1, kDefaultChannels, kDefaultWidth, kDefaultHeight};
    
        bool modelsDidntLoad = modelSymbol == nil || modelSymbol.length == 0 || modelParams == nil || modelSynset.count == 0;
        
        if (modelsDidntLoad) {
            NSException *e = [NSException
                              exceptionWithName: @"NullPreTrainedModelException"
                              reason: @"*** Pre-trained model  is null, cannot load it! Check model name and path!"
                              userInfo:nil];
            @throw e;
        }
        
        //create predictor
        MXPredCreate([modelSymbol UTF8String],     // structure of network (json file)
                     [modelParams bytes],          // pre-trained model
                     (int)[modelParams length],
                     1, 0, 1,
                     inputKeys,
                     inputShapeIndptr,
                     inputShapeData,
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
        float *inputBuffer = new float[numForComputing];
        
        for (int i = 0; i < numForRendering; i += 4) {
            int j = i / 4;
            inputBuffer[0 * kDefaultWidth * kDefaultHeight + j] = (imageData[i + 0] & 0xFF) - MEAN_R; // red
            inputBuffer[1 * kDefaultWidth * kDefaultHeight + j] = (imageData[i + 1] & 0xFF) - MEAN_G; // green
            inputBuffer[2 * kDefaultWidth * kDefaultHeight + j] = (imageData[i + 2] & 0xFF) - MEAN_B; // blue
        }
        
        mx_uint *shape = nil;
        mx_uint shapeLen = 0;
        MXPredSetInput(predictor, "data", inputBuffer, numForComputing);
        MXPredForward(predictor);
        
        delete[] inputBuffer;
        delete[] imageData;
        
        MXPredGetOutputShape(predictor, 0, &shape, &shapeLen);
        
        //output tensor size
        mx_uint tt_size = 1;
        for (mx_uint i = 0; i < shapeLen; i++) {
            tt_size *= shape[i];
        }

        std::vector<float> outputs(tt_size);
        MXPredGetOutput(predictor, 0, outputs.data(), tt_size);
        
        size_t maxIdx = std::distance(outputs.begin(), std::max_element(outputs.begin(), outputs.end()));
        if (modelSynset.count <= maxIdx || maxIdx < 0) {
            callback(nil);
            return;
        }
        NSArray *result = [modelSynset objectAtIndex:maxIdx];
        
        NSString * description = [result componentsJoinedByString:@" "];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            callback(description);
        });
    });
}

//debug
- (void) visualizeMeanData: (void (^)(UIImage *meanImage)) callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        // Visualize the Mean Data
        float modelMean[kDefaultImageSize];

        NSString *meanPath  = pathToResource(@"mean_224.bin");
        
        NSData *meanData = [[NSFileManager defaultManager] contentsAtPath:meanPath];
        [meanData getBytes:modelMean length:[meanData length]];
        
        std::vector<uint8_t> meanWithAlpha(kDefaultWidth * kDefaultHeight * (kDefaultChannels + 1), 0);
        float *pMean[3] = {
            modelMean + kDefaultWidth * kDefaultHeight * 0,
            modelMean + kDefaultWidth * kDefaultHeight * 1,
            modelMean + kDefaultWidth * kDefaultHeight * 2
        };
        
        for (int i = 0, mapIdx = 0, glbIdx = 0; i < kDefaultHeight; i++) {
            for (int j = 0; j < kDefaultWidth; j++) {
                meanWithAlpha[glbIdx++] = pMean[0][mapIdx]; // red
                meanWithAlpha[glbIdx++] = pMean[1][mapIdx]; // green
                meanWithAlpha[glbIdx++] = pMean[2][mapIdx]; // blue
                meanWithAlpha[glbIdx++] = 0; // alpha
                mapIdx++;
            }
        }
        
        NSData *meanDataAlpha = [NSData dataWithBytes:meanWithAlpha.data() length:meanWithAlpha.size() * sizeof(float)];
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)meanDataAlpha);
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
