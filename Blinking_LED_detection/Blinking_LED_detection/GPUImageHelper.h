//
//  GPUImageHelper.h
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 7/4/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@interface GPUImageHelper : NSObject
+ (size_t) getWidth:(CGImageRef) cgImage;
+ (size_t) getHeight:(CGImageRef) cgImage;
@end
