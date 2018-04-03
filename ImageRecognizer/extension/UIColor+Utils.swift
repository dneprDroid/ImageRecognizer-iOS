//
//  UIColor.swift
//  ImageRecognizer
//
//  Created by user on 12/27/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    class func blueLight() -> UIColor {
        return UIColor.rgb(0, 128, 255)
    }
    
    func rgbValues() -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            
            return (fRed, fGreen, fBlue)
        } else {
            return (0, 0, 0)
        }
    }
    
    class func rgb(_ red: CGFloat,_ green: CGFloat,_ blue: CGFloat) -> UIColor {
        return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
