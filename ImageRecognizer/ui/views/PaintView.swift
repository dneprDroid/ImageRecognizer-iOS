//
//  PaintView.swift
//  ImageRecognizer
//
//  Created by user on 12/26/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit


class PaintView: UIImageView {
    
    private var lastPoint = CGPoint.zero
    
    var brushWidth: CGFloat = 5.0
    var brushColor: (red: CGFloat, green: CGFloat, blue: CGFloat)  = rgbValues(UIColor.blueColor())
    private var paintMode: PaintMode = .Drawing

    var path: UIBezierPath  {
        let path  = UIBezierPath()
        path.stroke()
        path.lineWidth = 15
        return path
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewInit()
    }
    
    func viewInit() {
        self.contentMode = .ScaleAspectFit

        let gradient = CAGradientLayer()
        let gradientHeight = self.frame.height / 6
        
        let gradientFrame = CGRect(x: 0, y: self.frame.height - gradientHeight, width: self.frame.width, height: gradientHeight)

        let blackColor = UIColor(white: 0.1, alpha: 0.5).CGColor
        gradient.frame = self.layer.convertRect(gradientFrame, toLayer: gradient)

        gradient.colors = [UIColor.clearColor().CGColor, blackColor]
        self.layer.insertSublayer(gradient, atIndex: 0)
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
        
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), true)
        CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(), true)
        CGContextSetLineJoin(UIGraphicsGetCurrentContext(), .Round)
        CGContextSetMiterLimit(UIGraphicsGetCurrentContext(), 2.0)
        
        CGContextStrokePath(context)
        
        self.image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
    }
    
}

enum PaintMode {
    case Drawing
    case Photo
}