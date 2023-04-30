//
//  AppDelegate.swift
//  Darkmenubar
//
//  Created by content on 2022/12/6.
//
import Foundation
import Cocoa
import os.log
import ServiceManagement

let allDisplays: Bool = true
var sync: NSControl.StateValue = .on    //桌面壁纸与菜单栏壁纸亮度同步
var hide: NSControl.StateValue = .off   //隐藏刘海
var auto: NSControl.StateValue = .on    //壁纸亮度跟随系统切换

//保存深色模式下的亮度
var menuDarkBright: Double = 0, deskDarkBright: Double = 0
//保存浅色模式下的亮度
var menuLightBright: Double = 0, deskLightBright: Double = 0
//当前亮度
var menuBrightness: Double = 0.0
var deskBrightness: Double = 0.0
//隐藏刘海，顶部图片所使用的argb值
var a: UInt8 = 255, r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0

//用户默认数据库   ~~~/Library/Preferences/DarkWallpaper.plist
let defaults = UserDefaults(suiteName: "DarkWallpaper")!

//后台线程是否执行完毕
var isFinish: Bool = true

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    @IBOutlet var window: NSWindow!
    //重写NSView里的layout方法，用于检测系统外观变化
    @IBOutlet weak var view: View!
    var statusItem: NSStatusItem?   //状态栏
    @IBOutlet weak var appMenu: NSMenu! //主菜单
    //菜单栏亮度滑块
    let menuBarSlider = NSSlider(frame: NSRect(x: 15, y: 0, width: 200, height: 30))
    //桌面亮度滑块
    let desktopSlider = NSSlider(frame: NSRect(x: 15, y: 50, width: 200, height: 30))
    
    @IBOutlet weak var syncMenuItem: NSMenuItem!    //桌面与菜单栏同步菜单项
    @IBOutlet weak var autoAppearanceMenuItem: NSMenuItem!  //壁纸亮度跟随系统切换菜单项
    
    @IBOutlet weak var appearanceMenuItem: NSMenuItem!  //更改系统外观菜单项
    @IBOutlet weak var hideMenuItem: NSMenuItem!    //隐藏刘海菜单项
    @IBOutlet weak var startMenuItem: NSMenuItem!   //开机自启动菜单项
    
    //调节菜单栏墙纸亮度
    @objc func menuBarSliderChanged(_ sender: NSSlider) {
        if isFinish == false {
            return
        }
        
        let value = sender.doubleValue
        //防止重复执行
        if menuBrightness == value {
            return
        }
        menuBrightness = value
        //根据外观保存对应的亮度
        if darkMode == false {
            menuLightBright = value
        } else {
            menuDarkBright = value
        }
        
        updateWallpaper()
    }
    
    //调节桌面墙纸亮度
    @objc func deskSliderChanged(_ sender: NSSlider) {
        if isFinish == false {
            return
        }
        
        let value = sender.doubleValue
        //防止重复执行
        if deskBrightness == value {
            return
        }
        
        deskBrightness = value
        //根据外观保存对应的亮度
        if darkMode == false {
            deskLightBright = value
        } else {
            deskDarkBright = value
        }
        
        if sync == .on {
            menuBrightness = value
            
            if darkMode == false {
                menuLightBright = value
            } else {
                menuDarkBright = value
            }
        }
        updateWallpaper()
    }
    
    //桌面与菜单栏同步
    @IBAction func syncClicked(_ sender: NSMenuItem) {
        if isFinish == false {
            return
        }
        
        sync = (sender.state == .on ? .off : .on)
        sender.state = sync
        defaults.setValue(sync, forKey: "DesktopMenuBarSync")
        
        if sync == .on {
            menuBarSlider.isEnabled = false
            menuBarSlider.doubleValue = 0.0
            
            menuBrightness = deskBrightness
            menuLightBright = deskLightBright
            menuDarkBright = deskDarkBright
            
            updateWallpaper()
        } else {
            menuBarSlider.doubleValue = menuBrightness
            menuBarSlider.isEnabled = true
        }
    }
    
    //菜单即将打开
    func menuWillOpen(_ menu: NSMenu) {
        //更新
        if hide == .on {
            if isFinish == false {
                return
            }
            updateWallpaper()
        }
    }
    
    //隐藏刘海
    @IBAction func hideNotchClicked(_ sender: NSMenuItem) {
        if isFinish == false {
            return
        }
        
        hide = (sender.state == .on ? .off : .on)
        sender.state = hide
        defaults.setValue(hide, forKey: "HideNotch")
        
        if hide == .on {
            syncMenuItem.isEnabled = false
            
            menuBarSlider.doubleValue = 0.0
            menuBarSlider.isEnabled = false
        } else {
            syncMenuItem.isEnabled = true
            
            syncMenuItem.isHidden = false
            if sync == .off {
                menuBarSlider.doubleValue = menuBrightness
                menuBarSlider.isEnabled = true
            }
        }
        updateWallpaper()
    }
    
    //外观模式跟随系统
    @IBAction func autoSetClicked(_ sender: NSMenuItem) {
        if isFinish == false {
            return
        }
        
        auto = (sender.state == .on) ? .off : .on
        sender.state = auto
        defaults.setValue(auto, forKey: "AutoSetAppearance")
        
        if auto == .on  && darkMode != isDarkMode() {
            view.needsLayout = true
        }
    }
    
    @IBAction func setAppearanceClicked(_ sender: NSMenuItem) {
        Thread.detachNewThread() {
           NSAppleScript(source: "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode")?.executeAndReturnError(nil)
        }
    }
    
    //开机自启动
    @IBAction func startAtLoginClicked(_ sender: NSMenuItem) {
        let identifier = "\(Bundle.main.bundleIdentifier!)Helper" as String
        //macOS 13+
        let sm = SMAppService.loginItem(identifier: identifier)
        do {
            if sender.state == .on
            {
                try sm.unregister()
            } else {
                try sm.register()
            }
            sender.state = (sender.state == .on) ? .off : .on
            defaults.setValue(sender.state, forKey: "StartAtLogin")
        } catch {
            os_log("Toggle start at login failed", type: .error)
        }
        
        //macOS 10.6+
        /*if SMLoginItemSetEnabled(identifier, sender.state == .off) {
            sender.state = (sender.state == .on) ? .off : .on
            defaults.setValue((sender.state == .on), forKey: "StartAtLogin")
        } else {
            if #available(macOS 10.12, *) {
                os_log("Toggle start at login failed", type: .error)
            }
        }*/
    }
    
    //关于
    @IBAction func openAboutPanel(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }
    
    //菜单初始化
    func initMenu(_ menu: NSMenu) {
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.menu = appMenu
        statusItem?.button?.toolTip = "DarkWallpaper"
        statusItem?.button?.target = self
        let image: NSImage = NSImage(named: "MenuBarImage")!
        image.isTemplate = true
        statusItem?.button?.image = image
        
        appMenu.delegate = self
        
        //菜单栏
        let menuLabel: NSTextField = NSTextField(frame: NSRect(x: 15, y: 30, width: 200, height: 20))
        menuLabel.isEditable = false
        menuLabel.isSelectable = false
        menuLabel.isBezeled = false
        menuLabel.drawsBackground = false
        menuLabel.stringValue = "菜单"
        menuLabel.font = menu.font
        
        menuBarSlider.maxValue = 9.0
        menuBarSlider.minValue = -9.0
        menuBarSlider.numberOfTickMarks = 3
        menuBarSlider.target = self
        menuBarSlider.action = #selector(menuBarSliderChanged)
        menuBarSlider.isContinuous = false
        
        //桌面
        let deskLabel: NSTextField = NSTextField(frame: NSRect(x: 15, y: 80, width: 200, height: 20))
        deskLabel.isEditable = false
        deskLabel.isSelectable = false
        deskLabel.isBezeled = false
        deskLabel.drawsBackground = false
        deskLabel.stringValue = "桌面"
        deskLabel.font = menu.font
        
        desktopSlider.maxValue = 9.0
        desktopSlider.minValue = -9.0
        desktopSlider.numberOfTickMarks = 3
        desktopSlider.target = self
        desktopSlider.action = #selector(deskSliderChanged)
        desktopSlider.isContinuous = false
        
       
        
        let menuView = NSView(frame: NSRect(x: 0, y: 0, width: 230, height: 107))
        menuView.addSubview(menuLabel)
        menuView.addSubview(menuBarSlider)
        menuView.addSubview(deskLabel)
        menuView.addSubview(desktopSlider)

        let item = NSMenuItem()
        item.view = menuView
        //添加到主菜单
        menu.insertItem(item, at: 2)
        
        syncMenuItem.state = sync
        hideMenuItem.state = hide
        if sync == .on || hide == .on {
            menuBarSlider.isEnabled = false
        }
        if hide == .on {
            syncMenuItem.isEnabled = false
        }
        autoAppearanceMenuItem.state = auto
        startMenuItem.state = NSControl.StateValue(defaults.integer(forKey: "StartAtLogin"))
        
    }
    
    //更新Slider控件
    func updateSlider() {
        if sync == .off  && hide == .off{
            self.menuBarSlider.doubleValue = menuBrightness
        }
        self.desktopSlider.doubleValue = deskBrightness
    }
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        
        if initData() == false {
            applicationWillTerminate(aNotification)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        initMenu(appMenu)
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        saveData()
        
        restoreDefaultWallpaper()
        
        clearAllWallpaperFile()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}

