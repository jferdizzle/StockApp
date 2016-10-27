//
//  ViewController.swift
//  Maia+EFFI
//
//  Created by Julian Ferdman on 12/26/15.
//  Copyright © 2015 Julian Ferdman. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SnapKit
import PullToRefreshSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    
    var buyingPrice : Double! = 0.0026
    var commission : Double! = 8.95
    var shares : Double! =  60000.00
    var stockView = UITableView()
    
    
    
    var stockData : [String] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        loadTableView()
        view.backgroundColor = .yellow
        
    }
    
    
    
    //START TABLEVIEW
    
    func loadTableView() {
        
        
        self.view.addSubview(stockView)
        
        stockView.delegate = self
        stockView.dataSource = self
        stockView.separatorStyle = UITableViewCellSeparatorStyle.none
        stockView.rowHeight = view.frame.height/5
        
        
        var options = PullToRefreshOption()
        options.backgroundColor = .black
        options.indicatorColor = .yellow
        
        
        
        stockView.addPullRefresh(options: options) { [weak self] in
            
            DispatchQueue.main.async {
                self?.getStockData()
            }
            self?.stockView.stopPullRefreshEver()
            
        }
        
        
        stockView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        stockView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.top)
            make.centerX.equalTo(self.view.snp.centerX)
            make.width.equalTo(self.view.snp.width)
            make.bottom.equalTo(self.view.snp.bottom)
        }
        
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        
        cell.selectionStyle = .none
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .white
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 0
        
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        
        if (indexPath as NSIndexPath).row % 2 == 0 {
            //if even 
            cell.backgroundColor = UIColor.gray
        }
        else {
            //if odd
            cell.backgroundColor = UIColor.lightGray
        }
        //getStockData()
        if stockData.isEmpty {
            cell.textLabel?.text = "Reload Content"
            
        } else {
            cell.textLabel?.text = stockData[indexPath.row]
        }
        
        
        
        return cell
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\((indexPath as NSIndexPath).row)!")
        
        
    }
    
    //END TABLEVIEW
    
    //Connection
    func getStockData() {
        let path = "https://www.google.com/finance/info?q=OTC:EFFI"
        Alamofire.request(path,method: .get)
        
            .responseString { (response) in
                //print(response)
                var content = String(data: response.data!, encoding: String.Encoding.utf8)
                content = content?.replacingOccurrences(of: "// ", with: "")
                
                //print(content)
                //let jsonString = JSON(content)
                self.stockView.beginUpdates()
                if let dataFromString = content?.data(using: .utf8, allowLossyConversion: false) {
                    let json = JSON(data: dataFromString)
                    
                    
                    for jsonObjects in json {
                        print(jsonObjects.1)
                        
                        let current_price = jsonObjects.1["l_fix"].stringValue
                        
                        //let last_time = jsonObjects.1["ltt"].stringValue
                        //let last_date_time = jsonObjects.1["lt_dts"].stringValue
                        //let last_change = jsonObjects.1["c_fix"].stringValue
                        //let stock_ticker = jsonObjects.1["t"].stringValue
                        //let last_trade_date = jsonObjects.1["lt"].stringValue
                        //let percent_change = jsonObjects.1["cp"].stringValue
                        //Calculations
                        if let currentPrice : Double = Double(current_price) {
                            let percentGain = ((currentPrice - self.buyingPrice)/self.buyingPrice)*100 //NOTE: Percent gain does not include commission
                            let dollarValue = self.shares * currentPrice - self.commission
                            let purchaseValue = self.shares * self.buyingPrice - self.commission
                            let netGain = ((currentPrice * self.shares) - (self.buyingPrice * self.shares) - self.commission)
                            let randomIndex = Int(arc4random_uniform(UInt32(factsArray.count)))
                            
                            
                            self.stockData = ["EFFI IS TRADING AT "+current_price,"YOUR SHARES ARE WORTH $"+String(format: "%.2f",dollarValue),"THIS IS A GAIN OF $"+String(format: "%.2f",netGain)+" or "+String(format: "%.3f",percentGain)+"%","IF YOU SOLD NOW YOU'D BANK $"+String(format: "%.2f",netGain+purchaseValue),factsArray[randomIndex]]
                            
                        }
                        else {
                            NSLog("There's something wrong with the data")
                        }
                        
                    }
                }
                
                self.stockView.reloadData()
                self.stockView.endUpdates()
        }
        
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

