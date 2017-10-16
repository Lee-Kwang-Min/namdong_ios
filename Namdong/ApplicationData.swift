//
//  ApplicationData.swift
//  Namdong
//
//  Created by Chris Song on 2017. 8. 30..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit

enum ContentMode {
    case nscs, nsop, dycs, dyop
}

class ApplicationData: NSObject {

    static let shared = ApplicationData()
    
    let kServerUrl  = "http://210.113.16.214/"
    var contentType = ContentMode.nscs  // defaultValue
    var cookieData  = Dictionary<String, String>()
    var fcmToken    = ""
    var reservedUrl: String? = nil
    var menuid: String? = nil
    var paramdata: String? = nil
    var isFirstInit   = false
    
    
    override init() {
        
    }
    
    func getIntroImage() -> UIImage {
        var image = #imageLiteral(resourceName: "NS_Intro")
        
        let bundleID = Bundle.main.bundleIdentifier!
        switch bundleID {
        case "kr.co.namsung.cs", "kr.co.namsung.op":
            image = #imageLiteral(resourceName: "NS_Intro")
            
        case "kr.co.pcsline.cs", "kr.co.pcsline.op":
            image = #imageLiteral(resourceName: "DY_Intro")
        default:
            break
        }
        
        return image
    }
    
    func getLogoWithTitle() -> (UIImage, String) {
        var image = #imageLiteral(resourceName: "NS_LOGO_CS")
        var title = "The Best Logistics Value Creator"
        
        let bundleID = Bundle.main.bundleIdentifier!
        switch bundleID {
        case "kr.co.namsung.cs":
            image = #imageLiteral(resourceName: "NS_LOGO_CS")
            title = "The Best Logistics Value Creator";
            
        case "kr.co.namsung.op":
            image = #imageLiteral(resourceName: "NS_LOGO_OP")
            title = "The Best Logistics Value Creator";
            
        case "kr.co.pcsline.cs":
            image = #imageLiteral(resourceName: "DY_LOGO_CS")
            title = "Your Successful Business partner";
            
        case "kr.co.pcsline.op":
            image = #imageLiteral(resourceName: "DY_LOGO_OP")
            title = "Your Successful Business partner";
            
        default:
            break
        }
        
        return (image, title)
    }
    
    /// 서버 주소를 가져옴.
    ///
    /// - Returns: 서버 Url
    func getServerUrl() -> String {
//        http://msp.namsung.co.kr/
//        https://sslm.namsung.co.kr/
//        http://msp.pcsline.co.kr/
//        https://sslm.pcsline.co.kr/

        var url = kServerUrl   
        let bundleID = Bundle.main.bundleIdentifier!
        switch bundleID {
        case "kr.co.namsung.cs":
            url = "http://msp.namsung.co.kr/"
            self.contentType = .nscs
        case "kr.co.namsung.op":
            url = "https://sslm.namsung.co.kr/"
            self.contentType = .nsop
        case "kr.co.pcsline.cs":
            url = "http://msp.pcsline.co.kr/"
            self.contentType = .dycs
        case "kr.co.pcsline.op":
            url = "https://sslm.pcsline.co.kr/"
            self.contentType = .dyop
        default:
            break
        }
        
        return url
    }
    
    func getSecureServerUrl() -> String {
        
        var url = kServerUrl
        let bundleID = Bundle.main.bundleIdentifier!
        switch bundleID {
        case "kr.co.namsung.cs", "kr.co.namsung.op":
            url = "https://sslm.namsung.co.kr/"
        
        case "kr.co.pcsline.cs", "kr.co.pcsline.op":
            url = "https://sslm.pcsline.co.kr/"
        default:
            break
        }
        
        return url
    }
    
    /// 자동로그인 판단
    ///
    /// - Returns: 자동로그인 사용 여부를 반환
    func isUseAutoLogin() -> Bool {
        if cookieData.count == 0 {
            self.loadCookieData()
        }
        
        let key = self.getAutoLoginKey()
        
        let autoLogin = cookieData[key]
        guard autoLogin != nil else {
            return false
        }
        
        return autoLogin == "Y"
    }
    
    func loadCookieData(){
        for cookie in HTTPCookieStorage.shared.cookies! {
            let isDomainMatched = self.getSecureServerUrl().contains(cookie.domain)
            let isPathMatched   = cookie.path == "/" + self.getCookieUrl(type: ApplicationData.shared.contentType)
            if isDomainMatched && isPathMatched {
                cookieData.updateValue(cookie.value, forKey: cookie.name)
            }
        }
    }
    
