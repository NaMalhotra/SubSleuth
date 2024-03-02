# SubSleuth
Automation script for recon. 
Its functions are:
- Harvesting subdomains,
- Probing for alive subdomains,
- Checking potential takeovers,
- Checking for web technologies used,
- Generating wayback data (including possible js/json/jsp files),
- And taking screenshots of subdomains enumerated.

## Requirements
The following list of tools must be installed for this script:
1) Figlet 
2) Assetfinder
3) Amass
4) httprobe
5) Subjack
6) Whatweb
7) Waybackurls

## Installation
`git clone https://github.com/NaMalhotra/SubSleuth.git`
`cd SubSleuth`
`sudo chmod +x subsleuth.sh`

## Usage
`./subsleuth.sh <URL>`
