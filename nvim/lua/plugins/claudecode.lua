return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    -- 메인 (자주 씀, 짧게) — bypass permissions로 실행
    { "<leader>j", "<cmd>ClaudeCode --dangerously-skip-permissions<cr>", desc = "Claude toggle" },
    { "<leader>J", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude send selection" },

    -- 보조 (가끔 씀, <leader>a prefix)
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume --dangerously-skip-permissions<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue --dangerously-skip-permissions<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file from tree",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "snacks_picker_list" },
    },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
