//
//  ImageProcessing.swift
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 7/4/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

import Foundation

class ImageProcessing {
    
    enum HistogrammSignal: Int {
        case signal = 1
        case breakSignal = 0
    }
    
    enum SignalDuration: Int {
        case oneSignal = 1000
        case zeroSignal = 500
        case breakSignal = 400
    }
    
    var histogramm = [Int]()
    var wordResult = [[Int]]()
    var decodedResult = [Int]()
    static let sharedInstance = ImageProcessing()
    
    func addValueToHistogramm(value: Int) {
        histogramm.append(value)
        print("historgamm: ", histogramm)
    }
    
    func resetWordResult() {
        wordResult.removeAll()
    }
    
    func resetDecodedResult() {
        decodedResult.removeAll()
    }
    
    func resetHistogramm() {
        histogramm.removeAll()
    }
    
    func handleHistogramm() {
        var signalCount = 0
        var breakCount = 0
        var ableToDetect = false
        var ableToDetectBreak = false
       // histogramm = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]
        for sig in 0..<histogramm.count {
            switch(histogramm[sig]) {
            case 1:
//                if breakCount >= 3 && ableToDetectBreak {
//                    wordResult.append(decodedResult)
//                    breakCount = 0
//                    ableToDetectBreak = false
//                }
                
                signalCount += 1
                ableToDetect = true
            case 0:
                
                if ableToDetect {
                    if signalCount >= 3 {
                        decodedResult.append(1) //1
                    } else {
                        decodedResult.append(0)
                    }
                    signalCount = 0
                    ableToDetect = false
                    if decodedResult.count == 8 {
                        wordResult.append(decodedResult)
                        resetDecodedResult()
                    }
                }
               // breakCount += 1
               // ableToDetectBreak = true
                
                
                
                
            default:
                break
            }
        }
        print("decodedResult: ", decodedResult)
        print("wordResult: ", wordResult)
    }
    
}

//    private var arr = [Int]()
//    private var counter = 0
//    func addCounter() {
//        counter += 1
//        print("addCounter \(counter)")
//    }
//
//    func defineSignalAndBreak() {
//        print("defineSignal \(counter)")
//        switch counter {
//        case 10...24:
//            print("===== 1 ======")
//             arr.append(1)
//        case 6...10:
//            print("====== 0 =======")
//            arr.append(0)
//        default:
//            print("not defined")
//            break
//        }
//
//        counter = 0
//        if arr.count == 8 {
//            print("arr count: \(arr)")
//        }
//    }
