{
  description = "Offline LLM via llama.cpp with pre-fetched model";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        modelFile = pkgs.fetchurl {

          # url= "https://huggingface.co/gaebalai/DeepSeek-R1-0528-Qwen3-8B-Q8-GUFF/resolve/main/DeepSeek-R1-0528-Qwen3-8B-Q8_0.gguf";
          # sha256 = "sha256-emsr08k618afIAF8AZ5sOKOYh5aNsdjgAPKt25Nryc0=";

          url = "https://huggingface.co/h4shy/gemma-3-1b-it-fast-GUFF/resolve/main/gemma3-1b-Q8_0.gguf";
          sha256 = "sha256-z3V0tROK77VOmnDCgUSnDcvr27afwKlVj56zUC1O9R8=";
        };
      in
      {

        packages = rec {

          model = pkgs.stdenv.mkDerivation {
            name = "modelfile";

            src = pkgs.fetchgit {
              url = "https://huggingface.co/Qwen/Qwen2.5-Coder-3B";
              rev = "09d9bc5d376b0cfa0100a0694ea7de7232525803";
              fetchLFS = true;
              sha256 = "sha256-VSaxtj1WZB6upGCbqZThamlkYIAjrzkMxnnrXy8JUyg=";
            };

            buildInputs = [
              pkgs.llama-cpp
              pkgs.python3
            ];

            buildPhase = "convert_hf_to_gguf.py $src --outfile model.gguf";
            installPhase = "cp model.gguf $out";
          };

          default = pkgs.writeShellApplication {

            name = "offline-llm";

            text = ''

              if [ "$#" -eq 0 ]; then
                echo "Usage: $0 'your prompt'"
                exit 1
              fi

              PROMPT="$1"
              # shellcheck disable=SC2016
              ${pkgs.llama-cpp}/bin/llama-cli -m ${model} \
              -no-cnv \
              --offline \
              --no-warmup \
              --no-display-prompt \
              -p "$PROMPT"

            '';
          };
        };
      }
    );
}
