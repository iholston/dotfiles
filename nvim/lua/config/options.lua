-- Tab 
vim.opt.tabstop        = 4    --> How many characters Vim /treats/renders/ <TAB> as
vim.opt.softtabstop    = 4    --> How many characters the /cursor moves/ with <TAB> and <BS> -- 0 to disable
vim.opt.shiftwidth     = 4    --> Number of spaces to use for auto-indentaion, <<, >>, etc.
vim.opt.expandtab      = true --> Use spaces instead of tab

-- Buffer
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.wrap           = false
vim.opt.smartindent    = true

-- Search
vim.opt.hlsearch       = false
vim.opt.incsearch      = true

-- Split 
vim.opt.splitright     = true
vim.opt.splitbelow     = true

-- UI
vim.opt.signcolumn     = "number"
vim.opt.scrolloff      = 7    
vim.opt.termguicolors  = true 

-- Misc
vim.opt.shell          = "pwsh.exe"
vim.opt.updatetime     = 50
vim.opt.mouse          = "a"
vim.opt.confirm        = true --> Confirm before exiting with unsaved buffer(s)
