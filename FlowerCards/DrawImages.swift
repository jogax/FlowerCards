//
//  DrawImages.swift
//  JLinesV2
//
//  Created by Jozsef Romhanyi on 30.04.15.
//  Copyright (c) 2015 Jozsef Romhanyi. All rights reserved.
//

import UIKit



class DrawImages {
    var pfeillinksImage = UIImage()
    var pfeilrechtsImage = UIImage()
    var settingsImage = UIImage()
    var backImage = UIImage()
    var undoImage = UIImage()
    var restartImage = UIImage()
    var exchangeImage = UIImage()
    var uhrImage = UIImage()
    var cardPackage = UIImage()
    var tippImage = UIImage()
    
    //let imageColor = GV.khakiColor.CGColor
    let opaque = false
    let scale: CGFloat = 1
    
    init() {
        self.pfeillinksImage = drawPfeillinks(CGRect(x: 0, y: 0, width: 100, height: 100))
//        self.pfeilrechtsImage = pfeillinksImage.imageRotatedByDegrees(180.0, flip: false)
        self.settingsImage = drawSettings(CGRect(x: 0, y: 0, width: 100, height: 100))
        self.undoImage = drawUndo(CGRect(x: 0, y: 0, width: 100, height: 100))
        self.restartImage = drawRestart(CGRect(x: 0, y: 0, width: 100, height: 100))
        self.exchangeImage = drawExchange(CGRect(x: 0, y: 0, width: 100, height: 100))
        self.backImage = drawBack(CGRect(x: 0, y: 0, width: 100, height: 100))
        self.cardPackage = drawCardPackage(CGRect(x: 0, y: 0, width: 100, height: 100))
        self.tippImage = drawTipps(CGRect(x: 0, y: 0, width: 100, height: 100))
        
    }
    
    func drawPfeillinks(_ frame: CGRect) -> UIImage {
        let multiplier = frame.width / frame.height
        let size = CGSize(width: frame.width * multiplier, height: frame.height)
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setStrokeColor(UIColor.black.cgColor)
        
        /*
        CGContextSetLineWidth(ctx, 0.5)
        let center1 = CGPoint(x: frame.width / 2, y: frame.height / 2)
        let radius1 = frame.width / 2 - 5
        CGContextAddArc(ctx, center1.x, center1.y, radius1, CGFloat(0), CGFloat(2 * M_PI), 1)
        CGContextSetFillColorWithColor(ctx, imageColor)
        //CGContextSetStrokeColorWithColor(ctx,GV.springGreenColor.CGColor)
        CGContextDrawPath(ctx, kCGPathFillStroke)
        CGContextStrokePath(ctx)
        */
        ctx!.setLineWidth(4.0)
        ctx!.beginPath()
        
        let adder:CGFloat = 10.0
        let p1 = CGPoint(x: frame.origin.x + 1.2 * adder, y: frame.height / 2)
        let p2 = CGPoint(x: frame.origin.x + adder + frame.width / 4,   y: frame.origin.y + frame.height / 4)
        let p3 = CGPoint(x: frame.origin.x + adder + frame.width / 4,   y: frame.origin.y + frame.height / 2.5)
        let p4 = CGPoint(x: frame.origin.x - adder + frame.width - adder,       y: frame.origin.y + frame.height / 2.5)
        let p5 = CGPoint(x: frame.origin.x - adder + frame.width - adder,       y: frame.height   - frame.height / 2.5)
        let p6 = CGPoint(x: frame.origin.x + adder + frame.width / 4,   y: frame.height   - frame.height / 2.5)
        let p7 = CGPoint(x: frame.origin.x + adder + frame.width / 4,   y: frame.height   - frame.height / 4)
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
        ctx!.addLine(to: CGPoint(x: p3.x, y: p3.y))
        ctx!.addLine(to: CGPoint(x: p4.x, y: p4.y))
        ctx!.addLine(to: CGPoint(x: p5.x, y: p5.y))
        ctx!.addLine(to: CGPoint(x: p6.x, y: p6.y))
        ctx!.addLine(to: CGPoint(x: p7.x, y: p7.y))
        ctx!.addLine(to: CGPoint(x: p1.x, y: p1.y))
        //CGContextSetAlpha(ctx, 0)
        ctx!.setFillColor(red: 0.5, green: 0.5, blue: 0, alpha: 1)
        ctx!.strokePath()
        /*
        let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        let radius = frame.width / 2 - 5
        CGContextAddArc(ctx, center.x, center.y, radius, CGFloat(0), CGFloat(2 * M_PI), 1)
        CGContextStrokePath(ctx)
        */
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }

