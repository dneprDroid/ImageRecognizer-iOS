//
//  RecognButton.swift
//  ImageRecognizer
//
//  Created by user on 12/26/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit

class RecognButton: UIButton {
    
    var animationDuration: TimeInterval = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        btnSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        btnSetup()
    }
    
    private func btnSetup() {
        self.backgroundColor = UIColor.blueLight()
        self.tintColor = .white
        
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 0.8
        self.imageEdgeInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        self.clipsToBounds = false
        
        self.isUserInteractionEnabled = true
    }
    
    func startAnimation() {
        self.setTitle("Recognition...", for: .normal)

        self.isUserInteractionEnabled = false
        UIView.animateKeyframes(withDuration: animationDuration,
                                delay: 0,
                                options: [.repeat,  .autoreverse],
                                animations: {
                                                
            UIView.addKeyframe(withRelativeStartTime: 0.0,
                relativeDuration: self.animationDuration / 2, animations: {
                self.backgroundColor = UIColor.cyan
            })
            
            UIView.addKeyframe(withRelativeStartTime: self.animationDuration / 2,
                relativeDuration: self.animationDuration / 2, animations: {
                self.backgroundColor = UIColor.blueLight()
            })
            
            }, completion: nil)
    }
    
    func stopAnimation() {
        self.setTitle("What is", for: .normal)
        
        self.isUserInteractionEnabled = true
        self.layer.removeAllAnimations()
    }
}
