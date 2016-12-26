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
    
    var lastPoint = CGPoint.zero
    
    var brushWidth: CGFloat = 5.0
    let brushColor: (red: CGFloat, green: CGFloat, blue: CGFloat)  = rgbValues(UIColor.blueColor())

    var path: UIBezierPath  {
        let path  = UIBezierPath()
        path.stroke()
        path.lineWidth = 15
        return path
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            lastPoint = touch.locationInView(self)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self)
            drawLineFrom(lastPoint, toPoint: currentPoint)

            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    

        UIGraphicsBeginImageContext(self.frame.size)
        self.image?.drawInRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .Normal, alpha: 1.0)
        self.image?.drawInRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .Normal, alpha: 1)
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

       // self.image = nil
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        self.image?.drawInRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        

        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        CGContextSetLineCap(context, .Round)
        CGContextSetLineWidth(context, brushWidth)
        CGContextSetRGBStrokeColor(context, brushColor.red, brushColor.green, brushColor.blue, 1.0)
        CGContextSetBlendMode(context, .Normal)
        
        CGContextStrokePath(context)
        
        self.image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
    }
    
}