//
//  Extensions.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 2015. 12. 28..
//  Copyright © 2015. Jozsef Romhanyi. All rights reserved.
//

import UIKit


public extension UIDevice {
    enum UIDeviceTypes: Int {
        case noDevice = 0, iPodTouch5, iPodTouch6, iPhone4, iPhone4s, iPhone5, iPhone5c, iPhone5s, iPhone6, iPhone6Plus, iPhone6s, iPhone6sPlus, iPad2,
        iPad3, iPad4, iPadAir, iPadAir2, iPadMini, iPadMini2, iPadMini3, iPadMini4, iPadPro, appleTV, simulator}
    
    var modelName: String {
        let bounds = UIScreen.main.bounds
        let width = bounds.width
        let height = bounds.height
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro"
            case "AppleTV5,3":                              return "Apple TV"
            case "i386", "x86_64":
                switch (width, height) {
                    case (320, 480):                            return "iPhone 4s"
                    case (320, 568):                            return "iPhone 5s"
                    case (375, 667):                            return "iPhone 6"
                    case (414, 736):                            return "iPhone 6 Plus"
                    case (768, 1024):                           return "iPad Air"
                    case (1024, 1366):                          return "iPad Pro"
                    default:                                    return identifier
                }
            default:                                        return identifier
        }

    }
        
}

extension Double {
    var twoDecimals: Double {
        return nDecimals(2)
    }
    var threeDecimals: Double {
        return nDecimals(3)
    }
    func nDecimals(_ n: Int)->Double {
        let multiplier: Double = pow(10.0,Double(n))
        let divisior: Double = 1.0 / multiplier
        var v: Double = self
        v = v * multiplier
        
        return v.rounded() * divisior
    }
    
}

extension Int {
    var dayHourMinSec: String {
        var days: Int = 0
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = self
        if self > 59 {
            seconds = self % 60
            minutes = self / 60
        }
        if minutes > 59 {
            hours = minutes / 60
            minutes = minutes % 60
        }
        if hours > 23 {
            days = hours / 24
            hours = hours % 24
        }
        let daysString = days > 0 ? ((days < 10 ? "0":"") + String(days) + ":") : ""
        let hoursString = hours > 0 ? ((hours < 10 ? "0":"") + String(hours) + ":") : days > 0 ? "00:" : ""
        let minutesString = (minutes < 10 ? "0" : "") + String(minutes) + ":"
        let secondsString = (seconds < 10 ? "0" : "") + String(seconds)
        return daysString + hoursString + minutesString + secondsString
    }
    func isMemberOf(_ values: Int...)->Bool {
        for index in 0..<values.count {
            if self == values[index] {
                return true
            }
        }
        return false
    }
    
    func between(_ min: Int, max: Int)->Bool {
        return self >= min && self <= max
    }
    
    func rightJustified(_ length: Int)->String {
        var numberString = String(self)
        var countLeadingBlanks = length - numberString.length
        while countLeadingBlanks > 0 {
            numberString = " " + numberString
            countLeadingBlanks -= 1
        }
        return numberString
    }
    
    func toCGFloat()->CGFloat {
        return CGFloat(self)
    }
    
    func isOdd() -> Bool {
        if (self % 2 == 0) {
            return true
        }
        else {
            return false
        }
    }
    
    func toBinary(len: Int = 0)->String {
        let spacing = 4
        var string = ""
        var shifted = self
        for index in 0...63 {
            let digit = shifted & 1 == 0 ? "0" : "1"
            string = digit + string
            if index % spacing == 3 {
                string = " " + string
            }
            shifted = shifted >> 1
        }
        let offset = len == 0 ? 0 : string.length - len
        let startPos = string.index(string.startIndex, offsetBy: offset)
        let returnString = string.substring(from: startPos)
        return returnString
    }
}

extension UInt8 {
    func toBinary(len: Int = 0)->String {
        return Int(self).toBinary(len: len)
    }
    
    func countOnes()->Int {
        var counter = 0
        var myValue = self
        while myValue > 0 {
            counter += Int(myValue & 1)
            myValue >>= 1
        }
        return counter
    }
}

extension UInt16 {
    func toBinary(len: Int = 0)->String {
        return Int(self).toBinary(len: len)
    }
}

extension CGFloat {
    func between(_ min: CGFloat, max: CGFloat)->Bool {
        return self >= min && self <= max
    }
    
    func isPositiv()->Bool {
        return (self >= 0)
    }
    
    func isNegativ()->Bool {
        return (self < 0)
    }

}

extension String {
    func replace(_ what: String, values: [String])->String {
        let toArray = self.components(separatedBy: what)
        var endString = ""
        var vIndex = 0
        for index in 0..<toArray.count {
            endString += toArray[index] + (vIndex < values.count ? values[vIndex] : "")
            vIndex += 1
        }
        return endString
    }
    
