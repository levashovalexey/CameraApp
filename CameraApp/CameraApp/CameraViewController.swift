//
//  ViewController.swift
//  CameraApp
//
//  Created by Alexey Levashov on 1/10/17.
//  Copyright © 2017 Alexey Levashov. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate,UIPopoverControllerDelegate,UINavigationControllerDelegate  {

    
    //variables ant properties
    var photoOutput: AVCapturePhotoOutput!
    var session: AVCaptureSession!
    var captureDevice: AVCaptureDevice?
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var takePhotoButton: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Start Camera
        self.imageView.isUserInteractionEnabled = true
        self.configureCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pinch(_ sender: Any) {
        
        let vZoomFactor = ((sender as! UIPinchGestureRecognizer).scale)
        setZoom(zoomFactor: vZoomFactor, sender: sender as! UIPinchGestureRecognizer)
    }
    
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
    
    @IBAction func takePhotoButton(_ sender: Any) {
        capturePhoto()
    }
    
    @IBAction func openPhoto(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
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
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            self.imageView.image = UIImage(data: dataImage)
            UIImageWriteToSavedPhotosAlbum(UIImage(data: dataImage)!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    private func configureCamera() -> Bool {
        // init camera device
        
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
            return false
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
            previewLayer.frame = self.cameraView.bounds
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
            self.cameraView.layer.addSublayer(previewLayer)
            
            self.session.startRunning()
        }
        catch {
            // handle error here
        }
        return true
    }

}

