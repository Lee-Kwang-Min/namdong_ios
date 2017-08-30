//
//  ViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 7. 31..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit

public typealias CompletionHandler = (_ isOpenable: Bool) -> Void

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! MainViewController
        if sender != nil {
            let array = sender as! Array<String>
            viewController.title = array[0]
            viewController.targetUrl = array[1]
        }
    }
    @IBAction func openOtherApp(_ sender: Any) {
        let button = sender as! UIButton
        var urlString = ""
        var platformName = ""
        var installUrlString = ""
        switch button.tag {
        case 1:
            platformName = NSLocalizedString("KakaoTalk", comment: "App name KakaoTalk")
            urlString = "kakaolink://"
            installUrlString = "https://itunes.apple.com/kr/app/%EC%B9%B4%EC%B9%B4%EC%98%A4%ED%86%A1-kakaotalk/id362057947?mt=8"
        case 2:
            platformName = NSLocalizedString("Facebook", comment: "App name Facebook")
            urlString = "fb://"
            installUrlString = "https://itunes.apple.com/kr/app/facebook/id284882215?mt=8"
        case 3:
            platformName = NSLocalizedString("WeChat", comment: "App name WeChat")
            urlString = "weixin://"
            installUrlString = "https://itunes.apple.com/kr/app/wechat/id414478124?mt=8"
        default:
            return
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

    @IBAction func moveManageNamsung(_ sender: Any) {
        performSegue(withIdentifier: "showWeb", sender: ["남성 관리자", ApplicationData.shared.kServerUrl + "/NS_MOBILE_OP/login/loginOP.do"])
        ApplicationData.shared.contentType = .nsop
        
    }
    
    @IBAction func moveManagerDongyoung(_ sender: Any) {
        performSegue(withIdentifier: "showWeb", sender: ["동영 관리자", ApplicationData.shared.kServerUrl + "DY_MOBILE_OP/login/loginOP.do"])
        ApplicationData.shared.contentType = .dyop
    }
    
    @IBAction func moveUserNamsung(_ sender: Any) {
        performSegue(withIdentifier: "showWeb", sender: ["남성 사용자", ApplicationData.shared.kServerUrl + "/NS_MOBILE_CS/login/viewMain.do"])
        ApplicationData.shared.contentType = .nscs
    }
    
    @IBAction func moveUserDongyoung(_ sender: Any) {
        performSegue(withIdentifier: "showWeb", sender: ["동영 사용자", ApplicationData.shared.kServerUrl + "/DY_MOBILE_CS/login/viewMain.do"])
        ApplicationData.shared.contentType = .dycs
    }

}

