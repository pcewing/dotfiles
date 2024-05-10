local vim = vim

if _G.config_loaded == true then
    for name, _ in pairs(package.loaded) do
        if name:match('^dot%..*$') then
            package.loaded[name] = nil
        end
    end
end

_G.config_loaded = true

-- See the Util.load function in util.lua for why this is necessary
local Globals   = require('dot.globals')
local Log       = require('dot.log')
local Mappings  = require('dot.mappings')
local Plugins   = require('dot.plugins')
local Settings  = require('dot.settings')
local Theme     = require('dot.theme')
local Util      = require('dot.util')

local tmp_dir = Util.tmp_dir()

if not Util.directory_exists(tmp_dir) then
    vim.fn.mkdir(tmp_dir, "p", "0775")
end

Log.init(Log.levels.info, Util.path_join(tmp_dir, "nvim.log"))
Log.info('loading init.lua')

Settings.init()
Plugins.init()
Mappings.init()
Globals.init()
Theme.init()

if Util.is_wsl() then
    local Wsl = require('dot.wsl')
    Wsl.init()
end

Log.info('finished loading init.lua')
