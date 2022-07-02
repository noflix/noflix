#!/usr/local/bin/bash

# Tested: GNU bash, version 5.1.16(1)-release (x86_64-apple-darwin21.1.0)
# Warning: Using old bash versions may result in errors (floats are unsupported in older bash versions) 

# CONFIG
PAGE_NUMBER="1" # Default: 1
PLAYER="vlc" # TODO
MT="0.0001" # Menu refresh time

# TEXT AND MENU COLORS
N='\033[0m' # No color
R='\033[1;31m'  # Red
G='\033[0;32m'  # Green
Y='\033[1;33m'  # Yellow
C='\033[1;36m'  # Cyan
S='\033[1;37m\033[7;36m' #Selected (menu)

# MENU
function print_menu() # selected_item, ...menu_items
{
  local function_arguments=($@)

  local selected_item="$1"
  local menu_items=(${function_arguments[@]:1})
  local menu_size="${#menu_items[@]}"

  for (( i = 0; i < $menu_size; ++i ))
  do
    if [ "$i" = "$selected_item" ]
    then
      echo -e "$G-> $N$S${menu_items[i]}$N"
    else
      echo "   ${menu_items[i]}"
    fi
  done
}

function menu() # selected_item, ...menu_items
{
  local function_arguments=($@)

  local selected_item="$1"
  local menu_items=(${function_arguments[@]:1})
  local menu_size="${#menu_items[@]}"
  local menu_limit=$((menu_size - 1))

  clear
  print_menu "$selected_item" "${menu_items[@]}"
  
  while read -rsn 1 input
  do
    case "$input"
    in
      $'\x1B') # ESC ASCII code (https://dirask.com/posts/ASCII-Table-pJ3Y0j)
        read -t ${MT} -rsn 1 input
        if [ "$input" = "[" ]  # occurs before arrow code
        then
          read -t ${MT} -rsn 1 input
          case "$input"
          in
            A) # Up Arrow
              if [ "$selected_item" -ge 1 ]
              then
                selected_item=$((selected_item - 1))
                printf "\033c" # clear
                print_menu "$selected_item" "${menu_items[@]}"
              fi
              ;;
            B) # Down Arrow
              if [ "$selected_item" -lt "$menu_limit" ]
              then
                selected_item=$((selected_item + 1))
                printf "\033c" # clear
                print_menu "$selected_item" "${menu_items[@]}"
              fi
              ;;
          esac
        fi
        read -t ${MT} -rsn 5 # flushing stdin
        ;;
      "") # Enter key
        return "$selected_item"
        ;;
    esac
  done
}

# NOTFLIX
query=$(printf '%s' "$*" | tr ' ' '+')
stack=$(curl -s https://1337x.wtf/search/$query/$PAGE_NUMBER/ | grep -Eo "torrent\/[0-9]{7}\/[a-zA-Z0-9?%-]*/")

if [ -z "$stack" ]; then
  echo -e "\nnotflix.sh: ${R}Can't find ${Y}${*}${N}"
  echo -e "\n${C}*hint*${N} Narrow the notflix search for better results ${C}*hint*${N}\n"
  exit -1
else
  menu "0" "${stack[@]}"
  menu_result="$?"
fi

c=0
for i in ${stack[@]}; do
  if [ "$c" == "$menu_result" ]; then
    echo -e "\nSelected: $i"
    # TODO check for multiple/other magnets 
    magnet=$(curl -s https://1337x.wtf/"$i" | grep -Eo "magnet:\?xt=urn:btih:[a-zA-Z0-9]*" | head -n 1 )
  fi
  ((c++))
done

# TODO error magnet not found maybe
echo -e "\nMagnet: ${magnet}" 

# PEERFLIX - TODO players
peerflix ${magnet} --vlc -- -f
exit 0
