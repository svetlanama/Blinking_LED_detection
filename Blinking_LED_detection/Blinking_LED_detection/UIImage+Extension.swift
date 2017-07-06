//
//  UIImage+Extension.swift
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 7/4/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

import Foundation
import UIKit
import GPUImage

extension UIImage {
    
    func pixelColor(atLocation point: CGPoint) -> UIColor? {
        guard let cgImage = cgImage, let pixelData = cgImage.dataProvider?.data else { return nil }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let pixelInfo: Int = ((cgImage.bytesPerRow * Int(point.y)) + (Int(point.x) * bytesPerPixel))
        
        let b = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let r = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func grayscaleImage(brightness: Double = 0.0, contrast: Double = 1.0) -> UIImage?
    {
        if let ciImage = CoreImage.CIImage(image: self, options: nil)
        {
            let paramsColor: [String : AnyObject] = [ kCIInputBrightnessKey: NSNumber(value: brightness),
                                                      kCIInputContrastKey:   NSNumber(value: contrast),
                                                      kCIInputSaturationKey: NSNumber(value: 0.0) ]
            let grayscale = ciImage.applyingFilter("CIColorControls", withInputParameters: paramsColor)
            
            let processedCGImage = CIContext().createCGImage(grayscale, from: grayscale.extent)
            return UIImage(cgImage: processedCGImage!, scale: self.scale, orientation: self.imageOrientation)
        }
        return nil
    }
    
    func blackWhite() -> UIImage? {
        guard let image: GPUImagePicture = GPUImagePicture(image: self) else {
            print("unable to create GPUImagePicture")
            return nil
        }
        let filter = GPUImageAverageLuminanceThresholdFilter()
        image.addTarget(filter)
        filter.useNextFrameForImageCapture()
        image.processImage()
        guard let processedImage: UIImage = filter.imageFromCurrentFramebuffer(with: UIImageOrientation.up) else {
            print("unable to obtain UIImage from filter")
            return nil
        }
        return processedImage
    }
    
    
    func doBinarize() -> UIImage? {
        
        let grayScaledImg = self.grayImage()
        let imageSource = GPUImagePicture(image: grayScaledImg)
        let stillImageFilter = GPUImageAdaptiveThresholdFilter()
        stillImageFilter.blurRadiusInPixels = 8.0
        //let stillImageFilter = GPUImageLuminanceThresholdFilter()
        //stillImageFilter.threshold = 0.9 //works
        
        imageSource!.addTarget(stillImageFilter)
        stillImageFilter.useNextFrameForImageCapture()
        imageSource!.processImage()
        
        guard let retImage: UIImage = stillImageFilter.imageFromCurrentFramebuffer(with: UIImageOrientation.up) else {
            print("unable to obtain UIImage from filter")
            return nil
        }
        return retImage
    }
    
    func grayImage() -> UIImage? {
        // Create a graphic context.
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1.0)
        let imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        
        // Draw the image with the luminosity blend mode.
        // On top of a white background, this will give a black and white image.
        //[inputImage drawInRect:imageRect blendMode:kCGBlendModeLuminosity alpha:1.0]
        self.draw(in: imageRect, blendMode: .luminosity, alpha:  1.0)
        
        // Get the resulting image.
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return outputImage
    }
   
}
