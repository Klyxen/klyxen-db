#!/bin/bash

# === KLYXEN v1.1 ===
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

search_klyxen() {
  local keyword="$1"
  if [ -z "$keyword" ]; then
    echo -e "${RED}Error: No search keyword provided.${RESET}"
    echo -e "${YELLOW}Suggestion: Use '.search [keyword]' to search for files or folders.${RESET}"
    return
  fi
  echo -e "${CYAN}Searching for '$keyword' in $DB_DIR...${RESET}"
  results=$(find "$DB_DIR" -type f -o -type d -iname "*$keyword*" 2>/dev/null)
  if [ -z "$results" ]; then
    echo -e "${RED}No matches found for '$keyword' in $DB_DIR.${RESET}"
    echo -e "${YELLOW}Suggestion: Check spelling, try a different keyword, or use '.tree' to view all contents.${RESET}"
  else
    echo -e "${GREEN}Matches found:${RESET}"
    echo "$results" | while read -r line; do
      echo "  ${line#$DB_DIR/}"
    done
  fi
}

encrypt_item() {
  local type=$1 path=$2
  path=$(sanitize_path "$path")
  if [ -z "$path" ]; then
    echo -e "${RED}Error: Invalid or no $type name provided.${RESET}"
    echo -e "${YELLOW}Suggestion: Use '.ps -e -$type [path]' to encrypt a $type.${RESET}"
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
      echo -e "${YELLOW}Suggestion: Ensure 'gpg' is installed and try again.${RESET}"
    fi
  elif [ "$type" = "fl" ] && [ -f "$DB_DIR/$path" ]; then
    echo -e "${CYAN}Enter password for encryption:${RESET}"
    read -rs password
    if [ -z "$password" ]; then
      echo -e "${RED}Error: No password provided.${RESET}"
      return
    fi
    if gpg --batch --yes --passphrase "$password" -c "$DB_DIR/$path" 2>/dev/null; then
      mv "$DB_DIR/$path.gpg" "$DB_DIR/$path.enc" && rm "$DB_DIR/$path"
      echo -e "${GREEN}File '$path' encrypted as '$path.enc' in $DB_DIR.${RESET}"
    else
      echo -e "${RED}Encryption failed for file '$path'.${RESET}"
      echo -e "${YELLOW}Suggestion: Ensure 'gpg' is installed and try again.${RESET}"
    fi
  else
    echo -e "${RED}$type '$path' not found in $DB_DIR.${RESET}"
    echo -e "${YELLOW}Suggestion: Check the path or use '.search [keyword]' to find it.${RESET}"
  fi
}

decrypt_item() {
  local type=$1 path=$2
  path=$(sanitize_path "$path")
  local enc_path="$path"
  if [[ "$path" != *.enc ]]; then
    enc_path="$path.enc"
  fi
  if [ -z "$path" ]; then
    echo -e "${RED}Error: Invalid or no $type name provided.${RESET}"
    echo -e "${YELLOW}Suggestion: Use '.ps -d -$type [path]' to decrypt a $type.${RESET}"
    return
  fi
  if [ "$type" = "f" ] && [ -f "$DB_DIR/$enc_path" ]; then
    echo -e "${CYAN}Enter password for decryption:${RESET}"
    read -rs password
    if [ -z "$password" ]; then
      echo -e "${RED}Error: No password provided.${RESET}"
      return
    fi
    local dec_path="${path%.enc}"
    if gpg --batch --yes --passphrase "$password" -d "$DB_DIR/$enc_path" 2>/dev/null | tar -xzf - -C "$DB_DIR"; then
      rm "$DB_DIR/$enc_path"
      echo -e "${GREEN}Folder '$enc_path' decrypted to '$dec_path' in $DB_DIR.${RESET}"
    else
      echo -e "${RED}Decryption failed for folder '$enc_path'.${RESET}"
      echo -e "${YELLOW}Suggestion: Check the password or ensure the folder is encrypted with 'gpg'.${RESET}"
    fi
  elif [ "$type" = "fl" ] && [ -f "$DB_DIR/$enc_path" ]; then
    echo -e "${CYAN}Enter password for decryption:${RESET}"
    read -rs password
    if [ -z "$password" ]; then
      echo -e "${RED}Error: No password provided.${RESET}"
      return
    fi
    local dec_path="${path%.enc}"
    if gpg --batch --yes --passphrase "$password" -d "$DB_DIR/$enc_path" > "$DB_DIR/$dec_path" 2>/dev/null; then
      rm "$DB_DIR/$enc_path"
      echo -e "${GREEN}File '$enc_path' decrypted to '$dec_path' in $DB_DIR.${RESET}"
    else
      echo -e "${RED}Decryption failed for file '$enc_path'.${RESET}"
      echo -e "${YELLOW}Suggestion: Check the password or ensure the file is encrypted with 'gpg'.${RESET}"
    fi
  else
    echo -e "${RED}$type '$enc_path' not found in $DB_DIR.${RESET}"
    echo -e "${YELLOW}Suggestion: Check the path, ensure it ends with '.enc', or use '.search [keyword]' to find it.${RESET}"
  fi
}

