//
//  CameraAPI.swift
//  CameraApp
//
//  Created by Alexey Levashov on 1/19/17.
//  Copyright © 2017 Alexey Levashov. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraAPIDelegate: class {
    func capturedPhoto(dataImage: NSData)
    
   
}

class CameraAPI: NSObject, AVCapturePhotoCaptureDelegate {
    
    //variables ant properties
    private var photoOutput: AVCapturePhotoOutput!
    private var session: AVCaptureSession!
    private var captureDevice: AVCaptureDevice?
    
    weak var delegate:CameraAPIDelegate?
    
    init(view: UIView) {
        let captureSession: AVCaptureDeviceDiscoverySession? = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInDuoCamera, AVCaptureDeviceType.builtInTelephotoCamera,AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.back)
        
        // find back camera
        for device in (captureSession?.devices)! {
            if (device as AnyObject).position == AVCaptureDevicePosition.back {
                self.captureDevice = device
            }
        }
        
        if self.captureDevice != nil {
            // Debug
            print(captureDevice!.localizedName)
            print(captureDevice!.modelID)
        } else {
            print("Missing Camera")
        }
        
        // init device input
        do {
            let deviceInput: AVCaptureInput = try AVCaptureDeviceInput(device: captureDevice) as AVCaptureInput
            
            self.photoOutput = AVCapturePhotoOutput()
            
            // init session
            self.session = AVCaptureSession()
            self.session.sessionPreset = AVCaptureSessionPresetPhoto
            self.session.addInput(deviceInput as AVCaptureInput)
            self.session.addOutput(self.photoOutput)
            
            // layer for preview
            let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session) as AVCaptureVideoPreviewLayer
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            self.session.startRunning()
        }
        catch {
            // handle error here
        }
    }
    
    //Public API
    func setZoom(zoomFactor:CGFloat, sender : UIPinchGestureRecognizer) {
        var device: AVCaptureDevice = self.captureDevice!
        var error:NSError!
        do{
            try device.lockForConfiguration()
            defer {device.unlockForConfiguration()}
            if (zoomFactor <= device.activeFormat.videoMaxZoomFactor) {

                let desiredZoomFactor:CGFloat = zoomFactor + atan2(sender.velocity, 5.0);
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, device.activeFormat.videoMaxZoomFactor));
            }
            else {
                NSLog("Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, zoomFactor);
            }
        }
        catch error as NSError{
            NSLog("Unable to set videoZoom: %@", error.localizedDescription);
        }
        catch _{
        }
    }
    
    func capturePhoto() {
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160,
                             ]
        settings.previewPhotoFormat = previewFormat
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    //delegate
    
    internal func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            self.delegate?.capturedPhoto(dataImage: dataImage as NSData)
        }
        
    }
    
    //Private API
    private func switchCaptureImput() {
        //To Do
    }
    
    

}


