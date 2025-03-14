{
  description = "Label printing development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        fontFiles = pkgs.symlinkJoin {
          name = "fonts";
          paths = [ ./fonts ];
        };

        # Script to print labels
        printLabelScript = pkgs.writeScriptBin "print-label" ''
          #!/usr/bin/env bash
          export PATH=$PATH:${fontFiles}/fonts
          export FONT_PATH=${fontFiles}/fonts
          ${pkgs.uv}/bin/uv run ${./print_label.py} "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.typst
            pkgs.uv
            printLabelScript
          ];
        };
      }
    );
}
