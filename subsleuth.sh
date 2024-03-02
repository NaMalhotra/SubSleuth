#!/bin/bash

    figlet -f big "SubSleuth"
    url=$1
    
    if [ ! -d "$url" ];then
        mkdir $url
    fi

    if [ ! -d "$url/recon" ];then
        mkdir $url/recon
    fi

    if [ ! -d "$url/recon/scans" ];then
        mkdir $url/recon/scans
    fi

    if [ ! -d "$url/recon/httprobe" ];then
        mkdir $url/recon/httprobe
    fi

    if [ ! -d "$url/recon/potential_takeover" ];then
        mkdir $url/recon/potential_takeover
    fi

    if [ ! -d "$url/recon/wayback" ]; then
        mkdir $url/recon/wayback
    fi

    if [ ! -d "$url/recon/wayback/extensions" ]; then
        mkdir $url/recon/wayback/extensions
    fi

    if [ ! -d "$url/recon/wayback/params" ]; then
        mkdir $url/recon/wayback/params
    fi

    if [ ! -d "$url/recon/httprobe/alive.txt" ]; then
        touch $url/recon/httprobe/alive.txt
    fi

    if [ ! -d "$url/recon/finalsubs.txt" ]; then
        touch $url/recon/finalsubs.txt
    fi



    if [ ! -x "$(command -v assetfinder)" ]; then
        echo "[*] Assetfinder reqd but not installed (Installation guide: https://github.com/tomnomnom/assetfinder)"
        exit 1
    fi

    if [ ! -x "$(command -v amass)" ]; then
        echo "[*] Amass reqd but not installed (Installation: sudo apt install amass)"
        exit 1
    fi

    if [ ! -x "$(command -v sublist3r)" ]; then
        echo "[*] Sublist3r reqd but not installed (Installation guide: https://github.com/aboul3la/Sublist3r)"
        exit 1
    fi
    if [ ! -x "$(command -v gowitness)" ]; then
        echo "[*] Gowitness reqd but not installed (Installation guide: https://github.com/sensepost/gowitness/wiki/Installation)"
        exit 1
    fi
    if [ ! -x "$(command -v waybackurls)" ]; then
        echo "[*] waybackurls reqd but not installed (Installation guide: https://github.com/tomnomnom/waybackurls)"
        exit 1
    fi

    if [ ! -f "$url/recon/3rd-lvl" ];then
        touch $url/recon/3rd-lvl-domains.txt
    fi



    echo "[1] Harvesting subdomains with assetfinder......"
    assetfinder $url -subs-only > $url/recon/assets.txt && sort -u -o $url/recon/assets.txt $url/recon/assets.txt



    echo "[2] Running Amass......"
    amass enum -d $url > $url/recon/amass_subs.txt && sort -u -o $url/recon/amass_subs.txt $url/recon/amass_subs.txt



    echo "[3] Merging outputs.........."
    sort -u $url/recon/assets.txt >> $url/recon/final.txt
    sort -u $url/recon/amass_subs.txt >> $url/recon/final.txt
    
    echo "No of subdomains found =  $(wc -l $url/recon/final.txt | cut -d ' ' -f 1)"

    if [ ! -f "$url/recon/3rd-lvl" ];then
        touch $url/recon/3rd-lvl-domains.txt
    fi
    echo "  [3.x] Compiling 3rd lvl domains...(take a look if you want)"
    cat ~/$url/recon/final.txt | grep -Po '(\w+\.\w+\.\w+)$' | sort -u >> ~/$url/recon/3rd-lvl-domains.txt
    #write in line to recursively run thru final.txt
    for line in $(cat $url/recon/3rd-lvl-domains.txt);do echo $line | sort -u | tee -a $url/recon/final.txt;done



    echo "[4] Probing for alive domains using httprobe......"
    cat $url/recon/final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> $url/recon/httprobe/a.txt
    sort -u $url/recon/httprobe/a.txt > $url/recon/httprobe/alive.txt
    rm $url/recon/httprobe/a.txt



    echo "[5] Checking for Potential Subdomain takeover"
    if [ ! -f "$url/recon/potential_takeover/takeovers.txt" ]; then
        touch $url/recon/potential_takeover/takeovers.txt
    fi

    subjack -w $url/recon/final.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o $url/recon/potential_takeover/takeovers.txt
    echo " $(wc -l $url/recon/potential_takeover/takeovers.txt | cut -d ' ' -f 1)  Potential Takeover subs are available"



    echo "[6] Running whatweb on domains......."
    for domain in $(cat $url/recon/httprobe/alive.txt);do
        if [ ! -d  "$url/recon/whatweb/$domain" ];then
            mkdir $url/recon/whatweb/$domain
        fi
        if [ ! -d "$url/recon/whatweb/$domain/output.txt" ];then
            touch $url/recon/whatweb/$domain/output.txt
        fi
        if [ ! -d "$url/recon/whaweb/$domain/plugins.txt" ];then
            touch $url/recon/whatweb/$domain/plugins.txt
        fi
        echo "  [6.1] Pulling plugins data of $domain $(date + '%Y-%m-%d')"
        whatweb --info-plugins -t 50 -v $domain >> $url/recon/whatweb/$domain/plugins.txt
        echo "  [6.2] Running whatweb on domain $domain $(date + '%Y-%m-%d')"
        whatweb -t 50 -v $domain >> $url/recon/whatweb/$domain/output.txt
    done


    echo "[7] Pulling Wayback Data........."
    if [ ! -f "$url/recon/wayback/wayback_out.txt" ]; then
        touch $url/recon/wayback/wayback_out.txt
    fi
    cat $url/recon/final.txt | waybackurls >> $url/recon/wayback/wayback_out.txt
    sort -u $url/recon/wayback/wayback_out.txt
    echo "  [7.1] Pulling and Compiling all possible parameters in Wayback data"
    cat $url/recon/wayback/wayback_out.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> $url/recon/wayback/params/wayback_params.txt
    for line in $(cat $url/recon/wayback/wayback_params.txt);do echo $line'=';done

    echo "[7.2] Pulling and compiling js/php/aspx/jsp/json files from wayback output..."
    for line in $(cat $url/recon/wayback/wayback_output,txt);do 
        ext="{line##*.}"
        if [["$ext" == "js"]]; then
            echo $line >> $url/recon/wayback/extensions/js.txt && sort -u -o $url/recon/wayback/extensions/js.txt $url/recon/wayback/extensions/js.txt
        fi
        if [["$ext" == "html"]]; then
            echo $line >> $url/recon/wayback/extensions/jsp.txt && sort -u -o $url/recon/wayback/extensions/jsp.txt $url/recon/wayback/extensions/jsp.txt
        fi
        if [["$ext" == "json"]]; then
            echo $line >> $url/recon/wayback/extensions/json.txt && sort -u -o $url/recon/wayback/extensions/json.txt $url/recon/wayback/extensions/json.txt
        fi
        if [["$ext" == "php"]]; then
            echo $line >> $url/recon/wayback/extensions/php.txt && sort -u -o $url/recon/wayback/extensions/php.txt $url/recon/wayback/extensions/php.txt
        fi
        if [["$ext" == "aspx"]]; then
            echo $line >> $url/recon/wayback/extensions/aspx.txt && sort -u -o $url/recon/wayback/extensions/aspx.txt $url/recon/wayback/extensions/aspx.txt
        fi
    done



    echo "[8] Running Gowitness against all compliled subs..."
    $(gowitness file -f $url/recon/httprobe/alive.txt -P $url/recon/Gowitnesspath --no-http)
