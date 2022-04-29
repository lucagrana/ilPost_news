//
//  WebView.swift
//  Il Post News
//
//  Created by Luca Grana on 25/04/22.
//

import UIKit
import WebKit

class WebView: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    
    var webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
    var strinUrl: String = "Anonymous"
    
    let jsCode = "var divsToHide = document.getElementsByClassName('insideHeader'); for(var i = 0; i < divsToHide.length; i++){divsToHide[i].style.display = 'none';}" +
    "divsToHide2 = document.getElementsByClassName('userBar'); for(var i = 0; i < divsToHide2.length; i++){divsToHide2[i].style.display = 'none';}"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string:strinUrl)
        let myRequest = URLRequest(url: myURL!)
        webView.navigationDelegate = self
        webView.load(myRequest)
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.webView.evaluateJavaScript(self.jsCode)
        }
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    
    
    
    
}
