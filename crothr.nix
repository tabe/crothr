{ config
, stdenv
, fetchurl
, rPackages
, rWrapper
, runCommand
}: let

  torch-source = fetchurl {
    url = "https://cran.r-project.org/src/contrib/torch_0.12.0.tar.gz";
    hash = "sha256-eG16/sgNKBlMPUoe4MTlcn1V1+jSAFJo/kL18b5GjAg=";
  };

  r-torch = rPackages.buildRPackage {
    name = "torch";
    src = torch-source;

    ## Ignore the package's configure
    installFlags = "--no-configure";

    ## Skip the build of lantern
    preInstall = ''
      sed -e "s|@LANTERN_TARGET@|dummylantern|" src/Makevars.in > src/Makevars
    '';

    ## Imports from https://cran.r-project.org/package=torch
    propagatedBuildInputs = with rPackages; [
      Rcpp
      R6
      withr
      rlang
      bit64
      magrittr
      coro
      callr
      cli
      glue
      ellipsis
      desc
      safetensors
      jsonlite
    ];
  };

  libtorch-zip = fetchurl (if stdenv.isDarwin then {
    url = "https://github.com/mlverse/libtorch-mac-m1/releases/download/LibTorch-for-R/libtorch-v2.0.1.zip";
    hash = "sha256-cIvVxPCQRxuPvnjCzPaZ6b30QjTTQmewX4mLMrpUKnU=";
  } else (if config.cudaSupport then {
    url = "https://download.pytorch.org/libtorch/cu118/libtorch-cxx11-abi-shared-with-deps-2.0.1%2Bcu118.zip";
    hash = "";
  } else {
    url = "https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-2.0.1%2Bcpu.zip";
    hash = "sha256-E3qELRzx6RlrQZOQEzoWI++S+PhNx6By+VraaE85Sv0=";
  }));

  lantern-zip = fetchurl (if stdenv.isDarwin then {
    url = "https://storage.googleapis.com/torch-lantern-builds/binaries/refs/heads/cran/v0.12.0/latest/lantern-0.12.0+cpu+arm64-Darwin.zip";
    hash = "sha256-v+0pgMZBuakETXhMUfYWrBUG41TjWB0hDpp/p7xmuk0=";
  } else (if config.cudaSupport then {
    url = "https://storage.googleapis.com/torch-lantern-builds/binaries/refs/heads/cran/v0.12.0/latest/lantern-0.12.0+cu118+x86_64-Linux.zip";
    hash = "";
  } else {
    url = "https://storage.googleapis.com/torch-lantern-builds/binaries/refs/heads/cran/v0.12.0/latest/lantern-0.12.0+cpu+x86_64-Linux.zip";
    hash = "sha256-pdpxXNbQRez2KduC6zN9/E02EOcS6WizyJ0Yc06N7no=";
  }));

  build-R = rWrapper.override {
    packages = [
      r-torch
    ];
  };

  torch = runCommand "torch" { buildInputs = [ build-R ]; } ''
    export TORCH_HOME=$out
    export TORCH_URL="${libtorch-zip}"
    export LANTERN_URL="${lantern-zip}"
    Rscript --vanilla -e "torch::install_torch()"
  '';

in {
  r-torch = r-torch;
  torch = torch;
}
