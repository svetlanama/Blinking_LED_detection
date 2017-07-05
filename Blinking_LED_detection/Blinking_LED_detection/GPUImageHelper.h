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
+ (UIImage *) doBinarize:(UIImage *)sourceImage;
+ (UIImage *) grayImage :(UIImage *)inputImage;
@end
