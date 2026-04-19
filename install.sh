#!/usr/bin/env bash
# dotfiles installer: Neovim + LazyVim config (sudo 불필요, ~/.local 설치)
set -euo pipefail

REPO_URL="https://github.com/SonAIengine/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
NVIM_DIR="$HOME/.config/nvim"
LOCAL_DIR="$HOME/.local"
BIN_DIR="$LOCAL_DIR/bin"

log() { printf "\033[1;34m[install]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }

# 1. 필수 명령 확인
for cmd in git curl tar; do
  command -v "$cmd" >/dev/null || { err "$cmd required"; exit 1; }
done

# 2. Neovim 바이너리 설치
if command -v "$BIN_DIR/nvim" >/dev/null 2>&1 || command -v nvim >/dev/null 2>&1; then
  log "nvim already installed, skipping binary"
else
  log "installing neovim (latest stable, user-space)"
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  ASSET="nvim-linux-x86_64.tar.gz" ;;
    aarch64) ASSET="nvim-linux-arm64.tar.gz" ;;
    *) err "unsupported arch: $ARCH"; exit 1 ;;
  esac
  mkdir -p "$LOCAL_DIR/share" "$BIN_DIR"
  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/$ASSET" -o "$TMPDIR/nvim.tar.gz"
  tar xzf "$TMPDIR/nvim.tar.gz" -C "$TMPDIR"
  EXTRACTED=$(find "$TMPDIR" -maxdepth 1 -type d -name "nvim-linux*" | head -1)
  rm -rf "$LOCAL_DIR/share/nvim-stable"
  mv "$EXTRACTED" "$LOCAL_DIR/share/nvim-stable"
  ln -sf "$LOCAL_DIR/share/nvim-stable/bin/nvim" "$BIN_DIR/nvim"
  log "nvim installed -> $BIN_DIR/nvim"
fi

# 3. PATH에 ~/.local/bin 추가 (bash)
if ! grep -q 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  log "adding ~/.local/bin to PATH in ~/.bashrc"
  echo '' >> "$HOME/.bashrc"
  echo '# dotfiles: user-space binaries' >> "$HOME/.bashrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$BIN_DIR:$PATH"

# 4. dotfiles repo clone
if [ -d "$DOTFILES_DIR/.git" ]; then
  log "updating existing dotfiles"
  git -C "$DOTFILES_DIR" pull --ff-only
else
  log "cloning dotfiles"
  git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# 5. nvim config 심볼릭 링크
mkdir -p "$HOME/.config"
if [ -e "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
  BAK="$NVIM_DIR.bak-$(date +%Y%m%d-%H%M%S)"
  log "backing up existing nvim config -> $BAK"
  mv "$NVIM_DIR" "$BAK"
fi
ln -sfn "$DOTFILES_DIR/nvim" "$NVIM_DIR"
log "linked $NVIM_DIR -> $DOTFILES_DIR/nvim"

# 6. 플러그인 자동 설치
log "installing plugins (nvim --headless Lazy sync)"
"$BIN_DIR/nvim" --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true

log "done! run: source ~/.bashrc && nvim"
