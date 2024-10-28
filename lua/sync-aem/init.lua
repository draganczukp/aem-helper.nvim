local log = require("sync-aem.log")

---
---@class AemHelperOpts
---@field aem_path string
---@field jar_file string
---@field author {folder: string, port: number}
---@field publish {folder: string, port: number}
---@field dispatcher {folder: string, config: string}

local M = {}

local au_group = vim.api.nvim_create_augroup('aem_helper', { clear = true })


local function get_plugin_dir()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

local repo_script_path = get_plugin_dir() .. "script/repo.sh"

local function run_command(cmd, args)
	local full_cmd = repo_script_path .. " " .. cmd .. ' -f "' .. args .. '"'
	local output = vim.fn.system(full_cmd)
	print(output)
end

function M.export_folder(path)
	path = path or vim.fn.expand("%:p:h")
	run_command("put", path)
	print("Exported folder to AEM: " .. path)
end

function M.import_folder(path)
	path = path or vim.fn.expand("%:p:h")
	run_command("get", path)
	print("Imported folder from AEM: " .. path)

	-- Refresh all buffers that are within the imported folder
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local buf_name = vim.api.nvim_buf_get_name(buf)
		if vim.startswith(buf_name, path) then
			vim.cmd("checktime " .. buf)
		end
	end
end

function M.export_file()
	local current_file = vim.fn.expand("%:p")
	run_command("put", current_file)
	print("Exported current file to AEM: " .. current_file)
end

function M.import_file()
	local current_file = vim.fn.expand("%:p")
	run_command("get", current_file)
	print("Imported current file from AEM: " .. current_file)

	vim.cmd("edit!")
end

---
---@param env "author"|"publish"
function M.start_aem(env)
	--- @type AemHelperOpts
	local _opts = _G['aem_helper'].opts
	local uv = vim.uv;

	local path = vim.fs.joinpath(_opts.aem_path, _opts.author.folder);
	if not vim.fn.isdirectory(path) then
		log.debug("Path " .. path .. " does not exist")
		vim.fn.mkdir(path, "p");
	end

	local args = { "-jar", _opts.jar_file, "-port", tostring(_opts[env].port), "-nobrowser", "-b", _opts[env]
		.folder, "-nointeractive", "-r", env }

	log.debug("command" .. vim.inspect(args))

	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	log.debug("Starting AEM " .. env)
	local handle, pid = uv.spawn("java", {
		args = args,
		stdio = { nil, stdout, stderr },
		cwd = _opts.aem_path

	}, function(code, signal)
		if code ~= 0 then
			vim.schedule(function()
				log.debug(
					"AEM " .. env .. " stopped with code " .. code .. " and signal " .. signal)
			end)
		end
		stdout:read_stop()
		stderr:read_stop()
		stdout:close()
		stderr:close()
	end)

	stdout:read_start(function(err, data)
		if err then
			vim.schedule(function()
				log.debug("Error reading stdout: " .. err)
			end)
			return
		end
		if data then
			vim.schedule(function()
				log.debug("stdout: " .. data)
			end)
		end
	end)
	stderr:read_start(function(err, data)
		if err then
			vim.schedule(function()
				log.debug("Error reading stderr: " .. err)
			end)
			return
		end
		if data then
			vim.schedule(function()
				log.debug("stderr: " .. data)
			end)
		end
	end)

	log.debug("Started AEM " .. env .. " with pid " .. pid)

	_G['aem_helper'][env] = {
		pid = pid,
		stdout = stdout,
		stderr = stderr
	}

	vim.api.nvim_create_autocmd('VimLeavePre', {
		group = au_group,
		callback = function()
			M.stop_aem(env)
		end
	})
end

---
---@param env "author"|"publish"
function M.stop_aem(env)
	local pid = _G['aem_helper'][env].pid
	log.debug("Stopping AEM " .. env)
	vim.uv.kill(pid, "sigterm")
end

---
---@param opts AemHelperOpts
function M.setup(opts)
	if opts == nil or opts.aem_path == nil then
		log.error("aem_path is not set")
		return
	end

	opts = vim.tbl_deep_extend("force", require("sync-aem.default_config"), opts)
	opts.aem_path = vim.fs.normalize(opts.aem_path)

	_G['aem_helper'] = _G['aem_helper'] or {}
	_G['aem_helper']['opts'] = opts

	log.debug("config" .. vim.inspect(_G['aem_helper'].opts))

	-- NOTE: Testing only
	vim.api.nvim_create_user_command('AEMTest', function() M.start_aem("author") end, {})

	-- -- LEGACY
	-- vim.cmd([[
	--        command! -nargs=? -complete=dir AEMExportFolder lua require('sync-aem').export_folder(<f-args>)
	--        command! -nargs=? -complete=dir AEMImportFolder lua require('sync-aem').import_folder(<f-args>)
	--        command! AEMExportFile lua require('sync-aem').export_file()
	--        command! AEMImportFile lua require('sync-aem').import_file()
	--    ]])
end

return M
