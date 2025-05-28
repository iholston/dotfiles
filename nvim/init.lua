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
vim.opt.termguicolors   = true  -- Enables 24-bit RGB color in the TUIvertical

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

-- Allows highlighted text to be moved up/down with J/K
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Select all
vim.keymap.set({"n", "x"}, "<leader>a", "gg<S-v>G", { desc = "Select All" }) 

-- Keep cursor center when paging up/down and searching
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Toggle Wrap
vim.keymap.set("n", "<leader>v", ":set linebreak<CR>:set wrap!<CR>", { desc = "Toggle Linewrap" })

-- Reselecting when indenting multiple times
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Fast terminal, space-t
-- vim.keymap.set("n", "<leader>t", ":10sp<CR>:term<CR>:startinsert<CR>", { silent = true, desc = "Terminal" })

-- Quickfix List
vim.keymap.set("n", "<leader>q", -- toggles quickfix list
    function() 
        if vim.tbl_isempty(vim.fn.filter(vim.fn.getwininfo(), "v:val.quickfix")) then
            vim.cmd("copen")
        else
            vim.cmd("cclose")
        end
    end,
    { desc = "Toggle QuickFixList" }
)
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz")    -- ctrl-n, go to next thing in quickfix list
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz")    -- ctrl-p, go to prev thing in quickfix list

-- Fast saving
vim.keymap.set("n", "<Leader>w", ":write!<CR>", { desc = "Save" })              -- space-w, save

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
    --{
    --    "ellisonleao/gruvbox.nvim",
    --    priority = 1000,
    --    config = function()
    --        vim.cmd("colorscheme gruvbox")
    --    end
    --},
    {
        "mocte4/godotcolour-vim",
        config = function()
            vim.cmd("colorscheme godotcolour")
        end
    },
    -- gitsigns
    {
       "lewis6991/gitsigns.nvim",
       tag = "v0.9.0",
       config = function()
           require("gitsigns").setup()
       end
    },

    -- toggle term
    {
        'akinsho/toggleterm.nvim', version = "*", 
        config = function()
            vim.opt.shell = vim.fn.executable "pwsh" and "pwsh" or "powershell"
            vim.opt.shellcmdflag = "-nologo -noprofile -executionpolicy remotesigned -command [console]::inputencoding=[console]::outputencoding=[system.text.encoding]::utf8;"
            vim.opt.shellredir = "-redirectstandardoutput %s -nonewwindow -wait"
            vim.opt.shellpipe = "2>&1 | out-file -encoding utf8 %s; exit $lastexitcode"
            vim.opt.shellquote = ""
            vim.opt.shellxquote = ""
            require("toggleterm").setup({
                open_mapping = [[<c-t>]], -- can also use 2 c-t to open second terminal ect.
                terminal_mappings = true,
                insert_mappings = true,
                start_in_insert = true,
                direction = "tab",
            })
        end
    },

    -- statusline
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = { 
                    -- theme = "auto",
                    -- theme = "ayu_mirage",
                    theme = "material",

                    component_separators = '',
                    section_separators = ''
                },
                sections = {
                    lualine_b = { "branch" },
                    lualine_c = {
                        {
                            "filename",
                            file_status = true, -- displays file status (readonly status, modified status)
                            path = 0            -- 0 = just filename, 1 = relative path, 2 = absolute path
                        }
                    }, 
                    lualine_x = { "diagnostics", "diff" },
                }
            })
       end,
    },

    -- highlight, edit, and navigate code
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":tsupdate",
        config = function()
            require("nvim-treesitter.configs").setup {
                ensure_installed = {
                    "gdscript",
                    "godot_resource",
                    "gdshader",
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
                        init_selection = "<cr>",
                        node_incremental = "<cr>",
                        scope_incremental = "<s-cr>",
                        node_decremental = "<bs>",
                    },
                },
            }
        end
    },

    -- barbar
    {'romgrk/barbar.nvim',
         dependencies = {
             'lewis6991/gitsigns.nvim', -- optional: for git status
             'nvim-tree/nvim-web-devicons', -- optional: for file icons
         },
         init = function() vim.g.barbar_auto_setup = false end,
         opts = {},
         version = '^1.0.0', -- optional: only update when a new 1.x version is released
     },

    -- markdown
    {
        'meanderingprogrammer/render-markdown.nvim',
        ft = "markdown",
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        opts = {},
    },

