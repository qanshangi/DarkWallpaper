//
//  Extensions.swift
//  Darkmenubar
//
//  Created by content on 2022/12/4.
//

import Foundation
import Cocoa
import os.log

//代码来自igorkulman的ChangeMenuBarColor
//https://github.com/igorkulman/ChangeMenuBarColor
extension NSScreen {
    //获取屏幕大小
    var size: CGSize {
        return CGSize(width: frame.size.width * backingScaleFactor, height: frame.size.height * backingScaleFactor)
    }
    
    //获取菜单栏高度
    var menuBarHeight: CGFloat {
        let computedHeight = (frame.size.height - visibleFrame.height - visibleFrame.origin.y - 1) * backingScaleFactor
        guard computedHeight > 0 else {
            os_log("Menu bar height computation is still not good, using approximation", type: .debug)
            return 24 * backingScaleFactor
        }

        return computedHeight
    }
    
    //获取桌面高度
    var desktopHeight: CGFloat {
        let computedHeight = (visibleFrame.height + visibleFrame.origin.y + 1) * backingScaleFactor
        guard computedHeight > 0 else {
            os_log("Menu bar height computation is still not good, using approximation", type: .debug)
            return (frame.size.height - 24) * backingScaleFactor
        }
        return computedHeight
    }
}

//获取系统外观
func isDarkMode() ->Bool {
    return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
}
