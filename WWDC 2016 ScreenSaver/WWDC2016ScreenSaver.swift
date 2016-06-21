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
    
    /// Returns an array containing this sequence shuffled
    var shuffled: Array {
        var elements = self
        return elements.shuffle()
    }
    
    /// Shuffles this sequence in place
    @discardableResult
    mutating func shuffle() -> Array {
        indices.dropLast().forEach({
            guard case let index = Int(arc4random_uniform(UInt32(count - $0))) + $0
                where index != $0 else { return }
            swap(&self[$0], &self[index])
        })
        return self
    }

    func choose(_ n: Int) -> Array { return Array(shuffled.prefix(n)) }
}

class WWDC2016ScreenSaverView: ScreenSaverView {
    
    let scale: CGFloat = 0.5
    let numberOfItemsToDrawPerTick = 50
    static let fontSize: CGFloat = 13.0
    
    var maskImage: NSImage!
    var maskBitmap: NSBitmapImageRep!
    var maskImageRef: CGImage!
    var textLayers: [CATextLayer] = []
    
    lazy var font: NSFont = {
        let bundle = Bundle(for: self.dynamicType)
        let fontURL = bundle.urlForResource("SFMono-Regular", withExtension: "otf")!
        
        let provider = CGDataProvider(url: fontURL)!
        let fontRef = CGFont(provider)
        return CTFontCreateWithGraphicsFont(fontRef, WWDC2016ScreenSaverView.fontSize, nil, nil)
    }()
    
    let words = [":", ";", "\\", "/", ".", "!", "?",
                 "+", "-", "*", "&", "^", "[", "]",
                 "(", ")", "#", "@", "&", "<", ">",
                 "~"]    
    
    let colors = ["FFFFFF", "D08D61", "59B75C",
                  "8485BC", "94C472", "DB3C40",
                  "B43E92", "1AACA5"]
    
    override var frame: CGRect {
        didSet {
            createLayers()
        }
    }
    
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
    }
    
    
    func createLayers() {
        
        let newHeight = self.frame.height * scale
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
        
        var point: CGPoint = CGPoint.zero
        
        while true {

            let attributes: [String: AnyObject] = [NSFontAttributeName: font]
            
            let boundingRect = (" " as NSString).boundingRect(with: drawingRect.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes)
            
            let percentage = percentageOfBlackPixels(CGRect(origin: point, size: boundingRect.size))
            
            if percentage >= 1 {
                let drawingPoint = CGPoint(x: point.x + newOrigin.x, y: point.y + newOrigin.y)
                let textLayer = CATextLayer()
                textLayer.font = font
                textLayer.foregroundColor = backgroundColor.cgColor
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
        
        let percentage: CGFloat = numOfBlackPixels / numOfPixels
        return percentage
    }
    
    func tick() {
        func updateLayersText(layers: [CATextLayer]) {
            for i in 0..<layers.count {
                let layer = layers[i]
                layer.string = words.random
            }
        }
        
        func animateLayersColor(layers: [CATextLayer]) {
            for i in 0..<layers.count {
                
                let layer = layers[i]
                let color = NSColor.fromHex(colors.random).cgColor
                
                layer.removeAllAnimations()
                
                let animation = CABasicAnimation()
                animation.duration = 0.4
                animation.fromValue = layer.foregroundColor
                animation.toValue = color
                
                layer.foregroundColor = color
                layer.add(animation, forKey: #keyPath(CATextLayer.foregroundColor))
            }
        }
        
        if self.isAnimating == false {
            return
        }
        
        if textLayers.count == 0 {
            return
        }
        
        let layersToPresent = textLayers.filter { $0.string == nil }.choose(numberOfItemsToDrawPerTick)
        let visibleLayers = textLayers.filter { $0.string != nil }
        let layersToAnimate = visibleLayers.choose(numberOfItemsToDrawPerTick)

        if layersToPresent.count > 0 {
            updateLayersText(layers: layersToPresent)
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        CATransaction.setCompletionBlock {
            self.tick()
        }
        
        if layersToPresent.count > 0 {
            animateLayersColor(layers: layersToPresent)
        }
        
        if layersToAnimate.count > 0 && layersToPresent.count == 0 {
            animateLayersColor(layers: layersToAnimate)
        }
        
        CATransaction.commit()
        
        if layersToPresent.count == 0 {
            let layersToUpdate = textLayers.filter { layersToAnimate.contains($0) == false }.choose(numberOfItemsToDrawPerTick)
            updateLayersText(layers: layersToUpdate)
        }
    }
    
    override func startAnimation() {
        super.startAnimation()
        tick()
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }
}
