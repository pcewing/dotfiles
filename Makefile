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
