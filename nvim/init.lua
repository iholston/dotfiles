-- based on https://arslan.io/2023/05/10/the-benefits-of-using-a-single-init-lua-vimrc-file/

----------------
--- SETTINGS ---
----------------

-- Tab
vim.opt.tabstop         = 4     -- Number of spaces a TAB creates
vim.opt.softtabstop     = 4     -- Number of characters the cursor moves with <Tab> and <BS> 
vim.shiftwidth          = 4     -- Number of spaces for auto-indentation, <<, >>, etc.
vim.opt.expandtab       = true  -- Expand tabs into spaces
vim.opt.autoindent      = true  -- Copy indent from current line when starting a new line

-- Buffer 
vim.opt.number          = true  -- Show line numbers
vim.opt.relativenumber  = true  -- Show relative line numbers
vim.opt.wrap            = false -- Don"t wrap lines

-- Search 
vim.opt.hlsearch        = false -- Don"t highlight all matches
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
vim.opt.mouse           = "a"   -- Allows the use of the mouse in all modes
vim.opt.clipboard       = "unnamedplus" -- put yanks/pastes in system clipboard
vim.opt.confirm         = true  -- Confirm before exiting with unsaved buffer(s)


----------------
--- KEYMAPS ----
----------------

-- Leader
vim.g.mapleader = " "

-- jk to exit insert
vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("t", "jk", "<ESC>")

-- Allows highlighted text to be moved up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Copy and Paste
vim.keymap.set({"n", "x"}, "<leader>aa", "gg<S-v>G") -- Select all
vim.keymap.set("x", "p", "\"_dP")                    -- Don"t override clipboard with text being pasted over
vim.keymap.set("n", "Y", "y$")                       -- Yanking a line should act like D and C

-- File tree 
vim.keymap.set("n", "<leader>n", ":NvimTreeToggle<CR>", { noremap = true })

-- Keep cursor center when paging up/down and searching
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Reselecting when indenting multiple times    
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Fast terminal 
vim.keymap.set("n", "<leader>t", ":10sp<CR>:term<CR>:startinsert<CR>", silent)

-- Quickfix List
vim.keymap.set("n", "<leader>a", "<cmd>copen<CR>")
vim.keymap.set("n", "<leader>A", "<cmd>cclose<CR>")
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz")

-- Fast saving
vim.keymap.set("n", "<Leader>w", ":write!<CR>")
vim.keymap.set("n", "<Leader>q", ":q!<CR>", { silent = true })

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


----------------
--- PLUGINS ----
----------------

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
                    lualine_c = {
                        {
                            "filename",
                            file_status = true, -- displays file status (readonly status, modified status)
                            path = 2            -- 0 = just filename, 1 = relative path, 2 = absolute path
                        }
                    }
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

    -- file explorer
    --{
    --    "nvim-tree/nvim-tree.lua",
    --    version = "*",
    --    dependencies = { "nvim-tree/nvim-web-devicons" },
    --    config = function()
    --        require("nvim-tree").setup({
    --            sort_by = "case_sensitive",
    --            actions = {
    --                open_file = {
    --                    quit_on_open = true,
    --                },
    --            },
    --        })
    --    end,
    --},
    -- Floating version
    {
        "nvim-tree/nvim-tree.lua",
        config = function()
            -- https://www.reddit.com/r/neovim/comments/13u9okq/nvimtree_vs_neotree/
            -- https://github.com/MarioCarrion/videos/blob/269956e913b76e6bb4ed790e4b5d25255cb1db4f/2023/01/nvim/lua/plugins/nvim-tree.lua
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            -- https://neovim.discourse.group/t/how-to-configure-floating-window-colors-highlighting-in-0-8/3193
            vim.api.nvim_set_hl(0, "FloatBorder", {bg="#3B4252", fg="#5E81AC"})
            vim.api.nvim_set_hl(0, "NormalFloat", {bg="#3B4252"})
            vim.api.nvim_set_hl(0, "TelescopeNormal", {bg="#3B4252"})
            vim.api.nvim_set_hl(0, "TelescopeBorder", {bg="#3B4252"})
            local HEIGHT_RATIO = 0.8
            local WIDTH_RATIO = 0.5
            vim.keymap.set("n", "<leader>n", ":NvimTreeOpen<CR>", silent)
            require("nvim-tree").setup({
                disable_netrw = true,
                hijack_netrw = true,
                respect_buf_cwd = true,
                sync_root_with_cwd = true,
                view = {
                    relativenumber = true,
                    float = {
                        enable = true,
                        open_win_config = function()
                            local screen_w = vim.opt.columns:get()
                            local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                            local window_w = screen_w * WIDTH_RATIO
                            local window_h = screen_h * HEIGHT_RATIO
                            local window_w_int = math.floor(window_w)
                            local window_h_int = math.floor(window_h)
                            local center_x = (screen_w - window_w) / 2
                            local center_y = ((vim.opt.lines:get() - window_h) / 2)
                            - vim.opt.cmdheight:get()
                            return {
                                border = "rounded",
                                relative = "editor",
                                row = center_y,
                                col = center_x,
                                width = window_w_int,
                                height = window_h_int,
                            }
                        end,
                    },
                    width = function()
                        return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
                    end,
                },
            })
        end,
    },

    -- harpoon
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()
            vim.keymap.set("n", "<leader>`", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
            vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
            vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
            vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
            vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
            vim.keymap.set("n", "<leader>5", function() harpoon:list():append() end)
            vim.keymap.set("n", "<leader>6", function() harpoon:list():remove() end)

            -- Toggle previous & next buffers stored within Harpoon list
            vim.keymap.set("n", "<leader><Tab>", function() harpoon:list():prev() end)
            vim.keymap.set("n", "<leader><S-Tab>", function() harpoon:list():next() end)
        end
    },

    -- Telescope
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
            telescope.setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                            ["<C-j>"] = actions.move_selection_next, -- move to next result
                        }
                    },
                    path_display={"truncate"},
                }
            })
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
            vim.keymap.set("n", "<leader>fs", function()
                builtin.grep_string({ search = vim.fn.input("Grep > ") })
            end)
        end
    },


    -- LSP Plugins

})

