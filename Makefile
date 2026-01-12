PREFIX ?= /usr/local
BINDIR  ?= $(PREFIX)/bin

# =========================
# TOOLS
# =========================
GENAI_SRC    = genai_coding_assistant/code_ai.pl
GENAI_BIN    = aicode
GENAI_SRC_CONF = genai_coding_assistant/example_config.json
GENAI_CONF   = .aicode_conf

GITIGNORE_SRC = gitignore_creation_script/createigit.py
GITIGNORE_BIN = createigit

BATTLE_SRC = battle_royale_simulation/battle_royale.sh
BATTLE_BIN = battle

# =========================
# INTERNAL VARS
# =========================
REAL_USER  := $(if $(SUDO_USER),$(SUDO_USER),$(USER))
REAL_HOME  := $(shell eval echo ~$(REAL_USER))

# =========================
.PHONY: install uninstall \
        install-genai uninstall-genai \
        install-gitignore uninstall-gitignore \
        install-battleroyale uninstall-battleroyale \
        check-sudo check-perl check-python3 check-bash \
        help

# =========================
# DEFAULT
# =========================
install: install-genai install-gitignore install-battleroyale
uninstall: uninstall-genai uninstall-gitignore uninstall-battleroyale

# =========================
# GENAI CODING ASSISTANT
# =========================
install-genai: check-sudo check-perl
	@echo "\n======= Installing GenAI Coding Assistant =======\n"

	install -m 755 $(GENAI_SRC) $(BINDIR)/$(GENAI_BIN)

	mkdir -p $(REAL_HOME)/$(GENAI_CONF)
	
	install -m 755 $(GENAI_SRC_CONF) $(REAL_HOME)/$(GENAI_CONF)/config.json
	
	chown -R $(REAL_USER) $(REAL_HOME)/$(GENAI_CONF)
	chmod 644 $(REAL_HOME)/$(GENAI_CONF)/config.json

	@echo "✅ GenAI installed successfully"


uninstall-genai: check-sudo
	@echo "\n======= Removing GenAI Coding Assistant =======\n"
	rm -f $(BINDIR)/$(GENAI_BIN)
	rm -rf $(REAL_HOME)/$(GENAI_CONF)

# =========================
# GITIGNORE TOOL
# =========================
install-gitignore: check-sudo check-python3
	@echo "\n======= Installing gitignore tool =======\n"
	install -m 755 $(GITIGNORE_SRC) $(BINDIR)/$(GITIGNORE_BIN)

uninstall-gitignore: check-sudo
	@echo "\n======= Removing gitignore tool =======\n"
	rm -f $(BINDIR)/$(GITIGNORE_BIN)

# =========================
# BATTLE ROYALE
# =========================
install-battleroyale: check-sudo check-bash
	@echo "\n======= Installing battle royale simulator =======\n"
	install -m 755 $(BATTLE_SRC) $(BINDIR)/$(BATTLE_BIN)

uninstall-battleroyale: check-sudo
	@echo "\n======= Removing battle royale simulator =======\n"
	rm -f $(BINDIR)/$(BATTLE_BIN)

# =========================
# DEPENDENCY CHECKS
# =========================
check-sudo:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "❌ Error: run with sudo/root"; \
		exit 1; \
	fi

check-perl:
	@command -v perl >/dev/null 2>&1 || { echo "❌ perl not found"; exit 1; }

check-python3:
	@command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found"; exit 1; }

check-bash:
	@command -v bash >/dev/null 2>&1 || { echo "❌ bash not found"; exit 1; }

# =========================
# HELP
# =========================
help:
	@echo "Available targets:"
	@echo "  make install"
	@echo "  make uninstall"
	@echo "  make install-genai"
	@echo "  make uninstall-genai"
	@echo "  make install-gitignore"
	@echo "  make uninstall-gitignore"
	@echo "  make install-battleroyale"
	@echo "  make uninstall-battleroyale"
