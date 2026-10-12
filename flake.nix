{
  description = "Proteus 9 (Labcenter Electronics) under NixOS via Wine";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      wine = pkgs.wineWow64Packages.stable;

      env = ''
        export WINEARCH=win64
        export WINEPREFIX="''${PROTEUS_PREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/proteus9/prefix}"
        export WINEDEBUG="''${WINEDEBUG:--all}"
        # évite la création d'entrées de menu parasites par Wine
        export WINEDLLOVERRIDES="''${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
      '';

      # Usage : nix run .#setup -- prodemo.exe 
      proteus-setup = pkgs.writeShellApplication {
        name = "proteus-setup";
        runtimeInputs = [ wine pkgs.winetricks pkgs.cabextract pkgs.p7zip ];
        text = ''
          ${env}
          installer="''${1:?usage: proteus-setup <installeur-proteus.exe>}"
          mkdir -p "$WINEPREFIX"
          wineboot -u
          # 
          winetricks -q win8 corefonts vcrun2019 gdiplus dotnet48
          wine "$installer"
        '';
      };

      proteus-run = pkgs.writeShellApplication {
        name = "proteus";
        runtimeInputs = [ wine pkgs.findutils ];
        text = ''
          ${env}
          exe="''${PROTEUS_EXE:-}"
          if [ -z "$exe" ]; then
            exe="$(find "$WINEPREFIX/drive_c" -ipath '*Proteus 9*/BIN/PDS.EXE' -print -quit 2>/dev/null || true)"
          fi
          if [ -z "$exe" ]; then
            echo "Proteus 9 introuvable dans $WINEPREFIX : lancez d'abord proteus-setup <installeur.exe>" >&2
            exit 1
          fi
          cd "$(dirname "$exe")"
          exec wine "$exe" "$@"
        '';
      };

      desktop = pkgs.makeDesktopItem {
        name = "proteus9";
        desktopName = "Proteus 9";
        exec = "proteus";
        categories = [ "Development" "Electronics" ];
      };

      proteus = pkgs.symlinkJoin {
        name = "proteus9-wine";
        paths = [ proteus-run proteus-setup desktop ];
      };
    in
    {
      packages.${system} = {
        default = proteus;
        inherit proteus proteus-setup;
      };

      apps.${system} = {
        default = { type = "app"; program = "${proteus-run}/bin/proteus"; };
        setup   = { type = "app"; program = "${proteus-setup}/bin/proteus-setup"; };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ wine pkgs.winetricks proteus-run proteus-setup ];
      };
    };
}
