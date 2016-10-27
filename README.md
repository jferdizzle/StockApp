# StockApp
A quick example of how to parse the Google Finance API in a Swift app to access stock data.

## How to customize the software

### Google Finance API
The URL is accessed using Alamofire and converted from a string to JSON using SwiftyJSON, with some necessary cleanup. To add your own stock(s), simply edit the URL within the hyperlink (this example is only showing data from the stock ticker EFFI). OR even better, edit the end of the URL to be two variables, one for the exchange and one for the stock ticker. Then you can take user input and allow people to search the financial information for the stock of their dreams! :)

I have commented out various variables with suggested names to play with. There are a few more and you can see them by printing the json.

Please ask questions if you need help using this. 

### Random Facts
The random "facts" and quotes are not my own and serve no purpose for your financial needs, other than possibly brightening your days. Please see the documentation for credit.

May the Force be with you.


