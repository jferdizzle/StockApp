//
//  ViewController.swift
//  Maia+EFFI
//
//  Created by Julian Ferdman on 12/26/15.
//  Copyright © 2015 Julian Ferdman. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSURLConnectionDelegate, UITableViewDelegate  {
    
    lazy var data = NSMutableData()
    var buyingPrice : Double! = 0.0026
    var commission : Double! = 8.95
    var shares : Double! =  60000.00
    var emptyTable = UITableView()
    var refreshControl:UIRefreshControl!
    
    
    //Pane 1
    var Pane1 = UILabel()
    //Pane 2
    var Pane2 = UILabel()
    //Pane 3
    var Pane3 = UILabel()
    //Pane 4
    var Pane4 = UILabel()
    //Pane 5
    var Pane5 = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startConnection()
        
        //Pane 1
        Pane1.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height/5)
        Pane1.font = UIFont.systemFontOfSize(18)
        Pane1.textColor = UIColor.whiteColor()
        Pane1.backgroundColor = UIColor.grayColor()
        Pane1.textAlignment = NSTextAlignment.Center
        view.addSubview(Pane1)
        
        //Pane 2
        Pane2.frame = CGRect(x: 0, y: Pane1.frame.maxY, width: view.frame.width, height: view.frame.height/5)
        Pane2.font = UIFont.systemFontOfSize(18)
        Pane2.textColor = UIColor.whiteColor()
        Pane2.backgroundColor = UIColor.lightGrayColor()
        Pane2.textAlignment = NSTextAlignment.Center
        view.addSubview(Pane2)
        
        //Pane 3
        Pane3.frame = CGRect(x: 0, y: Pane2.frame.maxY, width: view.frame.width, height: view.frame.height/5)
        Pane3.font = UIFont.systemFontOfSize(18)
        Pane3.textColor = UIColor.whiteColor()
        Pane3.textAlignment = NSTextAlignment.Center
        Pane3.backgroundColor = UIColor.grayColor()
        view.addSubview(Pane3)
        
        //Pane 4
        Pane4.frame = CGRect(x: 0, y: Pane3.frame.maxY, width: view.frame.width, height: view.frame.height/5)
        Pane4.font = UIFont.systemFontOfSize(18)
        Pane4.textColor = UIColor.whiteColor()
        Pane4.textAlignment = NSTextAlignment.Center
        Pane4.backgroundColor = UIColor.lightGrayColor()
        view.addSubview(Pane4)
        
        //Pane 5
        Pane5.frame = CGRect(x: 0, y: Pane4.frame.maxY, width: view.frame.width, height: view.frame.height/5)
        Pane5.font = UIFont.systemFontOfSize(18)
        Pane5.textColor = UIColor.whiteColor()
        Pane5.lineBreakMode = .ByWordWrapping
        Pane5.numberOfLines = 0 
        Pane5.textAlignment = NSTextAlignment.Center
        Pane5.backgroundColor = UIColor.grayColor()
        view.addSubview(Pane5)
        
        //Empty Table
        emptyTable.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        emptyTable.delegate = self
        emptyTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        emptyTable.backgroundColor = UIColor.clearColor()
        emptyTable.separatorStyle = UITableViewCellSeparatorStyle.None
        emptyTable.opaque = false
        view.addSubview(emptyTable)
        
        //Refresh
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.emptyTable.addSubview(refreshControl)
        
        
        
    }
    
    func startConnection(){
        let baseUrl:NSURL = NSURL(string:"http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20%28%22EFFI%22%29%0A%09%09&env=http%3A%2F%2Fdatatables.org%2Falltables.env&format=json")!
        let request: NSURLRequest = NSURLRequest(URL: baseUrl)
        let connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: true)!
        
    }
    
    func connection(didReceiveResponse: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        
        // Recieved a new request, clear out the data object
        self.data = NSMutableData()
        
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        // Append the recieved chunk of data to our data object
        self.data.appendData(data)
    }
    
    
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        // Request complete, self.data should now hold the resulting info
        // Convert the retrieved data in to an object through JSON deserialization
        
        do {
            if let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary {
                let query: NSDictionary = jsonResult["query"] as! NSDictionary
                let results: NSDictionary = query["results"] as! NSDictionary
                let quote: NSDictionary = results["quote"] as! NSDictionary
                let price: String = quote["LastTradePriceOnly"] as! String
                let currentPrice : Double! = Double(price)
                
                //Calculations
                let percentGain = ((currentPrice! - buyingPrice)/buyingPrice)*100 //NOTE: Percent gain does not include commission
                let dollarValue = shares * currentPrice! - commission
                let purchaseValue = shares * buyingPrice - commission
                let netGain = currentPrice!*shares - buyingPrice * shares-commission
                let randomIndex = Int(arc4random_uniform(UInt32(factsArray.count)))
                
                //Show prices ------
                Pane1.text = "EFFI IS TRADING AT "+String(currentPrice)
                Pane2.text = "YOUR SHARES ARE WORTH $"+String(format: "%.2f",dollarValue)
                Pane3.text = "THIS IS A GAIN OF $"+String(format: "%.2f",netGain)+" or "+String(format: "%.3f",percentGain)+"%"
                Pane4.text = "IF YOU SOLD NOW YOU'D BANK $"+String(format: "%.2f",netGain+purchaseValue)
                Pane5.text = factsArray[randomIndex]
                
                //Stop refreshing
                self.refreshControl.endRefreshing()
                
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }

    }
    
    func refresh(sender:AnyObject)
    {
        // Code to refresh table view
        startConnection()
    }
    
    func emptyTable(emptyTable: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func emptyTable(emptyTable: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = emptyTable.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        cell.textLabel!.backgroundColor = UIColor.clearColor()
        cell.detailTextLabel!.backgroundColor = UIColor.clearColor()
        cell.backgroundColor = UIColor(white:0,alpha:1)
        return cell
        
    }
    
    func emptyTable(emptyTable: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

