.PHONY: help
help:
	@echo "Usage: make <bootstrap|provision|mypy|fmt-lua>"

.PHONY: bootstrap
bootstrap:
	./bootstrap.sh

.PHONY: provision
provision:
	.venv/bin/dot provision

# Run mypy static type checker against Python files
.PHONY: mypy
mypy:
	find . -iname '*.py' -not -path './.venv/*' -not -path '*/__pycache__/*' | xargs mypy --config-file ./mypy.ini
	mypy --config-file ./mypy.ini ./bin/fzf_cached_wsl

# Format every tracked Lua file with stylua (settings in .stylua.toml). To only
# check formatting, run .github/scripts/dotfiles_lint.sh
.PHONY: fmt-lua
fmt-lua:
	git ls-files -z '*.lua' | xargs -0 stylua
