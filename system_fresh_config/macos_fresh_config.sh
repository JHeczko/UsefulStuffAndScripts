#!/usr/bin/env bash

LINE_MOUSE="defaults write -g com.apple.mouse.scaling -integer -1"
LINE_ALIAS_LL='alias ll="ls -al"'
FILE="$HOME/.zprofile"

# ======= Miniconda install =======
set -e

# Ścieżka do instalacji
INSTALL_DIR="$HOME/miniconda"
PROFILE="$HOME/.zprofile"

# Sprawdź, czy conda już istnieje
if [ -d "$INSTALL_DIR" ]; then
    echo "✅ Miniconda już zainstalowana w $INSTALL_DIR"
else
    echo "📦 Instaluję Minicondę..."

    # Pobierz instalator (dla Intela - x86_64)
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O ~/miniconda.sh

    # Zainstaluj w trybie batch (-b) w katalogu $HOME/miniconda
    bash ~/miniconda.sh -b -p "$INSTALL_DIR"

    # Usuń instalator
    rm -rf ~/miniconda.sh

    # Dodaj Minicondę do PATH w .zprofile (tylko jeśli jeszcze jej tam nie ma)
    LINE="export PATH=\"$INSTALL_DIR/bin:\$PATH\""
    if ! grep -Fqx "$LINE" "$PROFILE"; then
        echo "$LINE" >> "$PROFILE"
    fi

    # Załaduj zmiany
    export PATH="$INSTALL_DIR/bin:$PATH"

    echo "✅ Miniconda zainstalowana i skonfigurowana."
fi

# ======= brew install =======
set -e

# Sprawdź czy brew istnieje
if command -v brew &>/dev/null; then
    echo "✅ Homebrew już zainstalowany."
else
    echo "📦 Instaluję Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Wykryj architekturę
ARCH=$(uname -m)
PROFILE="$HOME/.zprofile"

if [[ "$ARCH" == "arm64" ]]; then
    LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'
else
    LINE='eval "$(/usr/local/bin/brew shellenv)"'
fi

if ! grep -Fqx "$LINE" "$PROFILE"; then
    echo "$LINE" >> "$PROFILE"
fi

eval "$LINE"


# ======= personal aliases =======
if ! grep -Fxq "$LINE_MOUSE" "$FILE"; then
    echo "$LINE_MOUSE" >> "$FILE"
fi

if ! grep -Fxq "$LINE_ALIAS_LL" "$FILE"; then
    echo "$LINE_MOUSE" >> "$FILE"
fi

eval "$LINE_MOUSE"
eval "$LINE_ALIAS_LL"