local bufnr = 14
vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("TjsCoolTutorial", {clear = true}),
    pattern = "test1.py",
    callback = function()
        print("file saved")
        vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { "output of test1.py" })
        vim.fn.jobstart({"python", "test1.py"}, {
            stdout_buffered = true,
            on_stdout = function(_, data)
                if data then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
                else
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, "false1")
                end
            end,
            on_stderr = function(_, data)
                if data then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
                else
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, "false2")
                end
            end,
        })
    end,
})
