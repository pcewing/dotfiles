# wpr - Custom X11 Wallpaper Rotator Tool
# https://s3-us-west-2.amazonaws.com/pcewing-wpr/releases/
{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "wpr";
  version = "0.1.0";

  src = fetchurl {
    url = "https://s3-us-west-2.amazonaws.com/pcewing-wpr/releases/${version}/wpr.${version}.linux-amd64.tar.gz";
    sha256 = "sha256-YuJBoD8JWn1+fBMYdihIRz7qxpM+T+WmC3ruL2TcHWM=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp wpr $out/bin/
    chmod +x $out/bin/wpr
  '';

  meta = with lib; {
    description = "wpr x11 wallpaper rotator tool";
    platforms = platforms.linux;
  };
}
