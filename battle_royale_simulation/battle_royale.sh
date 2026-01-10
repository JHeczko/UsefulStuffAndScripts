#!/usr/bin/env bash
width=0
height=0
players=0
archers=0
knights=0
cavalry=0
mages=0

archers_health=100
knights_health=200
cavalry_health=150
mages_health=100

archers_damage=25
knights_damage=40
cavalry_damage=40
mages_damage=50

archers_range=1
knights_range=1
cavalry_range=1
mages_range=1

archers_moverange=1
knights_moverange=1
cavalry_moverange=2
mages_moverange=1

RED=$'\033[31m'
BLUE=$'\033[34m'
RESET=$'\033[0m'



# Arrays to store player data
declare -a player_x
declare -a player_y
declare -a player_class
declare -a player_hp
declare -a player_alive
declare -a player_moved
declare -a player_hit

# ============================================
# PRINT FUNCTIONS
# ============================================
print_help() {
    echo "Usage: $0 -p PLAYERS -x WIDTH -y HEIGHT [-a ARCHERS] [-k KNIGHTS] [-c CAVALRY] [-m MAGES]"
    echo ""
    echo "Options:"
    echo "  -x   Width of map (required)"
    echo "  -y   Height of map (required)"
    echo "  -p   Total number of players (required)"
    echo "  -a   Number of archers"
    echo "  -k   Number of knights"
    echo "  -c   Number of cavalry"
    echo "  -m   Number of mages"
    echo "  -h,  Show this help message"
    exit 0
}

type_to_continue() {
    echo -n "Press any key to continue..."
    read -n 1 -s
    echo
}

# ============================================
# GAME FUNCTIONS
# ============================================

# Function to add players to the map
add_players() {
    local idx=0
    local occupied_positions=()
    
    # Function to check if position is occupied
    is_occupied() {
        local x=$1
        local y=$2
        for pos in "${occupied_positions[@]}"; do
            if [[ "$pos" == "${x},${y}" ]]; then
                return 0
            fi
        done
        return 1
    }
    
    # Function to add a player of specific class
    add_class_players() {
        local count=$1
        local class=$2
        local hp=$3
        
        local i
        for ((i=0; i<count; i++)); do
            local x y
            while true; do
                x=$((RANDOM % width))
                y=$((RANDOM % height))
                if ! is_occupied $x $y; then
                    break
                fi
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
    
    # Add all classes
    add_class_players $archers "A" $archers_health
    add_class_players $knights "K" $knights_health
    add_class_players $cavalry "C" $cavalry_health
    add_class_players $mages "M" $mages_health
}

# Function to print the map
print_map() {
    # Clear screen and move cursor to top
    tput clear
    tput cup 0 0
    
    echo "╔$(printf '═%.0s' $(seq 1 $((width*2+1))))╗"
    
    local y x i
    for ((y=0; y<height; y++)); do
        echo -n "║ "
        for ((x=0; x<width; x++)); do
            local found=0
            
            # Check if there's a player at this position
            for ((i=0; i<${#player_x[@]}; i++)); do
                if [[ ${player_alive[$i]} -eq 1 && ${player_x[$i]} -eq $x && ${player_y[$i]} -eq $y ]]; then
                    if [[ ${player_hit[$i]} -eq 1 ]]; then
                        printf "%b " "${RED}${player_class[$i]}${RESET}"
                    elif [[ ${player_moved[$i]} -eq 1 ]]; then
                        echo -n "${BLUE}${player_class[$i]}${RESET} "
                    else
                        echo -n "${player_class[$i]} "
                    fi
                    found=1
                    break
                fi
            done
            
            if [[ $found -eq 0 ]]; then
                echo -n ". "
            fi
        done
        echo "║"
    done
    
    echo "╚$(printf '═%.0s' $(seq 1 $((width*2+1))))╝"
}

# Function to get player stats
get_stat() {
    local class=$1
    local stat=$2
    
    case $class in
        A)
            case $stat in
                damage) echo $archers_damage ;;
                range) echo $archers_range ;;
                moverange) echo $archers_moverange ;;
            esac
            ;;
        K)
            case $stat in
                damage) echo $knights_damage ;;
                range) echo $knights_range ;;
                moverange) echo $knights_moverange ;;
            esac
            ;;
        C)
            case $stat in
                damage) echo $cavalry_damage ;;
                range) echo $cavalry_range ;;
                moverange) echo $cavalry_moverange ;;
            esac
            ;;
        M)
            case $stat in
                damage) echo $mages_damage ;;
                range) echo $mages_range ;;
                moverange) echo $mages_moverange ;;
            esac
            ;;
    esac
}

