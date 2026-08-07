#!/bin/bash

# mac setup orchestrator (make mac):
#   bin/mac_lib.sh      print helpers
#   bin/mac_apps.sh     app / font / CLI checks + auto-install via brew
#   bin/mac_defaults.sh macOS defaults (make defaults で単体実行も可)
#   bin/mac_shell.sh    login shell -> zsh (+ history migration)

cd "$(dirname "$0")/.." || exit 1

source ./bin/mac_lib.sh
source ./bin/mac_apps.sh
source ./bin/mac_defaults.sh
source ./bin/mac_shell.sh

printTitle "start"
printInfo "check apps that usually needs, for mac."
printInfo "auto-install via brew when possible."

setupBrew
checkAapp
installBrewPackages
checkLoginItems
setupMacDefaults
setupDefaultShell
openDlLink
