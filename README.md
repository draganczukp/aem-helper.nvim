Forked from [tylopilus/sync-aem](https://github.com/tylopilus/sync-aem) in order to make it do _more_

# Sync AEM plugin for neovim

this plugin is a wrapper for Adobe's Repo tool https://github.com/Adobe-Marketing-Cloud/tools/tree/master/Repo

## install

### Lazy
```lua
  {
    "draganczukp/aem-helper.nvim",
    opts = {
      aem_path = "~/aem", -- REQUIRED, path to your "aem roor"
      -- Everything below this point is optional. Default values provided for convenience
      jar_file = "crx-quickstart.jar"
      -- NOTE: For both `author.folder` and `publish.folder`, AEM will create the
      -- `crx-quickstart` folder automatically. Don't include it in the folder path
      -- or you'll end up with `author/crx-quickstart/crx-quickstart`
      author = {
          folder = "author", -- path to author folder, absolute or relative to `aem_path`
          port = 4202 -- author port
      },
      publish = {
          folder = "publish", -- path to crx-quickstart folder
          port = 4203 -- publish port; will be used to launch dispatcher
      },
      dispatcher = {
          folder = "dispatcher", -- path to dispatcher SDK folder
          config = "dispatcher_config" -- path to dispatcher configuration folder
          port = 8080 -- dispatcher port
      }
    },
  },
```

## Usage
This plugin creates four commands 
- `:AEMExportFile` - Exports the file in current buffer to `http://localhost:4502`
- `:AEMExportFolder` - Exports the folders of the current buffers file to
`http://localhost:4502`
- `:AEMImportFile` - Imports the file in current buffer from
`http://localhost:4502`
- `:AEMImportFilder` - Imports the folder of the current buffers file from
`http://localhost:4502`


Additionally accepts args to absolute filepath e.g. `:AEMImportFolder ~/projects/repo/ui.apps/src/main/content/jcr_root/apps`

# TODO:
- [x] Config for AEM location
- [ ] Launch author, publish and dispatcher
  - [x] author
  - [x] publish
  - [ ] dispatcher
- [ ] Show logs (aemerror, stdout) for both instances
  - [ ] Floating window
  - [ ] Split
  - [ ] Tab
- [ ] Launch `mvn clean install...` in CWD
  - [ ] Option for later: choose author/publish
  - [ ] Option to choose floating window or in background
- [ ] Launch `npm run build` for the frontend package
  - [ ] Only in the background
  - [ ] `AEMExportFile` in `ui.frontend` should automatically export the whole frontend folder
- [ ] Documentation
- [ ] chores
  - [ ] Modularize the code
  - [ ] Proper error logging
  - [ ] Ensure things are closed when nvim closes

