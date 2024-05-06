return {
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
}
