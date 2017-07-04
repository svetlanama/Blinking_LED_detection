//
//  ImageProcessing.swift
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 7/4/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

import Foundation

class ImageProcessing {
    
    private var arr = [Int]()
    private var counter = 0

    func addCounter() {
        counter += 1
        print("addCounter \(counter)")
    }
    
    func defineSignalAndBreak() {
        print("defineSignal \(counter)")
        switch counter {
        case 10...24:
            print("===== 1 ======")
             arr.append(1)
        case 6...10:
            print("====== 0 =======")
            arr.append(0)
        default:
            print("not defined")
            break
        }
        
        counter = 0
        if arr.count == 8 {
            print("arr count: \(arr)")
        }
    }
    
    
}
