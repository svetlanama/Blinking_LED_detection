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
    let interval = 0.001 // 100 ms = 0.1
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
        
        if !flag {
            stopTimer()
            imagePorceccing.handleHistogramm()
        } else {
            imagePorceccing.resetWordResult()
            imagePorceccing.resetDecodedResult()
            imagePorceccing.resetHistogramm()
            startTimer()
        }
    }
    
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var binCameraView: UIView!
    @IBOutlet weak var frameImageView: UIImageView!
    @IBOutlet weak var smallImageView: UIImageView!
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }
    
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
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return ciImage
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        if flag && timerFlag {
            timerFlag = false
            DispatchQueue.main.async { [unowned self] in
                let croppedImage = self.cropImage(uiImage: uiImage)
                self.performImageRecognition(uimage: croppedImage!)
            }
        }
    }
    
    func cropImage(uiImage: CIImage) -> UIImage? {
        
        let originalRect = focusView.frame
        var convertedRect = self.cameraLayer.metadataOutputRectConverted(fromLayerRect: originalRect)
        convertedRect.origin.y = 1 - convertedRect.origin.y
        
        var outputRect = cameraLayer.metadataOutputRectConverted(fromLayerRect: originalRect)
        
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
        let imgSize = 25
        
        //DispatchQueue.global(qos: .background).async {
            let smallImage = image.resize(width: imgSize, height: imgSize)
            let data = smallImage.binarize()
        
            //DispatchQueue.main.sync { [weak self] in
                smallImageView.image = data.binarizedImage.uiImage
                if data.isWhite {
                    print("white spot detected")
                    imagePorceccing.addValueToHistogramm(value: 1)
                } else {
                    print("white spot NOT detected")
                    imagePorceccing.addValueToHistogramm(value: 0)
                }
            //}
        //}
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(ViewController.getCameraFrame(timer:)), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
    
    @objc func getCameraFrame(timer: Timer!) {
        timerFlag = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



