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
    
    
    override init() {
        
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
            if cookie.path == "/" + self.getCookieUrl(type: ApplicationData.shared.contentType) {
                print("\(cookie.name) \n\n \(cookie.value) \n\n \(cookie.version) \n\n \(cookie)")
                cookieData.updateValue(cookie.value, forKey: cookie.name)
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
            result = "eMobile_dycueMobile_auto"
            
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
            result = "eMobile_dycueMobile_usrlogin"
            
        case .dyop:
            result = "eMobile_dyopeMobile_usrlogin"
        }
        return result
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
            fileName = "actionAutoLoginCS.do "
            break;
            
        case .dyop:
            subUrl = "DY_MOBILE_OP/"
            fileName = "actionAutoLoginOP.do"
        }
        
        return kServerUrl + subUrl + "login/" + fileName
    }
    
    func getChangedUrlForAutoLogin(currentUrl: String) -> String{
        var fileName = "";
        var originFileName = "";
        switch (self.contentType){
        case .nscs, .dycs:
            fileName = "actionAutoLoginCS.do "
            originFileName = "loginCS.do"
            break;
            
        case .nsop, .dyop:
            fileName = "actionAutoLoginOP.do"
            originFileName = "loginOP.do"
            break;
            
        default:
            break;
        }
        
        return currentUrl.replacingOccurrences(of: originFileName, with: fileName)
    }
}
