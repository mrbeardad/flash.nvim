---@type Flash.Config
local M = {}

---@class Flash.Config
---@field mode? string
---@field enabled? boolean
---@field ns? string
local defaults = {
  -- labels = "abcdefghijklmnopqrstuvwxyz",
  labels = "asdfghjklqwertyuiopzxcvbnm",
  jump = {
    -- add pattern to search history
    history = false,
    -- add pattern to search register
    -- useful to use with `n` and `N` to repeat the jump
    register = false,
    -- clear highlight after jump
    nohlsearch = true,
    -- save location in the jumplist
    jumplist = true,
    pos = "start", -- "start" | "end" | "range"
  },
  search = {
    -- search/jump in all windows
    multi_window = true,
    -- search direction
    forward = true,
    -- when `false`, find only matches in the given direction
    wrap = true,
    ---@type Flash.Pattern.Mode
    -- Each mode will take ignorecase and smartcase into account.
    -- * exact: exact match
    -- * search: regular search
    -- * fuzzy: fuzzy search
    -- * fun(str): custom function that returns a pattern
    --   For example, to only match at the beginning of a word:
    --   mode = function(str)
    --     return "\\<" .. str
    --   end,
    mode = "exact",
    -- behave like `incsearch`
    incremental = false,
    filetype_exclude = { "notify", "noice" },
  },
  highlight = {
    label = {
      -- add a label for the first match in the current window.
      -- you can always jump to the first match with `<CR>`
      current = false,
      -- show the label after the match
      after = true, ---@type boolean|number[]
      -- show the label before the match
      before = false, ---@type boolean|number[]
      -- position of the label extmark
      style = "overlay", ---@type "eol" | "overlay" | "right_align" | "inline"
    },
    -- show a backdrop with hl FlashBackdrop
    backdrop = true,
    -- Highlight the search matches
    matches = true,
    -- extmark priority
    priority = 5000,
    groups = {
      match = "FlashMatch",
      current = "FlashCurrent",
      backdrop = "FlashBackdrop",
      label = "FlashLabel",
    },
  },
  -- You can override the default options for a specific mode.
  -- Use it with `require("flash").jump({mode = "forward"})`
  ---@type table<string, Flash.Config>
  modes = {
    -- options used when flash is activated through
    -- a regular search with `/` or `?`
    search = {
      enabled = true, -- enable flash for search
      highlight = { backdrop = false },
      jump = { history = true },
      search = {
        -- `forward` will be automatically set to the search direction
        -- `mode` is always set to `search`
        -- `incremental` is set to `true` when `incsearch` is enabled
      },
    },
    -- options used when flash is activated through
    -- `f`, `F`, `t`, `T`, `;` and `,` motions
    char = {
      enabled = true,
      search = { wrap = false },
      highlight = { backdrop = true },
      jump = { register = false },
    },
    -- options used for treesitter selections
    -- `require("flash").treesitter()`
    treesitter = {
      labels = "abcdefghijklmnopqrstuvwxyz",
      jump = { pos = "range" },
      highlight = {
        label = { before = true, after = true, style = "inline" },
        backdrop = false,
        matches = false,
      },
    },
    -- you can define your own modes
    -- `require("flash").jump({mode = "forward"})`
    forward = {
      search = { forward = true, wrap = false, multi_window = false },
    },
    -- `require("flash").jump({mode = "backward"})`
    backward = {
      search = { forward = false, wrap = false, multi_window = false },
    },
  },
}

---@type Flash.Config
local options

---@param opts? Flash.Config
function M.setup(opts)
  opts = opts or {}
  opts.mode = nil
  options = M.get(opts)

  if options.modes.search.enabled then
    require("flash.plugins.search").setup()
  end
  if options.modes.char.enabled then
    require("flash.plugins.char").setup()
  end
end

---@param ... Flash.Config|Flash.State.Config|nil
---@return Flash.State.Config
function M.get(...)
  ---@type Flash.Config[]
  local all = {}

  for i = 1, select("#", ...) do
    ---@type Flash.Config?
    local opts = select(i, ...)
    if opts then
      if opts.mode then
        all[#all + 1] = defaults.modes[opts.mode] or {}
        opts.mode = nil
      end
      all[#all + 1] = opts
    end
  end

  return vim.tbl_deep_extend("force", {}, defaults, options or {}, unpack(all))
end

return setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(defaults)[key]
    end
    return options[key]
  end,
})
