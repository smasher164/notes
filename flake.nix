{
  description = "notes";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let supportedSystems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
    ]; in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.flutter
            pkgs.llvmPackages_13.clang
            pkgs.cmake
            pkgs.ninja
            pkgs.gtk3
            pkgs.glib
            pkgs.gobjectIntrospection
            pkgs.pkgconfig
            pkgs.pcre
            pkgs.libepoxy
            pkgs.gnome3.adwaita-icon-theme
            pkgs.hicolor-icon-theme
            pkgs.utillinux
            pkgs.cargo
            pkgs.rustc
          ];
          shellHook = ''
            export XDG_DATA_DIRS="$XDG_DATA_DIRS:$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH"
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.libepoxy}/lib"
          '';
        };
      });
}
