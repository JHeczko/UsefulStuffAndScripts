# Installation
Important info about installation, there is makefile prepared, you have to have sudo in order to install a script(it is being install in `/usr/local/bin/` but you can set `PREFIX` to different installation path for ex. `make install PREFIX=$HOME/.local`). There is all posible combination of installation of scripts:
- `make install`: Install all tools
- `make uninstall`: Remove all tools
- `make install-genai`: Install GenAI assistant only
- `make uninstall-genai`: Remove GenAI assistant
- `make install-gitignore`: Install gitignore tool only
- `make uninstall-gitignore`: Remove gitignore tool
- `make help`: shows a above list of commands with explonation

# Requirements
- `createigit`:
   - python 3
- `aicode`:
   - perl 5
- `battle`:
   - bash

# Descriptions
It is a set of scripts and other stuff that i mostly use to automate tasks that can be automated, below there a list of those scirpt with the description.

## Git ignore file creator (`createigit`)
Script for creating and managing the .gitignore files, with sections that you can add, remove, etc. You are able to control the state of the file, create new .gitignore files that can be customized to your needs

There is a short manual of how to use a specific command:
- `--help`, `-h`: a manual page that you see now
- `--state`, `-s`: a state of existing .gitignore file
- `--list`: prints all available .gitignore sections
- `--lang`, `--sys`, `--editor`: creating .gitignore file from scratch with specified sections
- `--exclude_lang`, `--exclude_sys`, `--exclude_editor`: creating a file with all sections except those specified by those options
- `--add_lang`, `--add_sys`, `--add_editor`: adding to an existing .gitignore file a specified section
- `--del_lang`, `--del_sys`, `--del_editor`: deleting from an existing .gitignore file a specified section 
    
The sections that are currently supported are:
**Languages:**
- cpp
- c
- go 
- gradle 
- java
- langchain 
- maven
- node
- python 
- qt
- scala 
- swift 
- tex
- terraform 

**Systems:**
- linux
- windows
- macos

**Editors:**
- vsc
- xcode
- jetbrains

(you have to write them as they are)

The important thing is, if .gitignore already exist, you cannot execute commands such as: --lang, --sys, --editor, --exclude_lang, --exclude_sys, --exclude_editor, they only works on freshly created filed. If you want to modify the existing file use: --add_lang, --add_sys, --add_editor, --del_lang, --del_sys, --del_editor

## GenAI code assistant (`aicode`)
This is a command-line tool that integrates with Google's Gemini AI models to assist with coding tasks. It allows users to ask questions, debug code, refactor code, add comments, and modify code using AI-generated responses. The tool supports batching large files based on a configurable context window.

### Main Features
- **Ask a Question**: Prompt Gemini with a custom question and receive a direct response.
- **Debug Code**: Analyze a selected file for bugs, optionally with user-specified bug details, and get explanations and fixes.
- **Refactor Code**: Refactor a selected file to improve structure and readability while preserving functionality, saving to a new file.
- **Comment Code**: Add comments to a selected file explaining functions and complex syntax, saving to a new file.
- **Modify Code**: Modify a selected file based on user instructions, saving to a new file.

### Settings Menu
- **Check API Keys**: Display current API keys (prioritizing environment variables over config).
- **Set API Keys**: Update Gemini or OpenAI API keys in the config.
- **Select Model**: Choose from a list of available models (currently Google Gemini variants).
- **Show Current Model**: Display the currently selected model and provider.
- **Set Context Window Length**: Configure the maximum characters per batch for file processing (-1 disables batching, loading the whole file).

### Configuration
The config file is located at `~/.aicode_conf/config.json`. It stores API keys, selected model, prompts, and context window settings. API keys can also be set via environment variables (`GEMINI_API_KEY` or `OPENAI_API_KEY`).

The **context window** limits file reading to batches of the specified character length to manage large files. If set to -1, the entire file is loaded without batching.

### Example Config File
```json
{
   "model" : "gemma-3-1b-it",
   "type" : "google",
   "gemini-api-key" : "YOUR_API_KEY",
   "openai-api-key" : "YOUR_API_KEY",
   "sys-info-prompt": "You are a professional programmer and coding expert. You write precise, technical answers. You strictly follow all instructions and constraints given by the user. You do not add unnecessary explanations or introductions.",
   "ask-prompt": "Answer directly and concisely. Do not add any introduction or summary. Do not use markdown or formatting symbols. The output must be plain, terminal-friendly text only.",
   "debug-prompt": "You will receive source code (either complete or split into parts). Your task is to identify bugs or incorrect behavior(sometimes user will specify the problem to solve, focus on it). For each issue: specify the exact line number, explain why it is wrong, and provide a corrected full line or code block. Be precise and technical. Do not add introductions. Do not use markdown. Output must be terminal-friendly plain text.",
   "refactor-prompt": "You will receive source code (either complete or split into parts). Refactor the code while preserving its exact behavior. Improve structure, readability, and eliminate code smells where possible. Do not change functionality. Do not add comments or explanations. Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.",
   "comment-prompt":"You will receive source code (either complete or split into parts). Add comments inside a code, explainign what every function does. If there is complicated syntax, explain it too. Do not change the behavior of the code(do not refactor it, only add comments). Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.",
   "modify-prompt": "You will receive source code (either complete or split into parts). Please modify the given code, following given instruction below. Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.",
   "context-window" : -1
}
```

## Battle Royale Simulator (`battle`)
This is a command-line battle royale simulator where different unit classes fight on a grid-based battlefield. Watch as archers, knights, cavalry, and mages battle until only one remains. It's a fun time-waster to observe automated combat simulations.

### Usage

```
battle -x <width> -y <height> [options]
```

### Required Arguments

- `-x WIDTH`: Set the width of the battlefield.
- `-y HEIGHT`: Set the height of the battlefield.

### Optional Arguments

- `-p PLAYERS`: Total number of players in the simulation.
- `-a ARCHERS`: Specify number of Archer units (A).
- `-k KNIGHTS`: Specify number of Knight units (K).
- `-c CAVALRY`: Specify number of Cavalry units (C).
- `-m MAGES`: Specify number of Mage units (M).

### Automatic Distribution Logic

- If all classes (-a, -k, -c, -m) are provided, the -p value is ignored and automatically recalculated as the sum of all classes.
- If the sum of specified classes is greater than -p, the player count will be increased to match that sum.
- If -p is greater than the sum of specified classes, the remaining slots will be automatically filled by distributing them among the classes that were not explicitly set (left at 0).
- If only -p is given, players are distributed equally among all classes.

### Unit Statistics

| Class    | HP  | Damage | Range | Move |
|----------|-----|--------|-------|------|
| Archers  | 100 | 30     | 4     | 1    |
| Knights  | 200 | 40     | 1     | 1    |
| Cavalry  | 175 | 50     | 1     | 1    |
| Mages    | 100 | 40     | 2     | 1    |
