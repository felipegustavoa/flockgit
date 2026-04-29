#!/bin/bash

COMMANDS=(status update change)
COMMANDSHELP=(-h --help)

# O help usa listas centralizadas para manter validação e descrição em sincronia.
colors

descriptions() {
    case "$1" in 
        status) echo "List the status of branches (flockgit status [--summary])";;
        update) echo "Update branches, checking for updates in repositories (flockgit update [--summary])";;
        change) echo "Change branches (flockgit change main [--summary])";;
    esac
}

commands() {
    echo "Commands:"
    for command in "${COMMANDS[@]}"; do
        printf "    %s%-10s%s %s\n" "$YELLOW" "$command" "$RESET" "$(descriptions "$command")"
    done
}
