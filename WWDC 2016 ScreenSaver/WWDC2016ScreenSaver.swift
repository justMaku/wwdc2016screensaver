//
//  WWDC2016ScreenSaver.swift
//  WWDC 2016 ScreenSaver
//
//  Created by Michał Kałużny on 19/06/16.
//  Copyright © 2016 Makowiec. All rights reserved.
//

import Cocoa
import ScreenSaver

extension Array {
    var random: Iterator.Element {
        let index = arc4random_uniform(UInt32(self.count))
        return self[Int(index)]
    }
}

class WWDC2016ScreenSaverView: ScreenSaverView {
    
    var maskImage: NSImage!
    var maskBitmap: NSBitmapImageRep!
    var maskImageRef: CGImage!
    var textLayers: [CATextLayer] = []
    
    lazy var font: NSFont = {
        let bundle = Bundle(for: self.dynamicType)
        let fontURL = bundle.urlForResource("SFMono-Regular", withExtension: "otf")!
        
        let provider = CGDataProvider(url: fontURL)!
        let fontRef = CGFont(provider)
        return CTFontCreateWithGraphicsFont(fontRef, 13.0, nil, nil)
    }()
    
    let words = [":", ";", "\\", "/", ".", "!", "?",
                 "+", "-", "*", "&", "^", "[", "]",
                 "(", ")", "#", "@", "&", "<", ">",
                 "~"
    ]
    
    
    let colors = ["FFFFFF", "D08D61", "59B75C",
                  "8485BC", "94C472", "DB3C40",
                  "B43E92", "1AACA5"]
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        buildMaskImage()
        self.animationTimeInterval = 1 
        self.startAnimation()
    }
    
    func createLayers() {
        
        let newHeight = self.frame.height / 2
        let newWidth = maskImage.size.width * (newHeight / maskImage.size.height)
        let newSize = CGSize(width: newWidth, height: newHeight)
        let newOrigin = CGPoint(x: self.frame.width/2 - newWidth/2, y: self.frame.height/2 - newHeight/2)
        
        let scaledImage = scaleImage(maskImageRef, size: newSize)
        maskBitmap = NSBitmapImageRep(cgImage: scaledImage)
        
        let drawingRect = CGRect(origin: newOrigin, size: newSize)
        
        let backgroundColor = NSColor.fromHex("292B37")
        let layer = CALayer()
        layer.backgroundColor = backgroundColor.cgColor
        self.layer = layer
        self.wantsLayer = true
        
        var lastWord: String? = nil
        var lastColor: NSColor? = nil
        var point: CGPoint = CGPoint.zero
        
        while true {
            
            var word: String!
            var color: NSColor!
            
            while true {
                let nextColor = NSColor.fromHex(colors.random)
                if nextColor != lastColor {
                    color = nextColor
                    break
                }
            }
            
            while true {
                let nextWord = words.random
                if nextWord != lastWord {
                    word = nextWord
                    break
                }
            }
            
            let attributes: [String: AnyObject] = [NSForegroundColorAttributeName: color,
                                                   NSFontAttributeName: font]
            
            let boundingRect = (word as NSString).boundingRect(with: drawingRect.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes)
            
            let percentage = percentageOfBlackPixels(CGRect(origin: point, size: boundingRect.size))
            
            if percentage >= 95 {
                let drawingPoint = CGPoint(x: point.x + newOrigin.x, y: point.y + newOrigin.y)
                let textLayer = CATextLayer()
                textLayer.string = word
                textLayer.font = font
                textLayer.foregroundColor = color.cgColor
                textLayer.fontSize = 13.0
                textLayer.contentsScale = NSScreen.main()!.backingScaleFactor
                textLayer.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: boundingRect.size)
                textLayer.position = drawingPoint
                layer.addSublayer(textLayer)
                textLayers.append(textLayer)
            }
            
            
            if point.x > drawingRect.width - boundingRect.width {
                point.x = 0
                point.y += boundingRect.height
            } else {
                point.x += boundingRect.width
            }
            
            if point.y > drawingRect.height - boundingRect.height {
                break
            }
            
            lastColor = color
            lastWord = word
        }
    }
    
    override func draw(_ rect: NSRect) {
        if textLayers.count == 0 {
            createLayers()
        }
    }
    
    func buildMaskImage() {
        let bundle = Bundle(for: self.dynamicType)
        let imageURL = bundle.urlForResource("logo_outline", withExtension: "png")!
        
        self.maskImage = NSImage(contentsOf: imageURL)!
        
        let provider = CGDataProvider(url: imageURL)!
        let image = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        self.maskImageRef = image
    }
    
    func scaleImage(_ image: CGImage, size: CGSize) -> CGImage {
        let bitsPerComponent = image.bitsPerComponent
        let bytesPerRow = image.bytesPerRow
        let colorSpace = image.colorSpace
        let bitmapInfo = image.bitmapInfo
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                            bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue)
        
        context!.interpolationQuality = CGInterpolationQuality.high
        context!.draw(in: CGRect(origin: CGPoint.zero, size: size), image: image)
        return context!.makeImage()!
    }
    
    func percentageOfBlackPixels(_ rect: CGRect) -> CGFloat {
        
        let translatedOrigin = CGPoint(x: rect.origin.x, y: self.maskBitmap.size.height - rect.size.height - rect.origin.y)
        let translatedRect = CGRect(origin: translatedOrigin, size: rect.size)
        
        let numOfPixels = translatedRect.size.width * translatedRect.size.height
        var numOfBlackPixels: CGFloat = 0
        
        let start = CGPoint(x: translatedRect.origin.x, y: translatedRect.origin.y)
        let end = CGPoint(x: translatedRect.origin.x + translatedRect.size.width,
                          y: translatedRect.origin.y + translatedRect.size.height)
        
        for x in Int(start.x)...Int(end.x) {
            for y in Int(start.y)...Int(end.y) {
                let color = maskBitmap.colorAt(x: x, y: y)
                if color?.greenComponent != 1 {
                    numOfBlackPixels += 1
                }
            }
        }
        
        let percentage: CGFloat = (numOfBlackPixels * 100) / numOfPixels
        return percentage
    }
    
    override func animateOneFrame() {
        
        if textLayers.count == 0 {
            return
        }
        
        CATransaction.begin()
        
        for _ in 0...10 {
            let colorAnimation = CABasicAnimation()
            colorAnimation.duration = 2.0
            colorAnimation.keyPath = "foregroundColor"
            colorAnimation.toValue = NSColor.fromHex(colors.random).cgColor
            
            
            let layer = textLayers.random
            layer.add(colorAnimation, forKey: "foregroundColor")
            
            layer.string = self.words.random
        }
        
        CATransaction.setCompletionBlock { 
            self.needsDisplay = true
            
            self.startAnimation()
        }
        
        CATransaction.commit()
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }
}