    func saveCookieData(){
        let cookies = HTTPCookieStorage.shared.cookies
        if let cookieCount = cookies?.count, cookieCount > 0 {
            let cookieData = NSKeyedArchiver.archivedData(withRootObject: cookies as Any)
            
            // 키값을 별도로 추려서 저장함.
            for cookie in HTTPCookieStorage.shared.cookies! {
                let isDomainMatched = self.getSecureServerUrl().contains(cookie.domain)
                let isPathMatched   = cookie.path == "/" + self.getCookieUrl(type: ApplicationData.shared.contentType)
                if isDomainMatched && isPathMatched {
                    UserDefaults.standard.setValue(cookie.value, forKey: cookie.name)
                    
                    ApplicationData.shared.txtLog(string: "페이지 로드 후 저장한 값: -" + cookie.name + ": " + cookie.value)
                }
            }
            let stampString = String(arc4random()%100)
            UserDefaults.standard.setValue(stampString, forKey: "stamp")
            ApplicationData.shared.txtLog(string: "페이지 로드 후 스탬프: -" + stampString)
            
            
            UserDefaults.standard.set(cookieData, forKey: keyCookie)
            let result = UserDefaults.standard.synchronize()
            if result == false {
                ApplicationData.shared.txtLog(string: "저장 실패!!!!!!")
            }else{
                ApplicationData.shared.txtLog(string: "저장 완료")
            }
        }
    }
    
    func getCookieUrl(type: ContentMode) -> String{
        var result = ""
        
        switch type {
        case .nscs:
            result = "NS_MOBILE_CS/login"
            
        case .nsop:
            result = "NS_MOBILE_OP/login"
            
        case .dycs:
            result = "DY_MOBILE_CS/login"
            
        case .dyop:
            result = "DY_MOBILE_OP/login"
        }
        return result
    }
    
    func getUserLoginID() -> String{
        if cookieData.count == 0 {
            self.loadCookieData()
        }
        
        let key = self.getUserLoginIDKey()
        
        let userId = cookieData[key]
        guard userId != nil else {
            return ""
        }
        
        return userId!
    }
    
    func getAutoLoginKey() -> String{
        var result = ""
        
        switch self.contentType {
        case .nscs:
            result = "eMobile_nscseMobile_auto"
            
        case .nsop:
            result = "eMobile_nsopeMobile_auto"
            
        case .dycs:
            result = "eMobile_dycseMobile_auto"
            
        case .dyop:
            result = "eMobile_dyopeMobile_auto"
        }
        return result
    }
    
    func getUserLoginIDKey() -> String{
        var result = ""
        
        switch self.contentType {
        case .nscs:
            result = "eMobile_nscseMobile_usrlogin"
            
        case .nsop:
            result = "eMobile_nsopeMobile_usrlogin"
            
        case .dycs:
            result = "eMobile_dycseMobile_usrlogin"
            
        case .dyop:
            result = "eMobile_dyopeMobile_usrlogin"
        }
        return result
    }
    
    func getNormalLoginUrl() -> String{
        var subUrl = ""
        var fileName = ""
        
        switch self.contentType {
        case .nscs:
            subUrl = "NS_MOBILE_CS/"
            fileName = "viewMain.do"
            
        case .nsop:
            subUrl = "NS_MOBILE_OP/"
            fileName = "loginOP.do"
            
        case .dycs:
            subUrl = "DY_MOBILE_CS/"
            fileName = "viewMain.do"
            break;
            
        case .dyop:
            subUrl = "DY_MOBILE_OP/"
            fileName = "loginOP.do"
        }
        
        return self.getServerUrl() + subUrl + "login/" + fileName
    }
    
    func getAutoLoginUrl() -> String{
        var subUrl = ""
        var fileName = ""
        
        switch self.contentType {
        case .nscs:
            subUrl = "NS_MOBILE_CS/"
            fileName = "actionAutoLoginCS.do"
            
        case .nsop:
            subUrl = "NS_MOBILE_OP/"
            fileName = "actionAutoLoginOP.do"
            
        case .dycs:
            subUrl = "DY_MOBILE_CS/"
            fileName = "actionAutoLoginCS.do"
            break;
            
        case .dyop:
            subUrl = "DY_MOBILE_OP/"
            fileName = "actionAutoLoginOP.do"
        }
        
        return self.getSecureServerUrl() + subUrl + "login/" + fileName
    }
    
    func getChangedUrlForAutoLogin(currentUrl: String) -> String{
        var fileName = "";
        var originFileName = "";
        switch (self.contentType){
        case .nscs, .dycs:
            fileName = "actionAutoLoginCS.do"
            originFileName = "loginCS.do"
            break;
            
        case .nsop, .dyop:
            fileName = "actionAutoLoginOP.do"
            originFileName = "loginOP.do"
            break;
        }
        
        return currentUrl.replacingOccurrences(of: originFileName, with: fileName)
    }
    
    func clearPushData() {
        reservedUrl = nil
        menuid = nil
        paramdata = nil
    }
    
    func txtLog(string: String) {
        let file = "log.txt"
        print(string)
        
        let text = string + "\n";
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            
            let data = text.data(using: .utf8)
            
            // check exist
            if FileManager.default.fileExists(atPath: fileURL.path) == false {
                // create new
                FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: [:])
            }
            
            do {
                let fileHandle = try FileHandle.init(forWritingTo: fileURL)
                
                fileHandle.seekToEndOfFile()
                fileHandle.write(data!)
                fileHandle.closeFile()
            }catch {
                
            }
        }
    }
}
