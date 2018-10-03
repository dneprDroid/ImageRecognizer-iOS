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
        let blackColor = UIColor(white: 0.1, alpha: 0.3).cgColor
        
        let arrayColors = [UIColor.clear.cgColor, blackColor]
        
        gradient.colors = arrayColors
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.locations = [0.88, 1.0]
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = self.bounds

    }
    
    func viewInit() {
        self.accessibilityIdentifier = "paintView"//for testing
        self.contentMode = .scaleAspectFit

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
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if paintModeIsPhoto() {
            return
        }
        if let touch = touches.first {
            lastPoint = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if paintModeIsPhoto() {
            return
        }
        if let touch = touches.first {
            let currentPoint = touch.location(in: self)
            drawLine(fromPoint: lastPoint, toPoint: currentPoint)

            lastPoint = currentPoint
        }
    }
    
    func setPhoto(photo: UIImage) {
        setPaintMode(mode: .Photo)
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if paintModeIsPhoto() {
            return
        }

        UIGraphicsBeginImageContext(self.frame.size)
        self.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .normal, alpha: 1.0)
        self.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .normal, alpha: 1)
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    private func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
        
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()

        self.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))

        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(.round)
        context?.setLineWidth(brushWidth)
        context?.setFillColor(UIColor.blueLight().cgColor)
        context?.setStrokeColor(UIColor.blueLight().cgColor)
        context?.setBlendMode(.normal)
        context?.setAllowsAntialiasing(true)
        context?.setShouldAntialias(true)
        context?.setLineJoin(.round)
        context?.setMiterLimit(2.0)
        context?.strokePath()
        
        self.image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
    }
    
}

enum PaintMode {
    case Drawing
    case Photo
}
