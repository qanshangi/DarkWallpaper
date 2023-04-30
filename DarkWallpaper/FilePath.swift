//
//  FilePath.swift
//  Darkmenubar
//
//  Created by content on 2022/12/4.
//

import Foundation
import Cocoa
import os.log

//原壁纸路径
var sourceWallpaperPath: URL = URL(fileURLWithPath: "/")
//壁纸的保存路径
var workingDir: URL = URL(fileURLWithPath: "/")

//获得壁纸的文件路径
func getWallpaperPath(screen: NSScreen) -> URL? {
    
    guard var path = NSWorkspace.shared.desktopImageURL(for: screen) else {
        os_log("Cannot read the currently set macOS wallpaper. Try providing a specific wallpaper as a parameter instead.", type: .debug)
        return nil
    }
    
    //通过文件路径判断壁纸是否为本程序生成
    if path.absoluteString.contains("DarkWallpaper") {
        path = sourceWallpaperPath
        print(path)
    }
    else
    {
        sourceWallpaperPath = path
        //defaults.setValue(sourceWallpaperPath!.path, forKey: "SourceWallpaperPath")
    }
    return path
}

//设置壁纸
func setWallpaper(screen: NSScreen, wallpaperCGImage: CGImage) {
    let workingDirectory = workingDir
    let wallpaperFile = workingDirectory.appendingPathComponent("wallpaper-\(UUID().uuidString).png")
    
    let bitmapImage = NSBitmapImageRep(cgImage: wallpaperCGImage)
    guard let wallpaper = bitmapImage.representation(using: .png,
                            properties: [NSBitmapImageRep.PropertyKey.compressionMethod : 1]) else {
        os_log("Cannot create data from bitmap image", type: .error)
        return
    }

    do {
        //删除同名文件
        try? FileManager.default.removeItem(at: wallpaperFile)
        
        try wallpaper.write(to: wallpaperFile)
        os_log("Created new wallpaper for the main screen", type: .debug)
        
        //设置壁纸
        try NSWorkspace.shared.setDesktopImageURL(wallpaperFile, for: screen, options: [:])
        os_log("Wallpaper set", type: .debug)

    } catch {
        os_log("Writing new wallpaper file failed for the main screen", type: .error)
    }
}

//恢复原壁纸
func restoreDefaultWallpaper() {
    let screens: [NSScreen] = allDisplays ? NSScreen.screens : [NSScreen.main].compactMap({ $0 })
    guard !screens.isEmpty else {
        os_log("Could not detect any screens", type: .error)
        return
    }
    for screen in screens {
        do {
            try NSWorkspace.shared.setDesktopImageURL(sourceWallpaperPath, for: screen, options: [:])
            os_log("Wallpaper set", type: .debug)
        } catch {
            os_log("Writing new wallpaper file failed for the main screen", type: .error)
        }
    }
}

//获取壁纸要保存（工作）路径
func getWorkingDirectory() -> URL? {
    
    let applicationSupportDirectory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]
    let workingDirectory = applicationSupportDirectory + "/DarkWallpaper"
    
    let fileManager = FileManager.default
    //判断文件或文件夹是否存在
    let exist = fileManager.fileExists(atPath: workingDirectory)
    if exist == false {
        //创建文件夹
        do {
            try fileManager.createDirectory(atPath: workingDirectory,
                                              withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
    }
    return URL(fileURLWithPath: workingDirectory)
}

func clearAllWallpaperFile(){
    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: workingDir, includingPropertiesForKeys: nil, options: [])
        for (_, filePath) in directoryContents.enumerated() {
            try? FileManager.default.removeItem(at: filePath)
        }
    }
    catch {
        print(error.localizedDescription)
    }
}


//判断文件是否可读
/*let fileManager = FileManager.default
let exist = fileManager.isReadableFile(atPath: path.path)
if exist == false {
    if getqx() == false {
        return nil
    }
}*/

//获取文件权限
/*func getAuthorization () -> Bool {
    //appMenu.isAccessibilityHidden = true
    let fd: NSOpenPanel = NSOpenPanel()
    fd.directoryURL = sourceWallpaperPath
    fd.canChooseDirectories = false //不允许选择目录
    fd.canChooseFiles = true    //选择文件
    fd.allowsMultipleSelection = false  //不允许多选
    if (fd.runModal() == NSApplication.ModalResponse.OK)
    {
        let result = fd.url // Pathname of the file

        if (result != nil) {
            sourceWallpaperPath = result!
            print("browseFile path: \(sourceWallpaperPath)")
            //filename_field.stringValue = path
            return true
        }
    }
    return false
}*/
