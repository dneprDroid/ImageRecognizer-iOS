//
//  AlertToast.swift
//  ImageRecognizer
//
//  Created by user on 12/27/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit

class AlertToastView: UILabel {
    
    @IBInspectable var topInset: CGFloat = 0.0
    @IBInspectable var leftInset: CGFloat = 0.0
    @IBInspectable var bottomInset: CGFloat = 0.0
    @IBInspectable var rightInset: CGFloat = 0.0
    
    var insets: UIEdgeInsets {
        get {
            return UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset)
        }
        set {
            topInset = newValue.top
            leftInset = newValue.left
            bottomInset = newValue.bottom
            rightInset = newValue.right
        }
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var adjSize = super.sizeThatFits(size)
        adjSize.width += leftInset + rightInset
        adjSize.height += topInset + bottomInset
        
        return adjSize
    }
    
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += leftInset + rightInset
        contentSize.height += topInset + bottomInset
        
        return contentSize
    }
    
    class func show(rootView: UIView, text: String) {
        let label = AlertToastView()
        label.accessibilityIdentifier = "toastView"//for testing
        
        label.text = text
        
        label.textColor = UIColor.white
        label.layer.cornerRadius = 10
        label.layer.backgroundColor = UIColor.blueLight().cgColor
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 0.8
        
        //shadow
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 4, height: 4)
        label.layer.shadowOpacity = 0.5
        label.layer.shadowRadius = 1.0
        
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        label.frame.size.width =  rootView.frame.width * 0.7

        label.sizeToFit()
        label.center = CGPoint(x: rootView.frame.width / 2, y: rootView.frame.height / 5)

        rootView.addSubview(label)
        
        UIView.animate(withDuration: 1, delay: 2.0, options: .curveLinear, animations: {
            label.layer.opacity = 0
        }, completion: { completed in
            if completed {
              label.removeFromSuperview()
            }
        })
    }
}
