.PHONY: help
help:
	@echo "Usage: make <bootstrap|provision|mypy>"

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
