# Interzone
Shell script to install a [Interzone Masternode](http://interzone.space) on a Linux server running Ubuntu 16.04. Use it on your own risk.  

***
## Installation:  

wget -q https://raw.githubusercontent.com/eskaryo/interzone-mn-setup/master/interzone_install.sh
bash interzone_install.sh
***

## Desktop wallet setup  

After the MN is up and running, you need to configure the desktop wallet accordingly. Here are the steps:  
1. Open the Interzone Desktop Wallet.  
2. Go to RECEIVE and create a New Address: **MN1**  
3. Send **5000** ITZ to **MN1**.  
4. Wait for 30 confirmations.  
5. Go to **Command Line Interface tab"**  
6. Type the following command: **masternode outputs**  
7. Edit %appdata%\interzone\masternode.conf
8. Add a line with the following information separated as follows:
NICKNAME ADDRESS:PORT MASTERNODEGENKEY TXHASH TX-ID
* TxHash: **First value from Step 6**  
* TX-ID:  **Second value from Step 6**  
9. Save masternode.conf and restart wallet
10. Go to 'NetworkNodes tab'
11. Choose 'My NetworkNodes'
12. Select MN1 from the list
10. Click **Start All**  

***

## Usage:  

```
interzoned masternode status
interzoned getinfo
```  

Also, if you want to check/start/stop **Interzone** , run one of the following commands as **root**:

``` 
systemctl status Interzone #To check the service is running.  
systemctl start Interzone #To start Interzone service.  
systemctl stop Interzone #To stop Interzone service.  
systemctl is-enabled Interzone #To check whetether Interzone service is enabled on boot or not.  
```  
***

## Donations:
  
Any donation is highly appreciated  

**BTC**: 3DopdLoBk8X7SM4YqPzbFkhfqJzUMoowrU  
**ITZ**: 15WT16zAQZFNEYF6ahhDiBfNnK5FotiuTD
