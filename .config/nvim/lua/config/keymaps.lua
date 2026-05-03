-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Smart <C-]>: try tag jump, fall back to opening URL/file with gx
vim.keymap.set("n", "<C-]>", function()
  local cword = vim.fn.expand("<cword>")
  local ok, err = pcall(vim.cmd, "tag " .. cword)
  if not ok then
    -- tag jump failed (E433/E426), try gx instead
    local urls = require("vim.ui")._get_urls()
    if #urls > 0 then
      for _, url in ipairs(urls) do
        local _, open_err = vim.ui.open(url)
        if open_err then
          vim.notify(open_err, vim.log.levels.ERROR)
        end
      end
    else
      -- nothing to open either, surface the original error
      vim.notify(err, vim.log.levels.WARN)
    end
  end
end, { desc = "Tag jump / open link fallback" })
