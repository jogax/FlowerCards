//
//  MySKTable.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 08/04/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit


class MySKTable: SKSpriteNode {

    
    enum MyEvents: Int {
        case goBackEvent = 0, noEvent
    }
    
    enum VarType: Int {
        case string = 0, image
    }
    enum Orientation: Int {
        case left = 0, center, right
    }
    struct MultiVar {
        var varType: VarType
        var stringVar: String?
        var imageVar: UIImage?
        init(string:String) {
            stringVar = string
            varType = .string
        }
        init(image: UIImage) {
            imageVar = image
            varType = .image
        }
    }
    var heightOfMyHeadRow = CGFloat(0)
    var heightOfLabelRow = CGFloat(0)
    var fontSize = CGFloat(0)
    var myImageSize = CGFloat(0)
    var columns: Int
    var rows: Int
    var sizeOfElement: CGSize
    var touchesBeganAt: Date = Date()
    var touchesBeganAtNode: SKNode?
    var myParent: SKNode
    let separator = "-"
    var columnWidths: [CGFloat]
    var columnXPositions = [CGFloat]()
    var myHeight: CGFloat = 0
//    var positionsTable: [[CGPoint]]
    var parentView: UIView?
    var showVerticalLines = false
    var myStartPosition = CGPoint.zero
    var myTargetPosition = CGPoint.zero
    var headLines: [String]
    var scrolling = false
    var verticalPosition: CGFloat = 0
    
    let goBackImageName = "GoBackImage"
    
    init(columnWidths: [CGFloat], rows: Int, headLines: [String], parent: SKNode, width: CGFloat...) {
        
        self.columns = columnWidths.count
        self.rows = rows
        self.sizeOfElement = CGSize(width: parent.frame.size.width / CGFloat(self.columns), height: heightOfLabelRow)
        self.columnWidths = columnWidths
        self.myParent = parent
        self.headLines = headLines.count == 0 ? [""] : headLines
        
        super.init(texture: SKTexture(), color: UIColor.clear, size: CGSize.zero)
        setMyDeviceConstants()
        setMyDeviceSpecialConstants()

        let pSize = parent.parent!.scene!.size
        myStartPosition = CGPoint(x: pSize.width, y: pSize.height / 2)//(pSize.height - size.height) / 2 - 10)
        myTargetPosition = CGPoint(x: pSize.width / 2, y: pSize.height / 2) //(pSize.height - size.height) / 2 - 10)
        let headLineRows = CGFloat(headLines.count)
        
        heightOfMyHeadRow = (headLineRows == 0 ? 1 : headLineRows) * heightOfLabelRow

        self.position = myStartPosition
        
        self.zPosition = parent.zPosition + 200

        myHeight = heightOfLabelRow * CGFloat(rows) + heightOfMyHeadRow
        if myHeight > pSize.height {
            scrolling = true
            let positionToMoveY = myParent.frame.minY - self.frame.minY
            self.myTargetPosition.y += positionToMoveY
        }
        
        var mySize = CGSize.zero
        if width.count > 0 {
            mySize = CGSize(width: width[0], height: myHeight)
            self.showVerticalLines = true
        } else {
            mySize = CGSize(width: parent.frame.size.width * 0.9, height: myHeight)
        }
        self.size = mySize
        self.alpha = 1.0
        self.texture = SKTexture(image: drawTableImage(mySize, columnWidths: columnWidths, columns: self.columns, rows: rows))
        var columnMidX = -(mySize.width * 0.48)
        for column in 0..<columnWidths.count {
            columnXPositions.append(columnMidX)
            columnMidX += mySize.width * columnWidths[column] / 100
        }
        verticalPosition = (self.size.height - heightOfLabelRow) / 2 - heightOfMyHeadRow
        self.isUserInteractionEnabled = true
        //        fontSize = CGFloat(0)
        showMyImagesAndHeader(DrawImages.getGoBackImage(CGSize(width: myImageSize, height: myImageSize)), position: 10, name: goBackImageName)
        
        //        parent!.addChild(self)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeHeadLines(_ headLines: [String]) {
        self.headLines.removeAll()
        self.headLines.append(contentsOf: headLines)
    }
    
