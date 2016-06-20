//
//  NSColor+Hex.swift
//  WWDC 2016 ScreenSaver
//
//  Created by Michał Kałużny on 19/06/16.
//  Copyright © 2016 Makowiec. All rights reserved.
//

import Cocoa

extension NSColor {
    class func fromHex(_ hexColor: String) -> NSColor {
        var hex = String()
        if hexColor.hasPrefix("#") {
            hex = hexColor[1]
        } else {
            hex = hexColor
        }
        
        func hexToCGFloat(_ color: String) -> CGFloat {
            var result: CUnsignedInt = 0
            let scanner: Scanner = Scanner(string: color)
            scanner.scanHexInt32(&result)
            let colorValue: CGFloat = CGFloat(result)
            return colorValue / 255
        }
        
        let redComponent = hexToCGFloat(hex.substring(r: Range<Int>(uncheckedBounds: (lower: 0, upper: 2))))
        let greenComponent = hexToCGFloat(hex.substring(r: Range<Int>(uncheckedBounds: (lower: 2, upper: 4))))
        let blueComponent = hexToCGFloat(hex.substring(r: Range<Int>(uncheckedBounds: (lower: 4, upper: 6))))
        
        let color = NSColor(calibratedRed: redComponent, green: greenComponent, blue: blueComponent, alpha: 1)
        
        return color
    }
}

extension String {
    subscript (i: Int) -> String {
        return String(Array(self.characters)[i])
    }
    func substring(r: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = characters.index(startIndex, offsetBy: r.upperBound)
        return substring(with: start..<end)
    }
}

