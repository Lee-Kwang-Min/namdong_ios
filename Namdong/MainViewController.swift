//
//  MainViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 8. 1..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit
import Toaster
import Firebase
import WebKit

class MainViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    var webView: WKWebView? = nil
    var targetUrl = "http://google.com"
    var introViewController: UIViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set WKWebView
        webView = WKWebView.init(frame: self.view.frame)
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
        webView?.scrollView.bounces = false
        webView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView!);

        // Add Constraint
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|", options: [], metrics: nil, views: ["webView":webView!]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[top][webView][bottom]", options: [], metrics: nil, views: ["webView":webView!, "top":self.topLayoutGuide, "bottom":self.bottomLayoutGuide]))
        self.view.layoutIfNeeded()
        
        _ = ApplicationData.shared.getServerUrl()   // 등록용
        // Do any additional setup after loading the view.
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        introViewController = storyboard.instantiateViewController(withIdentifier: "introView")
        self.view.addSubview((introViewController?.view)!)
        
        self.loadWebViewMain()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadNotiUrl), name: NSNotification.Name(rawValue: "UrlNoti"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadNotiUrl), name: NSNotification.Name(rawValue: "TokenChanged"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let url = ApplicationData.shared.reservedUrl {
            let encodedString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let request = URLRequest.init(url: URL(string: encodedString)!)
            webView?.load(request)
            ApplicationData.shared.reservedUrl = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ModalFileViewer" {
            let navi = segue.destination
            let fileView = navi.childViewControllers.last as? FileViewController
            if sender is URLRequest {
                fileView?.request = sender as? URLRequest
            }else if sender is URL {
                fileView?.localPath = sender as? URL
            }
        }
    }
    
    /// Load webview main page
    func loadWebViewMain() {
        let fcmToken = Messaging.messaging().fcmToken
        if fcmToken != nil {
            UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
            UserDefaults.standard.synchronize()
        }
        let userId = ApplicationData.shared.getUserLoginID()
        if ApplicationData.shared.isUseAutoLogin() && userId.characters.count > 0 {
            // 자동 로그인
            let requestUrl = ApplicationData.shared.getAutoLoginUrl()
            var request = URLRequest.init(url: URL(string: requestUrl)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = ("eTokenId=" + fcmToken! + "&eDevice=I&inpusr=" + userId).data(using: .utf8)
            
            webView?.load(request)
        }else{
            // 일반 로그인
            targetUrl = ApplicationData.shared.getNormalLoginUrl()
            var request = URLRequest.init(url: URL(string: targetUrl)!)
            if fcmToken != nil {
                let body = ("eTokenId=" + fcmToken! + "&eDevice=I")
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = body.data(using: .utf8)
            }
            webView?.load(request)
        }
    }
    
    func loadNotiUrl(_ noti: Notification){
        if let url = noti.object as? String {
            let encodedString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let request = URLRequest.init(url: URL(string: encodedString)!)
            webView?.load(request)
            ApplicationData.shared.reservedUrl = nil
        }
    }
    
    /// Function caller
    ///
    /// - Parameter url: Scheme url
    /// - Returns: Result of processing.
    func callFunc(_ url: String?) -> Bool{
        let funcPrefix = "jscall://"
        let intentPrefix = "intent://"
        if let urlString = url, urlString.hasPrefix(funcPrefix) {
            let subString = urlString.substring(from: funcPrefix.endIndex)
            var funcName = ""
            var funcBody = Dictionary<String, String>()
            if subString.contains("?") {
                let funcArray = subString.components(separatedBy: "?")
                funcName = funcArray[0]
                let bodies = funcArray[1].components(separatedBy: "&")
                
                for row in bodies {
                    let result  = row.components(separatedBy: "=")
                    let key     = result[0].trimmingCharacters(in: NSCharacterSet.whitespaces)
                    let value   = result[1].trimmingCharacters(in: NSCharacterSet.whitespaces)
                    funcBody.updateValue(value, forKey: key)
                }
            }else{
                funcName = subString;
            }
            
            switch funcName {
            case "showToast":
                showToast(message: funcBody["message"]!)
                
            case "showAlertDialog":
                showDialog(title: funcBody["title"]!, message: funcBody["message"]!)
                
            case "mainPageReload":
                self.loadWebViewMain()
                
            default:
                break
            }
            
            return false;
        }
        
        if let urlString = url, urlString.hasPrefix(intentPrefix) {
            let subString = urlString.substring(from: funcPrefix.endIndex)
            var urlString = ""
            var platformName = ""
            var installUrlString = ""
            switch subString {
            case "com.kakao.talk":
                platformName = NSLocalizedString("KakaoTalk", comment: "App name KakaoTalk")
                urlString = "kakaolink://"
                installUrlString = "https://itunes.apple.com/kr/app/%EC%B9%B4%EC%B9%B4%EC%98%A4%ED%86%A1-kakaotalk/id362057947?mt=8"
                break
            case "com.facebook.katana":
                platformName = NSLocalizedString("Facebook", comment: "App name Facebook")
                urlString = "fb://"
                installUrlString = "https://itunes.apple.com/kr/app/facebook/id284882215?mt=8"
                break
            case "com.tencent.mm":
                platformName = NSLocalizedString("WeChat", comment: "App name WeChat")
                urlString = "weixin://"
                installUrlString = "https://itunes.apple.com/kr/app/wechat/id414478124?mt=8"
                break
                
            default:
                break
            }
            
            self.openUrl(urlString) { (isOpenable) in
                if !isOpenable {
                    let alertController = UIAlertController.init(title: NSLocalizedString("Open failed", comment: ""), message: String.init(format: NSLocalizedString("Can't open %@. Install the app for use this function.", comment: ""), platformName), preferredStyle: .alert)
                    let actionCancel = UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil)
                    let actionInstall = UIAlertAction.init(title: NSLocalizedString("Appstore", comment: ""), style: .default, handler: { (aletAction) in
                        self.openUrl(installUrlString)
                    })
                    alertController.addAction(actionCancel)
                    alertController.addAction(actionInstall)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            
            return false;
        }
        
        
        return true;
    }
    
    /// Content Opener
    ///
    /// - Parameter request: webview url request
    /// - Returns: is content url
    func openUrlByFileViewer(request: URLRequest) -> Bool{
        let isGoogle = request.url?.absoluteString.contains("drive.google.com")
        let isBlCopy = request.url?.absoluteString.contains("prtCopyBl.do")
        let isBooked = request.url?.absoluteString.contains("prtBookingSheet.do")
        let isInvoic = request.url?.absoluteString.contains("prtInvoice.do")
        let isExFree = request.url?.absoluteString.contains("prtExFreetime.do")
        let isArrive = request.url?.absoluteString.contains("prtArrivalNotice.do")
        
        
        let result = (isGoogle == true || isBlCopy == true || isBooked == true || isInvoic == true || isExFree == true || isArrive == true)
        if result {
            // 새 창
            self.performSegue(withIdentifier: "ModalFileViewer", sender: request)
        }
        return !result
    }
    
    /// Content Downloader
    ///
    /// - Parameter request: webview url request
    /// - Returns: is download
    func downloadFrom(request: URLRequest) -> Bool{
        let result = request.url?.absoluteString.contains("downloadFile.json")
        if result! {
            let session = URLSession.shared
            Toast.init(text: "Downloading").show()
            let task = session.dataTask(with: request) {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    if (statusCode == 200){
                        let fileName = httpResponse.suggestedFilename
                        // get document path
                        do {
                            let fManager = FileManager.default
                            let docPath = try fManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                            let filePath = docPath.appendingPathComponent(fileName!)
                            if (fManager.fileExists(atPath: filePath.path)){
                                try fManager.removeItem(at: filePath)
                            }
                            try data?.write(to: filePath)
                            
                            // open
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "ModalFileViewer", sender: filePath)
                            }
                        }catch{
                            // file save error
                            Toast.init(text: "Unknown error occur. try again.").show()
                        }
                        
                        Toast.init(text: "Download complete").show()
                    }else{
                        Toast.init(text: "Unknown error occur. try again.").show()
                    }
                }
            }
            task.resume()
        }
        
        return !result!
    }
    
    /// Url Openner
    ///
    /// - Parameters:
    ///   - urlString: url string
    ///   - completion: call back closure
    func openUrl(_ urlString: String, _ completion: CompletionHandler? = nil){
        guard let url = URL(string: urlString) else {
            return
        }
        
        let openable = UIApplication.shared.canOpenURL(url)
        if openable {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: { (finished) in
                    
                })
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url)
            }
        }
        
        if (completion != nil) {
            completion!(openable)
        }
    }
    
    /// Show Toast
    ///
    /// - Parameter message: Message to be shown on toast
    func showToast(message: String){
        let toast = Toast(text: message)
        toast.show()
    }
    
    /// Show Dialog
    ///
    /// - Parameters:
    ///   - title: Title to be shown on alert box
    ///   - message: Message to be shown on alert box
    func showDialog(title: String, message: String){
        let controller = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK button"), style: .default, handler: nil);
        controller.addAction(actionOK)
        self.present(controller, animated: true, completion: nil);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - WKWebView UIDelegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as! String?
        let alertController = UIAlertController(title: appName, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as! String?
        let alertController = UIAlertController(title: appName, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as! String?
        let alertController = UIAlertController(title: appName, message: prompt, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - WKNavigation Delegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if (navigationAction.navigationType == .linkActivated){
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        if statusCode == 404 {
            // Handle 404 Error
            do{
                let htmlPath = Bundle.main.path(forResource: "notFound", ofType: "html");
                let htmlString = try String.init(contentsOfFile: htmlPath!, encoding: String.Encoding.utf8)
                
                webView.loadHTMLString(htmlString, baseURL: nil)
            }catch{
                NSLog("HTML File load error")
            }
            
            decisionHandler(.cancel)
            return
        }
        
        var result = callFunc(webView.url?.absoluteString)
        let request = URLRequest.init(url: webView.url!)
        if result == true{
            result = self.openUrlByFileViewer(request: request)
        }
        if result == true{
            result = self.downloadFrom(request: request)
        }
        
        var policy = WKNavigationResponsePolicy.allow
        if result == false {
            policy = .cancel
        }
        decisionHandler(policy)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if introViewController != nil {
            introViewController?.view.removeFromSuperview()
            introViewController = nil
        }
    }
    
    @available(iOS 9, *)
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // 중복적으로 리로드가 일어나지 않도록 처리 필요.
        webView.reload()
    }
    
}