    func drawCardPackage(_ frame: CGRect) -> UIImage {
        let multiplier = frame.width / frame.height
        let size = CGSize(width: frame.width * multiplier, height: frame.height)
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setStrokeColor(UIColor.blue.cgColor)

        ctx!.setLineWidth(0.2)
        
        ctx!.stroke(frame)
        

        ctx!.setLineWidth(0.5)
        ctx!.beginPath()

        for index in 1...10 {
            let p1 = CGPoint(x: frame.origin.x, y: frame.height - frame.height / 10 * CGFloat(index))
            let p2 = CGPoint(x: frame.origin.x + frame.width / 10 * CGFloat(index), y: frame.height)
            let p3 = CGPoint(x: frame.width, y: frame.origin.y + frame.height / 10 * CGFloat(index))
            let p4 = CGPoint(x: frame.width - frame.width / 10 * CGFloat(index), y: frame.origin.y)
            let p5 = CGPoint(x: frame.width, y: frame.height - frame.height / 10 * CGFloat(index))
            let p6 = CGPoint(x: frame.width - frame.width / 10 * CGFloat(index), y: frame.height)
            
            let p7 = CGPoint(x: frame.origin.x, y: frame.height - frame.height / 10 * CGFloat(index))
            let p8 = CGPoint(x: frame.width - frame.width / 10 * CGFloat(index), y: frame.origin.y)
            ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
            ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
            ctx!.move(to: CGPoint(x: p3.x, y: p3.y))
            ctx!.addLine(to: CGPoint(x: p4.x, y: p4.y))
            ctx!.move(to: CGPoint(x: p5.x, y: p5.y))
            ctx!.addLine(to: CGPoint(x: p6.x, y: p6.y))
            ctx!.move(to: CGPoint(x: p7.x, y: p7.y))
            ctx!.addLine(to: CGPoint(x: p8.x, y: p8.y))
            ctx!.strokePath()
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }

    func drawBack(_ frame: CGRect) -> UIImage {
        let size = CGSize(width: frame.width, height: frame.height)
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setStrokeColor(UIColor.black.cgColor)
        
        ctx!.setLineWidth(16.0)
        ctx!.beginPath()
        
        let adder:CGFloat = frame.width / 8
        
        let p1 = CGPoint(x: frame.origin.x + adder,                 y: frame.origin.y + adder)
        let p2 = CGPoint(x: frame.origin.x + adder,                 y: frame.origin.y + frame.height - adder)
        let p3 = CGPoint(x: frame.origin.x + frame.height - adder,  y: frame.origin.y + frame.height - adder)
        let p4 = CGPoint(x: frame.origin.x + frame.height - adder,  y: frame.origin.y + adder)
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p3.x, y: p3.y))
        ctx!.strokePath()
        
        ctx!.move(to: CGPoint(x: p2.x, y: p2.y))
        ctx!.addLine(to: CGPoint(x: p4.x, y: p4.y))
        ctx!.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }
    
    func drawExchange(_ frame: CGRect) -> UIImage {
        let size = CGSize(width: frame.width, height: frame.height)
        //let endAngle = CGFloat(2*M_PI)
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setStrokeColor(UIColor.black.cgColor)
        
        ctx!.beginPath()
        ctx!.setLineWidth(4.0)
        
        let adder:CGFloat = frame.width / 20
        let r0 = frame.width * 0.4
        
        let center1 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + adder + r0 * 1.5)
        let center2 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height - adder - r0 * 1.5)
        
        
//        let oneGrad:CGFloat = CGFloat(M_PI) / 180
        let minAngle1 = 330 * GV.oneGrad
        let maxAngle1 = 210 * GV.oneGrad
        //println("1 Grad: \(oneGrad)")
        
        let minAngle2 = 150 * GV.oneGrad
        let maxAngle2 = 30 * GV.oneGrad
        
//        CGContextAddArc(ctx, center1.x, center1.y, r0, minAngle1, maxAngle1, 1)
        ctx!.addArc(center: center1, radius: r0, startAngle: minAngle1, endAngle: maxAngle1, clockwise: true)
        ctx!.strokePath()
        
