return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        -- https://github.com/akinsho/toggleterm.nvim/wiki/Tips-and-Tricks#using-toggleterm-with-powershell
        local powershell_options = {
            shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell",
            shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
            shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
            shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
            shellquote = "",
            shellxquote = "",
        }
        for option, value in pairs(powershell_options) do
            vim.opt[option] = value
        end
        local HEIGHT_RATIO = 0.8
        local WIDTH_RATIO = 0.5
        require("toggleterm").setup({
            size = 20,
            hide_numbers = true,
            open_mapping = [[<c-t>]],
            shade_filetypes = {},
            direction = "float",
            persist_size = true,
            insert_mappings = true,
            close_on_exit = false,
            float_opts = {
                border = "curved",
                winblend = 0,
                width = math.floor(vim.opt.columns:get() * WIDTH_RATIO),
                height = math.floor((vim.opt.lines:get() - vim.opt.cmdheight:get()) * HEIGHT_RATIO),
                highlights = {
                    border = "Normal",
                    background = "Normal",
                }
            }
        })
    end
}
