//
//  ViewController.swift
//  CameraApp
//
//  Created by Alexey Levashov on 1/10/17.
//  Copyright © 2017 Alexey Levashov. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, CameraAPIDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate  {

    var camera: CameraAPI?
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var takePhotoButton: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Start Camera
        self.imageView.isUserInteractionEnabled = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.camera = CameraAPI(view: self.cameraView);
        self.camera?.delegate = self
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //IBActions
    @IBAction func pinch(_ sender: Any) {
        self.camera?.setZoom(zoomFactor: (sender as! UIPinchGestureRecognizer).scale, sender: sender as! UIPinchGestureRecognizer)
    }
    
    @IBAction func takePhotoButton(_ sender: Any) {
        self.camera?.capturePhoto()
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
    
    //Delegates
    func capturedPhoto(dataImage: NSData) {
                    self.imageView.image = UIImage(data: dataImage as Data)
                    UIImageWriteToSavedPhotosAlbum(UIImage(data: dataImage as Data)!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}

