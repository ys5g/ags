# Bundles an AGS project into a standalone binary
self: pkgs': {
  pkgs ? pkgs',
  lib ? pkgs.lib,
  # Appending `Pkg` so they don't conflict with packages in nixpkgs
  agsPkg ? self.packages.${pkgs.sys}.ags,
  astalPkg ? self.packages.${pkgs.sys}.astal,
  pname ? "ags-project",
  src,
  version ? "0.1.0",
  meta ? null,
  extraPackages ? [],
}:
pkgs.stdenvNoCC.mkDerivation {
  inherit pname src version meta;

  nativeBuildInputs = with pkgs; [
    agsPkg
    wrapGAppsHook
    gobject-introspection
  ];
  builtInputs =
    extraPackages
    ++ (with pkgs; [
      astalPkg
      gjs
      glib
      gtk3
    ]);

  buildPhase = "ags -c ${src} --bundle";

  installPhase = ''
    mkdir -p $out/bin

    # Adds a shebang that calls gjs
    sed -i '1i\#!${lib.getExe pkgs.gjs} -m' ags.js

    install -m 755 ags.js $out/bin/${pname}
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${lib.makeBinPath extraPackages}"
    )
  '';
}
