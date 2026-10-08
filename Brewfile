# Non-Nix setup: mirrors the Homebrew lists in configuration.nix and the
# packages from home.nix. Apply with ./bootstrap-brew.sh (or `brew bundle`).

# from configuration.nix (brews)
brew "herdr"
brew "treehouse"
# terraform is provided by tfenv (already installed here); the unversioned
# terraform formula is no longer in homebrew-core and would conflict with it.
brew "tfenv"
brew "gh"

# from configuration.nix (casks)
cask "wezterm"
cask "claude-code"
cask "fluidvoice"
cask "gcloud-cli"

# from home.nix (home.packages)
brew "ripgrep"
brew "fd"
brew "fzf"
brew "jq"
brew "lazygit"
brew "neovim"
cask "font-hack-nerd-font"

# from home.nix (programs.zsh / programs.starship)
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
