local M = {}

M.log = function(level, msg)
	vim.notify("[AEM-Helper] [" .. level .. "] " .. msg)
end

M.debug = function(msg)
	if vim.g.aem_helper_debug == nil then
		return
	end
	M.log("DEBUG", msg)
end

M.info = function(msg)
	M.log("INFO", msg)
end

M.warn = function(msg)
	M.log("WARN", msg)
end

M.error = function(msg)
	M.log("ERROR", msg)
end

return M
