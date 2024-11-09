#!/data/data/com.termux/files/usr/bin/bash
# shellcheck disable=SC2086,SC2162 # disable double quote warning, disable read without -r waning

# pretty print function
function print_info() {
    echo -e "\e[1;32m[*]\e[0m $1"
}

# pretty error print function
function print_error() {
    echo -e "\e[1;31m[*]\e[0m $1"
}

function throw() {
  print_error "$1"
  exit 1
}

print_info "Please Grant Storage Permission on Next Screen..."
termux-setup-storage

print_info "Make sure you've installed Termux from FDroid"

print_info "Please confirm if installed Termux from FDroid or not."
print_info "Enter 'y' for Yes and 'n' for No."
read -n 1 confirmation
echo -ne "\b"
if [ "$confirmation" == "y" ]; then
    print_info "Continuing..."
else
    print_info "Don't worry, we will download Termux FDroid .apk file for you."
    print_info "Loading..."
    curl https://f-droid.org/repo/com.termux_117.apk \
        -so /sdcard/Download/com.termux_117.apk || throw "Failed to Download Termux APK, please try again or download it manually from https://f-droid.org/repo/com.termux_117.apk"
    print_info "APK Downloaded and is located at internal storage/Download/com.termux_117.apk"
    print_info "Please Install the APK and Run this Script again."
    exit 0
fi

print_info "Installing Required Packages"
print_info " - Installing Updates, you can skip this by pressing 'y' within..."
print_info " - 5 Seconds... (useful if you have limited data)"
read -n1 -t5 skip_update
if [[ "$skip_update" =~ [yY] ]]; then
    print_info "Skipping Update, only required Packages will be Installed"
else
    pkg update -y &>/dev/null || err=1
    yes | pkg upgrade &>/dev/null || err=1
    pkg update -y &>/dev/null || err=1
fi
pkg install tsu zip -y &>/dev/null || err=1
if [ "$err" == "1" ]; then
    throw "Failed to Install Packages, check your internet connection and try again."
fi

testfile=/cache/test.$RANDOM
print_info "Checking for root access"
sudo touch $testfile || throw "Root Access not Granted. Please Grant Root Access and Run this Script again."
sudo rm -f $testfile

print_info "Making Directory"
tmpdir="tmpdir-$RANDOM"
mkdir /sdcard/$tmpdir

print_info "Extracting Partitions"
partitions="
nvram
nvcfg
nvdata
persist
protect1
protect2
proinfo
"
for part in $partitions; do
  sudo dd if="/dev/block/by-name/$part" of="/sdcard/$tmpdir/$part.img" status="none"
done

print_info "Packing Partitions to Save Space"
filename="IMEI_Backup_$(date +%Y-%m-%d@%H-%M-%S).zip"
# shellcheck disable=SC2164
cd /sdcard
zip -qr $filename $tmpdir

print_info "Clean-Up"
rm -rf $tmpdir

print_info "Done. File is located in Internal Storage with Filename: "
print_info "$filename"
