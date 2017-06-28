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
        
        // set up the vision model
        guard let visionModel = try? VNCoreMLModel(for: Resnet50().model) else {
            fatalError("Could not load model")
        }
        
        // set up the request using our vision model
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassifications)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
        visionRequests = [classificationRequest]
        
        // begin the session
        self.captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        DispatchQueue.main.async { [unowned self] in
        let correctedImage = uiImage
            .applyingFilter("CIColorControls", withInputParameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 2.5,
                kCIInputBrightnessKey: -1.53
                ])
            //.applyingFilter("CIColorInvert", withInputParameters: nil)
            self.frameImageView.image = UIImage(ciImage: correctedImage)
            
//            var requestOptions: [VNImageOption: Any] = [:]
//           let imageRequestHandler = VNImageRequestHandler(image: correctedImage, options: requestOptions)
//            do {
//                try imageRequestHandler.perform(self.visionRequests)
//            } catch {
//                print(error)
//            }
            //self.captured(ciImage: uiImage)
        }
    }
    
    func handleClassifications(request: VNRequest, error: Error?) {
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
        
        DispatchQueue.main.async {
            print("result: \(classifications)")
            //self.resultView.text = classifications
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

