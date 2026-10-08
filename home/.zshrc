# Hand-written equivalent of the zsh config that home.nix generates.
# Used by the non-Nix setup (bootstrap-brew.sh links this to ~/.zshrc).

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export EDITOR=nvim

alias ..='cd ..'
alias add='git add .'
alias push='git push'
alias pull='git pull'
alias m='git switch main'
alias cc='claude --dangerously-skip-permissions'
alias co='codex --full-auto'

command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  # ghost text from history
  [ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
    && . "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  bindkey '^f' autosuggest-accept
  # must be sourced last: commands turn green when valid
  [ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
    && . "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