//        CGContextAddArc(ctx, center2.x, center2.y, r0, minAngle2, maxAngle2, 1)
        ctx!.addArc(center: center2, radius: r0, startAngle: minAngle2, endAngle: maxAngle2, clockwise: true)
        ctx!.strokePath()
        
        let p1 = pointOfCircle(r0, center: center1, angle: minAngle1)
        let p2 = CGPoint(x: p1.x - 20, y: p1.y - 30)
        let p3 = CGPoint(x: p1.x - 30, y: p1.y - 10)
        let p4 = pointOfCircle(r0, center: center2, angle: minAngle2)
        let p5 = CGPoint(x: p4.x + 20, y: p4.y + 30)
        let p6 = CGPoint(x: p4.x + 30, y: p4.y + 15)
        
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
        ctx!.strokePath()
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p3.x, y: p3.y))
        ctx!.strokePath()
        ctx!.move(to: CGPoint(x: p4.x, y: p4.y))
        ctx!.addLine(to: CGPoint(x: p5.x, y: p5.y))
        ctx!.strokePath()
        ctx!.move(to: CGPoint(x: p4.x, y: p4.y))
        ctx!.addLine(to: CGPoint(x: p6.x, y: p6.y))
        ctx!.strokePath()
        
        
        
        
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }
    
    func drawUndo(_ frame: CGRect) -> UIImage {
        let size = CGSize(width: frame.width, height: frame.height)
        //let endAngle = CGFloat(2*M_PI)
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setStrokeColor(UIColor.black.cgColor)
        
        ctx!.beginPath()
        ctx!.setLineWidth(4.0)
        
        let adder:CGFloat = frame.width / 20
        let r0 = frame.width * 0.4
        
        let center1 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + adder + r0 * 1.5)
//        let center2 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height - adder - r0 * 1.5)
        
        
//        let oneGrad:CGFloat = CGFloat(M_PI) / 180
        let minAngle1 = 340 * GV.oneGrad
        let maxAngle1 = 200 * GV.oneGrad
        //println("1 Grad: \(oneGrad)")
        
//        let minAngle2 = 150 * oneGrad
//        let maxAngle2 = 30 * oneGrad
        
//        CGContextAddArc(ctx, center1.x, center1.y, r0, minAngle1, maxAngle1, 1)
        ctx!.addArc(center: center1, radius: r0, startAngle: minAngle1, endAngle: maxAngle1, clockwise: true)
        ctx!.strokePath()
        
//        CGContextAddArc(ctx, center2.x, center2.y, r0, minAngle2, maxAngle2, 1)
//        CGContextStrokePath(ctx)
        
        let p1 = pointOfCircle(r0, center: center1, angle: maxAngle1)
        let p2 = CGPoint(x: p1.x + 10, y: p1.y - 30)
//        let p3 = CGPoint(x: p1.x + 30, y: p1.y + 10)
//        let p2 = CGPoint(x: p1.x - 20, y: p1.y - 30)
        let p3 = CGPoint(x: p1.x + 30, y: p1.y - 10)
//        let p4 = pointOfCircle(r0, center: center2, angle: minAngle2)
//        let p5 = CGPoint(x: p4.x + 20, y: p4.y + 30)
//        let p6 = CGPoint(x: p4.x + 30, y: p4.y + 15)
        
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
        ctx!.strokePath()
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p3.x, y: p3.y))
        ctx!.strokePath()
//        CGContextMoveToPoint(ctx, p4.x, p4.y)
//        CGContextAddLineToPoint(ctx, p5.x, p5.y)
//        CGContextStrokePath(ctx)
//        CGContextMoveToPoint(ctx, p4.x, p4.y)
//        CGContextAddLineToPoint(ctx, p6.x, p6.y)
//        CGContextStrokePath(ctx)
        
        
        
        
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }
    
    func drawRestart(_ frame: CGRect) -> UIImage {
        let size = CGSize(width: frame.width, height: frame.height)
        //let endAngle = CGFloat(2*M_PI)
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setStrokeColor(UIColor.black.cgColor)
        
        ctx!.beginPath()
        ctx!.setLineWidth(4.0)
        
        let adder:CGFloat = frame.width / 20
        let r0 = frame.width * 0.4
        
        let center1 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + adder + r0 * 1.0)
        //        let center2 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height - adder - r0 * 1.5)
        
        
        let minAngle1 = 430 * GV.oneGrad
        let maxAngle1 = 90 * GV.oneGrad
        //println("1 Grad: \(oneGrad)")
        
        //        let minAngle2 = 150 * oneGrad
        //        let maxAngle2 = 30 * oneGrad
        
