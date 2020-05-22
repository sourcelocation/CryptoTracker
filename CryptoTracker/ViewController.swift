//
//  ViewController.swift
//  CryptoTracker
//
//  Created by iMac on 19.05.2020.
//  Copyright © 2020 iMac. All rights reserved.
//

import UIKit
import SwiftMessages

class ViewController: UITableViewController {
    
    var apiData:[[String:Any]]?
    var loadingAlert:UIAlertController?
    var timer = Timer()
    var cryptoIds:[String] = []
    var refreshEnabled = false
    var sortBy = "rank"
    var crypto:[Crypto] = []
    var favoriteCrypto:[Crypto] = []
    var showingFavoriteCrypto = false
    
    @IBOutlet weak var starButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBAction func starTapped(_ sender: UIBarButtonItem) {
        showingFavoriteCrypto.toggle()
        UserDefaults.standard.set(showingFavoriteCrypto, forKey: "showingFavoriteCrypto")
        if showingFavoriteCrypto {
            sender.image = UIImage(systemName: "star.fill")
        } else {
            sender.image = UIImage(systemName: "star")
        }
        tableView.reloadData()
    }
    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        loadingAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        //create an activity indicator
        let indicator = UIActivityIndicatorView(frame: loadingAlert!.view.bounds)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        //add the activity indicator as a subview of the alert controller's view
        loadingAlert!.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        present(loadingAlert!, animated: false, completion: nil)
        if refreshEnabled {
            downloadData()
            refreshEnabled = false
            Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { _ in
                self.refreshEnabled = true
            })
        } else {
            Timer.scheduledTimer(withTimeInterval: .random(in: 0.3...1), repeats: false, block: { _ in
                self.loadingAlert?.dismiss(animated: false, completion: nil)
            })
        }
    }
    @IBAction func sortButtonClicked(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Sort options", message: "Please select, how the app should sort crypto.", preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(.init(title: "Sort by rank", style: .default, handler: { (alert) in
            self.sortCryptoData(by: "rank")
        }))
        alert.addAction(.init(title: "Sort by price", style: .default, handler: { (alert) in
            self.sortCryptoData(by: "price")
        }))
        alert.addAction(.init(title: "Sort by price change (descending)", style: .default, handler: { (alert) in
            self.sortCryptoData(by: "changeMax")
        }))
        alert.addAction(.init(title: "Sort by price change (ascending)", style: .default, handler: { (alert) in
            self.sortCryptoData(by: "changeMin")
        }))
        alert.addAction(.init(title: "Sort by name", style: .default, handler: { (alert) in
            self.sortCryptoData(by: "name")
        }))
        tableView.reloadData()
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showingFavoriteCrypto = UserDefaults.standard.bool(forKey: "showingFavoriteCrypto")
        if showingFavoriteCrypto {
            starButton.image = UIImage(systemName: "star.fill")
        } else {
            starButton.image = UIImage(systemName: "star")
        }
        let favoriteCryptoEncoded = UserDefaults.standard.data(forKey: "favoriteCryptoEncoded")
        if favoriteCryptoEncoded != nil {
            favoriteCrypto = try! JSONDecoder().decode([Crypto].self, from: favoriteCryptoEncoded!)
        }
        loadingAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        //create an activity indicator
        let indicator = UIActivityIndicatorView(frame: loadingAlert!.view.bounds)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        //add the activity indicator as a subview of the alert controller's view
        loadingAlert!.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        present(loadingAlert!, animated: false, completion: nil)
        
        
        downloadData()
        // Do any additional setup after loading the view.
        Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { _ in
            self.refreshEnabled = true
        })
        
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showingFavoriteCrypto {
            return favoriteCrypto.count
        } else {
            return apiData?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CustomTableCell
        cell.cryptoCountLabel.text = "\(row + 1)"
        var rowCrypto:Crypto!
        if showingFavoriteCrypto {
            rowCrypto = favoriteCrypto[row]
        } else {
            rowCrypto = crypto[row]
        }
        cell.cryptoNameLabel.text = rowCrypto.name
        cell.shortCryptoNameLabel.text = rowCrypto.shortName
        
        
        if (Double(rowCrypto.price!)!) < 5.0 {
            cell.priceLabel.text = "\((Double(rowCrypto.price!)!).round(to: 6))"
        } else {
            cell.priceLabel.text = "\((Double(rowCrypto.price!)!).round(to: 2))"
        }
        
        let percentChange = (Double(rowCrypto.priceChange!)!).round(to: 3)
        cell.priceChangeInPercentsLabel.text = "\(abs(percentChange))%"
        if percentChange < 0.0 {
            cell.priceChangeInPercentsLabel.textColor = .systemRed
            cell.priceChangeInPercentsLabel.text = "▼ \(cell.priceChangeInPercentsLabel.text!)"
        } else if percentChange > 0.0 {
            cell.priceChangeInPercentsLabel.textColor = .systemGreen
            cell.priceChangeInPercentsLabel.text = "▲ \(cell.priceChangeInPercentsLabel.text!)"
        } else if percentChange == 0.0 {
            cell.priceChangeInPercentsLabel.textColor = .gray
        }
        if apiData != nil {
            let symbol = (rowCrypto.shortName!).lowercased()
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(symbol)")
                let image    = UIImage(contentsOfFile: imageURL.path)
                
                if UIImage(named: symbol) != nil {
                    cell.logoImageView.image = UIImage(named: symbol)
                } else if image != nil {
                    cell.logoImageView.image = image
                } else {
                    cell.logoImageView.imageFromUrl(urlString: "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/32%402x/icon/\(symbol)%402x.png", cryptoSymbol: symbol)
                }
            }
        }
        
        cell.logoImageView.backgroundColor = .clear
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "detailVC") as! DetailViewController
        detailVC.crypto = self.crypto[indexPath.row]
        present(detailVC, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let view = MessageView.viewFromNib(layout: .cardView)
        
        view.button?.isHidden = true
        view.configureDropShadow()
        
        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
        var config = SwiftMessages.Config()
        config.presentationStyle = .bottom
        
        let favorite = UITableViewRowAction(style: .normal, title: (favoriteCrypto.contains(crypto[indexPath.row]) || showingFavoriteCrypto) ? "Unfavorite" : "Favorite") { action, index in
            if !self.showingFavoriteCrypto {
                if self.favoriteCrypto.contains(self.crypto[indexPath.row]) {
                    self.favoriteCrypto.remove(at: self.favoriteCrypto.firstIndex(of: self.crypto[indexPath.row])!)
                    view.configureTheme(.error)
                    let backgroundColor = UIColor(red: 97.0/255.0, green: 161.0/255.0, blue: 23.0/255.0, alpha: 1.0)
                    let foregroundColor = UIColor.white
                    view.configureContent(title: "Success", body: "Removed this cryptocurrency from favorites.")
                    view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor, iconImage: UIImage(named: "errorIcon")?.invertedImage())
                } else {
                    self.favoriteCrypto.append(self.crypto[indexPath.row])
                    view.configureTheme(.success)
                    view.configureContent(title: "Success", body: "Added this cryptocurrency to favorites.")
                }
            } else {
                self.favoriteCrypto.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                let backgroundColor = UIColor(red: 97.0/255.0, green: 161.0/255.0, blue: 23.0/255.0, alpha: 1.0)
                let foregroundColor = UIColor.white
                view.configureContent(title: "Success", body: "Removed this cryptocurrency from favorites.")
                view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor, iconImage: UIImage(named: "errorIcon")?.invertedImage())
            }
            
            for crypt in self.favoriteCrypto {
                print(crypt)
            }
            let favoriteCryptoEncoded = try? JSONEncoder().encode(self.favoriteCrypto)
            UserDefaults.standard.set(favoriteCryptoEncoded, forKey: "favoriteCryptoEncoded")
            SwiftMessages.show(config:config, view: view)
            tableView.reloadData()
        }
        favorite.backgroundColor = (favoriteCrypto.contains(crypto[indexPath.row]) || showingFavoriteCrypto) ? .systemRed : .systemBlue

        return [favorite]
    }
    func reloadData() {
        loadingAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        //create an activity indicator
        let indicator = UIActivityIndicatorView(frame: loadingAlert!.view.bounds)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingAlert!.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        present(loadingAlert!, animated: false, completion: nil)
        
        
        downloadData()
        // Do any additional setup after loading the view.
        Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { _ in
            self.refreshEnabled = true
        })
    }
    
    func sortCryptoData(by: String) {
        if by == "name" {
            crypto.sort { (crypto1, crypto2) -> Bool in
                return crypto1.name!.lowercased() < crypto2.name!.lowercased()
            }
        } else if by == "rank" {
            crypto.sort { (crypto1, crypto2) -> Bool in
                return Double(crypto1.rank!.lowercased())! < Double(crypto2.rank!.lowercased())!
            }
        } else if by == "price" {
            crypto.sort { (crypto1, crypto2) -> Bool in
                return Double(crypto1.price!.lowercased())! > Double(crypto2.price!.lowercased())!
            }
        } else if by == "changeMax" {
            crypto.sort { (crypto1, crypto2) -> Bool in
                return Double(crypto1.priceChange!.lowercased())! > Double(crypto2.priceChange!.lowercased())!
            }
        }  else if by == "changeMin" {
            crypto.sort { (crypto1, crypto2) -> Bool in
                return Double(crypto1.priceChange!.lowercased())! < Double(crypto2.priceChange!.lowercased())!
            }
        }
        
        self.tableView.reloadData()
    }
    func downloadData() {
        //
        URLSession.shared.dataTask(with: URL(string: "https://api.coincap.io/v2/assets")!) { (data, response, error) -> Void in
            // Check if data was received successfully
            if error == nil && data != nil {
                do {
                    // Convert to dictionary where keys are of type String, and values are of any type
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: Any]
                    // Access specific key with value of type String
                    self.apiData = json["data"] as? [[String:Any]]
                    DispatchQueue.main.async {
                        self.loadingAlert?.dismiss(animated: false, completion: nil)
                        self.crypto.removeAll()
                        for crypto in self.apiData! {
                            let id = crypto["id"]!
                            self.cryptoIds.append("\(id)")
                            
                            let newCrypto = Crypto()
                            newCrypto.name = crypto["name"] as? String
                            newCrypto.price = crypto["priceUsd"] as? String
                            newCrypto.priceChange = crypto["changePercent24Hr"] as? String
                            newCrypto.rank = crypto["rank"] as? String
                            newCrypto.shortName = crypto["symbol"] as? String
                            newCrypto.id = crypto["id"] as? String
                            self.crypto.append(newCrypto)
                        }
                        var favoriteNames:[String] = []
                        for favCrypto in self.favoriteCrypto {
                            favoriteNames.append(favCrypto.name!)
                        }
                        self.favoriteCrypto.removeAll()
                        for cr in self.crypto {
                            if favoriteNames.contains(cr.name!) {
                                self.favoriteCrypto.append(cr)
                            }
                        }
                        self.tableView.reloadData()
                    }
                } catch {
                    // Something went wrong
                }
            }
        }.resume()
    }
    
    
    
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension UIImageView {
    public func imageFromUrl(urlString: String,cryptoSymbol:String) {
        let url = URL(string:urlString)
        
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard let data = data, error == nil else { return }
            
            
            DispatchQueue.main.async() {    // execute on main thread
                self.image = UIImage(data: data)
                
                let fileManager = FileManager.default
                do {
                    let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                    let fileURL = documentDirectory.appendingPathComponent(cryptoSymbol)
                    var image = UIImage(data: data)
                    if image == nil {
                        image = UIImage(named: "generic")!
                        self.image = image
                    }
                    if let imageData = image!.jpegData(compressionQuality: 1) {
                        try imageData.write(to: fileURL)
                    }
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
}


class Crypto:Equatable, Codable {
    static func == (lhs: Crypto, rhs: Crypto) -> Bool {
        return lhs.name == rhs.name
    }
    
    var name:String?
    var price:String?
    var priceChange:String?
    var shortName:String?
    var rank:String?
    var id:String?
}

extension UIImage {
    func invertedImage() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CoreImage.CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setDefaults()
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        let context = CIContext(options: nil)
        guard let outputImage = filter.outputImage else { return nil }
        guard let outputImageCopy = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: outputImageCopy, scale: self.scale, orientation: .up)
    }
}
