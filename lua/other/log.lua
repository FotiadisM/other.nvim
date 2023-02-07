return require("plenary.log").new({
	plugin = "other.nvim",
	level = vim.env.OTHER_NIVM_LOG_LEVEL or "wanr",
})
