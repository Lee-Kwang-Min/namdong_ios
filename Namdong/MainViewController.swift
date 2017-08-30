//
//  MainViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 8. 1..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit
import Toaster

class MainViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var targetUrl = "http://www.naver.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let request = URLRequest.init(url: URL(string: targetUrl)!)
        webView.loadRequest(request)
//        KRProgressHUD.show()
    }
    
    func callFunc(_ url: String?) -> Bool{
        let funcPrefix = "jscall://"
        let intentPrefix = "intent://"
        if let urlString = url, urlString.hasPrefix(funcPrefix) {
            let subString = urlString.substring(from: funcPrefix.endIndex)
            let funcArray = subString.components(separatedBy: "?")
            let funcName = funcArray[0]
            let bodies = funcArray[1].components(separatedBy: "&")
            var funcBody = Dictionary<String, String>()
            
            for row in bodies {
                let result  = row.components(separatedBy: "=")
                let key     = result[0].trimmingCharacters(in: NSCharacterSet.whitespaces)
                let value   = result[1].trimmingCharacters(in: NSCharacterSet.whitespaces)
                funcBody.updateValue(value, forKey: key)
            }
            
            switch funcName {
            case "showToast":
                showToast(message: funcBody["message"]!)
                
            case "showAlertDialog":
                showDialog(title: funcBody["title"]!, message: funcBody["message"]!)
                
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
    
    func showToast(message: String){
        let toast = Toast(text: message)
        toast.show()
    }
    
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
    
    // MARK: - UIWebView Delegate
    func webViewDidFinishLoad(_ webView: UIWebView) {
//        KRProgressHUD.dismiss()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let result = callFunc(request.url?.absoluteString)
        return result
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
