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

          url = "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q2_k.gguf";
          sha256 = "sha256-z1hiYV8Q59GRMeyMMiPFGsQ7Y6ZqBge0TbK2lDFE1gc=";

        };
      in
      {
        packages.default = pkgs.writeShellApplication {

          name = "offline-llm";

          text = ''

            if [ "$#" -eq 0 ]; then
              echo "Usage: $0 'your prompt'"
              exit 1
            fi

            PROMPT="$1"
            # shellcheck disable=SC2016
            ${pkgs.llama-cpp}/bin/llama-cli -m ${modelFile} \
            -no-cnv \
            --offline \
            --no-warmup \
            --no-display-prompt \
            --jinja -fa \
            -p "$PROMPT" 2>/dev/null | \
            awk 'BEGIN{p=0} /^```/{p=!p; next} p{print}'

          '';
        };
      }
    );
}
