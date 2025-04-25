-- based on https://arslan.io/2023/05/10/the-benefits-of-using-a-single-init-lua-vimrc-file/

--  +----------------------------------------------------------+
--  |                        Settings                          |
--  +----------------------------------------------------------+

-- Tab
vim.opt.tabstop         = 4     -- Number of spaces a TAB creates
vim.opt.shiftwidth      = 4     -- Number of spaces for auto-indentation, <<, >>, etc.
vim.opt.expandtab       = true  -- Expand tabs into spaces
vim.opt.autoindent      = true  -- Copy indent from current line when starting a new line

-- Buffer 
vim.opt.number          = true  -- Show line numbers
vim.opt.relativenumber  = true  -- Show relative line numbers
vim.opt.wrap            = false -- Don't wrap lines

-- Search 
vim.opt.hlsearch        = false -- Don't highlight all matches
vim.opt.incsearch       = true  -- Highlights as you type
vim.opt.ignorecase      = true  -- Ignores case

-- Split
vim.opt.splitbelow      = true  -- Vertical splits created right
vim.opt.splitright      = true  -- Horizontal splits created below

-- UI
vim.opt.signcolumn      = "yes" -- Render signcolumn always to prevent text shifting
vim.opt.scrolloff       = 7     -- Keep minimum x number of screens lines above and below the cursor
vim.opt.termguicolors   = true  -- Enables 24-bit RGB color in the TUI

-- Misc
vim.opt.shell           = "pwsh.exe"
vim.opt.mouse           = "a"  -- Allows the use of the mouse in all modes
vim.opt.clipboard       = "unnamedplus"  -- put yanks/pastes in system clipboard
vim.opt.confirm         = true  -- Confirm before exiting with unsaved buffer(s)


--  +----------------------------------------------------------+
--  |                  Custom Key Mappings                     |
--  +----------------------------------------------------------+

-- Leader Key
vim.g.mapleader = " "

-- jk to exit insert
vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("t", "jk", "<ESC>")

-- Allows highlighted text to be moved up/down with J/K
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Select all
vim.keymap.set({"n", "x"}, "<leader>a", "gg<S-v>G") 

-- Keep cursor center when paging up/down and searching
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Toggle Wrap
vim.keymap.set("n", "<leader>v", ":set linebreak<CR>:set wrap!<CR>")

-- Reselecting when indenting multiple times
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Fast terminal, space-t
vim.keymap.set("n", "<leader>t", ":10sp<CR>:term<CR>:startinsert<CR>", silent) -- opens a terminal window on the bottom

-- Quickfix List
vim.keymap.set("n", "<leader>e", -- toggles quickfix list
    function() 
        if vim.tbl_isempty(vim.fn.filter(vim.fn.getwininfo(), "v:val.quickfix")) then
            vim.cmd("copen")
        else
            vim.cmd("cclose")
        end
    end
)
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz")    -- ctrl-n, go to next thing in quickfix list
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz")    -- ctrl-p, go to prev thing in quickfix list

-- Fast saving
vim.keymap.set("n", "<Leader>w", ":write!<CR>")                 -- space-w, save
vim.keymap.set("n", "<Leader>q", ":q!<CR>", {silent = true})    -- space-q, quit

-- Using <C-hjkl> to navigate panes
vim.keymap.set("n", "<C-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<C-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<C-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<C-l>", ":wincmd l<CR>")
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")



--  +----------------------------------------------------------+
--  |             Plugins w/o keymaps                          |
--  +----------------------------------------------------------+

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    -- colorscheme
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = function()
            vim.cmd("colorscheme gruvbox")
        end
    },

    -- statusline
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function ()
            require("lualine").setup({
                options = { theme = "gruvbox" },
                sections = {
                    -- Don't show insert/normal/etc
                    lualine_a = {}, 
                    lualine_c = {
                        {
                            "filename",
                            file_status = true, -- displays file status (readonly status, modified status)
                            path = 1            -- 0 = just filename, 1 = relative path, 2 = absolute path
                        }
                    }, 
                    -- Don't show utf-8, windows symbol, filetype
                    lualine_x = {},
                }
            })
       end,
    },

    -- Highlight, edit, and navigate code
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup {
                ensure_installed = {
                    "bash",
                    "c",
                    "cpp",
                    "latex",
                    "lua",
                    "markdown",
                    "python",
                    "rust",
                },
                auto_install = true,
                highlight = {
                    enable = true
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<CR>",
                        node_incremental = "<CR>",
                        scope_incremental = "<S-CR>",
                        node_decremental = "<BS>",
                    },
                },
            }
        end
    },

    -- Markdown
    {
        'MeanderingProgrammer/render-markdown.nvim',
        ft = "markdown",
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        opts = {},
    },

