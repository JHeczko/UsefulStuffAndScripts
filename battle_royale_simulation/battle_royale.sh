#!/usr/bin/env bash
width=0
height=0
players=0
archers=0
knights=0
cavalry=0
mages=0
speed=1.5

# HP settings
archers_health=100
knights_health=200
cavalry_health=150
mages_health=100

# Damage settings
archers_damage=25
knights_damage=40
cavalry_damage=40
mages_damage=50

# Range settings
archers_range=4
knights_range=1
cavalry_range=1
mages_range=2

# Move range settings
archers_moverange=1
knights_moverange=1
cavalry_moverange=2
mages_moverange=1

# Colors
RED=$'\033[31m'
GREEN=$'\033[32m'
GREY=$'\033[90m'
RESET=$'\033[0m'
BOLD=$'\033[1m'

declare -a player_x
declare -a player_y
declare -a player_class
declare -a player_hp
declare -a player_alive
declare -a player_moved
declare -a player_hit

# ============================================
# HELPER FUNCTIONS
# ============================================
print_usage() {
    echo "Usage: $0 -x WIDTH -y HEIGHT [-p PLAYERS] [-a ARCHERS] [-k KNIGHTS] [-c CAVALRY] [-m MAGES]"
}

print_help() {
    echo -e "${BOLD}BATTLE ROYALE SIMULATOR - HELP${RESET}"
    echo "======================================================================"
    echo "Usage: $0 -x <width> -y <height> [options]"
    echo ""
    echo "REQUIRED ARGUMENTS:"
    echo "  -x WIDTH      Set the width of the battlefield."
    echo "  -y HEIGHT     Set the height of the battlefield."
    echo ""
    echo "OPTIONAL ARGUMENTS:"
    echo "  -p PLAYERS    Total number of players in the simulation."
    echo "  -a ARCHERS    Specify number of Archer units (A)."
    echo "  -k KNIGHTS    Specify number of Knight units (K)."
    echo "  -c CAVALRY    Specify number of Cavalry units (C)."
    echo "  -m MAGES      Specify number of Mage units (M)."
    echo ""
    echo "AUTOMATIC DISTRIBUTION LOGIC:"
    echo "  • If all classes (-a, -k, -c, -m) are provided, the -p value is ignored"
    echo "    and automatically recalculated as the sum of all classes."
    echo "  • If the sum of specified classes is greater than -p, the player count"
    echo "    will be increased to match that sum."
    echo "  • If -p is greater than the sum of specified classes, the remaining"
    echo "    slots will be automatically filled by distributing them among the"
    echo "    classes that were not explicitly set (left at 0)."
    echo "  • If only -p is given, players are distributed equally among all classes."
    echo ""
    echo "UNIT STATISTICS (HP | DMG | RNG | MOVE):"
    echo "  Archers  : $archers_health  | $archers_damage  | $archers_range   | $archers_moverange"
    echo "  Knights  : $knights_health  | $knights_damage  | $knights_range   | $knights_moverange"
    echo "  Cavalry  : $cavalry_health  | $cavalry_damage  | $cavalry_range   | $cavalry_moverange"
    echo "  Mages    : $mages_health  | $mages_damage  | $mages_range   | $mages_moverange"
    echo "======================================================================"
    exit 0
}

type_to_continue() {
    echo -n "Press any key to continue..."
    read -n 1 -s
    echo
}

get_max_hp() {
    case $1 in
        A) echo $archers_health ;;
        K) echo $knights_health ;;
        C) echo $cavalry_health ;;
        M) echo $mages_health ;;
    esac
}

get_stat() {
    local class=$1 
    local stat=$2
    case $class in
        A) [[ $stat == "damage" ]] && echo $archers_damage || ([[ $stat == "range" ]] && echo $archers_range || echo $archers_moverange);;
        K) [[ $stat == "damage" ]] && echo $knights_damage || ([[ $stat == "range" ]] && echo $knights_range || echo $knights_moverange);;
        C) [[ $stat == "damage" ]] && echo $cavalry_damage || ([[ $stat == "range" ]] && echo $cavalry_range || echo $cavalry_moverange);;
        M) [[ $stat == "damage" ]] && echo $mages_damage   || ([[ $stat == "range" ]] && echo $mages_range   || echo $mages_moverange);;
    esac
}

# ============================================
# CORE GAME FUNCTIONS
# ============================================

add_players() {
    local idx=0
    local occupied_positions=()
    
    is_occupied() {
        local x=$1; local y=$2
        for pos in "${occupied_positions[@]}"; do
            [[ "$pos" == "${x},${y}" ]] && return 0
        done
        return 1
    }
    
    add_class_players() {
        local count=$1; local class=$2; local hp=$3
        local i
        for ((i=0; i<count; i++)); do
            local x y
            while true; do
                x=$((RANDOM % width))
                y=$((RANDOM % height))
                ! is_occupied $x $y && break
            done
            player_x[$idx]=$x
            player_y[$idx]=$y
            player_class[$idx]=$class
            player_hp[$idx]=$hp
            player_alive[$idx]=1
            occupied_positions+=("${x},${y}")
            ((idx++))
        done
    }
    
    add_class_players $archers "A" $archers_health
    add_class_players $knights "K" $knights_health
    add_class_players $cavalry "C" $cavalry_health
    add_class_players $mages "M" $mages_health
}

