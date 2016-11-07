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
import Kanna
import ChameleonFramework
import Charts

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var backgroundView = UIView()
    var stockView = UITableView()
    
    //User Data
    var stockTicker = "EFFI"
    var buyingPrice : Double! = 0.0026
    var commission : Double! = 8.95
    var shares : Double! =  60000.00
    
    
    var tableViewImage = UIImageView()
    
    var stockData : [String] = []
    var currentNews = ""
    var currentLink = ""
    
    //Historical
    var historicalPrice: [String] = []
    var historicalDate: [String] = []
    var historicalStockData = [String : String]()
    
    //Chart
    var lineChart = LineChartView()
    var lineChartData = LineChartData()
    var barChartView: BarChartView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.black
        
        addBackgroundView()
        getHistoricalPrices()
        loadTableView()
        getStockData()
        getNews()
        
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            loadLineChart()
            backgroundView.isHidden = true
        }
        else {
            backgroundView.isHidden = false
            lineChart.removeFromSuperview()
            lineChartData = LineChartData()
        }
    }
    
    func addBackgroundView() {
        view.addSubview(backgroundView)
        
        backgroundView.snp.makeConstraints { (make) in
            make.center.equalTo(view)
            make.height.equalTo(view)
            make.width.equalTo(view)
        }
    }
    

    //START TABLEVIEW
    
    func loadTableView() {
        
        
        self.backgroundView.addSubview(stockView)
        
        stockView.delegate = self
        stockView.dataSource = self
        stockView.separatorStyle = UITableViewCellSeparatorStyle.none
        stockView.rowHeight = view.frame.height/5
        stockView.backgroundColor = UIColor(red: 52/255, green: 73/255, blue: 94/255, alpha: 1)
        
        
        var options = PullToRefreshOption()
        options.backgroundColor = UIColor(red: 52/255, green: 73/255, blue: 94/255, alpha: 1)

        
        
        
        
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
            
            cell.backgroundColor = UIColor.gray.flatten()
                
            
        }
        else {
            //if odd
            cell.backgroundColor = UIColor.darkGray.flatten()
        }
        //getStockData()
        if stockData.isEmpty {
            cell.textLabel?.text = "Reload Content"
            
        } else {
            cell.textLabel?.text = stockData[indexPath.row]
        }
        
        if (indexPath as NSIndexPath).row == 4 {
            if self.currentNews == "" && self.currentLink == "" {
                print("No news")
            } else {
                cell.backgroundColor = UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: 1)
                cell.textLabel?.textColor = UIColor.white.flatten()
            }
        }
        
        
        return cell
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\((indexPath as NSIndexPath).row)!")
        
        if (indexPath as NSIndexPath).row == 4 {
            if self.currentNews == "" && self.currentLink == "" {
                print("No news")
            } else {
                UIApplication.shared.openURL(URL(string: self.currentLink)!)
            }
        }
        
    }
    
    
    //END TABLEVIEW
    
    //Connection
    func getStockData() {
        let path = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20IN%20(%22\(stockTicker)%22)&format=json&env=http://datatables.org/alltables.env"
        Alamofire.request(path,method: .get)
        
        
            .responseJSON { (response) in
                //print(response)
                
                    let json = JSON(response.result.value ?? "")
                    
                    let results = json["query"]["results"]["quote"]
                
                    let current_price = results["LastTradePriceOnly"].stringValue
                
                //Calculations
                if let currentPrice : Double = Double(current_price) {
                    let percentGain = ((currentPrice - self.buyingPrice)/self.buyingPrice)*100 //NOTE: Percent gain does not include commission
                    let dollarValue = self.shares * currentPrice - self.commission
                    let purchaseValue = self.shares * self.buyingPrice - self.commission
                    let netGain = ((currentPrice * self.shares) - (self.buyingPrice * self.shares) - self.commission)
                    let totalValue = netGain + purchaseValue
                    let randomIndex = Int(arc4random_uniform(UInt32(factsArray.count)))
                    
                    var cellFiveText = ""
                    if self.currentNews == "" && self.currentLink == "" {
                        cellFiveText = factsArray[randomIndex]
                    } else {
                        cellFiveText = self.currentNews
                    }
                    
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = NumberFormatter.Style.decimal
                    let dollarValueFormatted = numberFormatter.string(from: NSNumber(value: dollarValue))
                    let netGainFormatted = numberFormatter.string(from: NSNumber(value: netGain))
                    let totalValueFormatted = numberFormatter.string(from: NSNumber(value: totalValue))
                    
                    
                    self.stockData = ["\(self.stockTicker) IS TRADING AT "+current_price,"YOUR SHARES ARE WORTH $"+dollarValueFormatted!,"THIS IS A GAIN OF $"+netGainFormatted!+" or "+String(format: "%.2f",percentGain)+"%","IF YOU SOLD NOW YOU'D BANK $"+totalValueFormatted!,cellFiveText]
                    
                }
                else {
                    print("There's something wrong with the data")
                }
                
                
                
                self.stockView.reloadData()
                self.stockView.endUpdates()
        }
        
    }
    
    
    func getNews() {
        let myURLString = "https://www.bloomberg.com/quote/\(stockTicker):US"
        guard let myURL = URL(string: myURLString) else {
            print("Error: \(myURLString) doesn't seem to be a valid URL")
            return
        }
        
        do {
            let myHTMLString = try String(contentsOf: myURL, encoding: .utf8)
            //print("HTML : \(myHTMLString)")
            
            
            if let doc = HTML(html: myHTMLString, encoding: .utf8) {
                
                //Today's Date Formatted
                let todaysDate:NSDate = NSDate()
                let dateFormatter:DateFormatter =
                    DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let todayString:String = dateFormatter.string(from: todaysDate as Date)

                
                // Search for for links that match Company News Item
                for link in doc.css("a, link") {
                    if (link.text!).contains("Efftec") || (link.text!).contains("Efftech") {
                        if (link["href"]!).contains(todayString) {
                            
                            print(link.text ?? "")
                            print(link["href"] ?? "")
                            self.currentNews = link.text!
                            self.currentLink = link["href"]!
                            
                        }
                    }
                }

            }
        } catch let error {
            print("Error: \(error)")
        }
        
    }
    
    func getHistoricalPrices() {
        
        //Today's Date Formatted
        let todaysDate:NSDate = NSDate()
        let oneYearAgo:NSDate = todaysDate.addingTimeInterval(-31540000)
        let dateFormatter:DateFormatter =
            DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString:String = dateFormatter.string(from: todaysDate as Date)
        let lastYearString:String = dateFormatter.string(from: oneYearAgo as Date)
        
        self.historicalStockData.removeAll()
        
        let path = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.historicaldata%20where%20symbol%20%3D%20%22\(stockTicker)%22%20and%20startDate%20%3D%20%22\(lastYearString)%22%20and%20endDate%20%3D%20%22\(todayString)%22&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
        
        Alamofire.request(path,method: .get)
            
            
            .responseJSON { (response) in
                //print(response)
                
                let json = JSON(response.result.value ?? "")
                
                let results = json["query"]["results"]["quote"]
                var closePrice = ""
                var closeDate = ""
                
                for object in results {
                    for item in object.1 {
                        
                        if item.0 == "Close" {
                            closePrice = item.1.stringValue
                            self.historicalPrice.append(closePrice)
                        }
                        else if item.0 == "Date" {
                            closeDate = item.1.stringValue
                            self.historicalDate.append(closeDate)
                        }
                        self.historicalStockData[closeDate] = closePrice
                    }
                }
        }
        
        

    }

    
    //LOAD CHART
    func loadLineChart() {
        view.addSubview(lineChart)
        
        lineChart.snp.makeConstraints { (make) in
            make.center.equalTo(view)
            make.height.equalTo(view)
            make.width.equalTo(view)
        }
        
        if historicalStockData.isEmpty {
            print("Do loading work here")
        }
        else{
            loadChartData()
        }
        
        
        
    }
    
    func loadChartData() {
        
        lineChart.noDataText = "Wait for it!"
        lineChart.noDataTextColor = UIColor.white
        lineChart.noDataFont = UIFont.systemFont(ofSize: 10.0)
        lineChart.backgroundColor = UIColor.black
        lineChart.borderLineWidth = 5
        lineChart.chartDescription?.text = "\(stockTicker): 1 YEAR"
        lineChart.chartDescription?.textColor = UIColor.white
        lineChart.chartDescription?.font = UIFont.systemFont(ofSize: 10)
        lineChart.leftAxis.labelTextColor = UIColor.white
        lineChart.leftAxis.labelFont = UIFont.systemFont(ofSize: 10)
        lineChart.leftAxis.drawAxisLineEnabled = false
        lineChart.leftAxis.drawZeroLineEnabled = true
        lineChart.leftAxis.drawGridLinesEnabled = false
        lineChart.leftAxis.drawTopYLabelEntryEnabled = true
        lineChart.xAxis.drawLabelsEnabled = false
        lineChart.rightAxis.enabled = false
        lineChart.legend.enabled = false
        lineChart.doubleTapToZoomEnabled = false
        lineChart.pinchZoomEnabled = false
        lineChart.scaleXEnabled = false
        lineChart.scaleYEnabled = false
        
        
        let sortedDictionary =  historicalStockData.sorted(by: { $0.0 < $1.0 })
        var dataEntries : [ChartDataEntry] = []
        
        
        var count = 0.0
        for entry in sortedDictionary {
            //let newDate = (entry.key).replacingOccurrences(of: "-", with: "")
            //let doubleDate = Double(newDate)
            //print(doubleDate ?? "")
            //print(Double(entry.value) ?? "")
            
            let point = ChartDataEntry(x: count, y: Double(entry.value)!, data: entry as AnyObject?)
            dataEntries.append(point)
            
            
            count += 1
        }
        
        
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "Price")
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.drawVerticalHighlightIndicatorEnabled = false
        lineChartDataSet.mode = .cubicBezier
        lineChartDataSet.circleRadius = 0
        lineChartDataSet.lineWidth = 2.0
        lineChartDataSet.valueFont = UIFont.systemFont(ofSize: 10.0)
        lineChartDataSet.valueTextColor = UIColor.white
        lineChartDataSet.setColor(UIColor.green.flatten())
        lineChartDataSet.drawFilledEnabled = false
        lineChartDataSet.fillColor = UIColor.white
        let data: LineChartData = LineChartData(dataSets: [lineChartDataSet])
        self.lineChart.data = data
        
        let sortedDates =  historicalDate.sorted(by: { $0 < $1 })
        let xAxis = lineChart.xAxis
        xAxis.valueFormatter = XValsFormatter(xVals: sortedDates)
        xAxis.axisMinimum = Double(0)
        xAxis.drawGridLinesEnabled = false
        
        lineChartData.addDataSet(lineChartDataSet)
        lineChart.data = lineChartData
    }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



}

class XValsFormatter: NSObject, IAxisValueFormatter {
    
    let xVals: [String]
    init(xVals: [String]) {
        self.xVals = xVals
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return xVals[Int(value)]
    }
    
}