//获取保存的数据和工作路径
func initData() -> Bool {
    guard let workDir = getWorkingDirectory() else
    {
        os_log("获取工作路径失败", type: .error)
        return false
    }
    workingDir = workDir
    
    menuBrightness = defaults.double(forKey: "MenuBarBrightness")
    deskBrightness = defaults.double(forKey: "DesktopBrightness")
    menuLightBright = defaults.double(forKey: "MenuBarLightBrightness")
    menuDarkBright = defaults.double(forKey: "MenuBarDarkBrightness")
    deskLightBright = defaults.double(forKey: "DesktopLightBrightness")
    deskDarkBright = defaults.double(forKey: "DesktopDarkBrightness")
    sync = NSControl.StateValue(defaults.integer(forKey: "DesktopMenuBarSync"))
    hide = NSControl.StateValue(defaults.integer(forKey: "HideNotch"))
    auto = NSControl.StateValue(defaults.integer(forKey: "AutoSetAppearance"))
    
    guard let sourceURL = defaults.url(forKey: "SourceWallpaperPath") else {
        os_log("数据读取失败", type: .debug)
        return true
    }
    sourceWallpaperPath = sourceURL
    
    return true
}

//保存数据
func saveData() {
    defaults.setValue(sourceWallpaperPath.path, forKey: "SourceWallpaperPath")
    defaults.setValue(menuBrightness, forKey: "MenuBarBrightness")
    defaults.setValue(deskBrightness, forKey: "DesktopBrightness")
    defaults.setValue(menuLightBright, forKey: "MenuBarLightBrightness")
    defaults.setValue(menuDarkBright, forKey: "MenuBarDarkBrightness")
    defaults.setValue(deskLightBright, forKey: "DesktopLightBrightness")
    defaults.setValue(deskDarkBright, forKey: "DesktopDarkBrightness")
}

