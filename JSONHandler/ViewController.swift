//
//  ViewController.swift
//  JSONHandler
//
//  Created by Poonam on 27/07/19.
//  Copyright © 2019 Poonam. All rights reserved.
//

import UIKit
import SwiftyJSON

class ViewController: UIViewController {
    
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
        fetchPhotos()
        tableView.register(PhotosCell.self, forCellReuseIdentifier: "photos")
        setupViews()
    }
    
    func setupViews() {
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[vo]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["vo":tableView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[vo]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["vo":tableView]))
    }
    
    
    
    func fetchPhotos() {
        
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
