#!/usr/bin/env bash

#===============================================================================
# FILE: ai.sh
# DESCRIPTION: A polyglot execution wrapper for AI/Development tasks.
# USAGE: ./ai.sh <command> [args...]
# COMMANDS: eval, exec, bash, node, python3, npm, awk, sed
#===============================================================================

# Strict Mode
set -euo pipefail
IFS=$'\n\t'

#===============================================================================
# CONFIGURATION & COLORS
#===============================================================================

# Determine if output is a terminal
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\e[0m'
    readonly COLOR_RED='\e[0;31m'
    readonly COLOR_GREEN='\e[0;32m'
    readonly COLOR_YELLOW='\e[0;33m'
    readonly COLOR_BLUE='\e[0;34m'
    readonly COLOR_CYAN='\e[0;36m'
else
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_CYAN=''
fi

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

# Usage function
usage() {
    cat << EOF
Usage: $0 <command> [arguments...]

A dispatcher script to execute various development tools and languages.

Available Commands:
  eval <string>     Evaluate a string as a bash command.
  exec <command>    Replace the current shell with the command.
  bash [file]       Execute a bash script or enter interactive mode.
  node [file]       Execute a Node.js script or REPL.
  python3 [file]    Execute a Python3 script or REPL.
  npm <command>     Run an npm command.
  awk <program>     Execute an AWK program.
  sed <script>      Execute a SED script.

Example:
  $0 node -e "console.log('Hello World')"
  $0 python3 -c "print('Python works')"
  $0 eval "ls -la | grep ai"
EOF
    exit 1
}

# Check if a specific binary exists in PATH
check_dependency() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command '$cmd' is not installed or not in PATH."
        exit 127
    fi
}

#===============================================================================
# MAIN LOGIC
#===============================================================================

main() {
    # Check if at least one argument is provided
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local cmd="$1"
    shift # Remove the first argument so $@ contains the rest

    case "$cmd" in
        #---------------------------------------------------------------
        # BUILTIN COMMANDS
        #---------------------------------------------------------------
        eval)
            # SECURITY WARNING: eval is dangerous if inputs are untrusted.
            # This evaluates the concatenated arguments as a bash command.
            if [[ $# -eq 0 ]]; then
                log_error "The 'eval' command requires a string argument."
                exit 2
            fi
            log_info "Executing eval: $*"
            eval "$@"
            ;;

        exec)
            # exec replaces the current shell process with the new command.
            if [[ $# -eq 0 ]]; then
                log_error "The 'exec' command requires a command to execute."
                exit 2
            fi
            log_info "Executing exec replacement: $*"
            exec "$@"
            ;;

        #---------------------------------------------------------------
        # INTERPRETERS / RUNTIMES
        #---------------------------------------------------------------
        bash)
            check_dependency "bash"
            log_info "Launching bash: $*"
            bash "$@"
            ;;

        node)
            check_dependency "node"
            log_info "Launching node: $*"
            node "$@"
            ;;

        python3)
            check_dependency "python3"
            log_info "Launching python3: $*"
            python3 "$@"
            ;;

        npm)
            check_dependency "npm"
            log_info "Launching npm: $*"
            npm "$@"
            ;;

        #---------------------------------------------------------------
        # TEXT PROCESSING TOOLS
        #---------------------------------------------------------------
        awk)
            check_dependency "awk"
            log_info "Launching awk: $*"
            awk "$@"
            ;;

        sed)
            check_dependency "sed"
            log_info "Launching sed: $*"
            sed "$@"
            ;;

        #---------------------------------------------------------------
        # HELP / DEFAULT
        #---------------------------------------------------------------
        help|--help|-h)
            usage
            ;;

        *)
            log_error "Unknown command '$cmd'."
            echo ""
            usage
            ;;
    esac

    # Capture exit code explicitly if not handled by set -e
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Command '$cmd' failed with exit code $exit_code."
    fi
    exit $exit_code
}

# Execute main function passing all arguments
main "$@"
