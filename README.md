# UsefullStuff
It is a set of scripts and other stuff that i mostly use to automate tasks that can be automated, below there a list of those scirpt with the description.

## createigi.py
Script for creating and managing the .gitignore files, with sections that you can add, remove, etc. You are able to control the state of the file, create new .gitignore files that can be customized to your needs

There is a short manual of how to use a specific command:
- `--help`, `-h`: a manual page that you see now
- `--state`, `-s`: a state of existing .gitignore file
- --lang, --sys, --editor: creating .gitignore file from scratch with specified sections
- --exclude_lang, --exclude_sys, --exclude_editor: creating a file with all sections except those specified by those options
- --add_lang, --add_sys, --add_editor: adding to an existing .gitignore file a specified section
- `--del_lang`, --del_sys, --del_editor: deleting from an existing .gitignore file a specified section 
    
The sections that are currectly supported are:
**Languages:**
**Systems:**
**Editors:**

The important thing is, if .gitignore already exist, you cannot execute commands such as: --lang, --sys, --editor, --exclude_lang, --exclude_sys, --exclude_editor, they only works on freshly created filed. If you want to modify the existing file use: --add_lang, --add_sys, --add_editor, --del_lang, --del_sys, --del_editor
