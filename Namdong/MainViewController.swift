//
//  MainViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 8. 1..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit
//import KRProgressHUD

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
        
        return true;
    }
    
    func showToast(message: String){
        print("toast message", message)
    }
    
    func showDialog(title: String, message: String){
        print("showAlertDialog", title, message);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UIWebView Delegate
    func webViewDidFinishLoad(_ webView: UIWebView) {
//        KRProgressHUD.dismiss()
    }
        let result = callFunc(request.url?.absoluteString)

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
