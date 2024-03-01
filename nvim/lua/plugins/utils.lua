return {
	-- gitsigns
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
			vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
		end,
	},

	-- obsidian https://www.youtube.com/watch?v=aIoEQC7w_UI
	{
		"epwalsh/obsidian.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"hrsh7th/nvim-cmp",
			"nvim-telescope/telescope.nvim",
		},
		version = "*",
		lazy = true,
		ft = "markdown",
		config = function()
			require("obsidian").setup({
				completion = {
					nvim_cmp = true,
				},
				dir = "~/OneDrive/Documents/The Remote Store",
				new_notes_location = "current_dir",
			})
			vim.keymap.set("n", "<leader>oo", ":ObsidianOpen<CR>")
			vim.keymap.set("n", "<leader>os", ":ObsidianSearch<CR>")
		end,
	},
}
