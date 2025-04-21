#!/bin/bash

# === KLYXEN v1 prtp ===
# Klyxen: A Local DB File Scripting Tool (Bash Version)

# Exit on error
set -e

# Dependencies Setup
check_dependencies() {
  local missing_deps=()
  for dep in tput tree nano gpg; do
    if ! command -v "$dep" &> /dev/null; then
      missing_deps+=("$dep")
    fi
  done
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "${YELLOW}Installing missing dependencies: ${missing_deps[*]}...${RESET}"
    if ! sudo apt update && sudo apt install -y ncurses-bin tree nano gnupg; then
      echo "${RED}Failed to install dependencies. Please install ${missing_deps[*]} manually.${RESET}"
      exit 1
    fi
  fi
}

# Colors
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Database Directory
DB_DIR="$HOME/.klyxen.db"
mkdir -p "$DB_DIR"

# Functions
print_header() {
  clear
  echo "${CYAN}==== KLYXEN v1.1 ====${RESET}"
  echo "${CYAN}Local DB File Scripting Tool${RESET}"
}

command_help() {
  echo -e "${YELLOW}Available Commands:${RESET}"
  echo -e ".help                   = Show this help section"
  echo -e ".show -f [folder]       = Show folder structure (e.g., parent/child)"
  echo -e ".show -fl [file]        = Show contents of file (e.g., parent/child.txt)"
  echo -e ".del -f [folder]        = Delete a folder (ask if not empty)"
  echo -e ".del -fl [file]         = Delete a file"
  echo -e ".ed -fl [file]          = Edit file in nano"
  echo -e ".rn -f [folder]         = Rename a folder"
  echo -e ".rn -fl [file]          = Rename a file"
  echo -e ".ps -e -f [folder]      = Encrypt folder with password"
  echo -e ".ps -e -fl [file]       = Encrypt file with password"
  echo -e ".ps -d -f [folder]      = Decrypt folder"
  echo -e ".ps -d -fl [file]       = Decrypt file"
  echo -e ".tree                   = Show entire DB structure"
  echo -e ".mv -fl-f [file] [folder] = Move file into folder"
  echo -e ".mv -f-f [folder1] [folder2] = Move folder into another folder"
  echo -e ".search [keyword]       = Search for any folder/file name"
  echo -e ".exit                   = Exit Command Mode"
  echo -e "${YELLOW}Tip: Use forward slashes for paths (e.g., parent/child). Quote names with spaces.${RESET}"
}

sanitize_path() {
  local path="$1"
  # Remove leading/trailing slashes and normalize path
  path=$(echo "$path" | sed 's|^/*||;s|/*$||;s|//*|/|g')
  # Prevent directory traversal
  if [[ "$path" =~ \.\./|\.\. ]]; then
    echo ""
  else
    echo "$path"
  fi
}

# Encrypt function prototype
encrypt_item() {
  local type=$1 path=$2
  path=$(sanitize_path "$path")
  if [ -z "$path" ]; then
    echo -e "${RED}Error: Invalid or no $type name provided.${RESET}"
    return
  fi
  if [ "$type" = "f" ] && [ -d "$DB_DIR/$path" ]; then
    echo -e "${CYAN}Enter password for encryption:${RESET}"
    read -rs password
    if [ -z "$password" ]; then
      echo -e "${RED}Error: No password provided.${RESET}"
      return
    fi
    tar -czf - -C "$DB_DIR" "$path" | gpg --batch --yes --passphrase "$password" -c > "$DB_DIR/$path.enc" 2>/dev/null
    if [ $? -eq 0 ]; then
      rm -rf "$DB_DIR/$path"
      echo -e "${GREEN}Folder '$path' encrypted as '$path.enc' in $DB_DIR.${RESET}"
    else
      echo -e "${RED}Encryption failed for folder '$path'.${RESET}"
    fi
  fi
}

run_command_mode() {
  while true; do
    echo -ne "${CYAN}:/> ${RESET}"
    read -r cmd args
    IFS=' ' read -r -a arg_array <<< "$args"
    case $cmd in
      .help)
        print_header
        command_help
        ;;
      .ps)
        if [[ "${arg_array[1]}" == -e ]]; then
          encrypt_item "${arg_array[2]}" "${arg_array[3]}"
        else
          echo -e "${RED}Invalid encryption command.${RESET}"
        fi
        ;;
      .exit)
        break
        ;;
      *)
        echo -e "${RED}Invalid command.${RESET}"
        ;;
    esac
  done
}

# Main execution
check_dependencies
print_header
run_command_mode