//
//  DetailViewController.swift
//  
//
//  Created by iMac on 20.05.2020.
//

import UIKit

class DetailViewController: UIViewController {
    
    var crypto:Crypto!
    var apiData:[[String:Any]]?
    @IBOutlet weak var cryptoNameLabel: UILabel!
    @IBOutlet weak var cryptoImageView: UIImageView!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var cryptoPriceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    
    
    @IBOutlet weak var priceChartLabel1: UILabel!
    @IBOutlet weak var priceChartLabel2: UILabel!
    @IBOutlet weak var priceChartLabel3: UILabel!
    @IBOutlet weak var priceChartLabel4: UILabel!
    @IBOutlet weak var priceChartLabel5: UILabel!
    @IBOutlet weak var grapghView: Graph!
    
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        let segment = sender.selectedSegmentIndex
        if segment == 0 {
            downloadData(interval: "m15")
        } else if segment == 1 {
            downloadData(interval: "h2")
        } else if segment == 2 {
            downloadData(interval: "h6")
        }  else if segment == 3 {
            downloadData(interval: "d1")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cryptoNameLabel.text = crypto.name
        symbolLabel.text = crypto.shortName
        if (Double(crypto.price!)!) < 5.0 {
            cryptoPriceLabel.text = "\((Double(crypto.price!)!).round(to: 6))$"
        } else {
            cryptoPriceLabel.text = "\((Double(crypto.price!)!).round(to: 2))$"
        }
        
        let percentChange = (Double(crypto.priceChange!)!).round(to: 3)
        priceChangeLabel.text = "\(abs(percentChange))%"
        if percentChange < 0.0 {
            priceChangeLabel.backgroundColor = .systemRed
            priceChangeLabel.text = "  ▼ \(priceChangeLabel.text!)  "
        } else if percentChange > 0.0 {
            priceChangeLabel.backgroundColor = .systemGreen
            priceChangeLabel.text = "  ▲ \(priceChangeLabel.text!)  "
        } else if percentChange == 0.0 {
            priceChangeLabel.textColor = .gray
        }
        downloadData(interval: "m15")
    }
    
    func setupGraph(prices:[Double],interval:String) {
        var maxPrice = 0.0
        var minPrice = 0.0
        
        minPrice = prices.first ?? 0.0
        for price in prices {
            if price > maxPrice {
                maxPrice = price
            }
        }
        for price in prices {
            if price < minPrice {
                minPrice = price
            }
        }
        let middlePrice = (minPrice + maxPrice) / 2
        var roundNumber = 0
        if maxPrice >= 50 {
            roundNumber = 2
        }
        priceChartLabel3.text = "\(middlePrice.round(to: roundNumber))"
        priceChartLabel1.text = "\(maxPrice.round(to: roundNumber))"
        priceChartLabel5.text = "\(minPrice.round(to: roundNumber))"
        priceChartLabel2.text = "\(((maxPrice + middlePrice) / 2).round(to: roundNumber))"
        priceChartLabel4.text = "\(((middlePrice + minPrice) / 2).round(to: roundNumber))"
        
        var yPositions:[Double] = []
        let usdInPoints = 256/(maxPrice-minPrice)
        for price in prices {
            let point = usdInPoints * (price - minPrice)
            yPositions.append(point)
        }
        if interval == "m15" {
            if yPositions.count > 96 {
                yPositions = Array(yPositions.dropFirst(yPositions.count - 96))
            }
        } else if interval == "h2" {
            if yPositions.count > 84 {
                yPositions = Array(yPositions.dropFirst(yPositions.count - 84))
            }
        } else if interval == "h6" {
            if yPositions.count > 120 {
                yPositions = Array(yPositions.dropFirst(yPositions.count - 120))
            }
        } else if interval == "d1" {
            if yPositions.count > 365 {
                yPositions = Array(yPositions.dropFirst(yPositions.count - 365))
            }
        }
        
        grapghView.yPositions = yPositions
        grapghView.setNeedsDisplay()
        
        
    }
    
    func downloadData(interval:String) {
        //
        URLSession.shared.dataTask(with: URL(string: "https://api.coincap.io/v2/assets/\(self.crypto.id!)/history?interval=\(interval)")!) { (data, response, error) -> Void in
            // Check if data was received successfully
            if error == nil && data != nil {
                do {
                    // Convert to dictionary where keys are of type String, and values are of any type
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: Any]
                    // Access specific key with value of type String
                    self.apiData = json["data"] as? [[String:Any]]
                    DispatchQueue.main.async {
                        var prices:[Double] = []
                        for priceInApi in self.apiData! {
                            let price = Double(priceInApi["priceUsd"] as! String)
                            prices.append(price!)
                        }
                        self.setupGraph(prices: prices, interval:interval)
                    }
                } catch {
                    // Something went wrong
                }
            }
        }.resume()
    }
    
}
