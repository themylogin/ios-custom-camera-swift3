//
//  ViewController.swift
//  CustomCamera
//
//  Created by Adarsh V C on 06/10/16.
//  Copyright © 2016 FAYA Corporation. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var btnCapture: UIButton!
    @IBOutlet weak var btnOpen: UIButton!
    @IBOutlet weak var opacitySlider: UISlider!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var thicknessSlider: UISlider!
    @IBOutlet weak var gesturesView: UIView!
    
    var pinchGesture : UIPinchGestureRecognizer?
    var panGesture : UIPanGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    var taps = 0
    
    let imgOverlay = UIImageView()
    var img : UIImage?

    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        if let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] {
            // Loop through all the capture devices on this phone
            for device in devices {
                // Make sure this particular device supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    // Finally check the position and confirm we've got the back camera
                    if(device.position == AVCaptureDevicePosition.back) {
                        captureDevice = device
                        if captureDevice != nil {
                            print("Capture device found")
                            beginSession()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func actionCameraCapture(_ sender: AnyObject) {
        
        print("Camera button pressed")
        saveToCamera()
    }
    
    @IBAction func loadOverlay(_ sender: AnyObject) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showImage() {
        self.imgOverlay.alpha = CGFloat(self.opacitySlider!.value)
        if (self.img != nil) {
            if self.thresholdSlider!.value == 0 {
                self.imgOverlay.image = self.img!;
            } else {
                self.imgOverlay.image = OpenCVWrapper.cannyEdges(self.img!,
                                                                 threshold: Int32(self.thresholdSlider!.value),
                                                                 thickness: Int32(self.thicknessSlider!.value));
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.img = pickedImage
            self.showImage()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func beginSession() {
        
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            
        }
        catch {
            print("error: \(error.localizedDescription)")
        }
        
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) else {
            print("no preview layer")
            return
        }
        
        self.view.layer.addSublayer(previewLayer)
        previewLayer.frame = self.view.layer.frame
        captureSession.startRunning()
        
        self.imgOverlay.contentMode = .scaleAspectFit
        self.imgOverlay.frame = self.view.layer.frame
        
        self.view.addSubview(imgOverlay)
        self.view.addSubview(btnCapture)
        self.view.addSubview(btnOpen)
        self.view.addSubview(opacitySlider)
        self.view.addSubview(thresholdSlider)
        self.view.addSubview(thicknessSlider)
        self.view.addSubview(gesturesView)
        
        self.gesturesView.isUserInteractionEnabled = true
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.pinchedView))
        self.gesturesView.addGestureRecognizer(pinchGesture!)
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.panView))
        self.gesturesView.addGestureRecognizer(panGesture!)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapView))
        tapGesture?.numberOfTapsRequired = 1
        self.gesturesView.addGestureRecognizer(tapGesture!)
    }
    
    func pinchedView(sender: UIPinchGestureRecognizer) {
        imgOverlay.transform = imgOverlay.transform.scaledBy(x: sender.scale, y: sender.scale)
        sender.scale = 1.0
    }
    
    func panView(sender: UIPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: self.view)
            
            imgOverlay.center = CGPoint(x: imgOverlay.center.x + translation.x, y: imgOverlay.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    func tapView(sender: UIPanGestureRecognizer) {
        if sender.state == .ended {
            imgOverlay.transform = imgOverlay.transform.rotated(by: CGFloat(-Double.pi / 2))
        }
    }
    
    @IBAction func opacitySliderValueChanged(_ sender: UISlider) {
        self.showImage()
    }
    
    @IBAction func thresholdSliderValueChanged(_ sender: UISlider) {
        self.showImage()
    }
    
    @IBAction func thicknessSliderValueChanged(_ sender: UISlider) {
        self.showImage()
    }
    
    func saveToCamera() {
        
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (CMSampleBuffer, Error) in
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(CMSampleBuffer) {
                    
                    if let cameraImage = UIImage(data: imageData) {
                        
                        UIImageWriteToSavedPhotosAlbum(cameraImage, nil, nil, nil)                        
                    }
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

