# Klyxen DB
<p align="center">
  <img src="assets/logo.png" alt="KLYXEN-DB Logo" width="200"/>
</p>
A lightweight, offline file-based "database" system written in Bash. It stores and manages data using simple folders and files inside your home directory, designed for local file operations without needing an actual database engine.
This tool is designed for local use only on your own machine.
Not intended for multi-user, online, or production environments.

###
## How to Download and Run
'on terminal'
- wget https://github.com/Klyxen/klyxen-db/raw/main/klyxen.sh
- bash klyxen.sh
- Then type .help to see all available commands.
###
## Core Features
- .tree – View DB structure
- .ed -fl [file] – Edit a file (with nano)
- .del -f or .del -fl – Delete folder or file
- .rn -f or .rn -fl – Rename folder or file
- .ps -e / .ps -d – Encrypt/Decrypt using GPG
- .show -f / .show -fl – Display contents
- Auto-creates the database directory if missing
- Color-coded terminal UI (using tput)
- Auto-checks required dependencies (gpg, nano, tree)
###
## Version History
### v0.1 (Early Dev)
- Added .tree, .ed, .del, .show, .help
- Default DB path set to ~/.klyxen.db
- Core file/folder handling logic
###
### v0.2 (Early Dev)
- Added GPG encryption/decryption via .ps
- Added rename command .rn
- Basic error handling and cleaner CLI messages
###
### v1.0
- Full terminal UI styling with tput
- Dependency check added for required tools
- Encryption: .ps -e -f / .ps -d -fl
- Cleanup fixes for delete and file outputs
- Improved structure creation and validation
###
### v1.1
- Fixed file type checks in .show -fl
- Improved error handling for paths and non-existing files
- Input sanitization and secure path processing
- Optimized loading and command response speed
###
### v1.2
- Added .ren.[filename] [newname] for quick renamed
- Added .ed.[filename] for quick editing with nano
- Improved command parsing logic for dot-prefixed commands
- Fixed formatting in .tree output
- Minor optimization on response handling and UI consistency
- Inherits all v1.1 fixes (error handling, path checks, sanitization, and speed improvements)
###
### v1.3
- Added .ed -fl to edit files, .rn -f and -fl to rename, .ps -e and -d to encrypt/decrypt, and full path input cleaning.
- Updated .show, .del, and .tree with cleaner output and better logic.
- Fixed Broken paths, duplicate code, and command misreads.
Removed: Redundant handling and old error-prone checks.
- In progress, .mv -fl-f (move file to folder).
###
### v1.4
- Fixed broken paths, special character handling, extension issues, and missing files in .show, .del, and .tree.
- Added .ren.(file name) for renaming, .ed.(file name) for editing files, full path support, and folder existence checks before operations.
- Updated .tree, .show, and .del for cleaner output and better error handling.
- Removed redundant file existence checks in .ed and .ren.
###
### v1.5 ( stable )
- Updated KLYXEN v1.4 to KLYXEN v1.5.
- Database Location Changed from hidden $HOME/.klyxen.db to visible $HOME/klyxen.db for easier user access.
- Added 2>/dev/null to file operations (rm, mv, mkdir, touch, echo, cat, nano) in .show, .del, .ed, .rn, .mv, and main prompt to hide error messages and keep the terminal clean.
- Corrected "Decryption pops failed" to "Decryption failed" in the decrypt_item function for folder decryption.
- Added error messages for failed file reads in .show and file edits in .ed, making it clearer when operations fail (e.g., due to permissions).
###
#
## Personal Comments
- Coding them is a lot of time and I will keep on updating my skills to improve and develop this tool.
- I have also used AI like Copilot to atleast help with some of the code. Still, I don't rely much because I only view AI as a tool and not a worker lmao.
- I really hope I can improve everything and my skills too you know, I just want to grow because this is what I love to do.
#