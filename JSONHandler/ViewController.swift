//
//  ViewController.swift
//  JSONHandler
//
//  Created by Poonam on 27/07/19.
//  Copyright © 2019 Poonam. All rights reserved.
//

import UIKit
import SwiftyJSON
import WebKit

class ViewController: UIViewController {
    
    let webView: WKWebView  = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    var photos:[Photos] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.register(PhotosCell.self, forCellReuseIdentifier: "photos")
        setupViews()
        downloadPdfFile()
    }
    
    func setupViews() {
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[vo]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["vo":tableView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[vo]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["vo":tableView]))
    }
    
    // MARK:- Get request
    
    func getRequstTofetchPhotos() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/photos") else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil { return }
            guard let data = data else { return }
            let photos_ = try? JSONDecoder().decode([Photos].self, from: data)
            OperationQueue.main.addOperation {
                if let photos = photos_ {
                    self.photos = photos
                }
                self.tableView.reloadData()
            }
        }.resume()
    }
    
    // MARK:- Get request with parameters
    
    func getRequstTofetchPhotosWith(albumId:String) {
        let urlString = "https://jsonplaceholder.typicode.com/photos"
        
        var urlComponet = URLComponents(string: urlString)
        urlComponet?.queryItems = [URLQueryItem(name: "albumId", value: albumId)]
        
        guard let url = urlComponet?.url else {
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil { return }
            guard let data = data else { return }
            let photos_ = try? JSONDecoder().decode([Photos].self, from: data)
            OperationQueue.main.addOperation {
                if let photos = photos_ {
                    self.photos = photos
                }
                self.tableView.reloadData()
            }
        }.resume()
    }
    
    // MARK:- Post request
    
    func postRequestTofetchPosts() {
        let urlString = "https://jsonplaceholder.typicode.com/photos"
        guard let url = URL(string: urlString) else { return }
      
        var request = URLRequest(url: url)
        request.httpMethod = "post"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try? JSONSerialization.data(withJSONObject: ["album_id" : 4343, "album_name" : "new"], options: [])
        if let unwrapped_jsonData = jsonData {
            request.httpBody = unwrapped_jsonData
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil { return }
            guard let data = data else { return }
            let json = try? JSON(data: data)
            if let unwrapped_json = json {
                print(unwrapped_json)
            }
        }.resume()
    }
    
    // MARK:- Download session (PDF File)
    
    func downloadPdfFile() {
        
        guard let url = URL(string: "http://www.africau.edu/images/default/sample.pdf") else { return }
        
        let lasPathComponent = url.lastPathComponent
        
        let fileURL = documentDirectoryURL().appendingPathComponent(lasPathComponent)
    
        if FileManager.default.fileExists(atPath: fileURL.path) {
            showPDF(filePath: fileURL)
            return
        }
        URLSession.shared.downloadTask(with: url) { (tmp_url, response, error) in
            if error != nil {
                return
            }
            if let unwrapped_tmp_url = tmp_url {
                try? FileManager.default.copyItem(at: unwrapped_tmp_url, to: fileURL)
                DispatchQueue.main.async {
                    self.showPDF(filePath: fileURL)
                }
            }
        }.resume()
    }
    
    func documentDirectoryURL() -> URL {
        let doucmentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return doucmentDirectory[0]
    }
    
    func showPDF(filePath: URL) {
        view.addSubview(webView)
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.load(URLRequest(url: filePath))
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "photos", for: indexPath) as! PhotosCell
        //cell.thumbnailIcon.image = UIImage()
        cell.photoInfo = photos[indexPath.row]
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}


struct Photos: Decodable {
    let url: String?
    let albumId:Int?
    let id: Int?
    let title: String?
    let thumbnailUrl: String?
}


class PhotosCell: UITableViewCell {
    
    let imageCache = NSCache<NSString,UIImage>()
    var urlString = ""
    
    var photoInfo: Photos? {
        didSet {
            
            label.text = photoInfo?.title!.capitalized
            
            if let urlString = photoInfo?.thumbnailUrl, urlString.count > 0 {
                self.urlString = urlString
                if let image = imageCache.object(forKey: urlString as NSString) {
                    thumbnailIcon.image = image
                }
                else {
                    if let url = URL(string: urlString) {
                        URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                            if let data = data {
                                DispatchQueue.main.async {
                                    self.imageCache.setObject(UIImage(data: data)!, forKey: urlString as NSString)
                                    if self.urlString == urlString {
                                        self.thumbnailIcon.image = UIImage(data: data)
                                    }
                                }
                            }
                        }).resume()
                    }
                }
            }
        }
    }
    
    let thumbnailIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let label : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.blue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(thumbnailIcon)
        contentView.addSubview(label)
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[vo(80)]-20-[v1]-20-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["vo": thumbnailIcon, "v1" : label]))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[vo]-20-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["vo":thumbnailIcon]))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[vo]-20-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["vo":label]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
