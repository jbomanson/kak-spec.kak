kak_quote () {
    local delimiter=""
    local string
    for string
    do
        printf "%s" "$delimiter"
        printf "'"
        printf "%s" "$string" | sed "s/'/''/g"
        printf "'"
        delimiter=" "
    done
    printf "\n"
}
