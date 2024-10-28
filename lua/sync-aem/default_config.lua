return {
	aem_path = nil, -- absolute path to the AEM quickstart jar file
	jar_file = 'crx-quickstart.jar',
	author = {
		folder = "author/crx-quickstart", -- path to crx-quickstart folder, absolute or relative to `aem_path`
		port = 4202
	},
	publish = {
		folder = "publish/crx-quickstart", -- path to crx-quickstart folder
		port = 4203
	},
	dispatcher = {
		folder = "dispatcher", -- path to dispatcher SDK folder
		config = "dispatcher_config" -- path to dispatcher configuration folder
	}
}
