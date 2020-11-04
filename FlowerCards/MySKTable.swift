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
        case string = 0, texture, textures
    }
    enum Orientation: Int {
        case left = 0, center, right
    }
    struct MultiVar {
        var varType: VarType
        var stringVar: String?
        var textureVar: SKTexture?
        var textureSizeVar: CGFloat?
        var textureArray: [SKTexture] = []
        
        init(string:String) {
            stringVar = string
            varType = .string
        }
        init(texture: SKTexture, textureSize: CGFloat = 1.0) {
            textureVar = texture
            textureSizeVar = textureSize
            varType = .texture
        }
        init(textures: [SKTexture]) {
            self.textureArray.append(contentsOf: textures)
            varType = .textures
        }
        
    }
    
    struct RowOfTable {
        let elements: [MultiVar]
        var selected: Bool
        let headerRow: Bool
        
        init(elements: [MultiVar], selected: Bool, headerRow: Bool = false) {
            self.elements = elements
            self.selected = selected
            self.headerRow = headerRow
        }
    }
    var heightOfMyHeadRow = CGFloat(0)
    var heightOfLabelRow = CGFloat(0)
    var fontSize = CGFloat(0)
    var myImageSize = CGFloat(GV.onIpad ? 30 : 20)
    var columns: Int
    var rows: Int
    var touchesBeganAt: Date = Date()
    var touchesBeganAtNode: SKNode?
    var myParent: SKNode
    var myParentScene: SKScene
    let separator = "-"
    let elementSeparator = ":"
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
    var verticalPositionForTextures: CGFloat = 0
    var tableOfRows: [RowOfTable] = []
    var startIndex: Int = 1
    var maxLineCount: Int = 0
    var lastLocation = CGPoint.zero
    var firstLocation = CGPoint.zero
    var maxLocationDelta: CGFloat = 0
    let width: CGFloat?
    
    let goBackImageName = "GoBackImage"
    
    init(columnWidths: [CGFloat], countRows: Int, headLines: [String], parent: SKNode, myName: String, width: CGFloat? = nil) {
        
        self.columns = columnWidths.count
        self.rows = countRows
        self.columnWidths = columnWidths
        self.myParent = parent
        self.myParentScene = (GV.mainScene!.scene!) //parent.parent!.scene!
        self.headLines = headLines.count == 0 ? [""] : headLines
        self.width = width
        super.init(texture: SKTexture(), color: UIColor.clear, size: CGSize.zero)

        self.name = myName
        
        createTable()

    }
    
    func createTable() {
        let pSize = myParentScene.size
        myStartPosition = CGPoint(x: pSize.width, y: pSize.height / 2)
        myTargetPosition = CGPoint(x: pSize.width / 2, y: pSize.height / 2)
        let headLineRows = CGFloat(headLines.count)
        
        self.heightOfLabelRow = GV.mainScene!.frame.height / 20
        self.heightOfMyHeadRow = (headLineRows == 0 ? 1 : headLineRows) * heightOfLabelRow
        
        maxLineCount = calculateMaxLineCount()
        if self.rows > maxLineCount {
            self.rows = maxLineCount
            scrolling = true
        }
        self.position = myStartPosition
        
        self.zPosition = myParent.zPosition + 200
        self.fontSize = GV.mainScene!.frame.width / 40 < 20 ? 15 : GV.mainScene!.frame.width / 40
        
        
        
        myHeight = heightOfLabelRow * CGFloat(self.rows) + heightOfMyHeadRow
        if myHeight > pSize.height {
            let positionToMoveY = (myParentScene.frame.height - myHeight) / 2
            self.myTargetPosition.y += positionToMoveY
        }
        
        var mySize = CGSize.zero
        if width != nil {
            mySize = CGSize(width: width!, height: myHeight)
            self.showVerticalLines = true
        } else {
            mySize = CGSize(width: GV.mainScene!.frame.width * 0.9, height: myHeight)
        }
        self.size = mySize
        self.alpha = 1.0
        self.texture = SKTexture(image: drawTableImage(mySize, columnWidths: columnWidths, columns: self.columns, rows: self.rows))
        var columnMidX = -(mySize.width * 0.48)
        for column in 0..<columnWidths.count {
            columnXPositions.append(columnMidX)
            columnMidX += mySize.width * columnWidths[column] / 100
        }
        verticalPositionForTextures = (self.size.height - heightOfLabelRow) * 0.5 - heightOfMyHeadRow

//        verticalPosition = (self.size.height - heightOfLabelRow) * 0.5 - heightOfMyHeadRow - heightOfLabelRow * 0.2
        verticalPosition = verticalPositionForTextures - heightOfLabelRow * 0.2
        self.isUserInteractionEnabled = true
        //        fontSize = CGFloat(0)
        showMyImagesAndHeader(DrawImages.getGoBackImage(CGSize(width: myImageSize, height: myImageSize)), position: 10, name: goBackImageName)
        
        //        parent!.addChild(self)

    }
    
    func calculateMaxLineCount()->Int{
        let countLines = Int((GV.mainScene?.size.height)! * 0.9 / heightOfLabelRow)
        return countLines - headLines.count - 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeHeadLines(_ headLines: [String]) {
        self.headLines.removeAll()
        self.headLines.append(contentsOf: headLines)
    }
    
    
    
    
    func showTable() {
        showRowOfTable(rowOfTable: tableOfRows[0], row: 0)
        if maxLineCount > tableOfRows.count {
            maxLineCount = tableOfRows.count
        }
        var row = 1
        while row < maxLineCount {
            showRowOfTable(rowOfTable: tableOfRows[startIndex + row - 1], row: row)
            row += 1
        }
        
    }
    
    func setStartIndex() {
        if !(startIndex < GV.player!.levelID + 1 && startIndex + maxLineCount > GV.player!.levelID + 1) {
            startIndex = GV.player!.levelID + 1
        }
        
        if startIndex + maxLineCount - 1 > tableOfRows.count {
            startIndex = tableOfRows.count - maxLineCount + 1
            if startIndex < 1 {
                startIndex = 1
            }
        }
        // all lines to not selected
        for index in 0..<tableOfRows.count {
            if tableOfRows[index].selected {
                tableOfRows[index].selected = false
            }
        }
        tableOfRows[GV.player!.levelID + 1].selected = true
    }
    
    func showRowOfTable(rowOfTable: RowOfTable, row: Int) {
        for column in 0..<rowOfTable.elements.count {
            switch rowOfTable.elements[column].varType {
            case .string:
                showElementOfTable(rowOfTable.elements[column].stringVar!, column: column, row: row, selected: rowOfTable.selected)
            case .texture:
                showTextureInTable(texture: rowOfTable.elements[column].textureVar!, column: column, row: row, selected: rowOfTable.selected, textureSize: rowOfTable.elements[column].textureSizeVar!)
            case .textures:
                showTexturesInTable(textures: rowOfTable.elements[column].textureArray, column: column, row: row, selected: rowOfTable.selected)
            }
        }
    }
    
    func showElementOfTable(_ element: String, column: Int, row: Int, selected: Bool, orientation: Orientation...) {
        let name = "\(column)\(separator)\(row)"
        var label = SKLabelNode()
        var labelExists = false
        label.fontName = "ArialMT"
        
        
        for index in 0..<self.children.count {
            if self.children[index].name == name {
                label = self.children[index] as! SKLabelNode
                labelExists = true
                break
            }
        }
        
        label.fontColor = selected ? SKColor.blue : SKColor.black
        label.text = element
        label.fontSize = fontSize
//        label.verticalAlignmentMode = .baseline
        
        // when label too long, make it shorter
        
        let cellWidth = self.frame.width * columnWidths[column] / 100
        while label.frame.width + 8 > cellWidth {
           label.fontSize -= 1
        }
        
        if !labelExists {
            label.zPosition = self.zPosition + 10
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.baseline
            label.name = name
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
            label.fontName = "ArialMT"
            label.fontColor = SKColor.black
            label.text = headLines[index]
            label.name = name
            label.zPosition = self.zPosition + 100
            label.fontSize = fontSize
            label.verticalAlignmentMode = .baseline
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

    
    func showTextureInTable(texture: SKTexture, column: Int, row: Int, selected: Bool, textureSize: CGFloat = 1) {
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
        shape.texture = texture
        shape.name = name
        
        var xPos: CGFloat = 0
        for index in 0..<column {
            xPos += size.width * columnWidths[index] / 100
        }
        xPos += (size.width * columnWidths[column] / 100) / 2
        xPos -= self.size.width / 2
        
        shape.position = CGPoint(x: xPos, y: verticalPositionForTextures - CGFloat(row) * heightOfLabelRow)
        shape.alpha = 1.0
        shape.size = texture.size() * textureSize
        shape.zPosition = self.zPosition + 1000
        self.addChild(shape)
        
    }

    func showTexturesInTable(textures: [SKTexture], column: Int, row: Int, selected: Bool) {
        let name = "\(column)\(separator)\(row)"
        
        for child in self.children {
            if (child.name!.hasPrefix(name)) {
                child.removeFromParent()
            }
        }
        
        if !selected {
            return
        }
        
        var xPos: CGFloat = 0
        for index in 0..<column {
            xPos += size.width * columnWidths[index] / 100
        }
        
        let myWidth = size.width * columnWidths[column] / 100
        
        
        let imagePlaceSize = myWidth / CGFloat(textures.count)
        let imageCenter = imagePlaceSize / 2
        
        var imageSize = imagePlaceSize * 0.9
        if imageSize > heightOfLabelRow {
            imageSize = heightOfLabelRow * 0.9
        }
        var imagePosition = xPos + imageCenter - self.size.width / 2
        
        for index in 0..<textures.count {
            let shape = SKSpriteNode()
            shape.texture = textures[index]
            shape.name = name + elementSeparator + String(index) + elementSeparator
            
            
            shape.position = CGPoint(x: imagePosition, y: verticalPositionForTextures - CGFloat(row) * heightOfLabelRow)
            shape.alpha = 1.0
            shape.size = CGSize(width: imageSize, height: imageSize)
            shape.zPosition = self.zPosition + 1000
            self.addChild(shape)
            imagePosition += imagePlaceSize
        }
        
    }

    func  showMe(_ runAfter:@escaping ()->()) {
        let actionMove = SKAction.move(to: myTargetPosition, duration: 0.3)
        let alphaAction = SKAction.fadeOut(withDuration: 0.5)
        let runAfterAction = SKAction.run({runAfter()})
        //myParent.parent!.addChild(self)
        GV.mainScene?.addChild(self)
        
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
        
        self.removeFromParent()
        createTable()
/*
        myHeight = heightOfLabelRow * CGFloat(self.rows) + heightOfMyHeadRow

        self.size = CGSize(width: self.size.width, height: myHeight)
//        verticalPosition = (self.size.height - heightOfLabelRow) / 2 - heightOfMyHeadRow
        self.texture = SKTexture(image: drawTableImage(size, columnWidths: columnWidths, columns: columns, rows: rows))
//        let myTargetPosition = CGPointMake(parentView!.frame.size.width / 2, parentView!.frame.size.height / 2)
        let pSize = GV.mainScene!.size
        myTargetPosition = CGPoint(x: pSize.width / 2, y: pSize.height / 2)
        self.position = myTargetPosition
        myStartPosition = CGPoint(x: pSize.width, y: pSize.height / 2)
        showMyImagesAndHeader(DrawImages.getGoBackImage(CGSize(width: myImageSize, height: myImageSize)), position: 20, name: goBackImageName)
*/
        self.position = myTargetPosition
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

        let w = size.width / 100
        
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
    
    func checkTouches(_ touches: Set<UITouch>, withEvent event: UIEvent?)->(MyEvents, Int, Int, Int) {
        let touchLocation = touches.first!.location(in: self)
        let touchesEndedAtNode = atPoint(touchLocation)
        let row = -Int((touchLocation.y - self.size.height / 2) / heightOfLabelRow)
        var column = NoValue
        var element = NoValue
        var char: Character
        for index in 0..<columnXPositions.count {
            if columnXPositions[index] > touchLocation.x  + self.frame.minX / 2 {
                column = index - 1
                break
            }
        }
        if column == NoValue {
            column = columnXPositions.count - 1
        }

        if let name = touchesEndedAtNode.name {
            let length = name.length
            if (name.hasSuffix(elementSeparator)) {
                char = (name[(name.index((name.startIndex), offsetBy: length - 2))])
                element = Int(String(char))!
            }
        }

        if touchesEndedAtNode is SKSpriteNode && (touchesEndedAtNode as! SKSpriteNode).name == goBackImageName {
            return (.goBackEvent,row, column, NoValue)
        }
        return (.noEvent, startIndex + row - 1, column, element)
        
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        touchesBeganAtNode = atPoint(touchLocation)
        
        maxLocationDelta = 0
        firstLocation = touches.first!.location(in: GV.mainViewController!.view)
        lastLocation = touches.first!.location(in: GV.mainViewController!.view)
        if !(touchesBeganAtNode is SKLabelNode || (touchesBeganAtNode is SKSpriteNode && touchesBeganAtNode!.name != self.name)) {
            touchesBeganAtNode = nil
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let actLocation = touches.first!.location(in: GV.mainViewController!.view)
        let actLocationDelta = abs(actLocation.y - firstLocation.y)
        if actLocationDelta > maxLocationDelta {
            maxLocationDelta = actLocationDelta
        }
        let delta:CGFloat = lastLocation.y - actLocation.y
        if abs(delta) > heightOfLabelRow / 2 {
            lastLocation = actLocation
            scrollView(delta)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let actLocation = touches.first!.location(in: GV.mainViewController!.view)
        let (_, row, column, element) = checkTouches(touches, withEvent: event)
        if abs(actLocation.y - firstLocation.y) < heightOfLabelRow / 2 && maxLocationDelta < heightOfLabelRow / 2 {
            ownTouchesEnded(row: row, column: column, element: element)
        }
    }
    
    func ownTouchesEnded(row: Int, column: Int, element: Int) {
        
    }
    
    func scrollView(_ delta: CGFloat) {
        let adder = delta >= 0 ? 1 : -1
        if scrolling {
            if adder >= 0 {
                if startIndex + adder < tableOfRows.count + 2 - maxLineCount {
                    startIndex += adder
                    showTable()
                }
            } else {
                if startIndex + adder > 0 {
                    startIndex += adder
                    showTable()
                }
            }
        }
    }
}