//        CGContextAddArc(ctx, center1.x, center1.y, r0, minAngle1, maxAngle1, 1)
        ctx!.addArc(center: center1, radius: r0, startAngle: minAngle1, endAngle: maxAngle1, clockwise: true)
        ctx!.strokePath()
        
        //        CGContextAddArc(ctx, center2.x, center2.y, r0, minAngle2, maxAngle2, 1)
        //        CGContextStrokePath(ctx)
        
        let p1 = pointOfCircle(r0, center: center1, angle: maxAngle1)
        let p2 = CGPoint(x: p1.x - 20, y: p1.y - 20)
        //        let p3 = CGPoint(x: p1.x + 30, y: p1.y + 10)
        //        let p2 = CGPoint(x: p1.x - 20, y: p1.y - 30)
        let p3 = CGPoint(x: p1.x - 30, y: p1.y + 10)
        //        let p4 = pointOfCircle(r0, center: center2, angle: minAngle2)
        //        let p5 = CGPoint(x: p4.x + 20, y: p4.y + 30)
        //        let p6 = CGPoint(x: p4.x + 30, y: p4.y + 15)
        
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
        ctx!.strokePath()
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p3.x, y: p3.y))
        ctx!.strokePath()
        //        CGContextMoveToPoint(ctx, p4.x, p4.y)
        //        CGContextAddLineToPoint(ctx, p5.x, p5.y)
        //        CGContextStrokePath(ctx)
        //        CGContextMoveToPoint(ctx, p4.x, p4.y)
        //        CGContextAddLineToPoint(ctx, p6.x, p6.y)
        //        CGContextStrokePath(ctx)
        
        
        
        
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }
    
    func drawTipps(_ frame: CGRect) -> UIImage {
        let size = CGSize(width: frame.width, height: frame.height)
        //let endAngle = CGFloat(2*M_PI)
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setStrokeColor(UIColor.black.cgColor)
        
        ctx!.beginPath()
        ctx!.setLineWidth(4.0)
        
        let adder:CGFloat = frame.width * 0.05
        let r0 = frame.width * 0.25
        
        let center1 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + adder + r0 * 1.8)
        //        let center2 = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height - adder - r0 * 1.5)
        
        
        let minAngle1 = 410 * GV.oneGrad
        let maxAngle1 = 130 * GV.oneGrad
        let blitzAngle1 = 200 * GV.oneGrad
        let blitzAngle2 = 230 * GV.oneGrad
        let blitzAngle3 = 270 * GV.oneGrad
        let blitzAngle4 = 310 * GV.oneGrad
        let blitzAngle5 = 340 * GV.oneGrad
        //println("1 Grad: \(oneGrad)")
        
        //        let minAngle2 = 150 * oneGrad
        //        let maxAngle2 = 30 * oneGrad
        