--  +----------------------------------------------------------+
--  |               plugins with keymaps                       |
--  +----------------------------------------------------------+

    -- leap -> leader + s
    {
        "ggandor/leap.nvim",
        config = function()
            vim.keymap.set({"n", "x"}, "<leader>s", "<plug>(leap)", { desc = "leap" })
        end
    },
    
    -- which-key
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            delay = 2000,
            icons = {
                mappings = false,
            },
        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "buffer local keymaps (which-key)",
            },
        },
    },

    -- file explorer -> leader + n
    ---@type LazySpec
    {
        "mikavilpas/yazi.nvim",
        event = "VeryLazy",
        dependencies = {
            -- check the installation instructions at
            -- https://github.com/folke/snacks.nvim
            "folke/snacks.nvim"
        },
        keys = {
            -- 👇 in this section, choose your own keymappings!
            {
                "<leader>n",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Open yazi at the current file",
            },
        },
        ---@type YaziConfig | {}
        opts = {
            -- if you want to open yazi instead of netrw, see below for more info
            open_for_directories = true,
            keymaps = {
                show_help = "<f1>",
            },
        },
        -- 👇 if you use `open_for_directories=true`, this is recommended
        init = function()
            -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
            -- vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
        end,
    },

    -- lazy git 
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
        },
    },

    -- harpoon -> leader + h
    {
        "theprimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
             local harpoon = require("harpoon")
             harpoon:setup()
             -- open harpoon dialog
             vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

             -- add/remove 
             vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "harpoon add"})
             vim.keymap.set("n", "<leader>hd", function() harpoon:list():remove() end, { desc = "harpoon delete"})

             -- quickswap to marks
             vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "harpoon to file 1" })
             vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "harpoon to file 2" })
             vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "harpoon to file 3" })
             vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "harpoon to file 4" })
        end
    },

    -- telescope -> leader + f
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
                            ["<c-k>"] = actions.move_selection_previous, -- move to prev result
                            ["<c-j>"] = actions.move_selection_next, -- move to next result
                            ["<c-q>"] = actions.smart_send_to_qflist, -- send entire list or selected to quickfix
                        }
                    },
                    path_display = function(opts, path)
                        local tail = require("telescope.utils").path_tail(path)
                        return string.format("%s - %s", tail, path)
                    end,
                }
            })
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find files in cwd" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "live grep in cwd"})
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "find buffers in cwd" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "find through help" })
            vim.keymap.set("n", "<leader>fs",                       
                function()              
                    builtin.grep_string({ search = vim.fn.expand("<cword>") })
                end,
                { desc = "find string under cursor" })
        end
    },

    -- nvim dap
    {
        'mfussenegger/nvim-dap',
        dependencies = {
            'rcarriga/nvim-dap-ui',
            'nvim-neotest/nvim-nio',
            'williamboman/mason.nvim',
            'jay-babu/mason-nvim-dap.nvim',
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            require('mason-nvim-dap').setup({
                automatic_setup = true,
                handlers = {},
            })

            dapui.setup {
                -- set icons to characters that are more likely to work in every terminal.
                --    feel free to remove or use ones that you like more! :)
                --    don't feel like these are good choices.
                icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
                controls = {
                    icons = {
                        pause = '⏸',
                        play = '▶',
                        step_into = '⏎',
                        step_over = '⏭',
                        step_out = '⏮',
                        step_back = 'b',
                        run_last = '▶▶',
                        terminate = '⏹',
                        disconnect = '⏏',
                    },
                },
            }

            dap.adapters.godot = {
                type = "server",
                host = "127.0.0.1",
                port = 6006,
            }

            dap.configurations.gdscript = {
                {
                    type = "godot",
                    request = "launch",
                    name = "launch scene",
                    project = "${workspacefolder}",
                    launch_scene = true,
                },
            }
            --vim.api.nvim_create_user_command("breakpoint", "lua require'dap'.toggle_breakpoint()", {})
            --vim.api.nvim_create_user_command("continue", "lua require'dap'.continue()", {})
            --vim.api.nvim_create_user_command("stepover", "lua require'dap'.step_over()", {})
            --vim.api.nvim_create_user_command("stepinto", "lua require'dap'.step_into()", {})
            --vim.api.nvim_create_user_command("repl", "lua require'dap'.repl.open()", {})
            vim.keymap.set('n', '<leader>gr', "<cmd>lua require'dap'.continue()<cr>", { desc = "launch game or run until the next breakpoint" })
            vim.keymap.set('n', '<leader>gb', "<cmd>lua require'dap'.toggle_breakpoint()<cr>", { desc = "create or remove a breakpoint" })
            vim.keymap.set('n', '<leader>go', "<cmd>lua require'dap'.step_over()<cr>", { desc = "step over a line" })
            vim.keymap.set('n', '<leader>gi', "<cmd>lua require'dap'.step_into()<cr>", { desc = "step into a line" })
            vim.keymap.set('n', '<leader>gu', dapui.toggle, {})
            vim.keymap.set('n', '<leader>gs', "<cmd>lua require'dap'.disconnect()<cr>", { desc = "stop dap session" })

            dap.listeners.after.event_initialized['dapui_config'] = dapui.open
            dap.listeners.before.event_terminated['dapui_config'] = dapui.close
            dap.listeners.before.event_exited['dapui_config'] = dapui.close
        end
    },

--  +----------------------------------------------------------+
--  |                       lsp setup                          |
--  +----------------------------------------------------------+
-- https://lsp-zero.netlify.app/docs/getting-started.html
-- https://github.com/vonheikemen/lsp-zero.nvim#quickstart-for-the-impatient

    -- plugins required for lsp setup
    -- https://lsp-zero.netlify.app/docs/getting-started.html
    -- https://github.com/vonheikemen/lsp-zero.nvim#quickstart-for-the-impatient
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
require('lspconfig').rust_analyzer.setup({})
require('lspconfig').pyright.setup({})
require('lspconfig').gdscript.setup({
    force_setup = true, -- because the LSP is global. Read more on lsp-zero docs about this.
    single_file_support = false,
    cmd = {'ncat', '127.0.0.1', '6005'}, -- the important trick for Windows!
    root_dir = require('lspconfig.util').root_pattern('project.godot', '.git'),
    filetypes = {'gd', 'gdscript', 'gdscript3' }
})

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

-- godot setup
if vim.fn.filereadable(vim.fn.getcwd() .. '/project.godot') == 1 then
    local addr = './godot.pipe'
    if vim.fn.has 'win32' == 1 then
        addr = '127.0.0.1:6004'
    end
    vim.fn.serverstart(addr)
end

