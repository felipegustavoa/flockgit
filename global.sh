#!/bin/bash

# Inicializa cores apenas quando a saída está ligada a um terminal.
colors() {
  if { [ -t 1 ]; }; then
    RED=$'\e[31m'; 
    GREEN=$'\e[32m'; 
    YELLOW=$'\e[33m'; 
    BLUE=$'\e[34m'
    BOLD=$'\e[1m'; 
    DIM=$'\e[2m'; 
    RESET=$'\e[0m'
  fi
}