    func showRowOfTable(_ elements: [MultiVar], row: Int, selected: Bool) {
        for column in 0..<elements.count {
            switch elements[column].varType {
            case .string:
                showElementOfTable(elements[column].stringVar!, column: column, row: row, selected: selected)
            case .image:
                showImageInTable(elements[column].imageVar!, column: column, row: row, selected: selected)
            }
        }
    }
    
    func showElementOfTable(_ element: String, column: Int, row: Int, selected: Bool, orientation: Orientation...) {
        let name = "\(column)\(separator)\(row)"
        var label = SKLabelNode()
        var labelExists = false
        
        
        for index in 0..<self.children.count {
            if self.children[index].name == name {
                label = self.children[index] as! SKLabelNode
                labelExists = true
                break
            }
        }
        
        if selected {
            label.fontName = "Times New Roman"
            label.fontColor = SKColor.blue
        } else {
            label.fontName = "Times New Roman"
            label.fontColor = SKColor.black
        }
        label.text = element
        label.fontSize = fontSize
        
        // when label too long, make it shorter
        
        let cellWidth = self.frame.width * columnWidths[column] / 100
        while label.frame.width + 8 > cellWidth {
           label.fontSize -= 1
        }
        
        if !labelExists {
            label.zPosition = self.zPosition + 10
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
            label.name = name
            if orientation.count > 0 {
                
            }
            
            let horizontalPosition = columnXPositions[column]
            label.position = CGPoint(x: horizontalPosition,  y: verticalPosition - CGFloat(row) * heightOfLabelRow)
            
            self.addChild(label)
        }
    }
    
    func showMyImagesAndHeader(_ image: UIImage, position: CGFloat, name: String) {

        let shape = SKSpriteNode(texture: SKTexture(image: image))
 //       shape.texture = SKTexture(image: image)
        shape.name = name
        
        
        shape.position = CGPoint(x: -(self.size.width * 0.43), y: (self.size.height - heightOfMyHeadRow) / 2) //CGPointMake(self.size.width * position, (self.size.height - heigthOfMyImageRow) / 2)
        shape.alpha = 1.0
        shape.size = image.size
        shape.zPosition = self.zPosition + 1000
        self.addChild(shape)
        
        for index in 0..<headLines.count {
            let label = SKLabelNode()
            label.fontName = "Times New Roman"
            label.fontColor = SKColor.black
            label.text = headLines[index]
            label.name = name
            label.zPosition = self.zPosition + 100
            label.fontSize = fontSize
            var correctur = CGFloat(0)
            switch  headLines.count {
            case 1:
                correctur = heightOfLabelRow * 0.24
            case 2:
                correctur = heightOfLabelRow * -0.3
            case 3:
                correctur = heightOfLabelRow * -0.8
            case 4:
                correctur = heightOfLabelRow * -1.2
            default:
                correctur = heightOfLabelRow / 2
            }
            label.position = CGPoint(x: 0, y: (self.size.height - heightOfMyHeadRow) / 2 - correctur - CGFloat(index) * heightOfLabelRow)
            self.addChild(label)
        }
        
    }

    
    func showImageInTable(_ image: UIImage, column: Int, row: Int, selected: Bool) {
        let name = "\(column)\(separator)\(row)"
        
        for index in 0..<self.children.count {
            if self.children[index].name == name {
                self.children[index].removeFromParent()
                break
            }
        }
        
        if !selected {
            return
        }
        
        let shape = SKSpriteNode()
        shape.texture = SKTexture(image: image)
        shape.name = name
        
        var xPos: CGFloat = 0
        for index in 0..<column {
            xPos += size.width * columnWidths[index] / 100
        }
        xPos += (size.width * columnWidths[column] / 100) / 2
        xPos -= self.size.width / 2
        
        let verticalPosition = (self.size.height - heightOfLabelRow) / 2 - heightOfMyHeadRow
//        label.position = CGPointMake(-size.width * 0.45 + CGFloat(column) * sizeOfElement.width,  verticalPosition - CGFloat(row) * sizeOfElement.height)
        shape.position = CGPoint(x: xPos, y: verticalPosition - CGFloat(row) * heightOfLabelRow)
        shape.alpha = 1.0
        shape.size = image.size
        shape.zPosition = self.zPosition + 1000
        self.addChild(shape)
        
    }
    
