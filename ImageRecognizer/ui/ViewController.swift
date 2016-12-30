//
//  ViewController.swift
//  ImageRecognizer
//
//  Created by user on 12/24/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var paintView: PaintView!
    
    private var photoImage: UIImage?
    private var picker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToolbar()
        
        picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .PhotoLibrary
    }
    
    @IBAction func onRecognTapped(sender: RecognButton) {
        if paintView.paintModeIsDrawing() {
            if let image = paintView.getBackground() {
                self.photoImage = image
            }
        }
        
        if let image = photoImage {
            sender.startAnimation()
            //saveImageToGallery(image)

            NNManager.shared().recognizeImage(image, callback: { description in
                print("image: \(description)")
                sender.stopAnimation()
                AlertToastView.show(self.view, text: description)
            })
        }
    }
    
    @IBAction func clear(sender: UIButton) {
        self.paintView.clear()
        self.paintView.setPaintMode(.Drawing)
    }
    
    @IBAction func paintModeEnabled(sender: UIButton) {
        if self.paintView.paintModeIsPhoto() {
            self.paintView.clear()
        }
        self.paintView.setPaintMode(.Drawing)
    }
    
    @IBAction func onSelectFromGallery(sender: UIButton) {
        presentViewController(picker, animated: true, completion: nil)
    }
    
    private func setupToolbar() {
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationItem.title = "ImageRecognizer"
        
        let titleShadow = NSShadow()
        titleShadow.shadowColor =  UIColor.blackColor()
        titleShadow.shadowOffset = CGSize(width: 0, height: 1.5)

        self.navigationController?.navigationBar.titleTextAttributes = [
            NSShadowAttributeName:  titleShadow,
            NSFontAttributeName:    UIFont(name: "HelveticaNeue-CondensedBlack", size: 17.0)!]
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            paintView.setPhoto(pickedImage)
            self.photoImage = pickedImage
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
}