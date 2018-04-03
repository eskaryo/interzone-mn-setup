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
5. Go to **Help -> "Debug window - Console"**  
6. Type the following command: **masternode outputs**  
7. Go to **Masternodes** tab  
8. Click **Create** and fill the details:  
* Alias: **MN1**  
* Address: **VPS_IP:PORT**  
* Privkey: **Masternode Private Key**  
* TxHash: **First value from Step 6**  
* Output index:  **Second value from Step 6**  
* Reward address: leave blank  
* Reward %: leave blank  
9. Click **OK** to add the masternode  
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

**BTC**: 1BzeQ12m4zYaQKqysGNVbQv1taN7qgS8gY  
**ETH**: 0x39d10fe57611c564abc255ffd7e984dc97e9bd6d  
**LTC**: LXrWbfeejNQRmRvtzB6Te8yns93Tu3evGf  
