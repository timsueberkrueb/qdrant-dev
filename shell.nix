# Nix Development environment for Qdrant
#
# Usage:
#
# ```shell
# nix-shell
# ```
let
  # Overlay for the latest stable version of Rust
  rust_overlay = import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz");
  pkgs = import <nixpkgs> { overlays = [ rust_overlay ]; };
  rustStable = pkgs.rust-bin.stable.latest.minimal.override {
    extensions = [ "rust-src" ];
  };
  clippy = pkgs.rust-bin.stable.latest.clippy;
  # Nightly for rustfmt only
  rustfmt = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.rustfmt);

  # Protobuf pinned to the currently required version (compare `docs/DEVELOPMENT.md`)
  protobuf-pinned = pkgs.stdenv.mkDerivation rec {
    pname = "protobuf";
    version = "22.2";
    src = pkgs.fetchzip {
      url = "https://github.com/protocolbuffers/protobuf/releases/download/v${version}/protoc-${version}-linux-x86_64.zip";
      sha256 = "sha256-7d3sA+XhAP+s4ialfm/0vWoUgd3BBsJhh+5jNciRegc=";
      stripRoot = false;
    };
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r bin include $out/
    '';
  };
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # Build dependencies
    rustStable gcc clang llvmPackages.libclang.lib cmake jq protobuf-pinned
    # Linter
    clippy rustfmt
    # Profiling
    flamegraph cargo-flamegraph pprof graphviz gnuplot
  ];

  # Needed for librocksdb-sys to find libclang
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
}
