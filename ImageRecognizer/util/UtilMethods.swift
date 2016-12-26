//
//  UtilMethods.swift
//  ImageRecognizer
//
//  Created by user on 12/26/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit



func rgbValues(color: UIColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
    var fRed : CGFloat = 0
    var fGreen : CGFloat = 0
    var fBlue : CGFloat = 0
    var fAlpha: CGFloat = 0
    if color.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
        
        return (fRed, fGreen, fBlue)
    } else {
        return (0, 0, 0)
    }
}