//        CGContextAddArc(ctx, center1.x, center1.y, r0, minAngle1, maxAngle1, 1)
        ctx!.addArc(center: center1, radius: r0, startAngle: minAngle1, endAngle: maxAngle1, clockwise: true)
        ctx!.strokePath()
        
        //        CGContextAddArc(ctx, center2.x, center2.y, r0, minAngle2, maxAngle2, 1)
        //        CGContextStrokePath(ctx)
        
        let endPoint = pointOfCircle(r0, center: center1, angle: minAngle1)
        let p1 = pointOfCircle(r0, center: center1, angle: maxAngle1)
        let p2 = CGPoint(x: p1.x, y: p1.y + 4 * adder)
        let p3 = CGPoint(x: endPoint.x, y: p2.y)
        let p4 = CGPoint(x: p3.x, y: endPoint.y)
        let p5 = CGPoint(x: p1.x, y: p1.y + 1.3 * adder)
        let p6 = CGPoint(x: p3.x, y: p5.y)
        let p7 = CGPoint(x: p1.x, y: p1.y + 2.6 * adder)
        let p8 = CGPoint(x: p3.x, y: p7.y)
        
        let blitzStartAdder = adder * 1
        let blitzEndAdder = adder * 4
        
        let blitzStartPoint1 = pointOfCircle(r0 + blitzStartAdder, center: center1, angle: blitzAngle1)
        let blitzEndPoint1 = pointOfCircle(r0 + blitzEndAdder, center: center1, angle: blitzAngle1)
        let blitzStartPoint2 = pointOfCircle(r0 + blitzStartAdder, center: center1, angle: blitzAngle2)
        let blitzEndPoint2 = pointOfCircle(r0 + blitzEndAdder, center: center1, angle: blitzAngle2)
        let blitzStartPoint3 = pointOfCircle(r0 + blitzStartAdder, center: center1, angle: blitzAngle3)
        let blitzEndPoint3 = pointOfCircle(r0 + blitzEndAdder, center: center1, angle: blitzAngle3)
        let blitzStartPoint4 = pointOfCircle(r0 + blitzStartAdder, center: center1, angle: blitzAngle4)
        let blitzEndPoint4 = pointOfCircle(r0 + blitzEndAdder, center: center1, angle: blitzAngle4)
        let blitzStartPoint5 = pointOfCircle(r0 + blitzStartAdder, center: center1, angle: blitzAngle5)
        let blitzEndPoint5 = pointOfCircle(r0 + blitzEndAdder, center: center1, angle: blitzAngle5)

        
        
        ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
        ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
        ctx!.addLine(to: CGPoint(x: p3.x, y: p3.y))
        ctx!.addLine(to: CGPoint(x: p4.x, y: p4.y))
        ctx!.strokePath()

        ctx!.setLineWidth(2.0)
        ctx!.move(to: CGPoint(x: p5.x, y: p5.y))
        ctx!.addLine(to: CGPoint(x: p6.x, y: p6.y))
        ctx!.strokePath()
        
        ctx!.move(to: CGPoint(x: p7.x, y: p7.y))
        ctx!.addLine(to: CGPoint(x: p8.x, y: p8.y))
        ctx!.strokePath()
        
        ctx!.move(to: CGPoint(x: blitzStartPoint1.x, y: blitzStartPoint1.y))
        ctx!.addLine(to: CGPoint(x: blitzEndPoint1.x, y: blitzEndPoint1.y))
        ctx!.strokePath()

        ctx!.move(to: CGPoint(x: blitzStartPoint2.x, y: blitzStartPoint2.y))
        ctx!.addLine(to: CGPoint(x: blitzEndPoint2.x, y: blitzEndPoint2.y))
        ctx!.strokePath()
        
        ctx!.move(to: CGPoint(x: blitzStartPoint3.x, y: blitzStartPoint3.y))
        ctx!.addLine(to: CGPoint(x: blitzEndPoint3.x, y: blitzEndPoint3.y))
        ctx!.strokePath()
        
        ctx!.move(to: CGPoint(x: blitzStartPoint4.x, y: blitzStartPoint4.y))
        ctx!.addLine(to: CGPoint(x: blitzEndPoint4.x, y: blitzEndPoint4.y))
        ctx!.strokePath()
        
        ctx!.move(to: CGPoint(x: blitzStartPoint5.x, y: blitzStartPoint5.y))
        ctx!.addLine(to: CGPoint(x: blitzEndPoint5.x, y: blitzEndPoint5.y))
        ctx!.strokePath()
        
