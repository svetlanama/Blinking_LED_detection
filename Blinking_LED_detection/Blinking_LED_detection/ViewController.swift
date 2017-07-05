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
import GPUImage


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //let gpuImageHelper = GPUImageHelper()
    @IBOutlet private weak var focusView: UIView! {
        didSet {
            focusView.layer.borderColor = UIColor.yellow.cgColor
            focusView.layer.borderWidth = 1
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
        
        let image = UIImage(named: "3.png")  //"Blob.png")//
        
        //let corectedImage = performImageBinarization(uiImage:ciimage)
        //let img = UIImage(ciImage: corectedImage)
        //var img = image?.grayscaleImage(contrast: 1.0)
        
        //works
//         let binImage = image!.doBinarize()
//         frameImageView.image = binImage
//         guard let ciimage = CIImage(image: binImage!) else { return }
//         searchLightSpot(ciImage: ciimage)
//
//         imageColorAnalyze(img: binImage!)
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
            return
        }
        print("=== detected object ===", detectedObject)
    }
    
   
    
   func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
    
        imageRecognizer(image: UIImage(ciImage: uiImage))
    
//        DispatchQueue.main.async { [unowned self] in //unowned
//            self.frameImageView.image = UIImage(ciImage: correctedImage)
//        }
    }
    
    func imageRecognizer(image: UIImage) {
        let binImage = image.doBinarize()
        
        DispatchQueue.main.async { [unowned self] in
           self.frameImageView.image = binImage
        }
        guard let ciimage = CIImage(image: binImage!) else { return }
        searchLightSpot(ciImage: ciimage)
        
        //imageColorAnalyze(img: binImage!)
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
    
    func imageColorAnalyze(img: UIImage) {
        DispatchQueue.global(qos: .background).async { [weak self]
            () -> Void in
            
            for  y in 0..<img.size.height.toInt() {
                for x in 0..<img.size.width.toInt() {
                    
                    let color = img.pixelColor(atLocation: CGPoint(x: x, y: y))
                    print("color: ", color ?? "no color")
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension CGFloat {
       func toInt() -> Int {
               return Int(self)
           }
    
}