# Function to find closest enemy
find_target() {
    local attacker_idx=$1
    local ax=${player_x[$attacker_idx]}
    local ay=${player_y[$attacker_idx]}
    local range=$(get_stat ${player_class[$attacker_idx]} range)
    
    # Check 4 directions: up, down, left, right
    # Up (y decreases)
    for ((step=1; step<=range; step++)); do
        local check_y=$((ay - step))
        if [[ $check_y -ge 0 ]]; then
            local k
            for ((k=0; k<${#player_x[@]}; k++)); do
                if [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $ax && ${player_y[$k]} -eq $check_y ]]; then
                    echo $k
                    return 0
                fi
            done
        fi
    done
    
    # Down (y increases)
    for ((step=1; step<=range; step++)); do
        local check_y=$((ay + step))
        if [[ $check_y -lt $height ]]; then
            local k
            for ((k=0; k<${#player_x[@]}; k++)); do
                if [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $ax && ${player_y[$k]} -eq $check_y ]]; then
                    echo $k
                    return 0
                fi
            done
        fi
    done
    
    # Left (x decreases)
    for ((step=1; step<=range; step++)); do
        local check_x=$((ax - step))
        if [[ $check_x -ge 0 ]]; then
            local k
            for ((k=0; k<${#player_x[@]}; k++)); do
                if [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $check_x && ${player_y[$k]} -eq $ay ]]; then
                    echo $k
                    return 0
                fi
            done
        fi
    done
    
    # Right (x increases)
    for ((step=1; step<=range; step++)); do
        local check_x=$((ax + step))
        if [[ $check_x -lt $width ]]; then
            local k;
            for ((k=0; k<${#player_x[@]}; k++)); do
                if [[ ${player_alive[$k]} -eq 1 && $k -ne $attacker_idx && ${player_x[$k]} -eq $check_x && ${player_y[$k]} -eq $ay ]]; then
                    echo $k
                    return 0
                fi
            done
        fi
    done
    
    echo -1
    return 1
}

# Function to perform attack
attack() {
    local attacker_idx=$1
    local target_idx=$(find_target $attacker_idx)
    
    if [[ $target_idx -eq -1 || -z "$target_idx" ]]; then
        return 0
    fi
    
    local ax=${player_x[$attacker_idx]}
    local ay=${player_y[$attacker_idx]}
    local tx=${player_x[$target_idx]}
    local ty=${player_y[$target_idx]}
    
    local damage=$(get_stat ${player_class[$attacker_idx]} damage)
    player_hp[$target_idx]=$((${player_hp[$target_idx]} - damage))
    player_hit[$target_idx]=1

    #echo "Player $attacker_idx (${player_class[$attacker_idx]}) at ($ax,$ay) attacks Player $target_idx (${player_class[$target_idx]}) at ($tx,$ty) for $damage damage!"

    if [[ ${player_hp[$target_idx]} -le 0 ]]; then
        player_alive[$target_idx]=0
        echo "Player $target_idx (${player_class[$target_idx]}) has been eliminated!"
    fi
    
    return 0
}

# Function to move player
move_player() {
    local idx=$1
    local moverange=$(get_stat "${player_class[$idx]}" moverange)

    local orig_x=${player_x[$idx]}
    local orig_y=${player_y[$idx]}

    # Kierunki: 0=up 1=down 2=left 3=right
    local directions=(0 1 2 3)

    # Fisher–Yates shuffle (losowa kolejność)
    local k j tmp
    for ((k=${#directions[@]}-1; k>0; k--)); do
        j=$((RANDOM % (k + 1)))
        tmp=${directions[k]}
        directions[k]=${directions[j]}
        directions[j]=$tmp
    done

    local dir
    for dir in "${directions[@]}"; do
        local new_x=$orig_x
        local new_y=$orig_y

        case $dir in
            0) new_y=$((new_y - moverange)) ;; # up
            1) new_y=$((new_y + moverange)) ;; # down
            2) new_x=$((new_x - moverange)) ;; # left
            3) new_x=$((new_x + moverange)) ;; # right
        esac

        # Bounds check
        [[ $new_x -lt 0 || $new_x -ge $width ]] && continue
        [[ $new_y -lt 0 || $new_y -ge $height ]] && continue

        # Occupied check
        local occupied=0
        local k
        for ((k=0; k<${#player_x[@]}; k++)); do
            if [[ ${player_alive[$k]} -eq 1 &&
                  $k -ne $idx &&
                  ${player_x[$k]} -eq $new_x &&
                  ${player_y[$k]} -eq $new_y ]]; then
                occupied=1
                break
            fi
        done

        [[ $occupied -eq 1 ]] && continue

        # ✅ RUCH WYKONANY
        player_x[$idx]=$new_x
        player_y[$idx]=$new_y
        # oznaczenie ostatnej akcji
        player_moved[$idx]=1

        # echo "Player $idx (${player_class[$idx]}) moved to ($new_x,$new_y)"
        return
    done

    # ❌ brak możliwego ruchu
    # echo "Player $idx (${player_class[$idx]}) cannot move"
}


# Main simulation function
simulation() {
    local round=1
    
    while true; do
        # Count alive players
        local alive_count=0
        local i;
        for ((i=0; i<${#player_alive[@]}; i++)); do
            [[ ${player_alive[$i]} -eq 1 ]] && ((alive_count++))
        done
        
        if [[ $alive_count -le 1 ]]; then
            print_map
            echo "═══════════════════════════════"
            echo "    BATTLE ROYALE COMPLETE!"
            echo "═══════════════════════════════"
            for ((i=0; i<${#player_alive[@]}; i++)); do
                if [[ ${player_alive[$i]} -eq 1 ]]; then
                    echo "Winner: Player $i (${player_class[$i]}) at (${player_x[$i]},${player_y[$i]}) with ${player_hp[$i]} HP!"
                    break
                fi
            done
            break
        fi
        
        # Each player takes action
        local i
        for ((i=0; i<${#player_alive[@]}; i++)); do            
            if [[ ${player_alive[$i]} -eq 1 ]]; then
                local action=$((RANDOM % 3))
                case $action in
                    0) # Attack only
                        attack $i
                        ;;
                    1) # Move only
                        move_player $i
                        ;;
                    2) # Both - attack AND move
                        attack $i
                        move_player $i
                        ;;
                esac
            fi
        done
        
        print_map
        echo "═══════════════════════════════"
        echo "Round $round - Alive: $alive_count"
        echo "═══════════════════════════════"
        
        ((round++))
        local i
        for ((i=0; i<${#player_alive[@]}; i++)); do
            player_moved[$i]=0
            player_hit[$i]=0
        done
        sleep 3
    done
}

# ============================================
# MAIN
# ============================================

# parsing help
for var in "$@"; do
    if [[ $var == "--help" || $var == "-h" ]]; then
        print_help  
        exit 0
    fi
done

# parsing rest args
while getopts "x:y:p:a:k:c:m:" opt; do
  case $opt in
    x) width=$OPTARG ;;
    y) height=$OPTARG ;;
    p) players=$OPTARG ;;
    a) archers=$OPTARG ;;
    k) knights=$OPTARG ;;
    c) cavalry=$OPTARG ;;
    m) mages=$OPTARG ;;
    *) echo "Invalid option"; exit 1 ;;
  esac
done

# validation
echo $players
if [[ $players -le 0 || $height -le 0 || $width -le 0 ]]; then
    echo "Error: -p -x -y must be provided and > 0"
    exit 1
fi



if [[ $((width*height)) -le $players ]];then
    echo "Error: players wont fit on map (map_width * map_height) < num_of_players"
    exit 1
fi

sum=$((archers + knights + cavalry + mages))

if [[ $sum -gt $players ]]; then
    echo "Error: sum of class counts above total players"
    exit 1
fi

# automaticly evenly distributing the num of classes
remaining=$((players - sum))
classes=(archers knights cavalry mages)

zero_classes=0
for cls in "${classes[@]}"; do
    [[ ${!cls} -eq 0 ]] && ((zero_classes++))
done

# if no class given
if [[ $sum -eq 0 ]]; then
    base=$((players / 4))
    rest=$((players % 4))

    archers=$base
    knights=$base
    cavalry=$base
    mages=$base

    for cls in archers knights cavalry mages; do
        [[ $rest -le 0 ]] && break
        printf -v "$cls" "%d" "$(( ${!cls} + 1 ))"
        ((rest--))
    done
# if some class given
else
    if [[ $zero_classes -gt 0 ]]; then
            base=$((remaining / zero_classes))
            rest=$((remaining % zero_classes))

            for cls in "${classes[@]}"; do
                if [[ ${!cls} -eq 0 ]]; then
                    printf -v "$cls" "%d" "$base"
                    if [[ $rest -gt 0 ]]; then
                        printf -v "$cls" "%d" "$((base + 1))"
                        ((rest--))
                    fi
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

tput civis
add_players
simulation