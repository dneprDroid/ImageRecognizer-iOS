//
//  AlertToast.swift
//  ImageRecognizer
//
//  Created by user on 12/27/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit

class AlertToastView {
    
    class func show(rootView: UIView, text: String) {
        let label = UILabel()
        label.textColor = UIColor.blackColor()
        label.text = text
        label.textAlignment = .Center
        label.frame = CGRect(x: 0, y: 0, width: rootView.frame.width * 0.7, height: 50)
        label.center = CGPoint(x: rootView.frame.width / 2, y: rootView.frame.height / 5)
        rootView.addSubview(label)
        
        UIView.animateWithDuration(1, delay: 2.0, options: .CurveLinear, animations: {
            label.layer.opacity = 0
            }, completion: { completed in
                if completed {
                    label.removeFromSuperview()
                }
        })
    }
}