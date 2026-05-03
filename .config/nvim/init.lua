-- bootstrap lazy.nvim, LazyVim and your plugins
vim.g.auto_lsp = false
require("config.lazy")

vim.env.JAVA_HOME = "/usr/lib/jvm/java-21-openjdk"
vim.env.PATH = vim.env.JAVA_HOME .. "/bin:" .. (vim.env.PATH or "")