    func  showMe(_ runAfter:@escaping ()->()) {
        let actionMove = SKAction.move(to: myTargetPosition, duration: 0.3)
        let alphaAction = SKAction.fadeOut(withDuration: 0.5)
        let runAfterAction = SKAction.run({runAfter()})
        myParent.parent!.addChild(self)
        
        myParent.run(alphaAction)
        self.run(SKAction.sequence([actionMove, runAfterAction]))
    }
    
    func reDrawWhenChanged(_ columnWidths: [CGFloat], rows: Int) {
        if rows == self.rows {
            return
        }
        self.columns = columnWidths.count
        self.rows = rows
        reDraw()
    }
        
    func reDraw() {
        for _ in 0..<children.count {
            self.children.last!.removeFromParent()
        }
        self.sizeOfElement = CGSize(width: size.width / CGFloat(columns), height: size.height / CGFloat(rows))
        myHeight = heightOfLabelRow * CGFloat(rows) + heightOfMyHeadRow

        self.size = CGSize(width: self.size.width, height: myHeight)
        verticalPosition = (self.size.height - heightOfLabelRow) / 2 - heightOfMyHeadRow
        self.texture = SKTexture(image: drawTableImage(size, columnWidths: columnWidths, columns: columns, rows: rows))
//        let myTargetPosition = CGPointMake(parentView!.frame.size.width / 2, parentView!.frame.size.height / 2)
        let pSize = myParent.parent!.scene!.size
        myTargetPosition = CGPoint(x: pSize.width / 2, y: pSize.height / 2)
        self.position = myTargetPosition
        myStartPosition = CGPoint(x: pSize.width, y: pSize.height / 2)
        self.removeFromParent()
        showMyImagesAndHeader(DrawImages.getGoBackImage(CGSize(width: myImageSize, height: myImageSize)), position: 20, name: goBackImageName)
        myParent.parent!.addChild(self)
        
    }
    
    func getColumnRowOfElement(_ name: String)->(column:Int, row:Int) {        
        let components = name.components(separatedBy: separator)
        let column = Int(components[0])
        let row = Int(components[1])
        return (column: column!, row: row!)
    }
    
    func drawTableImage(_ size: CGSize, columnWidths:[CGFloat], columns: Int, rows: Int) -> UIImage {
        let opaque = false
        let scale: CGFloat = 1

//        let heightOfTableRow = size.height -  / CGFloat(rows)
        
        
        let w = size.width / 100
        
        //let mySize = CGSizeMake(size.width - 20, size.height)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: myHeight), opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        
        ctx!.beginPath()
        ctx!.setFillColor(UIColor.white.cgColor)

        ctx!.beginPath()
        ctx!.setLineJoin(.round)
        ctx!.setLineCap(.round)
        ctx!.setStrokeColor(UIColor.black.cgColor)

        let roundRect = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), byRoundingCorners:.allCorners, cornerRadii: CGSize(width: size.width * 0.02, height: size.height * 0.02)).cgPath
        ctx!.addPath(roundRect)
        ctx!.setFillColor(UIColor.white.cgColor);
        ctx!.fillPath()
        var points = [CGPoint]()
        ctx!.strokePath()
        
        points.removeAll()
        points = [
            CGPoint(x: w * 0, y: heightOfMyHeadRow),
            CGPoint(x: w * 100, y: heightOfMyHeadRow)
        ]
        ctx!.setLineWidth(0.1)
        ctx!.setStrokeColor(UIColor.darkGray.cgColor)
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
        
        
        ctx!.beginPath()
        
        ctx!.setStrokeColor(UIColor.black.cgColor)
        ctx!.fillPath();
        ctx!.strokePath()
        
        ctx!.setLineWidth(0.2)
        ctx!.setStrokeColor(UIColor.black.cgColor)
