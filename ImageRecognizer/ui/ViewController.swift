//
//  ViewController.swift
//  ImageRecognizer
//
//  Created by user on 12/24/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var paintView: PaintView!
    
    fileprivate var photoImage: UIImage?
    fileprivate lazy var picker: UIImagePickerController = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToolbar()
        
        picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
    }
    
    private func setupToolbar() {
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationItem.title = "ImageRecognizer"
        
        let titleShadow = NSShadow()
        titleShadow.shadowColor =  UIColor.black
        titleShadow.shadowOffset = CGSize(width: 0, height: 1.5)

        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.shadow:  titleShadow,
            NSAttributedStringKey.font:    UIFont(name: "HelveticaNeue-CondensedBlack", size: 17.0)!]
    }
}


//MARK: IBActions
extension ViewController {
    
    @IBAction private func onRecognTapped(_ sender: RecognButton) {
        if paintView.paintModeIsDrawing() {
            if let image = paintView.getBackground() {
                self.photoImage = image
            }
        }
        
        if let image = photoImage {
            sender.startAnimation()
            //saveImageToGallery(image)
            
            NNManager.shared().recognizeImage(image,
                                              callback: {[weak self] (description:String?) in
                print("image: \(description ?? "Undefined" )")
                sender.stopAnimation()
                guard let imageDescription = description,
                    let rootView = self?.view else { return }
                AlertToastView.show(rootView: rootView, text: imageDescription)
            })
        }
    }
    
    @IBAction private func clear(_ sender: UIButton) {
        self.paintView.clear()
        self.paintView.setPaintMode(mode: .Drawing)
    }
    
    @IBAction private func paintModeEnabled(_ sender: UIButton) {
        if self.paintView.paintModeIsPhoto() {
            self.paintView.clear()
        }
        self.paintView.setPaintMode(mode: .Drawing)
    }
    
    @IBAction private func onSelectFromGallery(_ sender: UIButton) {
        present(picker, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            paintView.setPhoto(photo: pickedImage)
            self.photoImage = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
}
