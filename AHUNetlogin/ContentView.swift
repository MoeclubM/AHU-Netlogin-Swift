import SwiftUI

struct ContentView: View {
    @State private var account: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = true
    @State private var isLoggedIn: Bool = false
    @State private var ipAddress: String = ""
    @State private var macAddress: String = ""
    @State private var acName: String = ""
    @State private var acIp: String = ""

    // 登录 URL 模板
    let loginUrlTemplate = "http://172.16.253.3:801/eportal/?c=Portal&a=login&callback=dr1003&login_method=1&user_account=%@&user_password=%@&wlan_user_ip=%@&wlan_user_ipv6=&wlan_user_mac=%@&wlan_ac_ip=%@&wlan_ac_name=%@&jsVersion=3.3.2&v=4946"
    let logoutUrlTemplate = "http://172.16.253.3:801/eportal/?c=Portal&a=logout&callback=dr1004&login_method=1&user_account=drcom&user_password=123&ac_logout=0&register_mode=1&wlan_user_ip=%@&wlan_user_ipv6=&wlan_vlan_id=0&wlan_user_mac=000000000000&wlan_ac_ip=%@&wlan_ac_name=%@&jsVersion=3.3.2&v=3484"
    
    var body: some View {
        VStack {
            // 账号输入框
            Text("账号：")
                .font(.headline)
                .foregroundColor(.blue)
            TextField("请输入账号", text: $account)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 密码输入框
            Text("密码：")
                .font(.headline)
                .foregroundColor(.blue)
            SecureField("请输入密码", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 记住信息勾选框
            Toggle("记住信息(此后自动登录)", isOn: $rememberMe)
                .padding()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            // 显示 IP 地址、MAC 地址、AC IP 和 AC 名称
            VStack(alignment: .leading) {
                Text("IP 地址：\(ipAddress)")
                Text("MAC 地址：\(macAddress)")
                Text("AC IP：\(acIp)")
                Text("AC 名称：\(acName)")
            }
            .padding()
            
            // 登录登出按钮
            HStack(spacing: 20) {
                Button("登录") {
                    login()
                }
                .padding()
                
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity)  // 使按钮填充宽度
                
                Button("登出") {
                    logout()
                }
                .padding()
                
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity)  // 使按钮填充宽度
            }
            
            // 登录状态提示
            if isLoggedIn {
                Text("已登录")
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            } else {
                Text("未登录")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .onAppear {
            // 获取网络信息并自动登录
            fetchLoginDetails()
        }
        .background(Color.white)  // 背景颜色设为白色
        .cornerRadius(15)  // 设置边角圆润
        .shadow(radius: 10)  // 添加阴影效果
    }

    func fetchLoginDetails() {
        let url = URL(string: "http://192.168.9.9/")!
        
        // 创建一个工作项来处理超时
        let timeoutWorkItem = DispatchWorkItem {
            showAlert(title: "网络连接超时", message: "请求超过 3 秒未响应，可能未连接校园网或已登录")
        }
        
        // 设置超时为 3 秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutWorkItem)

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                // 超时后如果请求返回，取消超时提示
                timeoutWorkItem.cancel()
                
                if let error = error {
                    showAlert(title: "获取数据失败", message: "请求失败: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    showAlert(title: "获取数据失败", message: "数据为空！")
                    return
                }
                
                let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .windowsCP1252]
                var htmlContent: String?
                for encoding in encodings {
                    if let decodedContent = String(data: data, encoding: encoding) {
                        htmlContent = decodedContent
                        break
                    }
                }
                
                guard let htmlContent = htmlContent else {
                    let rawDataString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
                    showAlert(title: "解码失败", message: "原始数据：\n\(rawDataString)")
                    print("原始数据：\(rawDataString)")
                    return
                }
                
                // 提取重定向 URL
                if let redirectUrl = extractRedirectUrl(from: htmlContent) {
                    print("Redirect URL: \(redirectUrl)")
                    ipAddress = extractParameter(from: redirectUrl, paramName: "wlanuserip") ?? ""
                    macAddress = extractParameter(from: redirectUrl, paramName: "wlanusermac") ?? ""
                    acName = extractParameter(from: redirectUrl, paramName: "wlanacname") ?? ""
                    acIp = extractParameter(from: redirectUrl, paramName: "wlanacip") ?? ""
                } else {
                    showAlert(title: "HTML 提取失败", message: "网页内容：\n\(htmlContent)")
                }
            }
        }.resume()
    }

    func login() {
        guard !account.isEmpty, !password.isEmpty else {
            showAlert(title: "登录失败", message: "请输入账号和密码！")
            return
        }
        
        let urlString = String(format: loginUrlTemplate, account, password, ipAddress, macAddress, acIp, acName)
        
        guard let url = URL(string: urlString) else {
            showAlert(title: "登录失败", message: "请求 URL 无效！")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    showAlert(title: "登录失败", message: "请求失败: \(error.localizedDescription)")
                } else if let data = data, let responseString = String(data: data, encoding: .utf8), responseString.contains("\"result\":\"1\"") {
                    isLoggedIn = true
                    showAlert(title: "登录成功", message: "您已成功登录！")
                    if rememberMe {
                        saveCredentials()
                    }
                } else {
                    showAlert(title: "登录失败", message: "未知错误！")
                }
            }
        }.resume()
    }

    func logout() {
        let urlString = String(format: logoutUrlTemplate, ipAddress, acIp, acName)
        guard let url = URL(string: urlString) else {
            showAlert(title: "登出失败", message: "请求 URL 无效！")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    showAlert(title: "登出失败", message: "请求失败: \(error.localizedDescription)")
                } else {
                    isLoggedIn = false
                    showAlert(title: "成功", message: "登出成功！")
                }
            }
        }.resume()
    }
    // 提取重定向 URL
    func extractRedirectUrl(from html: String) -> String? {
        let pattern = #"location\.href\s*=\s*"(.*?)""#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)) {
            if let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        return nil
    }

    // 提取指定参数的值
    func extractParameter(from url: String, paramName: String) -> String? {
        let pattern = "\(paramName)=([^&]*)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.utf16.count)) {
            if let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        return nil
    }
    
    // 显示消息提示框
    private func showAlert(title: String, message: String) {
#if os(iOS)
        // 在 iOS 中使用 UIAlertController
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
#elseif os(macOS)
        // 在 macOS 中使用 NSAlert
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "确定")
        alert.runModal()
#endif
    }
    
    // 保存账号密码
    func saveCredentials() {
        UserDefaults.standard.set(account, forKey: "Account")
        UserDefaults.standard.set(password, forKey: "Password")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

