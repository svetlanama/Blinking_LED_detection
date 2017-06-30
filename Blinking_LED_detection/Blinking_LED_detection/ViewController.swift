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
   // var visionRequests = [VNRequest]()
    
    @IBOutlet weak var frameImageView: UIImageView!
    
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
        
        
        // set up the vision model
//        guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
//            fatalError("Could not load model")
//        }
//        // set up the request using our vision model
//        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassifications)
//        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
//        visionRequests = [classificationRequest]
        
        //test(image: UIImage(named: "IMG_2259.PNG")!)
       // searchRectangle(ciImage: CIImage(image: UIImage(named: "black14.jpg")!)!)
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
           // DispatchQueue.main.async {
                print("not detected object")
            //}
            return
        }
        
        print("=== detected object ===", detectedObject)
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
         searchRectangle(ciImage: correctedImage)
       // test(image: UIImage(named: "IMG_2259.PNG")!)
        DispatchQueue.main.async { [weak self] in //unowned
            
        //.applyingFilter("CIColorInvert", withInputParameters: nil)
           self?.frameImageView.image = UIImage(ciImage: correctedImage)
        }
    }
    
    func searchRectangle(ciImage: CIImage) {
        var requestOptions: [VNImageOption: Any] = [:]
        let handler = VNImageRequestHandler(ciImage: ciImage, options: requestOptions)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.rectanglesRequest])//[self.rectanglesRequest]) self.visionRequests
            } catch {
                print(error)
            }
        }
    }
    
    
    /*func handleClassifications(request: VNRequest, error: Error?) {
        if let theError = error {
            print("Error: \(theError.localizedDescription)")
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        let classifications = observations[0...4] // top 4 results
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(($0.confidence * 100.0).rounded())" })
            .joined(separator: "\n")
        
        print("Object detected:", classifications)
//        DispatchQueue.main.async {
//            self.resultView.text = classifications
//        }
    }*/
    
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



/* func createHistorgamm(inputImage: UIImage) {
 
 // let primaryView = GPUImageView(frame: binCameraView.frame)
 //  view = primaryView
 
 var sourcePicture = GPUImagePicture(image: inputImage, smoothlyScaleOutput: true)
 
 // Creating another view to show histogram
 let histView = GPUImageView(frame: CGRect(x: 0, y: 0,width: 200, height: 200))
 histView.backgroundColor = UIColor.red
 binCameraView.addSubview(histView)
 binCameraView.bringSubview(toFront: histView)
 
 // Create histogram filter and generator and point it to histogram view
 let histFilter = GPUImageHistogramFilter()
 let histGenerator = GPUImageHistogramGenerator()
 histGenerator.forceProcessing(at: CGSizeMake(200.0, 200.0))
 histGenerator.addTarget(histFilter)
 
 
 histFilter.addTarget(histGenerator)
 // Note target - hist view
 histGenerator.addTarget(histView)
 
 // Setup sepia filter just to show main picture
 let sepiaFilter = GPUImageSepiaFilter()
 sepiaFilter.forceProcessing(at: primaryView.sizeInPixels)
 
 sourcePicture?.addTarget(sepiaFilter)
 // Note target - main view
 sepiaFilter.addTarget(primaryView)
 
 sourcePicture?.processImage()
 
 }

func createHistorgamm(inputImage: UIImage) {
    let filter = GPUImageHistogramFilter(HistogramType.luminance)
    
    let histogramGraph = GPUImageHistogramGenerator()
    histogramGraph.forceProcessingAtSize(CGSize(200.0, 200.0))
    filter.addTaget(histogramGraph)
    
    let blendFilter =  GPUImageAlphaBlendFilter()
    blendFilter.mix = 0.75
    blendFilter.forceProcessingAtSize(CGSize(200.0, 200.0))
    cameraView.addTarget(blendFilter)
    histogramGraph.addTarget(blendFilter)
    blendFilter.addTagret(filterView)
    
}
 
 
 
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
