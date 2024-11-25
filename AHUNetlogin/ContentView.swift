import SwiftUI

struct ContentView: View {
    @State private var account: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = true
    @State private var ipAddress: String = ""
    @State private var macAddress: String = ""
    @State private var acName: String = ""
    @State private var acIp: String = ""
    
    // 登录 URL 模板
    let loginUrlTemplate = "http://172.16.253.3:801/eportal/?c=Portal&a=login&callback=dr1003&login_method=1&user_account=%@&user_password=%@&wlan_user_ip=%@&wlan_user_ipv6=&wlan_user_mac=%@&wlan_ac_ip=%@&wlan_ac_name=%@&jsVersion=3.3.2&v=4946"
    let logoutUrlTemplate = "http://172.16.253.3:801/eportal/?c=Portal&a=logout&callback=dr1004&login_method=1&user_account=drcom&user_password=123&ac_logout=0&register_mode=1&wlan_user_ip=%@&wlan_user_ipv6=&wlan_vlan_id=0&wlan_user_mac=000000000000&wlan_ac_ip=%@&wlan_ac_name=%@&jsVersion=3.3.2&v=3484"
    
    var body: some View {
        ZStack {
            // 背景图片
            Image("backgroundImage") // 确保图片已添加到项目的 Assets.xcassets 中
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all) // 背景填充整个屏幕

            VStack {
                // 添加 Logo
                Image("Logo") // 确保图片已添加到 Assets.xcassets 中
                    .resizable()
                    .scaledToFit() // 保持图片比例
                    .frame(width: 100, height: 100) // 设置图片大小
                    .padding(.bottom, 20) // 添加与下方内容的间距

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
                VStack(alignment: .leading, spacing: 10) { // 添加适当的行间距
                    HStack {
                        Text("IP 地址：")
                        Text(ipAddress.isEmpty ? "未获取到数据" : ipAddress) // 如果 ipAddress 为空则显示占位文字
                            .foregroundColor(ipAddress.isEmpty ? .gray : .primary) // 占位文字显示为灰色
                    }
                    
                    HStack {
                        Text("MAC 地址：")
                        Text(macAddress.isEmpty ? "未获取到数据" : macAddress)
                            .foregroundColor(macAddress.isEmpty ? .gray : .primary)
                    }
                    
                    HStack {
                        Text("AC IP：")
                        Text(acIp.isEmpty ? "未获取到数据" : acIp)
                            .foregroundColor(acIp.isEmpty ? .gray : .primary)
                    }
                    
                    HStack {
                        Text("AC 名称：")
                        Text(acName.isEmpty ? "未获取到数据" : acName)
                            .foregroundColor(acName.isEmpty ? .gray : .primary)
                    }
                }
                .padding()

                // 登录登出按钮
                HStack(spacing: 20) {
                    Button(action: {
                        login()
                    }) {
                        Text("登录")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        logout()
                    }) {
                        Text("登出")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

            }
            .padding()
            .background(
                Color.white.opacity(0.8) // 半透明背景
            )
            .cornerRadius(15) // 边角圆润
            .shadow(radius: 10) // 添加阴影效果
            .frame(minWidth: 350, maxWidth: 350, minHeight: 450, maxHeight: 450)
        }
        .onAppear {
            // 获取网络信息并自动登录
            fetchLoginDetails()
            loadCredentials()
            
        }
    }
    
    
    func loadCredentials() {
        if let savedAccount = UserDefaults.standard.string(forKey: "Account"),
           let savedPassword = UserDefaults.standard.string(forKey: "Password") {
            account = savedAccount
            password = savedPassword
        }
    }
    
    func saveCredentials() {
        UserDefaults.standard.set(account, forKey: "Account")
        UserDefaults.standard.set(password, forKey: "Password")
    }
    class RedirectHandler: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        // 禁用自动重定向
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            print("拦截到跳转:")
            print("状态码: \(response.statusCode)")
            if let location = response.value(forHTTPHeaderField: "Location") {
                print("跳转地址: \(location)")
            }
            // 不跟随跳转，返回 nil
            completionHandler(nil)
        }
    }
    
    func fetchLoginDetails() {
        let url = URL(string: "http://192.168.111.111/")!
        
        // 创建一个工作项来处理超时
        let timeoutWorkItem = DispatchWorkItem {
            showAlert(title: "网络连接超时", message: "请求超过 3 秒未响应，可能未连接校园网或已登录")
            return
        }
        
        // 设置超时为 3 秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutWorkItem)
        
        // 使用自定义会话配置
        let redirectHandler = RedirectHandler()
        let session = URLSession(configuration: .default, delegate: redirectHandler, delegateQueue: nil)
        
        session.dataTask(with: url) { data, response, error in
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
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        // 处理200 OK响应
                        ipAddress = extractParameter(from: htmlContent, paramName: "wlanuserip") ?? ""
                        macAddress = extractParameter(from: htmlContent, paramName: "wlanusermac")?.replacingOccurrences(of: "-", with: "") ?? "000000000000"
                        acName = extractParameter(from: htmlContent, paramName: "wlanacname")?
                            .trimmingCharacters(in: CharacterSet(charactersIn: "\"</>").union(.whitespacesAndNewlines)) ?? "" // 清理特殊字符
                        acIp = extractParameter(from: htmlContent, paramName: "wlanacip") ?? ""
                        
                        print("200 OK - 数据已提取：\(ipAddress), \(macAddress), \(acName), \(acIp)")
                        
                    case 302:
                        if let location = httpResponse.value(forHTTPHeaderField: "Location") {
                            print("Redirect Location: \(location)")
                            ipAddress = extractParameter(from: location, paramName: "wlanuserip") ?? ""
                            macAddress = "000000000000" // 默认值全0
                            acName = extractParameter(from: location, paramName: "wlanacname") ?? ""
                            acIp = extractParameter(from: location, paramName: "wlanacip") ?? ""
                            print("302 Redirect - 数据已提取：\(ipAddress), \(macAddress), \(acName), \(acIp)")
                        } else {
                            showAlert(title: "HTML 提取失败", message: "没有找到重定向URL！")
                        }
                        
                    default:
                        showAlert(title: "获取失败", message: "返回了状态码：\(httpResponse.statusCode)")
                    }
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
                    return
                } else if let data = data, let responseString = String(data: data, encoding: .utf8), responseString.contains("\"result\":\"1\"") {
                    showAlert(title: "登录成功", message: "您已成功登录！")
                    if rememberMe {
                        saveCredentials()
                    }
                } else {
                    showAlert(title: "登录失败", message: "未知错误！")
                    return
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
    func extractParameter(from html: String, paramName: String) -> String? {
        let pattern = "\(paramName)=([^&\"]+)" // 匹配参数名=值
        if let range = html.range(of: pattern, options: .regularExpression) {
            let match = String(html[range])
            return match.components(separatedBy: "=").last
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
    
    
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    
}
