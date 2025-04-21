#!/bin/bash

# === KLYXEN: DB test ver ===
set -e

DB="$HOME/klyxen_files"
mkdir -p "$DB"

while true; do
  echo -ne "> "
  read -r cmd arg

  case $cmd in
    .new) 
      touch "$DB/$arg"
      echo "Created $arg"
      ;;
    .edit)
      nano "$DB/$arg"
      ;;
    .view)
      cat "$DB/$arg"
      ;;
    .del)
      rm -f "$DB/$arg"
      echo "Deleted $arg"
      ;;
    .ls)
      ls "$DB"
      ;;
    .exit)
      echo "Goodbye"
      break
      ;;
    *)
      echo "Unknown cmd"
      ;;
  esac
done
