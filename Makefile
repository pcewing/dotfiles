.PHONY: help
help:
	@echo "Usage: make <link|clean|windows>"

.PHONY: link
link:
	./dot.sh link

.PHONY: clean
clean:
	./dot.sh clean

.PHONY: windows
windows:
	./dot.sh windows

# Run mypy static type checker against Python files
.PHONY: mypy
mypy:
	find . -iname '*.py' | xargs mypy --config-file ./mypy.ini
	mypy --config-file ./mypy.ini ./bin/fzf_cached_wsl

# Run nixfmt on all Nix files
.PHONY: nixfmt
nixfmt:
	# Run this in a nix-shell so we can get the most up-to-date version of
	# nixfmt since the --indent option was added fairly recently.
	nix-shell -p nixfmt --run "find . -iname '*.nix' | xargs nixfmt --indent=4"
