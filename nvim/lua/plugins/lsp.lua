return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
    },
    config = function()
        require('mason').setup()
        require('mason-lspconfig').setup {
            ensure_installed = { 'lua_ls', 'rust_analyzer', 'pylsp', 'powershell_es', 'jdtls' },
        }
        local on_attach = function(_, _)
            vim.keymap.set({'n', 'v'}, '<leader>rn', vim.lsp.buf.rename, {})
            vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
            vim.keymap.set('n', '<leader>D', '<cmd>Telescope diagnostics bufnr=0<CR>', {})
            vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, {})
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
        end
        require('lspconfig').lua_ls.setup {
            on_attach = on_attach,
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { 'vim' }
                    }
                }
            }
        }
        require('lspconfig').pylsp.setup {
            on_attach = on_attach,
        }
        require('lspconfig').rust_analyzer.setup {
            on_attach = on_attach,
        }
        require('lspconfig').powershell_es.setup {
            on_attach = on_attach,
        }
        require('lspconfig').jdtls.setup {
            on_attach = on_attach,
        }
    end
}
