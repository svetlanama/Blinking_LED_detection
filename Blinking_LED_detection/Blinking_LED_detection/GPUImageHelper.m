//
//  GPUImageHelper.m
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 7/4/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

#import "GPUImageHelper.h"


@implementation GPUImageHelper
+ (UIImage *) doBinarize:(UIImage *)sourceImage
{
    //first off, try to grayscale the image using iOS core Image routine
    UIImage * grayScaledImg = [self grayImage:sourceImage];
    GPUImagePicture *imageSource = [[GPUImagePicture alloc] initWithImage:grayScaledImg];
    GPUImageAdaptiveThresholdFilter *stillImageFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
    stillImageFilter.blurRadiusInPixels = 8.0; //blurSize
    
    [imageSource addTarget:stillImageFilter];
    [imageSource processImage];
    
    UIImage *retImage = [stillImageFilter imageFromCurrentFramebuffer]; //imageFromCurrentlyProcessedOutput];
    return retImage;
}

+ (UIImage *) grayImage :(UIImage *)inputImage
{
    // Create a graphic context.
    UIGraphicsBeginImageContextWithOptions(inputImage.size, NO, 1.0);
    CGRect imageRect = CGRectMake(0, 0, inputImage.size.width, inputImage.size.height);
    
    // Draw the image with the luminosity blend mode.
    // On top of a white background, this will give a black and white image.
    [inputImage drawInRect:imageRect blendMode:kCGBlendModeLuminosity alpha:1.0];
    
    // Get the resulting image.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end