//        CGContextStrokeRect(ctx, CGRectMake(5, 5, mySize.width, mySize.height))
        
        var yPos:CGFloat = (size.height - heightOfMyHeadRow) / CGFloat(rows) + heightOfMyHeadRow
        ctx!.beginPath()
        
        if rows > 1 {
            for _ in 0..<rows - 1 {
                let p1 = CGPoint(x: 5, y: yPos)
                let p2 = CGPoint(x: size.width - 5, y: yPos)
                yPos += heightOfLabelRow
                ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
                ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
            }
        }
        ctx!.strokePath()
        
        
        
        if showVerticalLines {
            ctx!.beginPath()
            var xProcent = CGFloat(0)
            for column in 0..<columnWidths.count {
                xProcent += columnWidths[column]
                let p1 = (CGPoint(x: w * xProcent, y: heightOfMyHeadRow))
                let p2 = (CGPoint(x: w * xProcent, y: myHeight))
                ctx!.move(to: CGPoint(x: p1.x, y: p1.y))
                ctx!.addLine(to: CGPoint(x: p2.x, y: p2.y))
            }
            ctx!.strokePath()
        }
        
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        
        return UIImage()
    }
    
    func checkTouches(_ touches: Set<UITouch>, withEvent event: UIEvent?)->(MyEvents, Int) {
        let touchLocation = touches.first!.location(in: self)
        let touchesEndedAtNode = atPoint(touchLocation)
        let row = -Int((touchLocation.y - self.size.height / 2) / heightOfLabelRow)
        if touchesEndedAtNode is SKSpriteNode && (touchesEndedAtNode as! SKSpriteNode).name == goBackImageName {
            return (.goBackEvent,row)
        }
        return (.noEvent, row)
        
        
    }
    
    func scrollView(_ delta: CGFloat) {
        self.position.y += delta
    }
    
    func setMyDeviceSpecialConstants() {
        
    }
    
    func setMyDeviceConstants() {
        
        switch GV.deviceConstants.type {
        case .iPadPro12_9:
            heightOfLabelRow = CGFloat(40)
            fontSize = CGFloat(30)
            myImageSize = CGFloat(30)
        case .iPadPro9_7:
            heightOfLabelRow = CGFloat(40)
            fontSize = CGFloat(30)
            myImageSize = CGFloat(25)
        case .iPad2:
            heightOfLabelRow = CGFloat(40)
            fontSize = CGFloat(30)
            myImageSize = CGFloat(25)
        case .iPadMini:
            heightOfLabelRow = CGFloat(40)
            fontSize = CGFloat(30)
            myImageSize = CGFloat(30)
        case .iPhone6Plus:
            heightOfLabelRow = CGFloat(40)
            fontSize = CGFloat(25)
            myImageSize = CGFloat(23)
        case .iPhone6:
            heightOfLabelRow = CGFloat(40)
            fontSize = CGFloat(25)
            myImageSize = CGFloat(20)
        case .iPhone5:
            heightOfLabelRow = CGFloat(35)
            fontSize = CGFloat(28)
            myImageSize = CGFloat(15)
        case .iPhone4:
            heightOfLabelRow = CGFloat(35)
            fontSize = CGFloat(20)
            myImageSize = CGFloat(15)
        default:
            break
        }
        
    }
    

   
}
