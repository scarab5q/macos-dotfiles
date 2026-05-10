#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Generate Test Data
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎲
# @raycast.packageName Test Data
# @raycast.argument1 { "type": "text", "placeholder": "iban | phone | address" }
# @raycast.argument2 { "type": "text", "placeholder": "sy eg bd ng pk gb" }

# Documentation:
# @raycast.description Generate fake IBANs, phone numbers, or addresses for testing

KIND=$(echo "$1" | tr '[:upper:]' '[:lower:]')
COUNTRY=$(echo "$2" | tr '[:upper:]' '[:lower:]')

# Random digits helper
rand_digits() {
  local n=$1
  LC_ALL=C tr -dc '0-9' < /dev/urandom | head -c "$n"
}

rand_range() {
  echo $(( (RANDOM % ($2 - $1 + 1)) + $1 ))
}

pick() {
  local arr=("$@")
  echo "${arr[RANDOM % ${#arr[@]}]}"
}

generate_iban() {
  case "$COUNTRY" in
    sy|syria)
      # Syria: SY## #### #### #### #### ####  (24 chars, 2 letter + 2 check + 20 digits)
      echo "SY$(rand_digits 22)"
      ;;
    eg|egypt)
      # Egypt: EG## #### #### #### #### #### ### (29 chars)
      echo "EG$(rand_digits 27)"
      ;;
    bd|bangladesh)
      # Bangladesh: No IBAN system — generate a local account number
      echo "BD$(rand_digits 16)"
      ;;
    ng|nigeria)
      # Nigeria: No IBAN — NUBAN format (10 digits)
      local banks=("044" "058" "011" "033" "032" "030" "050" "070")
      echo "$(pick "${banks[@]}")$(rand_digits 7)"
      ;;
    pk|pakistan)
      # Pakistan: PK## AAAA #### #### #### #### (24 chars)
      local banks=("ALFH" "HABB" "MUCB" "NBPA" "SCBL" "UNIL" "BAHL" "MEZN")
      echo "PK$(rand_digits 2)$(pick "${banks[@]}")$(rand_digits 16)"
      ;;
    gb|uk)
      # UK: GB## AAAA #### #### #### ## (22 chars)
      local banks=("NWBK" "HBUK" "BARC" "LOYD" "MIDL")
      echo "GB$(rand_digits 2)$(pick "${banks[@]}")$(rand_digits 14)"
      ;;
    *)
      echo "Unknown country: $COUNTRY (use: sy eg bd ng pk gb)" && exit 1
      ;;
  esac
}

generate_phone() {
  case "$COUNTRY" in
    sy|syria)
      # +963 9XX XXX XXX (mobile)
      echo "+963 9$(rand_digits 2) $(rand_digits 3) $(rand_digits 3)"
      ;;
    eg|egypt)
      # +20 1X XXXX XXXX (mobile)
      local prefix=$(pick "0" "1" "2" "5")
      echo "+20 1${prefix} $(rand_digits 4) $(rand_digits 4)"
      ;;
    bd|bangladesh)
      # +880 1XXX XXXXXX (mobile)
      local prefix=$(pick "3" "4" "5" "6" "7" "8" "9")
      echo "+880 1${prefix}$(rand_digits 2) $(rand_digits 6)"
      ;;
    ng|nigeria)
      # +234 8XX XXX XXXX (mobile)
      local prefix=$(pick "03" "06" "07" "08" "09" "10" "13" "14")
      echo "+234 8${prefix} $(rand_digits 3) $(rand_digits 4)"
      ;;
    pk|pakistan)
      # +92 3XX XXXXXXX (mobile)
      local prefix=$(pick "00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32" "33" "34" "35" "36" "37" "38" "39" "40" "41" "42" "43" "44" "45" "46" "47" "48" "49")
      echo "+92 3${prefix} $(rand_digits 7)"
      ;;
    gb|uk)
      # +44 7XXX XXXXXX (mobile)
      local prefix=$(pick "400" "411" "457" "500" "521" "590" "700" "770" "800" "911")
      echo "+44 7${prefix} $(rand_digits 6)"
      ;;
    *)
      echo "Unknown country: $COUNTRY (use: sy eg bd ng pk gb)" && exit 1
      ;;
  esac
}

