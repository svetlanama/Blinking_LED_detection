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
//import GPUImage

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var binCameraView: UIView!
    private let context = CIContext()
    private var count = 0
    var visionRequests = [VNRequest]()
    
    @IBOutlet weak var frameImageView: UIImageView!
    
    let filter = CIFilter(name: "CIColorControls", withInputParameters: nil)! //CIColorMap CISepiaTone CIColorControls
    let blurfilter = CIFilter(name: "CIGaussianBlur")!
    
    /*func captured(ciImage: CIImage) {
     //let orientation = CGImagePropertyOrientation(rawValue: UInt32(UIImageOrientation.up.rawValue))
     //let imageElement = ciImage.applyingOrientation(Int32(orientation!.rawValue))
     
     filter.setValue(ciImage, forKey: kCIInputImageKey)
     filter.setValue(-1.53, forKey: kCIInputBrightnessKey) //-1.53
     filter.setValue(0.0, forKey: kCIInputSaturationKey)
     filter.setValue(2.1, forKey: kCIInputContrastKey) //3
     
     if let output = filter.outputImage {
     if let cgimg = context.createCGImage(output, from: output.extent) {
     let processedImage = UIImage(cgImage: cgimg)
     frameImageView.image = removeRotationForImage(image: processedImage)
     //frameImageView.image?.set.imageOrientation = UIImageOrientation.Up
     }
     }
     }*/
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return ciImage
    }
    
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
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
        
        // begin the session
        self.captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }
    
    lazy var rectanglesRequest: VNDetectRectanglesRequest = {
        return VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
    }()
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation]
            else {
                print("unexpected result type from VNDetectRectanglesRequest")
                return
                //fatalError("unexpected result type from VNDetectRectanglesRequest")
                //
        }
        guard let detectedRectangle = observations.first else {
           // DispatchQueue.main.async {
                print("not detected rect")
            //}
            return
        }
        
          print("=== detected rect ===")
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        let correctedImage = uiImage
            .applyingFilter("CIColorControls", withInputParameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 2.5,
                kCIInputBrightnessKey: -1.53
                ])
        
        test(image: UIImage(ciImage: uiImage))
        DispatchQueue.main.async { [weak self] in //unowned
            
            //.applyingFilter("CIColorInvert", withInputParameters: nil)
            self?.frameImageView.image = UIImage(ciImage: correctedImage)
            
            
//            var requestOptions: [VNImageOption: Any] = [:]
//            let handler = VNImageRequestHandler(ciImage: correctedImage, options: requestOptions)
//            DispatchQueue.global(qos: .userInteractive).async {
//                do {
//                    try handler.perform([self.rectanglesRequest])
//                } catch {
//                    print(error)
//                }
//            }
            //self.captured(ciImage: uiImage)
        }
    }
    
    func test(image: UIImage) -> Bool {
       // var result  = 0
       // var i = 0
        let color = image.pixelColor(atLocation: CGPoint(x: 15, y: 15))
            print("color:", color)
            
        
        for  y in 0..<image.size.height.toInt() {
            for x in 0..<image.size.width.toInt() {
                
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