--  +----------------------------------------------------------+
--  |               Plugins with keymaps                       |
--  +----------------------------------------------------------+

    -- leap -> LEADER + s
    {
        "ggandor/leap.nvim",
        config = function()
            vim.keymap.set({"n", "x"}, "<leader>s", "<Plug>(leap)")
        end
    },

    -- file explorer -> LEADER + n
    {
        "echasnovski/mini.nvim",
        version = false,
        config = function()
            local mini_files = require("mini.files")
            mini_files.setup({
                mappings = { 
                    go_in_plus = 'l',
                    go_in = 'L',
                    go_out_plus = 'h',
                    go_out = 'H',
                    trim_left = '>',
                    trim_right = '<',
                }, 
                options = {
                    permanent_delete = false
                },
                --windows = {
                --    preview = true,
                --    width_preview = 40,
                --}
            })
            vim.keymap.set("n", "<leader>n", mini_files.open)
        end
    },

    -- Harpoon -> LEADER + h
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
             local harpoon = require("harpoon")
             harpoon:setup()
             -- Open Harpoon Dialog
             vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

             -- Add/Remove 
             vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end)
             vim.keymap.set("n", "<leader>hd", function() harpoon:list():remove() end)

             -- Quickswap to marks
             vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
             vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
             vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
             vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
        end
    },

    -- Telescope -> LEADER + f
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = { 
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local builtin = require("telescope.builtin")
            telescope.setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                            ["<C-j>"] = actions.move_selection_next, -- move to next result
                            ["<M-e>"] = actions.smart_send_to_qflist, -- send entire list or selected to quickfix
                        }
                    },
                    path_display={"truncate"},
                }
            })
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {}) -- Search files in cwd
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})  -- Grep in cwd
            vim.keymap.set("n", "<leader>fb", builtin.buffers, {})    -- Search through open buffers
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})  -- Search through help 
            vim.keymap.set("n", "<leader>fs",                         -- Search for string under cursor 
                function()              
                    builtin.grep_string({ search = vim.fn.expand("<cword>") })
                end
            )
        end
    },


--  +----------------------------------------------------------+
--  |                       LSP Setup                          |
--  +----------------------------------------------------------+
-- https://lsp-zero.netlify.app/docs/getting-started.html
-- https://github.com/VonHeikemen/lsp-zero.nvim#quickstart-for-the-impatient

    -- Plugins required for LSP Setup
    -- https://lsp-zero.netlify.app/docs/getting-started.html
    -- https://github.com/VonHeikemen/lsp-zero.nvim#quickstart-for-the-impatient
    {'neovim/nvim-lspconfig'},
    {'hrsh7th/cmp-nvim-lsp'},
    {'hrsh7th/nvim-cmp'}, 
})


-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
    'force',
    lspconfig_defaults.capabilities,
    require('cmp_nvim_lsp').default_capabilities()
)

-- You'll find a list of language servers here:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
-- Drop languages you want here
require('lspconfig').rust_analyzer.setup{}
require('lspconfig').pyright.setup{}

-- LSP Keymaps in keymaps section

-- Other, idk
local cmp = require('cmp')
cmp.setup({
    sources = {
            {name = 'nvim_lsp'},
    },
    snippet = {
        expand = function(args)
                -- You need Neovim v0.10 to use vim.snippet
                vim.snippet.expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({select = false}),
  }),
})

-- LSP Keymaps - if there is a language server active in the file
-- g + letter
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        local opts = {buffer = event.buf}
        -- Creates popup with info about whats under cursor
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)              
        -- Goto 
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)        
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)       
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        -- Rename across project
        vim.keymap.set('n', 'gR', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        -- LSP auto format file
        vim.keymap.set({'n', 'x'}, 'gf', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        -- Show availabe code actions
        vim.keymap.set('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
    end,
})
