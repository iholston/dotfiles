-- Leader
vim.g.mapleader = " "

-- Jk to exit insert  
vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("t", "jk", "<ESC>")

-- Yank/Paste
vim.keymap.set("x", "<leader>p", "\"_dP")
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>yy", "\"+yy")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- Allows highlighted text to be moved up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Reselecting when indenting multiple times    
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Keep cursor center when paging up/down and searching
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Fast terminal 
vim.keymap.set("n", "<leader>t", ":10sp<CR>:term<CR>:startinsert<CR>", silent)

-- Netrw
-- vim.keymap.set("n", "<leader>n", ":Ex<CR>", silent)

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

-- Resize panes
vim.keymap.set("n", "<UP>", "<cmd>resize +2<CR>")
vim.keymap.set("n", "<Down>", "<cmd>resize -2<CR>")
vim.keymap.set("n", "<Left>", "<cmd>vertical resize +2<CR>")
vim.keymap.set("n", "<Right>", "<cmd>vertical resize -2<CR>")

-- Quick buffer nav
vim.keymap.set("n", "<leader><leader>", "<C-^>", silent)
for i = 1, 9 do
    vim.keymap.set("n", "<leader>" .. i, ":buffer " .. i .. "<CR>", silent)
end
