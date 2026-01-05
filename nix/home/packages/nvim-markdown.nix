{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-markdown";
    version = "unstable-2024-01-03";
    src = pkgs.fetchFromGitHub {
        owner = "ixru";
        repo = "nvim-markdown";
        rev = "37850581fdaec153ce84af677d43bf8fce60813a";
        sha256 = "sha256-wjYTO9WqdDEbH4L3dsHqOoeQf0y/Uo6WX94w/D4EuGU=";
    };
    meta.homepage = "https://github.com/ixru/nvim-markdown";
}