//更新壁纸
func updateWallpaperTasks() {
    //获取屏幕属性
    let screens: [NSScreen] = allDisplays ? NSScreen.screens : [NSScreen.main].compactMap({ $0 })
    guard !screens.isEmpty else {
        os_log("Could not detect any screens", type: .error)
        return
    }
    
    //遍历
    for (index, screen) in screens.enumerated() {
        guard let wallpaper = createWallpaper(screen: screen) else {
            os_log("Could not generate new wallpaper screen", type: .error)
                continue
            }
        setWallpaper(screen: screen, wallpaperCGImage: wallpaper)
        print("screen: \(index)")
    }
}

func updateWallpaper() {
    if isFinish == false {
        return
    }
    
    //多线程
    let group = DispatchGroup()
    let queue = DispatchQueue.global()
    
    //更新壁纸
    group.enter()
    queue.async {
        isFinish = false
        updateWallpaperTasks()
        group.leave()
    }
    
    //壁纸设置完成
    group.notify(queue: queue) {
        isFinish = true
        updateSlider()
    }
}

//更新Slider控件
func updateSlider() {
    //主线程
    let queue = DispatchQueue.main
    queue.async {
        let appdelegate = NSApplication.shared.delegate as! AppDelegate
        appdelegate.updateSlider()
    }
}