generate_address() {
  local num=$(rand_range 1 250)
  case "$COUNTRY" in
    sy|syria)
      local streets=("Al-Thawra Street" "Baghdad Street" "Straight Street" "Al-Hamidiyah" "Maysaloun Street" "Port Said Street" "Al-Jalaa Street" "Ibrahim Hanano Street")
      local cities=("Damascus" "Aleppo" "Homs" "Latakia" "Hama" "Tartus" "Deir ez-Zor" "Raqqa")
      local areas=("Abu Rummaneh" "Malki" "Mezzeh" "Sha'lan" "Baramkeh" "Muhajirin" "Bab Touma" "Kafr Souseh")
      echo "${num} $(pick "${streets[@]}"), $(pick "${areas[@]}"), $(pick "${cities[@]}"), Syria"
      ;;
    eg|egypt)
      local streets=("Tahrir Street" "Corniche El Nil" "26th of July Street" "Salah Salem Road" "El Merghany Street" "Ahmed Orabi Street" "Ramsis Street" "El Haram Street")
      local cities=("Cairo" "Alexandria" "Giza" "Luxor" "Aswan" "Mansoura" "Tanta" "Port Said")
      local areas=("Zamalek" "Maadi" "Heliopolis" "Dokki" "Mohandessin" "Nasr City" "Garden City" "Downtown")
      echo "${num} $(pick "${streets[@]}"), $(pick "${areas[@]}"), $(pick "${cities[@]}"), Egypt"
      ;;
    bd|bangladesh)
      local streets=("Mirpur Road" "Dhanmondi Road" "Gulshan Avenue" "Satmasjid Road" "Green Road" "Elephant Road" "Banani Road" "Mohakhali Road")
      local cities=("Dhaka" "Chittagong" "Sylhet" "Rajshahi" "Khulna" "Rangpur" "Comilla" "Gazipur")
      local areas=("Dhanmondi" "Gulshan" "Banani" "Uttara" "Mirpur" "Mohammadpur" "Motijheel" "Tejgaon")
      echo "${num} $(pick "${streets[@]}"), $(pick "${areas[@]}"), $(pick "${cities[@]}"), Bangladesh"
      ;;
    ng|nigeria)
      local streets=("Broad Street" "Marina Road" "Awolowo Road" "Adeola Odeku Street" "Ademola Adetokunbo" "Allen Avenue" "Ozumba Mbadiwe" "Tafawa Balewa Square")
      local cities=("Lagos" "Abuja" "Kano" "Ibadan" "Port Harcourt" "Benin City" "Kaduna" "Enugu")
      local areas=("Victoria Island" "Ikoyi" "Lekki" "Ikeja" "Surulere" "Yaba" "Ajah" "Wuse")
      echo "${num} $(pick "${streets[@]}"), $(pick "${areas[@]}"), $(pick "${cities[@]}"), Nigeria"
      ;;
    pk|pakistan)
      local streets=("Mall Road" "Jinnah Avenue" "Shahrah-e-Faisal" "GT Road" "Murree Road" "Tariq Road" "University Road" "Clifton Road")
      local cities=("Karachi" "Lahore" "Islamabad" "Rawalpindi" "Faisalabad" "Peshawar" "Multan" "Quetta")
      local areas=("Gulberg" "DHA" "Clifton" "F-7" "G-9" "Blue Area" "Saddar" "Model Town")
      echo "${num} $(pick "${streets[@]}"), $(pick "${areas[@]}"), $(pick "${cities[@]}"), Pakistan"
      ;;
    gb|uk)
      local streets=("High Street" "Church Lane" "Station Road" "Victoria Road" "Park Avenue" "King Street" "Queen Street" "Mill Lane")
      local cities=("London" "Manchester" "Birmingham" "Leeds" "Bristol" "Liverpool" "Edinburgh" "Glasgow")
      local areas=("Kensington" "Shoreditch" "Camden" "Islington" "Brixton" "Hackney" "Peckham" "Dalston")
      local postcodes=("SW1A 1AA" "EC2R 8AH" "W1D 3SE" "N1 9GU" "SE1 7PB" "E1 6AN" "NW1 4NR" "WC2N 5DU")
      echo "${num} $(pick "${streets[@]}"), $(pick "${areas[@]}"), $(pick "${cities[@]}") $(pick "${postcodes[@]}"), United Kingdom"
      ;;
    *)
      echo "Unknown country: $COUNTRY (use: sy eg bd ng pk gb)" && exit 1
      ;;
  esac
}

case "$KIND" in
  iban|i)
    RESULT=$(generate_iban)
    ;;
  phone|p|tel)
    RESULT=$(generate_phone)
    ;;
  address|a|addr)
    RESULT=$(generate_address)
    ;;
  *)
    echo "Unknown type: $KIND (use: iban phone address)" && exit 1
    ;;
esac

echo -n "$RESULT" | pbcopy
echo "Copied: $RESULT"
