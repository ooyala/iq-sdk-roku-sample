#Ooyala IQ Sample App For Roku

This is a sample app showing how to use Ooyala IQ  with a Roku channel. It connects to a Backlot account and displays all the account's assets. Static assets(outside of Backlot) can also be added manually in `getNonBacklotAssets`.


##Building

1.	Clone this repository 
2.	Get Ooyala IQ brightscript library and copy it into your source folder
3.	Update appMain file with your account information(PCODE, API_KEY, and SECRET).
4.	(Optional) Run `npm install` to get the necessary packages for deployment
5.	(Optional) Deploy your app on your Roku using the following command line : `grunt --user=YOUR_USERNAME --pwd=ROKU_PASSWORD --address=YOUR_ROKU_IP`

