"""Allow running the CLI via ``python -m dot``."""

import sys

from dot.cli.cli import main

if __name__ == "__main__":
    sys.exit(main())
