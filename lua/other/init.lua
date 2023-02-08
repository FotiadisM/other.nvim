local Path = require("plenary.path")
local log = require("other.log")

local M = {}

local data_path = vim.fn.stdpath("data")
local state_file = string.format("%s/other.json", data_path)

local normilize_path = function(path)
	return Path:new(path):make_relative(vim.loop.cwd())
end

local read_state = function()
	return vim.json.decode(Path:new(state_file):read())
end

local write_state = function(data)
	Path:new(state_file):write(vim.json.encode(data), "w")
end

M.setup = function()
	local ok, state = pcall(read_state)
	if not ok then
		state = {}
	end

	M.state = state
end

local constract_file_command = function(opts)
	local find_command = (function()
		if 1 == vim.fn.executable("rg") then
			return { "rg", "--files", "--color", "never" }
		elseif 1 == vim.fn.executable("fd") then
			return { "fd", "--type", "f", "--color", "never" }
		elseif 1 == vim.fn.executable("fdfind") then
			return { "fdfind", "--type", "f", "--color", "never" }
		elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
			return { "find", ".", "-type", "f" }
		elseif 1 == vim.fn.executable("where") then
			return { "where", "/r", ".", "*" }
		end
	end)()

	if not find_command then
		vim.notify("You need to install either find, fd, or rg", vim.log.levels.ERROR)
		return
	end

	local command = find_command[1]
	local hidden = opts.hidden
	local no_ignore = opts.no_ignore
	local no_ignore_parent = opts.no_ignore_parent
	local follow = opts.follow

	if command == "fd" or command == "fdfind" or command == "rg" then
		if hidden then
			find_command[#find_command + 1] = "--hidden"
		end
		if no_ignore then
			find_command[#find_command + 1] = "--no-ignore"
		end
		if no_ignore_parent then
			find_command[#find_command + 1] = "--no-ignore-parent"
		end
		if follow then
			find_command[#find_command + 1] = "-L"
		end
	elseif command == "find" then
		if not hidden then
			table.insert(find_command, { "-not", "-path", "*/.*" })
			find_command = vim.tbl_flatten(find_command)
		end
		if no_ignore ~= nil then
			log.warn("The `no_ignore` key is not available for the `find` command in `find_files`.")
		end
		if no_ignore_parent ~= nil then
			log.warn("The `no_ignore_parent` key is not available for the `find` command in `find_files`.")
		end
		if follow then
			table.insert(find_command, 2, "-L")
		end
	elseif command == "where" then
		if hidden ~= nil then
			log.warn("The `hidden` key is not available for the Windows `where` command in `find_files`.")
		end
		if no_ignore ~= nil then
			log.warn("The `no_ignore` key is not available for the Windows `where` command in `find_files`.")
		end
		if no_ignore_parent ~= nil then
			log.warn("The `no_ignore_parent` key is not available for the Windows `where` command in `find_files`.")
		end
		if follow ~= nil then
			log.warn("The `follow` key is not available for the Windows `where` command in `find_files`.")
		end
	end

	return find_command
end

--- @class openOptions
---@field follow boolean: if true, follows symlinks (i.e. uses `-L` flag for the `find` command)
---@field hidden boolean: determines whether to show hidden files or not (default: false)
---@field no_ignore boolean: show files ignored by .gitignore, .ignore, etc. (default: false)
---@field no_ignore_parent boolean: show files ignored by .gitignore, .ignore, etc. in parent dirs. (default: false)

--- Search for files (respecting .gitignore)
---@param opts? openOptions: options
M.open = function(opts)
	opts = opts or {}

	local cwd = vim.loop.cwd()
	local rel_path = normilize_path(vim.api.nvim_buf_get_name(0))

	M.state[cwd] = M.state[cwd] or {}

	if not M.state[cwd][rel_path] then
		local find_command = constract_file_command(opts)
		if not find_command then
			return
		end

		vim.fn.jobstart(find_command, {
			stdout_buffered = true,
			on_stdout = function(_, files)
				if not files then
					return
				end

				vim.ui.select(files, {}, function(item)
					if not item then
						return
					end

					if item == rel_path then
						return
					end

					-- update the state before writing it
					local ok, state = pcall(read_state)
					if not ok then
						state = {}
					end
					M.state = state
					M.state[cwd] = M.state[cwd] or {}

					if M.state[cwd][item] then
						vim.notify("File is already registered", vim.log.levels.ERROR)
						return
					end

					M.state[cwd][rel_path] = item
					M.state[cwd][item] = rel_path

					write_state(M.state)

					vim.cmd.edit(item)
				end)
			end,
		})

		return
	end

	vim.cmd.edit(M.state[cwd][rel_path])
end

M.clear = function()
	local ok, state = pcall(read_state)
	if not ok then
		state = {}
	end
	M.state = state

	local cwd = vim.loop.cwd()
	local rel_path = normilize_path(vim.api.nvim_buf_get_name(0))

	M.state[cwd] = M.state[cwd] or {}

	if M.state[cwd][rel_path] then
		local other = M.state[cwd][rel_path]
		M.state[cwd][rel_path] = nil
		M.state[cwd][other] = nil

		write_state(M.state)
	end
end

return M
