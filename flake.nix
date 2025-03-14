{
  description = "Label printing development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Script to print labels
        printLabelScript = pkgs.writeScriptBin "print-label" ''
          #!${pkgs.bash}/bin/bash
          ${pkgs.uv}/bin/uv run ${./print_label.py} "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.typst
            pkgs.uv
            pkgs.zlib
            printLabelScript
          ];

          shellHook = ''
            echo "Development environment loaded with typst and brother_ql"
            echo "Use 'uv run print_label.py \"Your text\" /path/to/printer' to print a label"
            echo "Use 'uv run print_label.py --dry-run \"Your text\"' to preview a label without printing"
          '';
        };
      }
    );
}
