PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

# genai tool vars
GENAI_SRC = genai_coding_assistant/code_ai.pl
GENAI_CONFIG = .aicode_conf
GENAI_BIN = aicode

# gitignore tool vars
GITIGNORE_SRC = gitignore_creation_script/createigit.py
GITIGNORE_BIN = createigit

# battle royale simulator var
BATTLE_SRC = battle_royale_simulation/battle_royale.sh
BATTLE_BIN = battle

.PHONY: install uninstall \
        install-genai uninstall-genai \
        install-gitignore uninstall-gitignore \
		install-battleroyale uninstall-battleroyale\
        help

# =========================
# DEFAULT
# =========================
install: install-genai install-gitignore install-battleroyale

uninstall: uninstall-genai uninstall-gitignore uninstall-battleroyale

# =========================
# GENAI CODING ASSISTANT
# =========================
install-genai: check-perl check-sudo
	@echo "\n======= Installing GenAI Coding Assistant =======\n"
	@command -v perl >/dev/null 2>&1 || { \
		echo "❌ Error: perl is not installed"; \
		exit 1; \
	}
	@perl -e 'exit($$] < 5 ? 1 : 0)' || { \
		echo "❌ Error: perl version < 5"; \
		exit 1; \
	}
	install -m 755 $(GENAI_SRC) $(BINDIR)/$(GENAI_BIN)
	
	mkdir -p $(HOME)/.aicode_conf
	@perl -MTie::IxHash -MJSON -e ' \
		tie my %conf, "Tie::IxHash"; \
		%conf = ( \
			"model"           => "gemma-3-27b-it", \
			"type"            => "google", \
			"gemini-api-key"  => "", \
			"openai-api-key"  => "", \
			"sys-info-prompt" => "You are a professional programmer and coding expert. You write precise, technical answers. You strictly follow all instructions and constraints given by the user. You do not add unnecessary explanations or introductions.", \
			"ask-prompt"      => "Answer directly and concisely. Do not add any introduction or summary. Do not use markdown or formatting symbols. The output must be plain, terminal-friendly text only.", \
			"debug-prompt"    => "You will receive source code (either complete or split into parts). Your task is to identify bugs or incorrect behavior(sometimes user will specify the problem to solve, focus on it). For each issue: specify the exact line number, explain why it is wrong, and provide a corrected full line or code block. Be precise and technical. Do not add introductions. Do not use markdown. Output must be terminal-friendly plain text.", \
			"refactor-prompt" => "You will receive source code (either complete or split into parts). Refactor the code while preserving its exact behavior. Improve structure, readability, and eliminate code smells where possible. Do not change functionality. Do not add comments or explanations. Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.", \
			"comment-prompt"  => "You will receive source code (either complete or split into parts). Add comments inside the code explaining what each function does. Explain complex syntax if present. Do not change behavior. Do not refactor. Do not add introductions. Do not use markdown. Output must be code only.", \
			"modify-prompt"	=> "You will receive source code (either complete or split into parts). Please modify the given code, following given instruction below. Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.", \
			"context-window"  => -1 \
		); \
		print JSON->new->pretty->encode(\%conf); \
	' > $(HOME)/.aicode_conf/config.json
	
	@if [ "$$SUDO_USER" ]; then \
		chown -R $$SUDO_USER $(HOME)/.aicode_conf; \
		echo "Changed ownership of config to $$SUDO_USER"; \
	fi
	chmod 644 $(HOME)/.aicode_conf/config.json

uninstall-genai: check-sudo
	@echo "\n======= Removing GenAI Coding Assistant =======\n"
	rm -rf $(HOME)/$(GENAI_CONFIG)
	rm -f $(BINDIR)/$(GENAI_BIN)


# =========================
# GITIGNORE CREATION SCRIPT
# =========================
install-gitignore: check-python3 check-sudo
	@echo "\n======= Installing gitignore creation script =======\n"
	@command -v python3 >/dev/null 2>&1 || { \
		echo "❌ Error: python3 is not installed"; \
		exit 1; \
	}
	install -m 755 $(GITIGNORE_SRC) $(BINDIR)/$(GITIGNORE_BIN)

uninstall-gitignore: check-sudo 
	@echo "\n======= Removing gitignore creation script =======\n"
	rm -f $(BINDIR)/$(GITIGNORE_BIN)

# =========================
# BATTLE ROYALE CREATION SCRIPT
# =========================
install-battleroyale: check-bash check-sudo
	@echo "\n======= Installing battle royal simmulator =======\n"
	install -m 755 $(BATTLE_SRC) $(BINDIR)/$(BATTLE_BIN)

uninstall-battleroyale: check-sudo
	@echo "\n======= Removing battle royal simmulator =======\n"
	rm -f $(BINDIR)/$(BATTLE_BIN)

# =========================
# DEPENDENCY CHECK
# =========================
check-sudo:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "❌ Error: this target must be run with sudo/root"; \
		exit 1; \
	fi

check-perl:
	@command -v perl >/dev/null 2>&1 || { \
		echo "❌ Error: perl is not installed"; \
		exit 1; \
	}
	@perl -e 'exit($$] < 5 ? 1 : 0)' || { \
		echo "❌ Error: perl version < 5"; \
		exit 1; \
	}

check-python3:
	@command -v python3 >/dev/null 2>&1 || { \
		echo "❌ Error: python3 is not installed"; \
		exit 1; \
	}

check-bash:
	@command -v bash >/dev/null 2>&1 || { \
		echo "❌ Error: bash is not installed"; \
		exit 1; \
	}

# =========================
# HELP
# =========================
help:
	@echo "Available targets:"
	@echo "  make install              Install all tools"
	@echo "  make uninstall            Remove all tools"
	@echo "  make install-genai        Install GenAI assistant only"
	@echo "  make uninstall-genai      Remove GenAI assistant"
	@echo "  make install-gitignore    Install gitignore tool only"
	@echo "  make uninstall-gitignore  Remove gitignore tool"
	@echo "  make install-battleroyale    Install battle royale simulator only"
	@echo "  make uninstall-battleroyale  Remove battle royale simulator"