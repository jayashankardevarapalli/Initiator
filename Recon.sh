
mkdir -p subs
subfinder -silent -all -nc -d $1 | tee -a "subs/subfinder.txt"
amass enum -passive -d $1 | tee -a "subs/amass.txt"
findomain -q -t $1 | tee -a "subs/findomain.txt"
assetfinder --subs-only $1 | tee -a "subs/assetfinder.txt"
chaos -silent -d $1 | tee -a "subs/chaos.txt"

curl -s "https://securitytrails.com/list/apex_domain/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | grep ".$1" | sort -u | tee -a "subs/sectrails.txt"
curl -s "https://jldc.me/anubis/subdomains/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee -a "subs/jldc.txt"
curl -s "https://rapiddns.io/subdomain/$1?full=1#result" | grep "<td><a" | cut -d '"' -f 2 | grep http | cut -d '/' -f3 | sed 's/#results//g' | sort -u | tee -a "subs/rapiddns.txt"
curl -s "https://crt.sh/?Identity=%.$1" | grep ">*.$1" | sed 's/<[/]*[TB][DR]>/\n/g' | grep -vE "<|^[\*]*[\.]*$1" | sort -u | awk 'NF' | tee -a "subs/crtsh.txt"

cat subs/*.txt | sort -u > "l1-domains.txt"

cat l1-domains.txt | dnsx -resp -silent -r resolvers.txt | tee -a dnsx.txt
cat dnsx.txt | awk -F " " '{print $1}' | sort -u | tee -a alive-domains.txt
cat dnsx.txt | awk -F " " '{print $2}' | sort -u | awk -F "[" '{print $2}' | awk -F "]" '{print $1}' | sort -u | tee -a ips.txt
cat ips.txt | dnsx -ptr -ro -r resolvers.txt | tee -a ptr-domains.txt

mkdir -p status-codes
cat alive-domains.txt | httpx -silent -nc -title -server -td -cdn -sc -ip -lc -mc 200,401,403,405,500 | tee -a httpx.txt
cat httpx.txt | awk -F " " '{print $1}' | tee -a urls.txt
cat httpx.txt | grep "200" | tee -a status-codes/200.txt
cat httpx.txt | grep "401" | tee -a status-codes/401.txt
cat httpx.txt | grep "403" | tee -a status-codes/403.txt
cat httpx.txt | grep "405" | tee -a status-codes/405.txt
cat httpx.txt | grep "500" | tee -a status-codes/500.txt

mkdir -p archive
echo "$1" | waybackurls | tee -a archive/wayback.txt
echo "$1" | gau | tee -a archive/gau.txt
katana -silent -nc -proxy socks5://127.0.0.1:9050 -r resolvers.txt -kf -jc -d 5 -c 20 -l urls.txt | tee -a archive/katana.txt
cat archive/*.txt| sort -u | tee -a archive.txt


cat archive.txt | subjs | tee -a raw-js.txt
cat raw-js.txt | httpx -silent -nc -mc 200 | tee -a alive-js.txt
python3 /root/Tools/xnLinkFinder/xnLinkFinder.py -i alive-js.txt -sf $1 -o "wordlist/js-wordlist.txt"
mv parameters.txt "wordlist/"



mkdir -p wordlist
cat "l1-domains.txt" | tr '.' '\n' | sort -u > "wordlist/subbrute.txt"
cat "l1-domains.txt" | tr '-' '\n' | sort -u >> "wordlist/subbrute.txt"
cat archive.txt | unfurl paths | sort -u | tee -a "wordlist/paths.txt"
cat archive.txt | unfurl keys | sort -u | tee -a "wordlist/keys.txt"
cat archive.txt | unfurl values | sort -u | tee -a "wordlist/values.txt"
cat archive.txt | unfurl format %s://%d%p | sort -u | tee -a "wordlist/format.txt" 