    func isMemberOf(_ values: String...)->Bool {
        for index in 0..<values.count {
            if self == values[index] {
                return true
            }
        }
        return false
    }
    
    var length: Int {
        return characters.count
    }
    
    func dataFromHexadecimalString() -> Data? {
        let data = NSMutableData(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.append([num], length: 1)
        }
        
        return data as Data?
    }
    
    func isNumeric()->Bool {
        var OK = false
        if Int(self) != nil
        {
            OK = true
        }
        return OK
    }
    
    func pad(with character: String = "0", toLength length: Int = 8) -> String {
        let padCount = length - self.characters.count
        guard padCount > 0 else { return self }
        
        return String(repeating: character, count: padCount) + self
    }
}

extension UIColor {
    static public func greenAppleColor()->UIColor {
        return UIColor(red: 0x52/0xff, green: 0xD0/0xff, blue: 0x17/0xff, alpha: 1.0)
    }
}

//extension UIImage {
//    public func imageRotatedByDegrees(_ degrees: CGFloat, flip: Bool) -> UIImage {
//       self.transform( = CGAffineTransform(rotationAngle: CGFloat.pi)
//        //        let radiansToDegrees: (CGFloat) -> CGFloat = {
//        //            return $0 * (180.0 / CGFloat(M_PI))
//        //        }
//        let degreesToRadians: (CGFloat) -> CGFloat = {
//            return $0 / 180.0 * CGFloat(M_PI)
//        }
//        
//        // calculate the size of the rotated view's containing box for our drawing space
//        let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
//        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
//        rotatedViewBox.transform = t
//        let rotatedSize = rotatedViewBox.frame.size
//        
//        // Create the bitmap context
//        UIGraphicsBeginImageContext(rotatedSize)
//        let bitmap = UIGraphicsGetCurrentContext()
//        
//        // Move the origin to the middle of the image so we will rotate and scale around the center.
//        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);
//        
//        //   // Rotate the image context
//        bitmap?.rotate(by: degreesToRadians(degrees));
//        
//        // Now, draw the rotated/scaled image into the context
//        var yFlip: CGFloat
//        
//        if(flip){
//            yFlip = CGFloat(-1.0)
//        } else {
//            yFlip = CGFloat(1.0)
//        }
//        
//        bitmap?.scaleBy(x: yFlip, y: -1.0)
//        bitmap!.draw(self as! CGImage, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
//        
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        return newImage!
//    }
//}

extension Data {
    
//    var hexString: String? {
//        let buf = UnsafePointer<UInt8>(bytes)
//        let charA = UInt8(UnicodeScalar("a").value)
//        let char0 = UInt8(UnicodeScalar("0").value)
//        
//        func itoh(_ value: UInt8) -> UInt8 {
//            return (value > 9) ? (charA + value - 10) : (char0 + value)
//        }
//        
//        let ptr = UnsafeMutablePointer<UInt8>(allocatingCapacity: count * 2)
//        
//        for i in 0 ..< count {
//            ptr[i*2] = itoh((buf[i] >> 4) & 0xF)
//            ptr[i*2+1] = itoh(buf[i] & 0xF)
//        }
//        
//        return String(bytesNoCopy: ptr, length: count*2, encoding: String.Encoding.utf8, freeWhenDone: true)
//    }

    var hexString: String? {
        
        let buf = self
        let charA = UInt8(UnicodeScalar("a").value)
        let char0 = UInt8(UnicodeScalar("0").value)
        
        func itoh(_ value: UInt8) -> UInt8 {
            return (value > 9) ? (charA + value - 10) : (char0 + value)
        }
        
        var str = [UInt8]()
        
        for i in 0 ..< count {
            str.append(itoh((buf[i] >> 4) & 0xF))
            str.append(itoh(buf[i] & 0xF))
        }
        
        return NSString(bytes: str, length: str.count, encoding: String.Encoding.utf8.rawValue) as String?
        
    }

}

extension UIViewController {
    func showAlert(_ alert:UIAlertController, delay: Double = 0) {
        if (presentedViewController != nil) {
            dismiss(animated: true, completion: {
                self.present(alert, animated: true, completion: {
                })

            })
        } else {
            self.present(alert, animated: true, completion: {
            })

        }
        if delay > 0 {
            let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time) { () -> Void in
                self.dismiss(animated: true, completion: nil)
            }
        }
    
    }
    
    
}

extension TimeInterval {
    func stringFromTimeInterval() -> NSString {
        
        let ti = Int(self)
        
        let ms = Int((self) * 1000)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms) as NSString
    }
}






