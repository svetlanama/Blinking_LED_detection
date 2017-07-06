//
//  GPUImageHelper.m
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 7/4/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

#import "GPUImageHelper.h"


@implementation GPUImageHelper

+ (size_t) getWidth:(CGImageRef) cgImage {
    return CGImageGetWidth(cgImage);
}

+ (size_t) getHeight:(CGImageRef) cgImage {
    return CGImageGetHeight(cgImage);
}
 
@end
