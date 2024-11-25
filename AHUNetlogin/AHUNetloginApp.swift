//
//  AHUNetloginApp.swift
//  AHUNetlogin
//
//  Created by Tiancheng Yao on 2024/11/24.
//

import SwiftUI

@main
struct AHUNetloginApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            .onAppear {
                #if os(macOS)
                if let window = NSApplication.shared.windows.first {
                    window.styleMask.remove(.resizable) // 禁用窗口大小调整
                    window.setContentSize(NSSize(width: 430, height: 650)) // 设置窗口默认大小

                }
                #endif
            }
        }
    }
}

