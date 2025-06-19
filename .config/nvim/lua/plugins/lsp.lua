return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    local lspconfig = require('lspconfig')
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    capabilities.textDocument.completion.completionItem.snippetSupport = true

    local cmp_nvim_lsp = require('cmp_nvim_lsp')
    capabilities = vim.tbl_deep_extend(
      'force',
      capabilities,
      cmp_nvim_lsp.default_capabilities()
    )

    -- CSS Language Server (cssls) setup
    lspconfig.cssls.setup({
      capabilities = capabilities,
      settings = {
        css = {
          validate = true,
          completion = {
            atSuggestions = true,
            triggerPropertyValueCompletion = true,
          },
        },
        scss = {
          validate = true,
          completion = {
            atSuggestions = true,
            triggerPropertyValueCompletion = true,
          },
        },
        less = {
          validate = true,
          completion = {
            atSuggestions = true,
            triggerPropertyValueCompletion = true,
          },
        },
      },
    })

    -- Add other language servers here if needed.
  end,
}
