all:
	echo "do some setting"

mac:
	bash ./bin/mac_check.sh

defaults:
	bash ./bin/mac_defaults.sh

shell:
	bash ./bin/shell_setting.sh

dotfile:
	bash ./bin/dotfile.sh
	@# apply the synced config to a running herdr server (skip if not running)
	@if command -v herdr >/dev/null && [ -S ~/.config/herdr/herdr.sock ]; then \
		herdr server reload-config; \
	else \
		echo "herdr not running, config will be read on next launch"; \
	fi

