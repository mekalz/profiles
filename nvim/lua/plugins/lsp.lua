return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  keys = {
    {
      "<leader><space>",
      "<cmd>lua vim.lsp.buf.hover()<cr>",
      desc = "LSP hover",
    },
    {
      "<leader>r",
      "<cmd>lua vim.lsp.buf.references()<cr>",
      desc = "List references",
    },
    {
      "[d",
      "<cmd>lua if vim.diagnostic.jump then vim.diagnostic.jump()(-1) else vim.diagnostic.goto_prev() end<cr>",
      desc = "Goto previous diagnostic",
    },
    {
      "]d",
      "<cmd>lua if vim.diagnostic.jump then vim.diagnostic.jump()(1) else vim.diagnostic.goto_next() end<cr>",
      desc = "Goto next diagnostic",
    },
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "pylsp", "lua_ls" },
    })

    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- LSP Keybindings
    local on_attach = function(client, bufnr)
      -- Unset formatexpr (fex) to use default range formatter
      -- TODO: Remove when tuned the one offered by LSP
      vim.bo[bufnr].formatexpr = nil
    end

    -- Configure LSP servers
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    })

    lspconfig.pylsp.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end,
}
