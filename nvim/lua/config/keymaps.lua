-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- <C-/>: 터미널 토글 (우측 세로 분할, 현재 프로젝트 root, 자동 포커스)
local function toggle_right_terminal()
  local term = Snacks.terminal.toggle(nil, {
    cwd = LazyVim.root(),
    win = {
      position = "right",
      width = 0.3,
      border = "none",
      wo = { winbar = "" },
    },
    start_insert = true,
    auto_insert = true,
  })
  if term and term.win and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_set_current_win(term.win)
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
  end
end

map({ "n", "t" }, "<C-/>", toggle_right_terminal, { desc = "Terminal (right)" })
map({ "n", "t" }, "<C-_>", toggle_right_terminal, { desc = "which_key_ignore" })

-- 마우스 클릭으로 창 포커스 전환 보장
vim.opt.mouse = "a"
vim.opt.mousefocus = false
