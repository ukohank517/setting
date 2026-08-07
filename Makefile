.PHONY: all mac defaults dotfile

all:
	@echo "make mac      : app/font/CLI check & auto-install, macOS defaults, login shell -> zsh"
	@echo "make defaults : macOS defaults only"
	@echo "make dotfile  : sync config files between git (src/home) and local (~)"

mac:
	bash ./bin/mac_check.sh

defaults:
	bash ./bin/mac_defaults.sh

dotfile:
	bash ./bin/dotfile.sh
	@# apply the synced config to a running herdr server (skip if not running)
	@if command -v herdr >/dev/null && [ -S ~/.config/herdr/herdr.sock ]; then \
		herdr server reload-config; \
	else \
		echo "herdr not running, config will be read on next launch"; \
	fi
