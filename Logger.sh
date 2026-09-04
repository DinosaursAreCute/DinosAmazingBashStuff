#!/usr/bin/env bash
#shellcheck source=./cursor_controls.sh
source cursor_controls.sh
# shellcheck source=./terminal_controls.sh
source terminal_controls.sh
# shellcheck source=./colors.sh
source colors.sh
# shellcheck source=./terminal_renderer.sh
source terminal_renderer.sh

minimum_log_level=0
log_to_file=false
log_to_console=true
log_with_color=true

log_level_name=(
    "DEBUG  " 
    "VALUE  "
    "ACTION "
    "SYSTEM "
    "SUCCESS"
    "WARNING"
    "ERROR  "
    "FATAL  "
)
log_level_colors=(
    "${DIM_WHITE}" # debug
    "${BRIGHT_MAGENTA}" # value
    "${BRIGHT_BLUE}" # action
    "${BRIGHT_CYAN}" # system
    "${BRIGHT_GREEN}" # success
    "${BRIGHT_YELLOW}" # warning
    "${BRIGHT_RED}" # error
    "${HOT_PINK}${BG_DIM_RED}" # fatal
)


build_prefix() {
    local _prefix="$1"
    local _level="${log_level_name[$2]}" #alligned
    local _timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    local _calling_func
    printf -v _calling_func "%-10s" "${FUNCNAME[2]:-main}"
    local _calling_file
    printf -v _calling_file "%-15s" "${BASH_SOURCE[2]:-Logger.sh}"
    if [[ $log_with_color == true ]]; then
        local _color="${log_level_colors[$2]}"
        _prefix="$_color$_prefix${RESET}"
    fi
    
    

    printf "[%s] [%s%s%s] [%s] [%s]" "$_timestamp"  "$_level" "${RESET}" "$_calling_file" "$_calling_func" 
}
log_message() {
    if [[ $2 -lt $minimum_log_level ]]; then
        return 0
    fi

    local _msg="$1"
    local _level="${2:-info}"
    local _prefix="$(build_prefix "$_prefix" "$_level")"
    echo $_prefix
    echo -e "$_prefix" "$_msg"
}


log_debug() {
    log_message "$1" 0
}
log_value() {
    log_message "$1" 1
}
log_action() {
    log_message "$1" 2  
}
log_system() {
    log_message "$1" 3
}
log_success() {
    log_message "$1" 4
}
log_warning() {
    log_message "$1" 5
}
log_error() {
    log_message "$1" 6
}
log_fatal() {
    log_message "$1" 7
}


log_result_success() {
    local _msg="$1"
    log_success "$_msg \n${BRIGHT_GREEN}$(box_string "$_msg")${RESET}"
    
}

function_name() 
{
    log_debug "This is a debug message from function_name"
    log_value "This is a value message from function_name"
    log_action "This is an action message from function_name"
    log_system "This is a system message from function_name"
    log_success "This is a success message from function_name"
    log_warning "This is a warning message from function_name"
    log_error "This is an error message from function_name"
}

function_name

badges "pass:Build" 
badges "fail:Tests"
badges "skip:Lint"
badges "info:v2.1.0"
badges "warn:Deprecated"
badges "run:Deploying"

tree "" "Root" "  Child1" "    Grandchild1" "    Grandchild2" "  Child2" "  Grandchild3" "    Grandchild4" "  Child3"