return {
    -- Mason
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    },

    -- Mason-LspConfig
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    -- LSPs
                    "lua_ls",
                    "rust_analyzer",
                    "pylsp",
                    "powershell_es",
                    "jdtls",
                }
            })
        end
    },

    -- Mason-Null-Ls
    {
        "jay-babu/mason-null-ls.nvim",
        config = function()
            require("mason-null-ls").setup({
                ensure_installed = {
                    "stylua",
                    "isort",
                    "black",
                },
                automatic_installation  = false,
                handlers = {},
            })
        end
    },

    -- Null-ls
    {
        "nvimtools/none-ls.nvim",
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.stylua,
                    null_ls.builtins.formatting.black,
                    null_ls.builtins.formatting.isort,
                },
            })
            vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
        end,
    },

    -- Nvim-LspConfig
    {
        "neovim/nvim-lspconfig",
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            local on_attach = function(_, _)
                vim.keymap.set({'n', 'v'}, '<leader>rn', vim.lsp.buf.rename, {})
                vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
                vim.keymap.set('n', '<leader>D', '<cmd>Telescope diagnostics bufnr=0<CR>', {})
                vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, {})
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
            end
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            require('lspconfig').lua_ls.setup {
                on_attach = on_attach,
                capabilities = capabilities,
                settings = { Lua = { diagnostics = { globals = { 'vim' } } } }
            }
            require('lspconfig').pylsp.setup {
                on_attach = on_attach,
                capabilities = capabilities,
            }
            require('lspconfig').rust_analyzer.setup {
                on_attach = on_attach,
                capabilities = capabilities,
            }
            require('lspconfig').powershell_es.setup {
                on_attach = on_attach,
                capabilities = capabilities,
            }
            require('lspconfig').jdtls.setup {
                on_attach = on_attach,
                capabilities = capabilities,
            }
        end
    },
}
