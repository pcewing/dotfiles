1. There's a few apt packages that don't appear to have direct associated nix packages:
    # TODO: software-properties-common
    # TODO: apt-file
    # TODO: libfuse

Figure out if we still need those and if so, how to install properly.

2. Clang and GCC

Installing both `clang` and `gcc` in `home.packages` results in a conflict
because they both provide the same colliding `ld.bfd` file. For now, I'm only
installing `clang-tools` without `clang`. We can try to figure out how to have
both side-by-side later on or maybe just make a different profile for clang

3. Bcompare license

According to the docs, if we just put our license in a text file in the right
place registration should automatically happen:
https://www.scootersoftware.com/kb/linuxtips

Maybe we can have Nix do that?
