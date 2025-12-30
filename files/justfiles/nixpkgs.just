upgrade-nix:
    echo 'Installing latest Lix package'
    nix profile install nixpkgs#lix && nix upgrade-nix

install-nix-software-center:
    echo 'Installing Nix Software Center'
    nix profile install github:snowfallorg/nix-software-center