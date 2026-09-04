#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  TERMINAL QUERIES & CONTROLS
# ─────────────────────────────────────────────

# Get terminal size in characters → TERM_ROWS, TERM_COLS
term.size() {
    local _r _c
    read -r _r _c < <(stty size 2>/dev/null || echo "24 80")
    printf -v "${1:-TERM_ROWS}" '%s' "$_r"
    printf -v "${2:-TERM_COLS}" '%s' "$_c"
}

# Get terminal size in pixels → TERM_PX_H, TERM_PX_W
term.size_px() {
    local _resp
    IFS=';' read -rs -d t -p $'\e[14t' _resp 2>/dev/null
    _resp="${_resp#*;}"
    printf -v "${1:-TERM_PX_H}" '%s' "${_resp%;*}"
    printf -v "${2:-TERM_PX_W}" '%s' "${_resp#*;}"
}

# Get character cell size in pixels → CELL_H, CELL_W
term.cell_size() {
    local _resp
    IFS=';' read -rs -d t -p $'\e[16t' _resp 2>/dev/null
    _resp="${_resp#*;}"
    printf -v "${1:-CELL_H}" '%s' "${_resp%;*}"
    printf -v "${2:-CELL_W}" '%s' "${_resp#*;}"
}

# Get screen size in characters → SCREEN_ROWS, SCREEN_COLS
term.screen_size() {
    local _resp
    IFS=';' read -rs -d t -p $'\e[19t' _resp 2>/dev/null
    _resp="${_resp#*;}"
    printf -v "${1:-SCREEN_ROWS}" '%s' "${_resp%;*}"
    printf -v "${2:-SCREEN_COLS}" '%s' "${_resp#*;}"
}

# Get screen size in pixels → SCREEN_PX_H, SCREEN_PX_W
term.screen_size_px() {
    local _resp
    IFS=';' read -rs -d t -p $'\e[15t' _resp 2>/dev/null
    _resp="${_resp#*;}"
    printf -v "${1:-SCREEN_PX_H}" '%s' "${_resp%;*}"
    printf -v "${2:-SCREEN_PX_W}" '%s' "${_resp#*;}"
}

# Get cursor position → CURSOR_LINE, CURSOR_COL
term.cursor_pos() {
    local _pos
    IFS=';' read -rs -d R -p $'\e[6n' _pos
    _pos="${_pos#*[}"
    printf -v "${1:-CURSOR_LINE}" '%s' "${_pos%%;*}"
    printf -v "${2:-CURSOR_COL}"  '%s' "${_pos#*;}"
}

# Get window title → WINDOW_TITLE
term.get_title() {
    local _resp
    read -rs -d $'\e' -p $'\e[21t' _resp 2>/dev/null
    # response is ESC ] l <title> ESC \   — varies by terminal
    read -rs -d $'\\' _resp
    printf -v "${1:-WINDOW_TITLE}" '%s' "${_resp#*l}"
}

# Check device status (returns 0 if terminal is OK)
term.is_ok() {
    local _resp
    read -rs -d n -p $'\e[5n' _resp 2>/dev/null
    [[ "${_resp}" == *"0" ]]
}

# Detect color depth → TERM_COLORS (0, 16, 256, 16777216)
term.color_level() {
    if [[ "${COLORTERM}" =~ ^(truecolor|24bit)$ ]]; then
        TERM_COLORS=16777216
    elif [[ "${TERM}" == *256color* ]]; then
        TERM_COLORS=256
    elif [[ -n "${TERM}" ]]; then
        TERM_COLORS=16
    else
        TERM_COLORS=0
    fi
}

# Check truecolor support (boolean)
term.has_truecolor() {
    [[ "${COLORTERM}" =~ ^(truecolor|24bit)$ ]]
}

# Check if running inside tmux
term.is_tmux() {
    [[ -n "${TMUX}" ]]
}

# Check if running inside screen
term.is_screen() {
    [[ "${TERM}" == screen* ]]
}

# Check if running in SSH session
term.is_ssh() {
    [[ -n "${SSH_CONNECTION}" || -n "${SSH_TTY}" ]]
}

# Check if stdout is a terminal (vs pipe/redirect)
term.is_tty() {
    [[ -t 1 ]]
}

# Check if stdin is a terminal
term.is_interactive() {
    [[ -t 0 ]]
}

# Get terminal type/emulator name via DA2 → TERM_NAME
term.identify() {
    local _resp
    read -rs -d c -p $'\e[>c' _resp 2>/dev/null
    printf -v "${1:-TERM_ID}" '%s' "${_resp#*[?}"
}