//        CGContextAddArc(ctx, center1.x, center1.y, r0, maxAngle1, minAngle1, 1)
        ctx!.addArc(center: center1, radius: r0, startAngle: maxAngle1, endAngle: minAngle1, clockwise: true)
        ctx!.strokePath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }
    
    func drawSettings(_ frame: CGRect) -> UIImage {
        let size = CGSize(width: frame.width, height: frame.height)
        let endAngle = CGFloat(2*M_PI)
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.beginPath()
        
        /*
        CGContextSetLineWidth(ctx, 0.5)
        let center1 = CGPoint(x: frame.width / 2, y: frame.height / 2)
        let radius1 = frame.width / 2 - 5
        CGContextAddArc(ctx, center1.x, center1.y, radius1, CGFloat(0), CGFloat(2 * M_PI), 1)
        CGContextSetFillColorWithColor(ctx, imageColor)
        CGContextDrawPath(ctx, kCGPathFillStroke)
        CGContextStrokePath(ctx)
        */
        ctx!.setLineWidth(4.0)
        
        let adder:CGFloat = 10.0
        let center = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height / 2)
        let r0 = frame.width / 2.2 - adder
        let r1 = frame.width / 3.0 - adder
        let r2 = frame.width / 4.0 - adder
        let count: CGFloat = 8
        let countx2 = count * 2
        let firstAngle = (endAngle / countx2) / 2
        
        ctx!.setFillColor(UIColor.black.cgColor)
        
        //CGContextSetRGBFillColor(ctx, UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1).CGColor);
        for ind in 0..<Int(count) {
            let minAngle1 = firstAngle + CGFloat(ind) * endAngle / count
            let maxAngle1 = minAngle1 + endAngle / countx2
            let minAngle2 = maxAngle1
            let maxAngle2 = minAngle2 + endAngle / countx2
            
            
            let startP = pointOfCircle(r1, center: center, angle: maxAngle1)
            let midP1 = pointOfCircle(r0, center: center, angle: maxAngle1)
            let midP2 = pointOfCircle(r0, center: center, angle: maxAngle2)
            let endP = pointOfCircle(r1, center: center, angle: maxAngle2)
//            CGContextAddArc(ctx, center.x, center.y, r0, max(minAngle1, maxAngle1) , min(minAngle1, maxAngle1), 1)
            ctx!.addArc(center: center, radius: r0, startAngle: max(minAngle1, maxAngle1), endAngle: min(minAngle1, maxAngle1), clockwise: true)
            ctx!.strokePath()
            ctx!.move(to: CGPoint(x: startP.x, y: startP.y))
            ctx!.addLine(to: CGPoint(x: midP1.x, y: midP1.y))
            ctx!.strokePath()
//            CGContextAddArc(ctx, center.x, center.y, r1, max(minAngle2, maxAngle2), min(minAngle2, maxAngle2), 1)
            ctx!.addArc(center: center, radius: r1, startAngle: max(minAngle2, maxAngle2), endAngle: min(minAngle2, maxAngle2), clockwise: true)
            ctx!.strokePath()
            ctx!.move(to: CGPoint(x: midP2.x, y: midP2.y))
            ctx!.addLine(to: CGPoint(x: endP.x, y: endP.y))
            ctx!.strokePath()
        }
        ctx!.fillPath()
        
