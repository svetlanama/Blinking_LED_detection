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
import EasyImagy



class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var timer: Timer?
    let interval =  0.1 // 100 ms
    var flag = false
    var timerFlag = false
    let imagePorceccing = ImageProcessing.sharedInstance
    
    @IBOutlet private weak var focusView: UIView! {
        didSet {
            focusView.layer.borderColor = UIColor.yellow.cgColor
            focusView.layer.borderWidth = 1
        }
    }
    
    @IBAction func onTakeFrame(_ sender: Any) {
      flag = !flag
      //  imagePorceccing.handleHistogramm()
        if !flag {
            stopTimer()
            imagePorceccing.handleHistogramm()
        } else {
            imagePorceccing.resetDecodedResult()
            imagePorceccing.resetHistogramm()
            startTimer()
        }
    }
    
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var binCameraView: UIView!
    private let context = CIContext()
    private var count = 0
    
    @IBOutlet weak var frameImageView: UIImageView!
    @IBOutlet weak var smallImageView: UIImageView!
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return ciImage
    }
    
    let stillImageOutput = AVCaptureStillImageOutput()
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
        
        //TEST
        //var image = UIImage(named: "Blob.png")//"3.png")
        // image = GPUImageHelper.cropImage(image, to: CGRect(x: 0, y:0 , width: 100, height: 100), andScaleTo: focusView.frame.size)
        // var binImage = image!.doBinarize()
        
        // frameImageView.image =  binImage
        //guard let ciimage = CIImage(image: binImage!) else { return }
        //searchLightSpot(ciImage: ciimage)
        
        //performImageRecognition(image: image)
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(ViewController.event(timer:)), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
    
    @objc func event(timer: Timer!) {
        print("timer")
        timerFlag = true
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        if flag && timerFlag {
            DispatchQueue.main.async { [unowned self] in
                let croppedImage = self.cropImage(uiImage: uiImage)
                self.performImageRecognition(uimage: croppedImage!)
            }
            timerFlag = false
        }
    }
    
    func cropImage(uiImage: CIImage) -> UIImage? {
        
        let originalRect = focusView.frame
        var convertedRect = self.cameraLayer.metadataOutputRectConverted(fromLayerRect: originalRect)
        convertedRect.origin.y = 1 - convertedRect.origin.y
        
        var outputRect = cameraLayer.metadataOutputRectConverted(fromLayerRect: originalRect)
        //print("outputRect: ", outputRect)
        //  outputRect.origin.y = outputRect.origin.x
        //  outputRect.origin.x = 0
        //  outputRect.size.height = outputRect.size.width
        //  outputRect.size.width = 1
        
        let takenImage = UIImage(ciImage: uiImage)
        let context = CIContext()
        let takenCGImage: CGImage = context.createCGImage(uiImage, from: uiImage.extent)!
        
        let width = CGFloat(GPUImageHelper.getWidth(takenCGImage))
        let height = CGFloat(GPUImageHelper.getHeight(takenCGImage))
        let cropRect = CGRect(x: outputRect.origin.x * width, y: outputRect.origin.y * height, width: outputRect.size.width * width, height: outputRect.size.height * height)
        
        if let cropCGImage: CGImage = takenCGImage.cropping(to: cropRect) {
            let its: UIImage = UIImage(cgImage: cropCGImage, scale: 1, orientation: takenImage.imageOrientation)
            return its
        }
        return nil
    }
    
    func performImageRecognition(uimage: UIImage) {
        
        let image = Image<RGBA>(uiImage: uimage)!
        let binarized = image.map {  $0.gray < 245 ? .black : .white }
        
        self.frameImageView.image = binarized.uiImage
        let smallInage = binarized.resize(width: 50, height: 50)
        self.smallImageView.image = smallInage.uiImage
        
        if isWhiteSpotExists(image: smallInage) {
            print("white spot detected")
            imagePorceccing.addValueToHistogramm(value: 1)
        } else {
            print("white spot NOT detected")
            imagePorceccing.addValueToHistogramm(value: 0)
        }
    }
    
    func isWhiteSpotExists(image: Image<RGBA>) -> Bool {
        
         var kWidth = 0
         for x in 0..<image.width{
              //print("======== W =======")
            var kHeight = 0
            for y in 0..<image.height {
                 //print("======== H =======")
                if let pixel = image.pixel(x, y) {
                    //print(pixel)
                    if pixel.description == "#FFFFFFFF" {
                        kHeight += 1
                        //print("H Pixel is white: \(kHeight)")
                    } else {
                        kHeight = 0
                    }
                    
                    if kHeight > 10 { //define % 5% of height
                        kWidth += 1
                        break
                    }
                }
            }
            print("Hwhite: \(kHeight) Wwhite: \(kWidth)")
            if kHeight >= 10 && kWidth >= 10  {
                return true
            }
        }
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
