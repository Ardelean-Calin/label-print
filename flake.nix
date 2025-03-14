{
  description = "Label printing development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Python with brother_ql package
        pythonEnv = pkgs.python312.withPackages (ps: with ps; [
          brother-ql
        ]);
        
        # Script to print labels
        printLabelScript = pkgs.writeScriptBin "print-label" ''
          #!${pkgs.bash}/bin/bash
          if [ $# -lt 2 ]; then
            echo "Usage: print-label TEXT PRINTER_PATH"
            echo "Example: print-label \"Hello World\" /dev/usb/lp0"
            exit 1
          fi
          
          TEXT="$1"
          PRINTER_PATH="$2"
          
          ${pythonEnv}/bin/python ${self}/print_label.py "$TEXT" "$PRINTER_PATH"
        '';
        
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.typst
            printLabelScript
          ];
          
          shellHook = ''
            echo "Development environment loaded with typst and brother_ql"
            echo "Use 'print-label \"Your text\" /path/to/printer' to print a label"
          '';
        };
      }
    );
}
