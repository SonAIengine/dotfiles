# dotfiles

Neovim (LazyVim) portable config. No sudo required.

## Install (any Linux server)

```bash
curl -fsSL https://raw.githubusercontent.com/SonAIengine/dotfiles/main/install.sh | bash
source ~/.bashrc
nvim
```

Works on Ubuntu/Debian/CentOS with `git`, `curl`, `tar`.

## What it does

1. Downloads neovim stable binary → `~/.local/share/nvim-stable/`
2. Symlinks `~/.local/bin/nvim`
3. Adds `~/.local/bin` to PATH in `~/.bashrc`
4. Clones this repo to `~/.dotfiles`
5. Symlinks `~/.config/nvim` → `~/.dotfiles/nvim`
6. Runs `:Lazy sync` headless to install plugins
