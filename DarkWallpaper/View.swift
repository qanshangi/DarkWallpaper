//
//  View.swift
//  Darkmenubar
//
//  Created by content on 2022/12/6.
//

import Foundation
import Cocoa
import os.log

//是否深色模式
var darkMode: Bool = false
var systemAppearance: Bool = false

class View: NSView {
    var viewInit: Bool = true
    
    
    //系统外观更改时，调用此函数
    override func layout() {
        super.layout()
        
        //NSView初始化会调用两次
        //初始化
        if viewInit == true {
            
            updateSlider()
            updateWallpaper()
            
            viewInit = false
            return
        }
        
        systemAppearance = isDarkMode()
        let appdelegate = NSApplication.shared.delegate as! AppDelegate
        if systemAppearance == false {
            appdelegate.appearanceMenuItem.title = "深色模式"
        } else {
            appdelegate.appearanceMenuItem.title = "浅色模式"
        }
        
        if auto == .on {
            darkMode = systemAppearance
            //浅色
            if darkMode == false {
                menuBrightness = menuLightBright
                deskBrightness = deskLightBright
            //深色
            } else {
                menuBrightness = menuDarkBright
                deskBrightness = deskDarkBright
            }
            updateSlider()
            updateWallpaper()
        }
    }
}
