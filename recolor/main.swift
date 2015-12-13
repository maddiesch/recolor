//
//  main.swift
//  recolor
//
//  Created by Skylar Schipper on 12/13/15.
//  Copyright © 2015 OpenSky, LLC. All rights reserved.
//

import Foundation
import Cocoa
import CoreGraphics

func TintImage(image: NSImage, tint: NSColor) -> NSImage {
    let tinted = image.copy() as! NSImage

    tinted.lockFocus()
    tint.set()

    let rect = NSRect(origin: NSZeroPoint, size: tinted.size)
    NSRectFillUsingOperation(rect, .CompositeSourceAtop)

    tinted.unlockFocus()

    return tinted
}

func WriteImage(image: NSImage, path: String) {
    if NSFileManager.defaultManager().fileExistsAtPath(path) {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        } catch let e {
            fatalError("\(e)")
        }
    }

    guard let lImage = image.CGImageForProposedRect(nil, context: nil, hints: nil) else {
        fatalError("Failed to create image")
    }

    let bitmap = NSBitmapImageRep(CGImage: lImage)
    bitmap.size = image.size

    guard let data = bitmap.representationUsingType(.NSPNGFileType, properties: [:]) else {
        fatalError("Failed to create PNG")
    }

    do {
        try data.writeToFile(path, options: .AtomicWrite)
    } catch let e {
        fatalError("Write Failed: \(e)")
    }
}

func ColorFromInput(string: String) -> NSColor {
    var local = string.stringByReplacingOccurrencesOfString("#", withString: "")
    local = local.stringByReplacingOccurrencesOfString("0x", withString: "", options: .CaseInsensitiveSearch)

    if local.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) != 6 {
        fatalError("Expected a color in FFFFFF format")
    }

    let toFloat: (String) -> CGFloat = { string in

        let scanner = NSScanner(string: "0x\(string)")

        var pointer = UnsafeMutablePointer<UInt32>.alloc(1)
        pointer.initialize(0)
        defer {
            pointer.destroy()
            pointer.dealloc(1)
        }
        if !scanner.scanHexInt(pointer) {
            fatalError("Failed to get integer for \(local)")
        }
        let value = CGFloat(pointer.memory)

        return value / 255.0
    }

    let redRange = Range<String.Index>(start: local.startIndex, end: local.startIndex.advancedBy(2))
    let greenRange = Range<String.Index>(start: local.startIndex.advancedBy(2), end: local.startIndex.advancedBy(4))
    let blueRange = Range<String.Index>(start: local.startIndex.advancedBy(4), end: local.startIndex.advancedBy(6))

    let redF = toFloat(local.substringWithRange(redRange))
    let greenF = toFloat(local.substringWithRange(greenRange))
    let blueF = toFloat(local.substringWithRange(blueRange))

    return NSColor(calibratedRed: redF, green: greenF, blue: blueF, alpha: 1.0)
}

let args = NSProcessInfo.processInfo().arguments

guard args.count >= 3 else {
    fatalError("expected to have a color and image path")
}

let color = args[1]
let path = args[2]

guard let image = NSImage(contentsOfFile: path) else {
    fatalError("Expected image for file \(path)")
}

let tinted = TintImage(image, tint: ColorFromInput(color))

var pathComponents = path.componentsSeparatedByString("/")

let fileName = pathComponents.removeLast()

var parts = fileName.componentsSeparatedByString(".")
parts.removeLast()
parts.append("tinted")
let output = parts.joinWithSeparator("-") + ".png"

pathComponents.append(output)

WriteImage(tinted, path: pathComponents.joinWithSeparator("/"))
