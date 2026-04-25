{
  description = "Nix dev shell for TTS-Story";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        python = pkgs.python312;

        pythonRuntimeLibs = with pkgs; [
          stdenv.cc.cc
          zlib
          glib
          openssl
          libsndfile
          libffi
          sqlite
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python
            git
            gnumake
            gcc
            pkg-config
            cmake
            ffmpeg
            sox
            rubberband
            espeak-ng
            libsndfile
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath pythonRuntimeLibs;

          shellHook = ''
            export PIP_DISABLE_PIP_VERSION_CHECK=1
            export PYTHONNOUSERSITE=1

            echo "TTS-Story dev shell ready"
            echo "Run: ./setup.sh"
            echo "Then: ./run.sh"
          '';
        };
      });
}
