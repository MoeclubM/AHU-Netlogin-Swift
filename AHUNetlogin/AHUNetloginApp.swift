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
                #if os(macOS)
                .frame(minWidth: 450, maxWidth: 500, minHeight: 450, maxHeight: 480) // 限制窗口的大小范围
                #endif
        }
    }
}

