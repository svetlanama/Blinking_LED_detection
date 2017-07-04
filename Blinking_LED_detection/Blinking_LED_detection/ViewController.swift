//
//  ViewController.swift
//  Blinking_LED_detection
//
//  Created by Svitlana Moiseyenko on 6/25/17.
//  Copyright © 2017 Svitlana Moiseyenko. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import MetalKit
import QuartzCore
import CoreImage

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var breakCounter = 0
    private let imageProcessing = ImageProcessing()
    private var flag = false
    
    @IBOutlet private weak var focusView: UIView! {
        didSet {
            focusView.layer.borderColor = UIColor.yellow.cgColor
            focusView.layer.borderWidth = 1
        }
    }
    @IBOutlet private weak var rectView: UIView! {
        didSet {
            rectView.layer.borderColor = UIColor.green.cgColor
            rectView.layer.borderWidth = 1
        }
    }
    
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var binCameraView: UIView!
    private let context = CIContext()
    private var count = 0
    
    @IBOutlet weak var frameImageView: UIImageView!
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return ciImage
    }
    
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    let captureDevice = AVCaptureDevice.default(for: .video)
    
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard
            let backCamera = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        
        session.addInput(input)
        
        return session
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraView?.layer.addSublayer(self.cameraLayer)
        self.cameraLayer.videoGravity = .resizeAspectFill
        
        // register to receive buffers from the camera
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        self.captureSession.addOutput(videoOutput)
        setUpFocus()
        
        // begin the session
        self.captureSession.startRunning()
        
        view.bringSubview(toFront: focusView)
        //view.bringSubview(toFront: rectView)
    }
    
    func setUpFocus() {
        let focus_x = cameraView.frame.size.width / 2
        let focus_y = cameraView.frame.size.height / 2
        
        if (captureDevice!.isFocusModeSupported(.autoFocus) && captureDevice!.isFocusPointOfInterestSupported) {
            do {
                try captureDevice?.lockForConfiguration()
                captureDevice?.focusMode = .autoFocus
                captureDevice?.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                
                captureDevice?.exposurePointOfInterest =  CGPoint(x: focus_x, y: focus_y)
                captureDevice?.exposureMode = .continuousAutoExposure
                
                //                if (captureDevice!.isExposureModeSupported(.autoExpose) && captureDevice!.isExposurePointOfInterestSupported) {
                //                    captureDevice?.exposureMode = .autoExpose
                //                    captureDevice?.exposurePointOfInterest = CGPoint(x: focus_x, y: focus_y)
                //                }
                
                captureDevice?.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }
    
    lazy var rectanglesRequest: VNDetectRectanglesRequest = {
        return VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
    }()
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNDetectedObjectObservation]
            else {
                print("unexpected result type from VNDetectedObjectObservation")
                return
        }
        guard let detectedObject = observations.first else {
            print("not detected object")
            if flag {
                breakCounter += 1
                print("breakCounter: \(breakCounter)")
                if breakCounter > 5 {
                    imageProcessing.defineSignalAndBreak()
                } else {
                    imageProcessing.addCounter()
                }
            }
            return
        }
        print("=== detected object ===", detectedObject)
        flag = true
        breakCounter = 0
        imageProcessing.addCounter()
        
        //        var transformedRect = detectedObject.boundingBox
        //        transformedRect.origin.y = 1 - transformedRect.origin.y
        //        var convertedRect = self.cameraLayer.layerRectConverted(fromMetadataOutputRect: transformedRect)
        //        rectView.frame = convertedRect
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        let correctedImage = uiImage
            .applyingFilter("CIColorControls", withInputParameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 4.5,
                kCIInputBrightnessKey: -1.54
                ])
        //.applyingFilter("CISharpenLuminance", withInputParameters: [
        //                kCIInputSharpnessKey: 0.5
        //                ])
        //.applyingFilter("CIColorInvert", withInputParameters: nil)
        self.searchLightSpot(ciImage: correctedImage)
        
        DispatchQueue.main.async { [unowned self] in //unowned
            self.frameImageView.image = UIImage(ciImage: correctedImage)
        }
    }
    
    func searchLightSpot(ciImage: CIImage) {
        var requestOptions: [VNImageOption: Any] = [:]
        let handler = VNImageRequestHandler(ciImage: ciImage, options: requestOptions)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.rectanglesRequest])
            } catch {
                print(error)
            }
        }
    }
    
    //
    //    @IBAction func tapToFocus(_ sender: UITapGestureRecognizer) {
    //        if (sender.state == .ended) {
    //            let thisFocusPoint = sender.location(in: cameraView)
    //
    //            print("touch to focus ", thisFocusPoint)
    //
    //            let focus_x = thisFocusPoint.x / cameraView.frame.size.width
    //            let focus_y = thisFocusPoint.y / cameraView.frame.size.height
    //
    //            if (captureDevice!.isFocusModeSupported(.autoFocus) && captureDevice!.isFocusPointOfInterestSupported) {
    //                do {
    //                    try captureDevice?.lockForConfiguration()
    //                    captureDevice?.focusMode = .autoFocus
    //                    captureDevice?.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
    //
    //                    captureDevice?.exposurePointOfInterest =  CGPoint(x: focus_x, y: focus_y)
    //                    captureDevice?.exposureMode = .continuousAutoExposure
    //
    //                    //                    if (captureDevice!.isExposureModeSupported(.autoExpose) && captureDevice!.isExposurePointOfInterestSupported) {
    //                    //                        captureDevice?.exposureMode = .autoExpose;
    //                    //                        captureDevice?.exposurePointOfInterest = CGPoint(x: focus_x, y: focus_y);
    //                    //                    }
    //
    //                    captureDevice?.unlockForConfiguration()
    //                } catch {
    //                    print(error)
    //                }
    //            }
    //
    //
    //            // calculate view rect
    //            var transformedRect = CGRect(x: focus_x - 50, y: focus_y - 50, width: 100, height: 100)
    //            transformedRect.origin.y = 1 - transformedRect.origin.y
    //            let convertedRect = self.cameraLayer.layerRectConverted(fromMetadataOutputRect: transformedRect)
    //
    //            // move the highlight view
    //            self.highlightView?.frame = convertedRect
    //            view.bringSubview(toFront: highlightView!)
    //        }
    //    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

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
}

extension CGFloat {
    func toInt() -> Int {
        return Int(self)
    }
}



/*
 
 func test(image: UIImage) -> Bool {
 // var result  = 0
 // var i = 0
 
 
 
 for  y in 0..<image.size.height.toInt() {
 print("===height===")
 for x in 0..<image.size.width.toInt() {
 let color = image.pixelColor(atLocation: CGPoint(x: x, y: y))
 print("color:", color)
 //                let color = self.color   [self colorAt:image atX:x andY:y]
 //
 //                const CGFloat * colors = CGColorGetComponents(color.CGColor)
 //                let r = colors[0]
 //                let g = colors[1]
 //                let b = colors[2]
 //                result += .299 * r + 0.587 * g + 0.114 * b
 //                i++
 }
 }
 //float brightness = result / (float)i;
 // NSLog(@"Image Brightness : %f",brightness);
 //        if (brightness > 0.8 || brightness < 0.3) {
 //            return false
 //        }
 return true
 }
 */
