#!/usr/bin/env bash
# dotfiles installer: Neovim + yazi + LazyVim config (sudo 불필요, ~/.local 설치)
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

mkdir -p "$LOCAL_DIR/share" "$BIN_DIR"

# 2. Neovim 바이너리 설치
if [ -x "$BIN_DIR/nvim" ] || command -v nvim >/dev/null 2>&1; then
  log "nvim already installed, skipping"
else
  log "installing neovim (latest stable)"
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  ASSET="nvim-linux-x86_64.tar.gz" ;;
    aarch64) ASSET="nvim-linux-arm64.tar.gz" ;;
    *) err "unsupported arch: $ARCH"; exit 1 ;;
  esac
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/$ASSET" -o "$TMP/nvim.tar.gz"
  tar xzf "$TMP/nvim.tar.gz" -C "$TMP"
  EXT=$(find "$TMP" -maxdepth 1 -type d -name "nvim-linux*" | head -1)
  rm -rf "$LOCAL_DIR/share/nvim-stable"
  mv "$EXT" "$LOCAL_DIR/share/nvim-stable"
  ln -sf "$LOCAL_DIR/share/nvim-stable/bin/nvim" "$BIN_DIR/nvim"
  rm -rf "$TMP"
  log "nvim installed -> $BIN_DIR/nvim"
fi

# 3. yazi 바이너리 설치 (zip → python zipfile로 해제)
if [ -x "$BIN_DIR/yazi" ] || command -v yazi >/dev/null 2>&1; then
  log "yazi already installed, skipping"
else
  log "installing yazi"
  ARCH=$(uname -m)
  # musl = static binary (glibc 버전 독립, 구 배포판에서도 동작)
  case "$ARCH" in
    x86_64)  ASSET="yazi-x86_64-unknown-linux-musl.zip" ;;
    aarch64) ASSET="yazi-aarch64-unknown-linux-musl.zip" ;;
    *) err "unsupported arch: $ARCH"; exit 1 ;;
  esac
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/$ASSET" -o "$TMP/yazi.zip"
  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$TMP/yazi.zip" -d "$TMP"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import zipfile; zipfile.ZipFile('$TMP/yazi.zip').extractall('$TMP')"
  else
    err "need unzip or python3 to extract yazi"
    exit 1
  fi
  EXT=$(find "$TMP" -maxdepth 1 -type d -name "yazi-*" | head -1)
  cp "$EXT/yazi" "$BIN_DIR/yazi"
  [ -f "$EXT/ya" ] && cp "$EXT/ya" "$BIN_DIR/ya" || true
  chmod +x "$BIN_DIR/yazi" "$BIN_DIR/ya" 2>/dev/null || true
  rm -rf "$TMP"
  log "yazi installed -> $BIN_DIR/yazi"
fi

# 3b. tree-sitter CLI (nvim-treesitter parser 빌드용)
if [ -x "$BIN_DIR/tree-sitter" ] || command -v tree-sitter >/dev/null 2>&1; then
  log "tree-sitter already installed, skipping"
else
  log "installing tree-sitter CLI"
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  TS_ASSET="tree-sitter-linux-x64.gz" ;;
    aarch64) TS_ASSET="tree-sitter-linux-arm64.gz" ;;
    *) err "unsupported arch: $ARCH"; exit 1 ;;
  esac
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/$TS_ASSET" \
    | gunzip > "$BIN_DIR/tree-sitter"
  chmod +x "$BIN_DIR/tree-sitter"
  log "tree-sitter installed -> $BIN_DIR/tree-sitter"
fi

# 4. ~/.bashrc 설정 (PATH + y 함수)
if ! grep -q 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  log "adding ~/.local/bin to PATH in ~/.bashrc"
  {
    echo ''
    echo '# dotfiles: user-space binaries'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo 'export EDITOR="nvim"'
  } >> "$HOME/.bashrc"
fi

if ! grep -q '# yazi wrapper: y()' "$HOME/.bashrc" 2>/dev/null; then
  log "adding y() yazi wrapper to ~/.bashrc"
  cat >> "$HOME/.bashrc" <<'BASHRC_EOF'

# yazi wrapper: y() — exit 시 선택한 디렉토리로 cd
function y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
BASHRC_EOF
fi
export PATH="$BIN_DIR:$PATH"

# 5. dotfiles repo clone
if [ -d "$DOTFILES_DIR/.git" ]; then
  log "updating existing dotfiles"
  git -C "$DOTFILES_DIR" pull --ff-only
else
  log "cloning dotfiles"
  git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# 6. nvim config 심볼릭 링크
mkdir -p "$HOME/.config"
if [ -e "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
  BAK="$NVIM_DIR.bak-$(date +%Y%m%d-%H%M%S)"
  log "backing up existing nvim config -> $BAK"
  mv "$NVIM_DIR" "$BAK"
fi
ln -sfn "$DOTFILES_DIR/nvim" "$NVIM_DIR"
log "linked $NVIM_DIR -> $DOTFILES_DIR/nvim"

# 7. 플러그인 자동 설치
log "installing plugins (nvim --headless Lazy sync)"
"$BIN_DIR/nvim" --headless "+Lazy! sync" +qa 2>&1 | tail -3 || true

log "done! run: source ~/.bashrc && nvim (or y)"
