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
    
    var isHomeAfterLogin = false
    var isHomeAfterLogout = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let spinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
        let myURL = URL(string:strinUrl)
        let myRequest = URLRequest(url: myURL!)
        webView.allowsBackForwardNavigationGestures = true
        webView.load(myRequest)
//        view.addSubview(spinner)
//
//        spinner.startAnimating()
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.webView.evaluateJavaScript(self.jsCode)
        }
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let urlStr = navigationAction.request.url?.absoluteString{
            if urlStr == "https://www.ilpost.it/" && (isHomeAfterLogin || isHomeAfterLogout) {
                if isHomeAfterLogin {
                    isHomeAfterLogin = false
                } else {
                    isHomeAfterLogout = false
                }
                decisionHandler(.cancel)
                self.dismiss(animated: true)
                print(urlStr)
                return
            } else if urlStr == "https://www.ilpost.it/wp-login.php?redirect_to=https://www.ilpost.it" {
                isHomeAfterLogin = true
            } else if urlStr.contains("action=logout") {
                isHomeAfterLogout = true
            }
           }
        decisionHandler(.allow)
    }
    
    override func loadView() {
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    
    
    
    
}