//        CGContextAddArc(ctx, center.x, center.y, r2, 0, endAngle, 1)
        ctx!.addArc(center: center, radius: r2, startAngle: 0, endAngle: endAngle, clockwise: true)
        ctx!.strokePath()
        
        /*
        let center2 = CGPoint(x: frame.width / 2, y: frame.height / 2)
        let radius = frame.width / 2 - 5
        CGContextAddArc(ctx, center2.x, center2.y, radius, CGFloat(0), CGFloat(2 * M_PI), 1)
        CGContextStrokePath(ctx)
        */
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }
    func getPfeillinks () -> UIImage {
        return pfeillinksImage
    }
    
    func getPfeilrechts () -> UIImage {
        return pfeilrechtsImage
    }
    
    func getSettings () -> UIImage {
        return settingsImage
    }
    
    func getUndo () -> UIImage {
        return undoImage
    }
    
    func getRestart () -> UIImage {
        return restartImage
    }
    
    func getExchange () -> UIImage {
        return exchangeImage
    }
    
    func getBack () -> UIImage {
        return backImage
    }

    func getCardPackage () -> UIImage {
        return cardPackage
    }

    func getTipp () -> UIImage {
        return tippImage
    }
    
    func pointOfCircle(_ radius: CGFloat, center: CGPoint, angle: CGFloat) -> CGPoint {
        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        return pointOfCircle
    }
    
    static func getDeleteImage (_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        ctx!.setLineWidth(w * 2)
       
        ctx!.setStrokeColor(UIColor.red.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        let points1 = [
            CGPoint(x: w * 20,y: h * 20),
            CGPoint(x: w * 30, y: h * 90),
            CGPoint(x: w * 70, y: h * 90),
            CGPoint(x: w * 80, y: h * 20)
        ]
//        CGContextAddLines(ctx, points1, points1.count)
        ctx!.addLines(between: points1)
        
        ctx!.move(to: CGPoint(x: w * 32, y: h * 25))
        ctx!.addLine(to: CGPoint(x: w * 38, y: h * 80))
        
        ctx!.move(to: CGPoint(x: w * 50, y: h * 25))
        ctx!.addLine(to: CGPoint(x: w * 50, y: h * 80))
        
        ctx!.move(to: CGPoint(x: w * 68, y: h * 25))
        ctx!.addLine(to: CGPoint(x: w * 62, y: h * 80))

        
        
        ctx!.move(to: CGPoint(x: w * 16, y: h * 18))
        ctx!.addLine(to: CGPoint(x: w * 84, y: h * 18))
        
        
        ctx!.move(to: CGPoint(x: w * 18, y: h * 15))
        ctx!.addLine(to: CGPoint(x: w * 82, y: h * 15))
        
        ctx!.setLineCap (.round)
        ctx!.strokePath()
        
        ctx!.beginPath()
        
        let r0 = w * 10
        
        let center1 = CGPoint(x: w * 50, y: h * 14)
        
        
        //        let oneGrad:CGFloat = CGFloat(M_PI) / 180
        let minAngle1 = 180 * GV.oneGrad
        let maxAngle1 = 0 * GV.oneGrad
        //println("1 Grad: \(oneGrad)")
        
        
//        CGContextAddArc(ctx, center1.x, center1.y, r0, minAngle1, maxAngle1, 0)
        ctx!.addArc(center: center1, radius: r0, startAngle: minAngle1, endAngle: maxAngle1, clockwise: true)
 
        ctx!.strokePath()
        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }

    
    static func getModifyImage (_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width
        let h = size.height
        ctx!.setLineWidth(w * 0.08)
        //        let roundRect = UIBezierPath(roundedRect: CGRectMake(0, 0, size.width * 0.6, size.height * 0.8), byRoundingCorners:.AllCorners, cornerRadii: CGSizeMake(size.width * rounding, size.height * rounding)).CGPath
        //
        //        CGContextAddPath(ctx, roundRect)
        
        //        CGContextSetShadow(ctx, CGSizeMake(10,10), 1.0)
        //        CGContextStrokePath(ctx)
        
        
        ctx!.setStrokeColor(UIColor.gray.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        let roundRect = UIBezierPath(roundedRect: CGRect(x: w * 0.1, y: h * 0.4, width: w * 0.8, height: h * 0.5), byRoundingCorners:.allCorners, cornerRadii: CGSize(width: w * 0.08, height: h * 0.08)).cgPath
        ctx!.addPath(roundRect)
        ctx!.strokePath()

        ctx!.beginPath()
        ctx!.setLineWidth(w * 0.1)
        ctx!.setStrokeColor(UIColor.brown.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        
//        CGContextSetShadow(ctx, CGSizeMake(w * 0.04, h * 0.04), 0.5)
//        CGContextSetFillColorWithColor(ctx, UIColor(red: 240/255, green: 255/255, blue: 240/255, alpha: 1.0 ).CGColor);

//        let frame = CGRectMake(w * 0.1, h * 0.1, w * 0.8, h * 0.8)
//        
//        CGContextStrokeRect(ctx, frame)

        let points = [
            CGPoint(x: w * 0.60, y: h * 0.60),
            CGPoint(x: w * 0.80, y: h * 0.20)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()

        ctx!.beginPath()
        ctx!.setLineWidth(w * 0.03)
        ctx!.setStrokeColor(UIColor.white.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        let points1 = [
            CGPoint(x: w * 0.63, y: h * 0.50),
            CGPoint(x: w * 0.73, y: h * 0.30)
        ]
//        CGContextAddLines(ctx, points1, points1.count)
        ctx!.addLines(between: points1)

        ctx!.strokePath()
        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }

    static func getOKImage (_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.greenAppleColor().cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        ctx!.setLineWidth(w * 20)
        let points = [
            CGPoint(x: w * 10, y: h * 70),
            CGPoint(x: w * 50, y: h * 95),
            CGPoint(x: w * 80, y: h * 20)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }
    
    static func getLockImage (_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.yellow.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        ctx!.setLineWidth(w * 20)
        let points = [
            CGPoint(x: w * 10, y: h * 70),
            CGPoint(x: w * 50, y: h * 95),
            CGPoint(x: w * 80, y: h * 20)
        ]
        //        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }
    
    static func getNOKImage (_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.red.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        ctx!.setLineWidth(w * 20)
        let points = [
            CGPoint(x: w * 10, y: h * 90),
            CGPoint(x: w * 90, y: h * 10),
        ]
        let points1 = [
            CGPoint(x: w * 10, y: h * 10),
            CGPoint(x: w * 90, y: h * 90),
            ]
        //CGContextAddLines(ctx, points, points.count)
//        CGContextAddLines(ctx, points1, points.count)
        ctx!.addLines(between: points)
        ctx!.addLines(between: points1)
        ctx!.strokePath()
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }
    static func getStatisticImage(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.black.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        ctx!.setLineWidth(w * 4)
        var points = [
            CGPoint(x: w * 10, y: h * 10),
            CGPoint(x: w * 5, y: h * 90),
            CGPoint(x: w * 90, y: h * 90)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
        ctx!.beginPath()
        ctx!.setStrokeColor(UIColor.black.cgColor)
        ctx!.setLineWidth(w * 0.5)
        points = [
            CGPoint(x: w * 10, y: h * 25),
            CGPoint(x: w * 90, y: h * 25)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)

        points = [
            CGPoint(x: w * 10, y: h * 50),
            CGPoint(x: w * 90, y: h * 50)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        
        points = [
            CGPoint(x: w * 10, y: h * 70),
            CGPoint(x: w * 90, y: h * 70)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        
        ctx!.strokePath()
        
        ctx!.beginPath()
        ctx!.setStrokeColor(UIColor.red.cgColor)
        ctx!.setLineWidth(w * 5)
        points.removeAll()
        
        points = [
            CGPoint(x: w * 10, y: h * 80),
            CGPoint(x: w * 30, y: h * 40),
            CGPoint(x: w * 60, y: h * 60),
            CGPoint(x: w * 90, y: h * 30)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()

        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }

    static func getGoBackImage(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.blue.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        ctx!.setLineWidth(w * 5)
        let points = [
            CGPoint(x: w * 80, y: h * 10),
            CGPoint(x: w * 5, y: h * 50),
            CGPoint(x: w * 80, y: h * 90)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }

    static func getGoForwardImage(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.blue.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        ctx!.setLineWidth(w * 5)
        let points = [
            CGPoint(x: w * 20, y: h * 10),
            CGPoint(x: w * 95, y: h * 50),
            CGPoint(x: w * 20, y: h * 90)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }

    static func getHelpImage(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.blue.cgColor)
        ctx!.setLineJoin (.round)
        ctx!.setLineCap (.round)
        
        ctx!.setLineWidth(w * 5)
        let points = [
            CGPoint(x: w * 20, y: h * 10),
            CGPoint(x: w * 95, y: h * 50),
            CGPoint(x: w * 20, y: h * 90)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }

    static func getStartImage(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        
        ctx!.setStrokeColor(UIColor.black.cgColor)
        ctx!.setFillColor(UIColor.black.cgColor)
//        CGContextSetLineJoin (ctx, .Round)
//        CGContextSetLineCap (ctx, .Round)
        
        ctx!.setLineWidth(w * 1)
        let points = [
            CGPoint(x: w * 5, y: h * 5),
            CGPoint(x: w * 95, y: h * 50),
            CGPoint(x: w * 5, y: h * 95),
            CGPoint(x: w * 5, y: h * 5),
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.fillPath()
        ctx!.strokePath()
        ctx!.closePath()
        
        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }


    static func getSetVolumeImage(_ size: CGSize, volumeValue: CGFloat) -> UIImage { // volumeValue 0 ... 100
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        let w = size.width / 100
        let h = size.height / 100
        let radius = h * 40
        let v = radius + (size.width - 2 * radius) * volumeValue / 100
        
        ctx!.setStrokeColor(UIColor.red.cgColor)
//        CGContextSetLineJoin (ctx, .Round)
        ctx!.setLineCap (.round)
        
        
        ctx!.setLineWidth(h * 20)
        let redLinePoints = [
            CGPoint(x: radius, y: h * 50),
            CGPoint(x: v, y: h * 50),
        ]
        
//        CGContextAddLines(ctx, redLinePoints, redLinePoints.count)
        ctx!.addLines(between: redLinePoints)
        ctx!.strokePath()
        
        let greenLinePoints = [
            CGPoint(x: v , y: h * 50),
            CGPoint(x: w * 100 - radius, y: h * 50),
        ]
//        CGContextAddLines(ctx, greenLinePoints, redLinePoints.count)
        ctx!.addLines(between: greenLinePoints)
        ctx!.setStrokeColor(UIColor.green.cgColor)
        ctx!.strokePath()

        let center = CGPoint(x: v, y: h * 50)
        ctx!.setStrokeColor(UIColor.gray.cgColor)
//        CGContextAddArc(ctx, center.x, center.y, radius, 0, 360 * GV.oneGrad, 1)
        ctx!.addArc(center: center, radius: radius, startAngle: 0, endAngle: 360 * GV.oneGrad, clockwise: true)
        ctx!.setFillColor(UIColor.gray.cgColor)
        ctx!.fillPath()
        ctx!.strokePath()

        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }
    

}




