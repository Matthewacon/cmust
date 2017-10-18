#!/bin/bash
read -r -d '' USAGE << EOUSAGE
Usage: ./cmus_tools.sh [OPTIONS ...]\n\n

toggle		Toggle commands:\n
 - play			Toggles play or pause\n
 - pause		Toggles play or pause\n
 - repeat		Toggles repeat functionality\n
 - repeatC		Toggles repeat for currently active song\n
 - shuffle		Toggle shuffle\n\n

inc / dec	Increment and decrement commands:\n
 - vol			Increase or decrease volume\n
 - seek			Seek forward or barkwards\n\n

prev		Plays previous song\n
next		Plays next song\n
stop		Stops the player\n
EOUSAGE

RED=$(tput setaf 1)

args=($@)
cmus_status=$(cmus-remote -Q)
playStatus=$(echo $cmus_status | grep -i status | awk -F"status" '{print $2}')
cmus_status=($cmus_status)

isPlayable() {
 ([[ "$playStatus" == *"playing"* ]] || [[ "$playStatus" == *"paused"* ]]) && echo true && return;
 echo false
}

cut_array() {
 local lArgs=($@)
 local sIndex=${lArgs[0]}
 local eIndex=${lArgs[1]}
 printf '%b ' "\nStarting Index: $sIndex"
 printf '%b ' "\nEnding Index: $eIndex"
 local new_args=""
 [[ $sIndex -gt $eIndex ]] && echo -1 && return;
 for index in ${!lArgs[@]}; do
  ([[ $index == "0" ]] || [[ $index == "1" ]]) && continue;
  ([[ $(($index-2)) -lt $sIndex ]] || [[ $(($index-2)) -gt $eIndex ]]) && printf '%b ' "Skipping: $index" && continue;
  printf '%b ' "Index: $index"
  new_args=$new_args" ${lArgs[$index]}"
 done
 echo $new_args
}

index_of() {
# local arg=$1
 local arr=($@)
 #printf "${arr[*]}"
# printf "SIZE: "${#arr[@]}"    "
 for i in "${!arr[@]}"; do
  ([[ $i != 0 ]] && [[ ${arr[$i]} == *"$1"* ]]) && echo $(($i-1)) && return
 done
 echo -1
}

last_arg() {
 local lArgs=($@)
 echo ${lArgs[$((${#lArgs[@]}-1))]}
}

remove_arg() {
 local new_args=""
 for ((i=0; i<${#args[@]}; i=$i+1)); do
  if [[ $i > 0 ]]; then
   new_args=$new_args" ${args[$i]}"
  fi
 done
 echo $new_args
}

toggle() {
 local lArgs=($@)
 printf '%b ' "Toggle args: $@"
 case "${lArgs[0]}" in
  "play") 
 if [[ $playStatus == *"playing"* ]]; then
  cmus-remote -u
 elif [[ $playStatus == *"paused"* ]]; then
  cmus-remote -p
 else
  printf "${RED}Queue empty!"
 fi;;
  *) printf '%b ' "Printing";;
 esac
}

inc_dec() {
 local lArgs=($@)
 local volume=${cmus_status[$(($(index_of vol_right ${cmus_status[*]})+1))]}
 local duration=""
 local seek=""
 local offset=""
 # GOOGLE: Bash 0 > -1 == false?
 #printf "$([[ $(index_of inc $@) > -1 ]] && echo Bonjour)"
 if [[ $(index_of inc $@) -gt -1 ]]; then
  offset="+"
 elif [[ $(index_of dec $@) -gt -1 ]]; then
  offset="-"
 fi
 offset=$offset"$(last_arg $@)"
 if [[ $(isPlayable) ]]; then
  duration=${cmus_status[$(($(index_of duration ${cmus_status[*]})+1))]}
  seek=${cmus_status[$(($(index_of position ${cmus_status[*]})+1))]}
 fi
 eval $(
 case ${lArgs[$(($(index_of $([[ $offset = *"+"* ]] && echo "inc"; [[ $offset = *"-"* ]] && echo "dec";) $@)+1))]} in 
   ("vol") echo "cmus-remote --vol "$(($seek$offset));;
   ("seek") echo "cmus-remote --seek "$(($seek$offset));;
  esac
 )
}

#echo $(inc_dec dec seek 10)
#echo ${cmus_status[$(($(index_of position ${cmus_status[*]})+1))]}
for ((i=0; i<${#args[@]}; i=$i+1)); do
 case ${args[$i]} in
  "prev") cmus-remote -r;;
  "next") cmus-remote -n;;
  "stop") cmus-remote -s;;
  "toggle") printf '%b ' "TOGGLED\n" && toggle $(cut_array 1 $((${#args[@]}-1)) $args);;
  "inc") inc_dec $@;;
  "dec") inc_dec $@;;
  *) printf '%b ' "${RED}Unknown command: ${args[$i]}\n"; echo -e $USAGE;;
 esac
done