print_map() {
    tput cup 0 0
    echo "╔$(printf '═%.0s' $(seq 1 $((width*3+1))))╗"
    
    local y x i
    for ((y=0; y<height; y++)); do
        echo -n "║ "
        for ((x=0; x<width; x++)); do
            local found=0
            local pid=""
            
            for ((i=0; i<${#player_x[@]}; i++)); do
                if [[ ${player_alive[$i]} -eq 1 && ${player_x[$i]} -eq $x && ${player_y[$i]} -eq $y ]]; then
                    pid=$i
                    found=1
                    break
                fi
            done
            
            if [[ $found -eq 1 ]]; then
                # Tylko numer, bez koloru na mapie
                printf "%02d " "$pid"
            else
                echo -n ".  "
            fi
        done
        echo "║"
    done
    echo "╚$(printf '═%.0s' $(seq 1 $((width*3+1))))╝"
}

print_stats() {
    echo "══════════════════════════════════════════════════════════════════════"
    local cols=4
    local count=0
    
    for ((i=0; i<${#player_alive[@]}; i++)); do
        local p_class=${player_class[$i]}
        
        if [[ ${player_alive[$i]} -eq 1 ]]; then
            local max_hp=$(get_max_hp "$p_class")
            local curr_hp=${player_hp[$i]}
            
            # LOGIKA KOLORÓW STATYSTYK
            if [[ ${player_hit[$i]} -eq 1 ]]; then
                # Dostał hita = CZERWONY
                printf "%b%02d: %3d/%-3d (%s)%b  " "$RED" "$i" "$curr_hp" "$max_hp" "$p_class" "$RESET"
            else
                # Żyje i bezpieczny = ZIELONY
                printf "%b%02d: %3d/%-3d (%s)%b  " "$GREEN" "$i" "$curr_hp" "$max_hp" "$p_class" "$RESET"
            fi
        else
            # Martwy = SZARY
            printf "%b%02d: DEAD          %b  " "$GREY" "$i" "$RESET"
        fi
        
        ((count++))
        if [[ $((count % cols)) -eq 0 ]]; then echo ""; fi
    done
    
    if [[ $((count % cols)) -ne 0 ]]; then echo ""; fi
    echo "══════════════════════════════════════════════════════════════════════"
}

find_target() {
    local attacker_idx=$1
    local ax=${player_x[$attacker_idx]}
    local ay=${player_y[$attacker_idx]}
    local range=$(get_stat ${player_class[$attacker_idx]} range)
    
    # UP
    for ((step=1; step<=range; step++)); do
        local cy=$((ay - step)) 
        [[ $cy -ge 0 ]] || break
        local k 
        for ((k=0; k<${#player_x[@]}; k++)); do
            [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $ax && ${player_y[$k]} -eq $cy ]] && echo $k && return 0
        done
    done
    # DOWN
    for ((step=1; step<=range; step++)); do
        local cy=$((ay + step))
        [[ $cy -lt $height ]] || break
        local k
        for ((k=0; k<${#player_x[@]}; k++)); do
            [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $ax && ${player_y[$k]} -eq $cy ]] && echo $k && return 0
        done
    done
    # LEFT
    for ((step=1; step<=range; step++)); do
        local cx=$((ax - step)) 
        [[ $cx -ge 0 ]] || break
        local k
        for ((k=0; k<${#player_x[@]}; k++)); do
            [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $cx && ${player_y[$k]} -eq $ay ]] && echo $k && return 0
        done
    done
    # RIGHT
    for ((step=1; step<=range; step++)); do
        local cx=$((ax + step))
        [[ $cx -lt $width ]] || break
        local k 
        for ((k=0; k<${#player_x[@]}; k++)); do
            [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $cx && ${player_y[$k]} -eq $ay ]] && echo $k && return 0
        done
    done
    
    echo -1 
    return 1
}

attack() {
    local idx=$1
    local target=$(find_target $idx)
    
    if [[ $target -ne -1 ]]; then
        local dmg=$(get_stat ${player_class[$idx]} damage)
        player_hp[$target]=$((${player_hp[$target]} - dmg))
        player_hit[$target]=1
        if [[ ${player_hp[$target]} -le 0 ]]; then
            player_alive[$target]=0
        fi
        return 0
    fi
    return 1 
}

move_player() {
    local idx=$1
    local range=$(get_stat "${player_class[$idx]}" moverange)
    local ox=${player_x[$idx]}
    local oy=${player_y[$idx]}
    local dirs=(0 1 2 3)
    
    # randommizig the array
    for ((k=3; k>0; k--)); do
        local j=$((RANDOM % (k+1))) 
        local t=${dirs[k]}
        dirs[k]=${dirs[j]}
        dirs[j]=$t
    done

    for d in "${dirs[@]}"; do
        local nx=$ox 
        local ny=$oy
        case $d in
            0) ny=$((ny - range));; 
            1) ny=$((ny + range));;
            2) nx=$((nx - range));; 
            3) nx=$((nx + range));;
        esac
        
        [[ $nx -lt 0 || $nx -ge $width || $ny -lt 0 || $ny -ge $height ]] && continue
        
        local occ=0
        local k

        # checking collision
        for ((k=0; k<${#player_x[@]}; k++)); do
            if [[ ${player_alive[$k]} -eq 1 && $k -ne $idx && ${player_x[$k]} -eq $nx && ${player_y[$k]} -eq $ny ]];then
                occ=1 
                break
            fi
        done
        
        [[ $occ -eq 1 ]] && continue

        player_x[$idx]=$nx 
        player_y[$idx]=$ny
        player_moved[$idx]=1
        return
    done
}

simulation() {
    local round=1
    tput clear
    
    print_map
    echo " Round: 0 (START) | Alive: $players"
    print_stats
    type_to_continue

    tput clear


    while true; do
        local alive=0
        for p in "${player_alive[@]}"; do [[ $p -eq 1 ]] && ((alive++)); done
        
        if [[ $alive -le 1 ]]; then
            tput clear
            print_map
            echo -e "\n    ${GREEN}BATTLE ROYALE COMPLETE!${RESET}"
            for ((i=0; i<${#player_alive[@]}; i++)); do
                if [[ ${player_alive[$i]} -eq 1 ]]; then
                    echo "Winner: Player $i (${player_class[$i]})"
                    break
                fi
            done
            break
        fi

        local i
        for ((i=0; i<${#player_alive[@]}; i++)); do
            if [[ ${player_alive[$i]} -eq 1 ]]; then
                if ! attack $i; then
                    move_player $i
                fi
            fi
        done
        
        print_map
        printf " Round: %d | Alive: %02d\n" "$round" "$alive"
        print_stats
        
        ((round++))
        sleep $speed

        local i
        for ((i=0; i<${#player_alive[@]}; i++)); do
            player_moved[$i]=0
            player_hit[$i]=0
        done
    done
}

# ============================================
# MAIN
# ============================================
for var in "$@"; do 
    if [[ $var == "-h" ]]; then 
    print_help; 
    fi; 
done

while getopts "x:y:p:a:k:c:m:" opt; do
    case $opt in
        x) width=$OPTARG ;; 
        y) height=$OPTARG ;; 
        p) players=$OPTARG ;;
        a) archers=$OPTARG ;; 
        k) knights=$OPTARG ;; 
        c) cavalry=$OPTARG ;; 
        m) mages=$OPTARG ;;
        *)  print_usage; exit 1;;  
    esac
done

if [[ $players -lt 0 || $height -le 0 || $width -le 0 ]]; then 
    echo "Error params. "
    print_usage
    exit 1
fi

sum=$((archers + knights + cavalry + mages))

if [[ $archers -ne 0 && $knights -ne 0 && $cavalry -ne 0 && $mages -ne 0 ]]; then
    if [[ $players -ne 0 ]]; then
        echo "[WARNING] Changing player size to $sum, because program received number of all classes"
        players=$sum
    else
        players=$sum
    fi
fi

if [[ $sum -gt $players ]]; then 
    echo "[WARNING] Too many classes. Changing player size to $sum"
    players=$sum
fi

if [[ $((width*height)) -le $players ]]; then 
    echo "Map too small" 
    exit 1
fi


# Auto-distribution logic
remaining=$((players - sum))
classes=(archers knights cavalry mages)
zero_classes=0
for cls in "${classes[@]}"; do 
    [[ ${!cls} -eq 0 ]] && ((zero_classes++))
done

if [[ $sum -eq 0 ]]; then
    base=$((players/4))
    rest=$((players%4))
    archers=$base; knights=$base; cavalry=$base; mages=$base
    for cls in archers knights cavalry mages; do
        [[ $rest -le 0 ]] && break
        printf -v "$cls" "%d" "$(( ${!cls} + 1 ))"
        ((rest--))
    done
else
    if [[ $zero_classes -gt 0 ]]; then
        base=$((remaining/zero_classes)) 
        rest=$((remaining%zero_classes))
        for cls in "${classes[@]}"; do
            if [[ ${!cls} -eq 0 ]]; then
                printf -v "$cls" "%d" "$base"
                [[ $rest -gt 0 ]] && printf -v "$cls" "%d" "$((base+1))" && ((rest--))
            fi
        done
    fi
fi

echo "Battle Royale setup:"
echo "Width of map : $width"
echo "Height of map : $height"
echo "Players : $players"
echo "Archers : $archers"
echo "Knights : $knights"
echo "Cavalry : $cavalry"
echo "Mages   : $mages"
type_to_continue


cleanup() {
    tput cnorm
    exit 0
}

trap cleanup SIGINT

tput civis
add_players
simulation
tput cnorm