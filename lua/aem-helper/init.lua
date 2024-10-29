local log = require("aem-helper.internal.log")

local runner = require("aem-helper.internal.run")

---
---@class AemHelperOpts
---@field aem_path string
---@field jar_file string
---@field author {folder: string, port: number}
---@field publish {folder: string, port: number}
---@field dispatcher {folder: string, config: string, port: number}

local M = {}

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

	vim.notify("Starting " .. env)
	local path = vim.fs.joinpath(_opts.aem_path, _opts.author.folder);
	if not vim.fn.isdirectory(path) then
		vim.notify("Path " .. path .. " does not exist. Creating it now")
		vim.fn.mkdir(path, "p");
	end

	local cmd = { "java", "-jar", _opts.jar_file, "-port", tostring(_opts[env].port), "-nobrowser", "-b", _opts[env]
		.folder, "-nointeractive", "-r", env, "-nofork" }

	-- NOTE: AEM pushes all output to stderr. And it's useless for us here, so it's getting ignored
	local _, _, pid = runner.run(cmd, "aem_" .. env, {
		cwd = _opts.aem_path,
	})

	log.debug("Started AEM " .. env .. " with pid " .. pid)
end

function M.start_dispatcher()
	--- @type AemHelperOpts
	local _opts = _G['aem_helper'].opts;

	local dispatcher_folder = vim.fs.joinpath(_opts.aem_path, _opts.dispatcher.folder);

	local cmd = { "bin/docker_run.sh", _opts.dispatcher.config, "172.17.0.1" .. ":" .. _opts.publish.port, _opts
		.dispatcher.port }

	local _, stderr, pid = runner.run(cmd, "aem_dispatcher", {
		cwd = dispatcher_folder
	})

	stderr:read_start(function(err, data)
		if err then
			log.error(err)
		end
		if data then
			log.debug(data)
		end
	end)

	log.debug("Started AEM dispatcher with pid " .. pid)
end

function M.launch()
	vim.ui.select({ "all", "author + publish", "author", "publish", "dispatcher" }, {
		prompt = "Select environment",
	}, function(item)
		vim.notify("Starting " .. item)
		if item == "all" then
			M.start_aem("author")
			M.start_aem("publish")
			M.start_dispatcher()
		elseif item == "author + publish" then
			M.start_aem("author")
			M.start_aem("publish")
		elseif item == "author" then
			M.start_aem("author")
		elseif item == "publish" then
			M.start_aem("publish")
		elseif item == "dispatcher" then
			M.start_dispatcher()
		end
	end)
end

---
---@param opts AemHelperOpts
function M.setup(opts)
	vim.g.aem_helper_debug = true
	if opts == nil or opts.aem_path == nil then
		log.error("aem_path is not set")
		return
	end

	opts = vim.tbl_deep_extend("force", require("aem-helper.default_config"), opts)
	opts.aem_path = vim.fs.normalize(opts.aem_path)

	-- TODO: Probably not needed to be global?
	_G['aem_helper'] = _G['aem_helper'] or {}
	_G['aem_helper']['opts'] = opts

	log.debug("config" .. vim.inspect(_G['aem_helper'].opts))

	-- NOTE: Testing only
	vim.api.nvim_create_user_command('AEMTest', function() M.launch() end, {})

	vim.keymap.set("n", "<Plug>(LaunchAem)", function() M.launch() end, { noremap = true, silent = true })

	-- -- LEGACY
	-- vim.cmd([[
	--        command! -nargs=? -complete=dir AEMExportFolder lua require('aem-helper').export_folder(<f-args>)
	--        command! -nargs=? -complete=dir AEMImportFolder lua require('aem-helper').import_folder(<f-args>)
	--        command! AEMExportFile lua require('aem-helper').export_file()
	--        command! AEMImportFile lua require('aem-helper').import_file()
	--    ]])
end

return M
