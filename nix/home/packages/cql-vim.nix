{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
  pname = "cql-vim";
  version = "unstable-2024-01-03";
  src = pkgs.fetchFromGitHub {
    owner = "elubow";
    repo = "cql-vim";
    rev = "6f61df5a633c3a91edea7bcb5d5772648df19d1a";
    sha256 = "sha256-GHiXIJpNJj/ysWywWziUuTy21LKjZKe7q3bUkJjeMV0=";
  };
  meta.homepage = "https://github.com/elubow/cql-vim";
}
