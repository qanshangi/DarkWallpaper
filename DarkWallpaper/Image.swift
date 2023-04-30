//
//  Image.swift
//  Darkmenubar
//
//  Created by content on 2022/12/4.
//

import Foundation
import Cocoa
import os.log

//将图片调整到合适的尺寸
func resizeImage(size: NSSize, path: URL) -> CGImage? {
    
    guard let inputCIImage = CIImage(contentsOf: path) else {
        return nil
    }
    
    //获取壁纸尺寸
    let sourceWidth: CGFloat = inputCIImage.extent.width
    let sourceHeight: CGFloat = inputCIImage.extent.height
    
    let context = CIContext()
    
    //大小相同不做调整
    if sourceWidth == size.width && sourceHeight == size.height {
        return context.createCGImage(_: inputCIImage, from: CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight))
    }
    
    //计算比例
    let widthRatio  = size.width / sourceWidth
    let heightRatio = size.height / sourceHeight
    var ratio: CGFloat = 0.0
    ratio = (widthRatio > heightRatio ? widthRatio : heightRatio)
    //ratio = CGFloat(Int(ratio * 10)) / 10.0
    
    
    //创建用于处理图片的滤镜（Filter）
    let filter = CIFilter(name: "CILanczosScaleTransform")!
    //设置缩放比例
    filter.setValue(ratio, forKey: kCIInputScaleKey)
    filter.setValue(inputCIImage, forKey: kCIInputImageKey)
    // 获取经过滤镜处理之后的图片，并且将其放置在开头设置好的CIContext()中
    let result = filter.outputImage!
    
    //获取缩放后的大小
    let newWidth = result.extent.width
    let newHeight = result.extent.height
    
    //居中裁剪
    let x = floor((newWidth - size.width) / 2)
    let y = floor((newHeight - size.height) / 2)
    let rect = CGRect(x: x, y: y, width: size.width, height: size.height)
    
    guard let newCGImage = context.createCGImage(result, from: rect) else {
        os_log("创建图片失败", type: .error)
        return nil
    }
    
    return newCGImage
}

//更改图片亮度、对比度
func ChangeImageBrightness(inputCGImage: CGImage, rect: CGRect, brightness: Double) -> CGImage? {
    //创建一个CIContext()，用来放置处理后的内容
    let a = brightness
    let context = CIContext()
    //将输入的UIImage转变成CIImage
    let inputCIImage = CIImage(cgImage: inputCGImage)
    
    //创建用于处理图片的滤镜（Filter）
    let filter = CIFilter(name: "CIColorControls")!
    //这里设置亮度
    
    filter.setValue(0.05 * a, forKey: kCIInputBrightnessKey)
    //设置对比度
    filter.setValue( 1.0 + 0.1 * a, forKey: kCIInputContrastKey)
    //设置饱和度
    //filter.setValue(a > 0 ? 1.0 : 1.0 - a * 0.1, forKey: kCIInputSaturationKey)
    //设置输入图片
    filter.setValue(inputCIImage, forKey: kCIInputImageKey)
    
    // 获取经过滤镜处理之后的图片，并且将其放置在开头设置好的CIContext()中
    let result = filter.outputImage!
    
    guard let cgImage = context.createCGImage(result, from: rect) else {
        os_log("创建图片失败", type: .error)
        return nil
    }
    return cgImage
    
}

