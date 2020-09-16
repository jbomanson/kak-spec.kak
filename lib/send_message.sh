send_message () {
    if test -w "$KAK_SPEC_DIR/fifo"; then
        {
            printf "%s\n" "$1" | wc -l
            printf "%s\n" "$1"
        } >"$KAK_SPEC_DIR/fifo"
    fi
}
