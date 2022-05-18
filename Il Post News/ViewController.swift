//
//  ViewController.swift
//  Il Post News
//
//  Created by Luca Grana on 03/04/22.
//

import UIKit
import SafariServices
import WebKit
import SystemConfiguration


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, WKUIDelegate {
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewsTableViewCell.self, forCellReuseIdentifier: NewsTableViewCell.identifier)
        return table
    }()
    
    private var viewModels = [NewsTableViewCellViewModel]()
    private var articles = [Article]()
    let refreshControl = UIRefreshControl()
    
    
    
    private var rssItems: [RSSItem]?
    
    private var searchVC = UISearchController(searchResultsController: nil)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Il Post News"
//
//        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
//        button.backgroundColor = .green
//        button.setTitle("Test Button", for: .normal)
//        button.addTarget(self, action: #selector(login(sender:)), for: .touchUpInside)
        let loginBtn = UIBarButtonItem.init(title: "LOGIN", style: .done, target: self, action: #selector(self.login(sender:)))
        self.navigationItem.rightBarButtonItem = loginBtn
        
        let goToSiteBtn = UIBarButtonItem.init(title: "Sito completo", style: .plain, target: self, action: #selector(self.goToSite(sender:)))
        self.navigationItem.leftBarButtonItem = goToSiteBtn
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .systemBackground
        addSearchBar()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        fetchData()
        
        
    }
    
    @objc func login(sender: UIBarButtonItem) {
        let newVC = WebView()
        newVC.strinUrl = "https://www.ilpost.it/wp-login.php?redirect_to=https://www.ilpost.it"
        self.present(newVC, animated: true)
    }
    
    @objc func goToSite(sender: UIBarButtonItem) {
        let newVC = WebView()
        newVC.strinUrl = "https://www.ilpost.it/"
        self.present(newVC, animated: true)
    }
    
    public func offlineAlert()  {
        let alert = UIAlertController(title: "Sei offline", message: "OOOOOPS! Sembra che tu sia offline", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Chiudi app", style: .cancel, handler: { action in
            exit(-1)
        }))
        alert.addAction(UIAlertAction(title: "Riprova", style: .default, handler: { action in
            self.fetchData()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
    
    
    private func addSearchBar() {
        navigationItem.searchController = searchVC
        searchVC.searchBar.delegate = self
    }
    
    @objc func refresh(_ sender: AnyObject) {
        fetchData()
    }
    
    private func fetchData() {
        if !isConnectedToNetwork() {
            offlineAlert()
            return
        }
        let feedParser = FeedParser()
        var tempImageUrl: URL = URL(string: "https://ilpost.it")!
        var tempDescription = ""
        feedParser.parseFeed(url: "https://ilpost.it/feed") { (rssItems) in
            self.rssItems = rssItems
            self.viewModels = []
            
            for item in rssItems {
                tempImageUrl = self.checkForUrls(text: item.description)[0]
                tempDescription = String(item.description[item.description.endIndex(of: "</div>")!...])
                self.viewModels.append(NewsTableViewCellViewModel(
                    title: item.title,
                    subtitle: tempDescription,
                    imageURL: tempImageUrl,
                    url: item.link))
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
            
        }
    }
    
    
    private func fetchTopStories() {
        APICaller.shared.getTopStories { [weak self]result in
            switch result{
            case .success(let articles):
                self?.articles = articles
                self?.viewModels = articles.compactMap({
                    NewsTableViewCellViewModel(
                        title: $0.title,
                        subtitle: $0.description ?? "No description",
                        imageURL: URL(string: $0.urlToImage ?? ""),
                        url: $0.url
                    )
                })
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
                break
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func checkForUrls(text: String) -> [URL] {
        let types: NSTextCheckingResult.CheckingType = .link
        
        do {
            let detector = try NSDataDetector(types: types.rawValue)
            
            let matches = detector.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
            
            return matches.compactMap({$0.url})
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        
        return []
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NewsTableViewCell.identifier,
            for: indexPath
        ) as? NewsTableViewCell else {
            fatalError()
        }
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let article = viewModels[indexPath.row]
        
        let newVC = WebView()
        newVC.strinUrl = article.url ?? "https://www.ilpost.it"
        self.present(newVC, animated: true)
        
        
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        let urlWithSearchText = "https://www.ilpost.it/search_gcse/?q=\(searchText)"
        
        let newVC = WebView()
        newVC.strinUrl = urlWithSearchText
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.present(newVC, animated: true)
        
    }
    
    
    
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
            .range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
            index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    
    
}