run_command_mode() {
  while true; do
    echo -ne "${CYAN}:/> ${RESET}"
    read -r cmd args
    # Split args into array for better parsing
    IFS=' ' read -r -a arg_array <<< "$args"
    case $cmd in
      .help)
        print_header
        command_help
        ;;
      .show)
        print_header
        if [[ "${arg_array[0]}" == -f ]]; then
          folder=$(sanitize_path "${arg_array[*]:1}")
          if [ -z "$folder" ]; then
            echo -e "${RED}Error: No folder name provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.show -f [folder]' to view a folder.${RESET}"
          elif [ -d "$DB_DIR/$folder" ]; then
            tree "$DB_DIR/$folder" 2>/dev/null || find "$DB_DIR/$folder" -print | sed -e "s|$DB_DIR/||" -e 's|[^/]*/|  |g' -e 's|  |  |g'
          else
            echo -e "${RED}Folder '$folder' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check the folder path or use '.tree' to view all folders.${RESET}"
          fi
        elif [[ "${arg_array[0]}" == -fl ]]; then
          file=$(sanitize_path "${arg_array[*]:1}")
          if [ -z "$file" ]; then
            echo -e "${RED}Error: No file name provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.show -fl [file]' to view a file.${RESET}"
          elif [ -f "$DB_DIR/$file" ]; then
            cat "$DB_DIR/$file"
          else
            echo -e "${RED}File '$file' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check the file path or use '.search [keyword]' to find it.${RESET}"
          fi
        else
          echo -e "${RED}Invalid .show command.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.show -f [folder]' or '.show -fl [file]'.${RESET}"
        fi
        ;;
      .del)
        if [[ "${arg_array[0]}" == -f ]]; then
          folder=$(sanitize_path "${arg_array[*]:1}")
          if [ -z "$folder" ]; then
            echo -e "${RED}Error: No folder name provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.del -f [folder]' to delete a folder.${RESET}"
          elif [ -d "$DB_DIR/$folder" ]; then
            if [ "$(ls -A "$DB_DIR/$folder")" ]; then
              read -p "${YELLOW}Folder '$folder' is not empty. Delete anyway? (y/n): ${RESET}" confirm
              if [[ $confirm == y ]]; then
                rm -rf "$DB_DIR/$folder" && echo -e "${GREEN}Folder '$folder' deleted from $DB_DIR.${RESET}"
              else
                echo -e "${YELLOW}Deletion canceled.${RESET}"
              fi
            else
              rm -rf "$DB_DIR/$folder" && echo -e "${GREEN}Folder '$folder' deleted from $DB_DIR.${RESET}"
            fi
          else
            echo -e "${RED}Folder '$folder' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check the folder path or use '.tree' to view all folders.${RESET}"
          fi
        elif [[ "${arg_array[0]}" == -fl ]]; then
          file=$(sanitize_path "${arg_array[*]:1}")
          if [ -z "$file" ]; then
            echo -e "${RED}Error: No file name provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.del -fl [file]' to delete a file.${RESET}"
          elif [ -f "$DB_DIR/$file" ]; then
            rm "$DB_DIR/$file" && echo -e "${GREEN}File '$file' deleted from $DB_DIR.${RESET}"
          else
            echo -e "${RED}File '$file' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check the file path or use '.search [keyword]' to find it.${RESET}"
          fi
        else
          echo -e "${RED}Invalid .del command.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.del -f [folder]' or '.del -fl [file]'.${RESET}"
        fi
        ;;
      .ed)
        file=$(sanitize_path "${arg_array[*]:1}")
        if [[ "${arg_array[0]}" != -fl ]]; then
          echo -e "${RED}Invalid .ed command.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.ed -fl [file]' to edit a file.${RESET}"
        elif [ -z "$file" ]; then
          echo -e "${RED}Error: No file name provided.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.ed -fl [file]' to edit a file.${RESET}"
        elif [ -f "$DB_DIR/$file" ]; then
          nano "$DB_DIR/$file"
        else
          echo -e "${RED}File '$file' not found in $DB_DIR.${RESET}"
          echo -e "${YELLOW}Suggestion: Check the file path or create a new file with option 1 in the main menu.${RESET}"
        fi
        ;;
      .rn)
        if [[ "${arg_array[0]}" == -f ]]; then
          folder=$(sanitize_path "${arg_array[*]:1}")
          if [ -z "$folder" ]; then
            echo -e "${RED}Error: No folder name provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.rn -f [folder]' to rename a folder.${RESET}"
          elif [ -d "$DB_DIR/$folder" ]; then
            read -p "${CYAN}New folder name (use / for nested paths): ${RESET}" new
            new=$(sanitize_path "$new")
            if [ -z "$new" ]; then
              echo -e "${RED}Error: No new name provided.${RESET}"
              echo -e "${YELLOW}Suggestion: Provide a valid name or path for the folder.${RESET}"
            elif [ -e "$DB_DIR/$new" ]; then
              echo -e "${RED}Error: Name '$new' already exists in $DB_DIR.${RESET}"
              echo -e "${YELLOW}Suggestion: Choose a different name.${RESET}"
            else
              mkdir -p "$(dirname "$DB_DIR/$new")"
              mv "$DB_DIR/$folder" "$DB_DIR/$new" && echo -e "${GREEN}Folder renamed to '$new' in $DB_DIR.${RESET}"
            fi
          else
            echo -e "${RED}Folder '$folder' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check the folder path or use '.tree' to view all folders.${RESET}"
          fi
        elif [[ "${arg_array[0]}" == -fl ]]; then
          file=$(sanitize_path "${arg_array[*]:1}")
          if [ -z "$file" ]; then
            echo -e "${RED}Error: No file name provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.rn -fl [file]' to rename a file.${RESET}"
          elif [ -f "$DB_DIR/$file" ]; then
            read -p "${CYAN}New file name (use / for nested paths): ${RESET}" new
            new=$(sanitize_path "$new")
            if [ -z "$new" ]; then
              echo -e "${RED}Error: No new name provided.${RESET}"
              echo -e "${YELLOW}Suggestion: Provide a valid name or path for the file.${RESET}"
            elif [ -e "$DB_DIR/$new" ]; then
              echo -e "${RED}Error: Name '$new' already exists in $DB_DIR.${RESET}"
              echo -e "${YELLOW}Suggestion: Choose a different name.${RESET}"
            else
              mkdir -p "$(dirname "$DB_DIR/$new")"
              mv "$DB_DIR/$file" "$DB_DIR/$new" && echo -e "${GREEN}File renamed to '$new' in $DB_DIR.${RESET}"
            fi
          else
            echo -e "${RED}File '$file' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check the file path or use '.search [keyword]' to find it.${RESET}"
          fi
        else
          echo -e "${RED}Invalid .rn command.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.rn -f [folder]' or '.rn -fl [file]'.${RESET}"
        fi
        ;;
      .ps)
        if [[ "${arg_array[0]}" == -e ]]; then
          if [[ "${arg_array[1]}" == -f ]]; then
            folder=$(sanitize_path "${arg_array[*]:2}")
            encrypt_item "f" "$folder"
          elif [[ "${arg_array[1]}" == -fl ]]; then
            file=$(sanitize_path "${arg_array[*]:2}")
            encrypt_item "fl" "$file"
          else
            echo -e "${RED}Invalid .ps -e command.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.ps -e -f [folder]' or '.ps -e -fl [file]'.${RESET}"
          fi
        elif [[ "${arg_array[0]}" == -d ]]; then
          if [[ "${arg_array[1]}" == -f ]]; then
            folder=$(sanitize_path "${arg_array[*]:2}")
            decrypt_item "f" "$folder"
          elif [[ "${arg_array[1]}" == -fl ]]; then
            file=$(sanitize_path "${arg_array[*]:2}")
            decrypt_item "fl" "$file"
          else
            echo -e "${RED}Invalid .ps -d command.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.ps -d -f [folder]' or '.ps -d -fl [file]'.${RESET}"
          fi
        else
          echo -e "${RED}Invalid .ps command.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.ps -e' to encrypt or '.ps -d' to decrypt.${RESET}"
        fi
        ;;
      .tree)
        print_header
        if [ -z "$(ls -A "$DB_DIR")" ]; then
          echo -e "${RED}No folders or files in the database.${RESET}"
          echo -e "${YELLOW}Suggestion: Create a folder or file using option 1 in the main menu.${RESET}"
        else
          tree "$DB_DIR" 2>/dev/null || find "$DB_DIR" -print | sed -e "s|$DB_DIR/||" -e 's|[^/]*/|  |g' -e 's|  |  |g'
        fi
        ;;
      .mv)
        if [[ "${arg_array[0]}" == -fl-f ]]; then
          file=$(sanitize_path "${arg_array[1]}")
          folder=$(sanitize_path "${arg_array[2]}")
          if [ -z "$file" ] || [ -z "$folder" ]; then
            echo -e "${RED}Error: Both file and folder names must be provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.mv -fl-f [file] [folder]' to move a file.${RESET}"
          elif [ -f "$DB_DIR/$file" ] && [ -d "$DB_DIR/$folder" ]; then
            mv "$DB_DIR/$file" "$DB_DIR/$folder/" && echo -e "${GREEN}File '$file' moved to '$folder' in $DB_DIR.${RESET}"
          else
            echo -e "${RED}Error: File '$file' or folder '$folder' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check names or paths or use '.tree' to view structure.${RESET}"
          fi
        elif [[ "${arg_array[0]}" == -f-f ]]; then
          folder1=$(sanitize_path "${arg_array[1]}")
          folder2=$(sanitize_path "${arg_array[2]}")
          if [ -z "$folder1" ] || [ -z "$folder2" ]; then
            echo -e "${RED}Error: Both folder names must be provided.${RESET}"
            echo -e "${YELLOW}Suggestion: Use '.mv -f-f [folder1] [folder2]' to move a folder.${RESET}"
          elif [ -d "$DB_DIR/$folder1" ] && [ -d "$DB_DIR/$folder2" ]; then
            mv "$DB_DIR/$folder1" "$DB_DIR/$folder2/" && echo -e "${GREEN}Folder '$folder1' moved to '$folder2' in $DB_DIR.${RESET}"
          else
            echo -e "${RED}Error: Folder '$folder1' or '$folder2' not found in $DB_DIR.${RESET}"
            echo -e "${YELLOW}Suggestion: Check names or paths or use '.tree' to view structure.${RESET}"
          fi
        else
          echo -e "${RED}Invalid .mv command.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.mv -fl-f [file] [folder]' or '.mv -f-f [folder1] [folder2]'.${RESET}"
        fi
        ;;
      .search)
        search_klyxen "$args"
        ;;
      .exit)
        echo -e "${GREEN}Exiting Command Mode...${RESET}"
        break
        ;;
      *)
        echo -e "${RED}Unknown command: '$cmd'.${RESET}"
        echo -e "${YELLOW}Suggestion: Use '.help' to see available commands.${RESET}"
        ;;
    esac
  done
}

