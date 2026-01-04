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
	nix-shell -p nixfmt --run "find . -iname '*.nix' | xargs nixfmt --indent=4"