//创建纯色图片
func createSolidImage(color: NSColor, width: Int, height: Int) -> CGImage? {
    guard let context = createContext(width: width, height: height) else {
        os_log("Could not create graphical context for solid color image", type: .error)
        return nil
    }

    context.setFillColor(color.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    guard let composedImage = context.makeImage() else {
        os_log("Could not create composed image for solid color image", type: .error)
        return nil
    }

    return composedImage
}

//创建壁纸
func createWallpaper(screen: NSScreen) -> CGImage? {
    guard let path = getWallpaperPath(screen: screen) else {
        return nil
    }
    //调整大小后的壁纸
    guard let baseCGImage = resizeImage(size: screen.size, path: path) else {
        return nil
    }
    
    //隐藏刘海
    if hide == .on {
        //创建一张黑色图片
        let color: NSColor = NSColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        guard let solidCGImage = createSolidImage(color: color,
                                                  width: Int(screen.size.width),
                                                  height: Int(screen.menuBarHeight)) else {
            return nil
        }
        //未改变桌面亮度
        if deskBrightness == 0 {
            return combineImages(baseCGImage: baseCGImage, addCGImage: solidCGImage)
        //改变桌面亮度
        } else {
            guard let deskCGImage = ChangeImageBrightness(inputCGImage: baseCGImage,
                                               rect: CGRect(x: 0, y: 0, width: screen.size.width, height: screen.desktopHeight),
                                               brightness: deskBrightness) else {
                return nil
            }
            return combineImages(baseCGImage: baseCGImage, addCGImage1: solidCGImage, addCGImage2: deskCGImage)
        }
    }
    
    //打开同步
    if sync == .on {
        guard let screenCGImage = ChangeImageBrightness(inputCGImage: baseCGImage,
                                             rect: CGRect(x: 0, y: 0, width: screen.size.width, height: screen.size.height),
                                             brightness: deskBrightness) else {
            return nil
        }
        return combineImages(baseCGImage: baseCGImage, addCGImage: screenCGImage)
    //关闭同步
    } else {
        //菜单栏
        guard let menuCGImage = ChangeImageBrightness(inputCGImage: baseCGImage,
                                           rect: CGRect(x: 0, y: screen.size.height - screen.menuBarHeight, width: screen.size.width, height: screen.menuBarHeight),
                                           brightness: menuBrightness) else {
            return nil
        }
        //桌面
        guard let deskCGImage = ChangeImageBrightness(inputCGImage: baseCGImage,
                                           rect: CGRect(x: 0, y: 0, width: screen.size.width, height: screen.desktopHeight),
                                           brightness: deskBrightness) else {
            return nil
        }
        return combineImages(baseCGImage: baseCGImage, addCGImage1: menuCGImage, addCGImage2: deskCGImage)
    }
    
}

//两张图片拼接
func combineImages(baseCGImage: CGImage, addCGImage: CGImage) -> CGImage? {
    
    guard let context = createContext(width: baseCGImage.width, height: baseCGImage.height) else {
        os_log("Could not create graphical context when merging images", type: .error)
        return nil
    }
    
    context.draw(baseCGImage, in: CGRect(x: 0, y: 0, width: baseCGImage.width, height: baseCGImage.height))
    context.draw(addCGImage, in: CGRect(x: 0, y: baseCGImage.height - addCGImage.height, width: addCGImage.width, height: addCGImage.height))
    

    guard let composedImage = context.makeImage() else {
        os_log("Could not create composed image when merging with the wallpaper", type: .error)
        return nil
    }
    
    return composedImage
}

//三张图片拼接
func combineImages(baseCGImage: CGImage, addCGImage1: CGImage, addCGImage2: CGImage) -> CGImage? {
    
    guard let context = createContext(width: baseCGImage.width, height: baseCGImage.height) else {
        os_log("Could not create graphical context when merging images", type: .error)
        return nil
    }
    
    context.draw(baseCGImage, in: CGRect(x: 0, y: 0, width: baseCGImage.width, height: baseCGImage.height))
    context.draw(addCGImage1, in: CGRect(x: 0, y: baseCGImage.height - addCGImage1.height, width: addCGImage1.width, height: addCGImage1.height))
    context.draw(addCGImage2, in: CGRect(x: 0, y: 0, width: addCGImage2.width, height: addCGImage2.height))
    

    guard let composedCGImage = context.makeImage() else {
        os_log("Could not create composed image when merging with the wallpaper", type: .error)
        return nil
    }

    return composedCGImage
}

//创建绘图环境
func createContext(width: Int, height: Int) -> CGContext? {
    return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
}
