//
//  Image+Extension.swift
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 7/12/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

import Foundation
import EasyImagy

extension Image where Pixel == RGBA {
    
    fileprivate func getPixelCount() -> Int {
        return Int(10 * width / 100)
    }
    
    func binarize() -> (isWhite: Bool, binarizedImage: Image<RGBA>) {
        
        var kWidth = 0
        var img = self
        let pixelCount = getPixelCount()
        for x in 0..<width{
            var kHeight = 0
            for y in 0..<height {
                
                if let _pixel = pixel(x, y) {
                    if _pixel.gray < 245 {
                        img[x, y] = .black
                        kHeight = 0
                    } else {
                        img[x, y] = .white
                        kHeight += 1
                    }
                    
                    if kHeight > pixelCount {
                        kWidth += 1
                        break
                    }
                }
            }
            print("Hwhite: \(kHeight) Wwhite: \(kWidth)")
            if kHeight >= pixelCount && kWidth >= pixelCount  {
                return (true, img)
            }
        }
        return (false, img)
    }
}
