//
//  PaintView.swift
//  ImageRecognizer
//
//  Created by user on 12/26/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit

//TODO: set drawing area as a square, because predictor accepts only square images (224 x 224)
class PaintView: UIImageView {
    
    private var lastPoint = CGPoint.zero
    
    var brushWidth: CGFloat = 5.0
    var brushColor: (red: CGFloat, green: CGFloat, blue: CGFloat)  = UIColor.blueLight().rgbValues()
    private var paintMode: PaintMode = .Drawing

    //bottom gradient
    private let gradient : CAGradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.masksToBounds = true
        let blackColor = UIColor(white: 0.1, alpha: 0.3).CGColor
        
        let arrayColors = [UIColor.clearColor().CGColor, blackColor]
        
        gradient.colors = arrayColors
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.locations = [0.88, 1.0]
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        
        self.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        super.layoutSublayersOfLayer(layer)
        gradient.frame = self.bounds
    }
    
    func viewInit() {
        self.accessibilityIdentifier = "paintView"//for testing
        self.contentMode = .ScaleAspectFit

        //fill color
        /*
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        let drawRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height)
        CGContextSetRGBFillColor(context, 1, 1, 1, 1.0)
        CGContextFillRect(context, drawRect)
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        */
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if paintModeIsPhoto() {
            return
        }
        if let touch = touches.first {
            lastPoint = touch.locationInView(self)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if paintModeIsPhoto() {
            return
        }
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self)
            drawLineFrom(lastPoint, toPoint: currentPoint)

            lastPoint = currentPoint
        }
    }
    
    func setPhoto(photo: UIImage) {
        setPaintMode(.Photo)
        self.image = photo
    }
    
    func setPaintMode(mode: PaintMode) {
        self.paintMode = mode
    }
    
    func paintModeIsDrawing() -> Bool {
        return paintMode == .Drawing
    }
    
    func paintModeIsPhoto() -> Bool {
        return paintMode == .Photo
    }
    
    func clear() {
        self.image = nil
    }
    
    func getBackground() -> UIImage? {
        return self.image
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if paintModeIsPhoto() {
            return
        }

        UIGraphicsBeginImageContext(self.frame.size)
        self.image?.drawInRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .Normal, alpha: 1.0)
        self.image?.drawInRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .Normal, alpha: 1)
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    private func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()

        self.image?.drawInRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))

        
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        CGContextSetLineCap(context, .Round)
        CGContextSetLineWidth(context, brushWidth)
        CGContextSetRGBStrokeColor(context, brushColor.red, brushColor.green, brushColor.blue, 1.0)
        CGContextSetBlendMode(context, .Normal)
        
        CGContextSetAllowsAntialiasing(context, true)
        CGContextSetShouldAntialias(context, true)
        CGContextSetLineJoin(context, .Round)
        CGContextSetMiterLimit(context, 2.0)
        CGContextStrokePath(context)
        
        self.image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
    }
    
}

enum PaintMode {
    case Drawing
    case Photo
}