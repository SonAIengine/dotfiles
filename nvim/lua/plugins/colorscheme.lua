return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      theme = "wave",
      background = {
        dark = "wave",
        light = "lotus",
      },
      terminalColors = true,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-wave",
    },
  },
}
