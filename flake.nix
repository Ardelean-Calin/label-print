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

        # Python with brother_ql package
        pythonEnv = pkgs.python312.withPackages (ps:
          with ps; [
            brother-ql
          ]);

        # Script to print labels
        printLabelScript = pkgs.writeScriptBin "print-label" ''
          #!${pkgs.bash}/bin/bash
          DRY_RUN=""

          # Parse arguments
          while [[ $# -gt 0 ]]; do
            case "$1" in
              --dry-run)
                DRY_RUN="--dry-run"
                shift
                ;;
              *)
                if [ -z "$TEXT" ]; then
                  TEXT="$1"
                elif [ -z "$PRINTER_PATH" ]; then
                  PRINTER_PATH="$1"
                else
                  echo "Too many arguments"
                  exit 1
                fi
                shift
                ;;
            esac
          done

          if [ -z "$TEXT" ] || ([ -z "$PRINTER_PATH" ] && [ -z "$DRY_RUN" ]); then
            echo "Usage: print-label [--dry-run] TEXT [PRINTER_PATH]"
            echo "  --dry-run    Generate the label image but don't print it"
            echo "Example: print-label \"Hello World\" /dev/usb/lp0"
            echo "Example: print-label --dry-run \"Hello World\""
            exit 1
          fi

          ${pythonEnv}/bin/python ${self}/print_label.py "$TEXT" "$PRINTER_PATH" $DRY_RUN
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.typst
            pkgs.uv
            printLabelScript
          ];

          shellHook = ''
            echo "Development environment loaded with typst and brother_ql"
            echo "Use 'print-label \"Your text\" /path/to/printer' to print a label"
            echo "Use 'print-label --dry-run \"Your text\"' to preview a label without printing"
          '';
        };
      }
    );
}
