send_message () {
    if test -w "$SCRATCH_UNIT_TEST_DIR/fifo"; then
        {
            printf "%s\n" "$1" | wc -l
            printf "%s\n" "$1"
        } >"$SCRATCH_UNIT_TEST_DIR/fifo"
    fi
}
