-- This file is responsible for configuring treesitter

-- TODO: Link to useful docs
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = false,
    disable = {},
  },
  ensure_installed = {
    "bash",
    "c",
    "c_sharp",
    "cpp",
    "dockerfile",
    "erlang",
    "go",
    "gomod",
    "hcl",
    "html",
    "java",
    "javascript",
    "json",
    "latex",
    "lua",
    "python",
    "rust",
    "yaml"
  },
}

