![Ansibash](.github/anime.gif)

# ANSIBASH (Ansible in Bash)
This is a simple script like Ansible but written in Bash

## Usage
```shell
USAGE: ansibash.sh [OPTION] COMMAND
Run a command or a script on multiple targets.
OPTION:
-h, --hosts    List of hosts (separated by commas) where the command should be broadcast. 
-i, --inventory    Inventory file with one host per line
-u, --user     User used for connexion (ssh)
-o, --output   Print all result to a output file
-c, --command  Command to broadcast on hosts (always put at the end of the command)
-s, --script   Run a script to the remote target
-f, --file     Upload file to remote host
--help         Print this help
-------------------------------------------------
SPECIALS OPTIONS:
--ignore_error     Continues the script even if an error occurs
```