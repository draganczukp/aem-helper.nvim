local log = require("aem-helper.internal.log")

local augroup = vim.api.nvim_create_augroup('aem_helper_runner', { clear = false })

local M = {};

--- @class AEMRunOpts
--- @field cwd string
--- @field env? table
---
---
---@param cmd string[] Command to run as array of strings
---@param opts AEMRunOpts
---@param id string Internal ID, used to identify a running process. Can be any arbitrary string
---@return uv_pipe_t stdout
---@return uv_pipe_t stderr
---@return number|string pid
M.run = function(cmd, id, opts)
	local uv = vim.uv;
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	local command = cmd[1]
	local args = vim.list_slice(cmd, 2)

	log.debug("Opts: " .. vim.inspect(opts))
	log.debug("Running " .. command .. " " .. table.concat(args, " "))

	-- Start the process
	local handle, pid = uv.spawn(command, {
		args = args,
		stdio = { nil, stdout, stderr },
		cwd = opts.cwd,
		env = opts.env or {}
	}, function(code, signal) -- on_exit
		if code ~= 0 then
			vim.schedule(function()
				log.debug(
					command .. " stopped with code " .. code .. " and signal " .. signal)
			end)
			stdout:read_stop()
			stderr:read_stop()
			stdout:close()
			stderr:close()
		end
	end)

	-- Store data for future use
	_G['aem_helper'][id] = {
		handle = handle,
		pid = pid,
		stdout = stdout,
		stderr = stderr
	}

	-- Cleanup
	vim.api.nvim_create_autocmd('VimLeavePre', {
		group = augroup,
		callback = function()
			vim.uv.close(stdout);
			vim.uv.close(stderr);
			vim.uv.kill(pid, "sigterm")
		end
	})


	return stdout, stderr, pid
end

return M;