# Get stty settings dump
term.stty_dump() {
    stty -a 2>/dev/null
}

# Save entire terminal state
term.save_state() {
    _SAVED_STTY=$(stty -g 2>/dev/null)
}

# Restore saved terminal state
term.restore_state() {
    [[ -n "${_SAVED_STTY}" ]] && stty "${_SAVED_STTY}" 2>/dev/null
}

# Enter raw mode (for custom key reading)
term.raw() {
    term.save_state
    stty raw -echo 2>/dev/null
}

# Enter cbreak mode (char-at-a-time, signals still work)
term.cbreak() {
    term.save_state
    stty -icanon -echo min 1 time 0 2>/dev/null
}

# Restore cooked mode
term.cooked() {
    term.restore_state
}

# Disable echo
term.echo_off() {
    stty -echo 2>/dev/null
}

# Enable echo
term.echo_on() {
    stty echo 2>/dev/null
}

# Read a single keypress (returns in KEYPRESS)
term.read_key() {
    local _old
    _old=$(stty -g 2>/dev/null)
    stty raw -echo min 1 time 0 2>/dev/null
    IFS= read -r -n1 "${1:-KEYPRESS}"
    stty "$_old" 2>/dev/null
}

# Read a single keypress with timeout (seconds)
term.read_key_timeout() {
    local _old _timeout="${2:-1}"
    _old=$(stty -g 2>/dev/null)
    stty raw -echo min 0 time $((_timeout * 10)) 2>/dev/null
    IFS= read -r -n1 "${1:-KEYPRESS}"
    stty "$_old" 2>/dev/null
}

# Query background color → TERM_BG (light/dark/unknown)
# Useful for choosing color schemes
term.detect_bg() {
    local _resp _r _g _b
    # OSC 11 query
    echo -ne "\e]11;?\a"
    if IFS=: read -rs -d $'\a' -t 1 _resp 2>/dev/null; then
        _resp="${_resp##*/}"
        _r=$((16#${_resp:0:2}))
        _g=$((16#${_resp:2:2}))
        _b=$((16#${_resp:4:2}))
        local luma=$(( (_r * 299 + _g * 587 + _b * 114) / 1000 ))
        if (( luma > 128 )); then
            printf -v "${1:-TERM_BG}" 'light'
        else
            printf -v "${1:-TERM_BG}" 'dark'
        fi
    else
        printf -v "${1:-TERM_BG}" 'unknown'
    fi
}

# Get number of available colors via tput
term.colors() {
    printf -v "${1:-TERM_COLORS_TPUT}" '%s' "$(tput colors 2>/dev/null || echo 0)"
}

# Check if unicode is supported
term.has_unicode() {
    local _lang="${LANG:-}${LC_ALL:-}${LC_CTYPE:-}"
    [[ "$_lang" == *UTF-8* || "$_lang" == *utf8* ]]
}

# Get process controlling the terminal
term.parent() {
    ps -o comm= -p "$(ps -o ppid= -p $$)" 2>/dev/null
}

pb.init() {
    local rows cols
    read -r rows cols < <(stty size)

    _PB_ROW="$rows"

    # Scroll region = all lines except the last
    echo -ne "\e[1;$((_PB_ROW - 1))r"

    # Move cursor into the scroll region
    echo -ne "\e[$((_PB_ROW - 1));1H"

    # Draw initial empty bar on the reserved bottom line
    echo -ne "\e7"                          # save cursor
    echo -ne "\e[${_PB_ROW};1H\e[2K"       # jump to bottom, clear
    echo -ne "\e8"                          # restore cursor
}

pb.update() {
    local msg="${1}" current="${2}" total="${3}"
    local bar='████████████████████'
    local space='....................'
    local wheel=('\' '|' '/' '-')
    local wi=$((current % 4))
    local pct=$((100 * current / total))
    local bp=$((pct / 5))

    local line="|${bar:0:$bp}$(tput dim)${space:$bp:20}$(tput sgr0)| ${wheel[$wi]} ${pct}% [ ${msg} ] "

    echo -ne "\e7"                          # save cursor
    echo -ne "\e[${_PB_ROW};1H\e[2K"       # jump to bottom, clear
    echo -ne "$(tput setaf 6)${line}$(tput sgr0)"                      # draw bar
    echo -ne "\e8"                          # restore cursor
}

pb.teardown() {
    echo -ne "\e[r"                         # reset scroll region to full screen
    echo -ne "\e[${_PB_ROW};1H\e[2K"       # clear the bar line
    echo -ne "\e[$((_PB_ROW - 1));1H"       # move cursor to last usable line
    unset _PB_ROW
}