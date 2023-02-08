# other.nvim

Open (and set) the alternative file for the current buffer with fewest keystrokes possible.

## The problem

I love [harpoon](https://github.com/ThePrimeagen/harpoon), it gives me speed and sanity. However, I found myself _harpooning_ similar files.
What I mean with similar files? `bugless_code.c` and `bugless_code.h` or `vscode_bad.go` and `vscode_bad_test.go`.

## The solution

This plugin duh.

## Usage

[other-nvim.webm](https://user-images.githubusercontent.com/47476275/217492080-4301125e-d64b-4654-be28-986111249ed6.webm)

When I want to jump to the _other_ file I use `require("other").open()`. If I have already registered the _other_ file then it opens it and I can toggle
between the two using the same command, if not, then a fuzzy finder will open for me to pick a file.

The state is stored on disk similarly to [harpoon](https://github.com/ThePrimeagen/harpoon) so you set the _other_ file once and forget it.

This plugin does not try to be smart and guess the alternative file, and I think it's better this way.

```lua
-- this is required
require("other").setup()

vim.keymap.set("n", "<space>o", require("other").open, {
	noremap = true,
	silent = true,
	desc = "open other file"
})

vim.keymap.set("n", "<space><space>o", require("other").clear, {
	noremap = true,
	silent = true,
	desc = "clear other file"
})

```
