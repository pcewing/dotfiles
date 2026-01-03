{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
  pname = "mesonic";
  version = "unstable-2024-01-03";
  src = pkgs.fetchFromGitHub {
    owner = "igankevich";
    repo = "mesonic";
    rev = "d6780c3af29ebfc8c631399b2692b928da9bf7bd";
    sha256 = "sha256-XFrV7ZJtVqmUsad/94UZ/ZnPQOKyZ6mmsJlVLtKKAZQ="; # Placeholder
  };
  meta.homepage = "https://github.com/igankevich/mesonic";
}
