{
  description = "Example using crothr";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }: let

    supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];

    forSupportedSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f (import nixpkgs { inherit system; }));

    example = pkgs: with pkgs; let

      crothr = callPackages ../crothr.nix {};

      R = rWrapper.override {
        packages = [ crothr.r-torch ];
      };

      ## Antal,Balint and Hajdu,Andras. (2014). Diabetic Retinopathy Debrecen. UCI Machine Learning Repository. https://doi.org/10.24432/C5XP4P.
      messidor-data = fetchzip {
        url = "https://archive.ics.uci.edu/static/public/329/diabetic+retinopathy+debrecen.zip";
        hash = "sha256-sMhob6BSAzeuNiL4fhq42v3Y+JHPB0sBXr9rihTs4fE=";
      };

      train-R = ./R;

      train = writeShellApplication {
        name = "train";

        derivationArgs = {

          buildInputs = [
            crothr.torch
            messidor-data
            train-R
          ];

        };

        runtimeInputs = [
          R
        ];

        text = ''
          export TORCH_HOME=${crothr.torch}
          Rscript ${train-R}/train.R ${messidor-data}/messidor_features.arff
        '';
      };

    in {
      default = train;
    };

  in {
    packages = forSupportedSystems example;
  };
}
