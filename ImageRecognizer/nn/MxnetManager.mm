//
//  MxnetManager.mm
//
//

#import <vector>

#import "MxnetManager.h"

typedef void(^RecognitionCallback) (NSString *recognResult);

@implementation MxnetManager

+ (id)shared {
    static MxnetManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] initMxnet];
    });
    return shared;
}

- (id)initMxnet {
    if (self = [super init]) {
        if (!predictor) {

            NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"Inception_BN-symbol.json" ofType:nil];
            NSString *paramsPath = [[NSBundle mainBundle] pathForResource:@"Inception_BN-0039.params" ofType:nil];
            NSString *meanPath = [[NSBundle mainBundle] pathForResource:@"mean_224.bin" ofType:nil];
            NSString *synsetPath = [[NSBundle mainBundle] pathForResource:@"synset.txt" ofType:nil];
            //NSLog(@"mean:  %@", meanPath);
            model_symbol = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:jsonPath] encoding:NSUTF8StringEncoding];
            model_params = [[NSFileManager defaultManager] contentsAtPath:paramsPath];
            
            NSString *input_name = @"data";
            const char *input_keys[1];
            input_keys[0] = [input_name UTF8String];
            const mx_uint input_shape_indptr[] = {0, 4};
            const mx_uint input_shape_data[] = {1, kDefaultChannels, kDefaultWidth, kDefaultHeight};
            MXPredCreate([model_symbol UTF8String], [model_params bytes], (int)[model_params length], 1, 0, 1,
                         input_keys, input_shape_indptr, input_shape_data, &predictor);
            
            NSData *meanData = [[NSFileManager defaultManager] contentsAtPath:meanPath];
            [meanData getBytes:model_mean length:[meanData length]];
            
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
            
            // Visualize the Mean Data
            std::vector<uint8_t> mean_with_alpha(kDefaultWidth * kDefaultHeight * (kDefaultChannels + 1), 0);
            float *p_mean[3] = {
                model_mean,
                model_mean + kDefaultWidth * kDefaultHeight,
                model_mean + kDefaultWidth * kDefaultHeight * 2
            };
            for (int i = 0, map_idx = 0, glb_idx = 0; i < kDefaultHeight; i++) {
                for (int j = 0; j < kDefaultWidth; j++) {
                    mean_with_alpha[glb_idx++] = p_mean[0][map_idx];
                    mean_with_alpha[glb_idx++] = p_mean[1][map_idx];
                    mean_with_alpha[glb_idx++] = p_mean[2][map_idx];
                    mean_with_alpha[glb_idx++] = 0;
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
                                                kCGRenderingIntentDefault
                                                );
            meanImage = [UIImage imageWithCGImage: imageRef];
            CGImageRelease(imageRef);
            CGDataProviderRelease(provider);
            //self.imageView.image = meanImage;
        }
    }
    return self;
}

- (void)predictImage:(UIImage *)image callback: (RecognitionCallback) callback {
    
    const int numForRendering = kDefaultWidth * kDefaultHeight * (kDefaultChannels + 1);
    const int numForComputing = kDefaultWidth * kDefaultHeight * kDefaultChannels;
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
     
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        uint8_t imageData[numForRendering];
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
        std::vector<float> input_buffer(numForComputing);
        float *p_input_buffer[3] = {
            input_buffer.data(),
            input_buffer.data() + kDefaultWidth * kDefaultHeight,
            input_buffer.data() + kDefaultWidth * kDefaultHeight * 2
        };
        const float *p_mean[3] = {
            model_mean,
            model_mean + kDefaultWidth * kDefaultHeight,
            model_mean + kDefaultWidth * kDefaultHeight * 2
        };
        for (int i = 0, map_idx = 0, glb_idx = 0; i < kDefaultHeight; i++) {
            for (int j = 0; j < kDefaultWidth; j++) {
                p_input_buffer[0][map_idx] = imageData[glb_idx++] - p_mean[0][map_idx];
                p_input_buffer[1][map_idx] = imageData[glb_idx++] - p_mean[1][map_idx];
                p_input_buffer[2][map_idx] = imageData[glb_idx++] - p_mean[2][map_idx];
                glb_idx++;
                map_idx++;
            }
        }
        
        mx_uint *shape = nil;
        mx_uint shape_len = 0;
        MXPredSetInput(predictor, "data", input_buffer.data(), numForComputing);
        MXPredForward(predictor);
        MXPredGetOutputShape(predictor, 0, &shape, &shape_len);
        mx_uint tt_size = 1;
        for (mx_uint i = 0; i < shape_len; i++) {
            tt_size *= shape[i];
        }
        std::vector<float> outputs(tt_size);
        MXPredGetOutput(predictor, 0, outputs.data(), tt_size);
        size_t max_idx = std::distance(outputs.begin(), std::max_element(outputs.begin(), outputs.end()));
        NSString *result = [[model_synset objectAtIndex:max_idx] componentsJoinedByString:@" "];
            
        dispatch_async(dispatch_get_main_queue(), ^(){
            callback(result);
        });
    });
}


@end
