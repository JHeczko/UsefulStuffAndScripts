#!/usr/bin/env bash

LINE_MOUSE="defaults write -g com.apple.mouse.scaling -integer -1"
LINE_ALIAS_LL='alias ll="ls -al"'
PATH_BIN_ALIAS='export PATH=\"$BIN_DIR:\$PATH\"'
FILE="$HOME/.zprofile"

# ======= create .bin folder =======
if [ ! -d "$BIN_DIR" ]; then
    mkdir -p "$BIN_DIR"
    echo "📂 Utworzono katalog $BIN_DIR"
fi

# ======= add scripts to .bin =======
REPO_URL="git@github.com:JHeczko/UsefulStuffAndScripts.git"
REPO_DIR="$HOME/UsefulStuffAndScripts"
SCRIPT_SRC="gitignore_creation_script/createigit.py"
SCRIPT_DEST="$HOME/.bin/createigit"

# clone repo
git clone "$REPO_URL" "$REPO_DIR"

# add createigit script
cp "$REPO_DIR/$SCRIPT_SRC" "$SCRIPT_DEST"
chmod 755 "$SCRIPT_DEST"

# delete repo
rm -rf "$REPO_DIR"

# ======= add lines to .zprofile =======
if ! grep -Fxq "$PATH_BIN_ALIAS" "$FILE"; then
    echo "$PATH_BIN_ALIAS" >> "$FILE"
fi

if ! grep -Fxq "$LINE_MOUSE" "$FILE"; then
    echo "$LINE_MOUSE" >> "$FILE"
fi

if ! grep -Fxq "$LINE_ALIAS_LL" "$FILE"; then
    echo "$LINE_MOUSE" >> "$FILE"
fi

eval "$LINE_MOUSE"
eval "$LINE_ALIAS_LL"
eval "$PATH_BIN_ALIAS"