# Main Prompt
check_dependencies
while true; do
  print_header
  echo -e "${CYAN}1.${RESET} Create Data"
  echo -e "${CYAN}2.${RESET} View Data"
  echo -e "${CYAN}3.${RESET} View Tree Structure"
  echo -e "${CYAN}0.${RESET} Command Mode"
  echo -ne "${YELLOW}Choose an option (0-3): ${RESET}"
  read -r choice

  case $choice in
    1)
      clear
      print_header
      echo -ne "${CYAN}Create directory or file? (dir/file): ${RESET}"
      read type
      type=$(echo "$type" | tr '[:upper:]' '[:lower:]')
      if [[ "$type" != "dir" && "$type" != "file" ]]; then
        echo -e "${RED}Error: Invalid type. Please enter 'dir' or 'file'.${RESET}"
        echo -e "${YELLOW}Suggestion: Try again with 'dir' or 'file'.${RESET}"
        read -p "${YELLOW}Press enter to continue...${RESET}"
        continue
      fi
      echo -ne "${CYAN}Name (use / for nested paths, e.g., parent/child or 'my folder'): ${RESET}"
      read -r name
      name=$(sanitize_path "$name")
      if [ -z "$name" ]; then
        echo -e "${RED}Error: No name provided or invalid path.${RESET}"
        echo -e "${YELLOW}Suggestion: Provide a valid name or path for the directory or file.${RESET}"
        read -p "${YELLOW}Press enter to continue...${RESET}"
        continue
      elif [ -e "$DB_DIR/$name" ]; then
        echo -e "${RED}Error: Path '$name' already exists in $DB_DIR.${RESET}"
        echo -e "${YELLOW}Suggestion: Choose a different name or delete the existing one using '.del'.${RESET}"
        read -p "${YELLOW}Press enter to continue...${RESET}"
        continue
      fi
      if [ "$type" == "dir" ]; then
        mkdir -p "$DB_DIR/$name"
        echo -e "${GREEN}Directory '$name' created in $DB_DIR.${RESET}"
      else
        mkdir -p "$(dirname "$DB_DIR/$name")"
        echo -ne "${CYAN}Enter data (leave empty to create empty file): ${RESET}"
        read -r data
        if [ -z "$data" ]; then
          touch "$DB_DIR/$name"
          echo -e "${GREEN}Empty file '$name' created in $DB_DIR.${RESET}"
        else
          echo "$data" > "$DB_DIR/$name"
          echo -e "${GREEN}File '$name' with data created in $DB_DIR.${RESET}"
        fi
      fi
      read -p "${YELLOW}Add more? (y/n): ${RESET}" again
      [[ $again == y ]] && continue
      ;;
    2)
      clear
      print_header
      echo -ne "${CYAN}Enter folder or file path to view (e.g., parent/child or 'my folder'): ${RESET}"
      read -r view
      view=$(sanitize_path "$view")
      if [ -z "$view" ]; then
        echo -e "${RED}Error: No name provided or invalid path.${RESET}"
        echo -e "${YELLOW}Suggestion: Provide a folder or file path to view.${RESET}"
      elif [ -f "$DB_DIR/$view" ]; then
        if [ -s "$DB_DIR/$view" ]; then
          cat "$DB_DIR/$view"
        else
          echo -e "${RED}File '$view' is empty.${RESET}"
          echo -e "${YELLOW}Suggestion: Use '.ed -fl \"$view\"' to edit the file and add content.${RESET}"
        fi
      elif [ -d "$DB_DIR/$view" ]; then
        if [ -z "$(ls -A "$DB_DIR/$view")" ]; then
          echo -e "${RED}Folder '$view' is empty.${RESET}"
          echo -e "${YELLOW}Suggestion: Create files or subfolders in '$view' using option 1.${RESET}"
        else
          ls -l "$DB_DIR/$view"
        fi
      else
        echo -e "${RED}'$view' not found in $DB_DIR.${RESET}"
        echo -e "${YELLOW}Suggestion: Check the path or use '.search [keyword]' to find it.${RESET}"
      fi
      read -p "${YELLOW}Press enter to continue...${RESET}"
      ;;
    3)
      clear
      print_header
      if [ -z "$(ls -A "$DB_DIR")" ]; then
        echo -e "${RED}No folders or files in the database.${RESET}"
        echo -e "${YELLOW}Suggestion: Create a folder or file using option 1 in the main menu.${RESET}"
      else
        tree "$DB_DIR" 2>/dev/null || find "$DB_DIR" -print | sed -e "s|$DB_DIR/||" -e 's|[^/]*/|  |g' -e 's|  |  |g'
      fi
      read -p "${YELLOW}Press enter to continue...${RESET}"
      ;;
    0)
      clear
      print_header
      run_command_mode
      ;;
    *)
      echo -e "${RED}Invalid option: '$choice'.${RESET}"
      echo -e "${YELLOW}Suggestion: Choose a number between 0 and 3.${RESET}"
      read -p "${YELLOW}Press enter to continue...${RESET}"
      ;;
  esac
done