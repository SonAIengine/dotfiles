-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local function git_root_of(path)
  if not path or path == "" then
    return nil
  end
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":p:h")
  local output = vim.fn.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local root = (output:gsub("%s+$", ""))
  if root == "" or vim.fn.isdirectory(root) == 0 then
    return nil
  end
  return root
end

-- LazyVim이 markdown/gitcommit/text 등에서 자동으로 켜는 spell 끄기
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("disable_spell", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- nvim 시작 시: argv의 첫 파일/디렉토리의 git root로 cd
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("auto_project_root_vimenter", { clear = true }),
  once = true,
  callback = function()
    for _, arg in ipairs(vim.fn.argv()) do
      if type(arg) == "string" and arg ~= "" then
        local root = git_root_of(arg)
        if root and vim.fn.getcwd() ~= root then
          vim.cmd.cd(vim.fn.fnameescape(root))
          return
        end
      end
    end
  end,
})

-- 파일 열 때: 그 파일의 git root로 cd
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("auto_project_root_bufenter", { clear = true }),
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then
      return
    end
    local file = vim.api.nvim_buf_get_name(args.buf)
    if file == "" or vim.fn.filereadable(file) == 0 then
      return
    end
    local root = git_root_of(file)
    if root and vim.fn.getcwd() ~= root then
      vim.cmd.cd(vim.fn.fnameescape(root))
    end
  end,
})
