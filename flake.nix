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
        stdenv = pkgs.stdenv;
        lib = pkgs.lib;
      in
      {
        devShell = pkgs.mkShell rec {
          buildInputs = [
            pkgs.flutter
            pkgs.dart
            pkgs.llvmPackages_13.clang
            pkgs.llvmPackages_13.libclang.lib
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
            pkgs.rustfmt
          ];
          shellHook = ''
            export XDG_DATA_DIRS="$XDG_DATA_DIRS:$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH"
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.libepoxy}/lib"
            export Rust_CARGO="${pkgs.cargo}/bin/cargo"
            export PATH=~/.cargo/bin:$PATH
            export LIBCLANG_PATH="${pkgs.llvmPackages_13.libclang.lib}/lib";
            export BINDGEN_EXTRA_CLANG_ARGS="$(< ${stdenv.cc}/nix-support/libc-crt1-cflags) \
              $(< ${stdenv.cc}/nix-support/libc-cflags) \
              $(< ${stdenv.cc}/nix-support/cc-cflags) \
              $(< ${stdenv.cc}/nix-support/libcxx-cxxflags) \
              ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
              ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
            ";
            alias gen-bindings='flutter_rust_bridge_codegen --llvm-path=$LIBCLANG_PATH/libclang.so --llvm-compiler-opts="$BINDGEN_EXTRA_CLANG_ARGS" --rust-input=backend/src/api.rs  --rust-output=backend/src/bridge_generated.rs -d lib/bridge_generated.dart -c ios/Runner/bridge_generated.h && flutter pub run build_runner build';
          '';
        };
      });
}
