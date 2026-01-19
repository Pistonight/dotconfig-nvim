-- # General Configuration
local editorapi = require("editorapi")

-- line numbers
vim.opt.number = true    -- Enable line numbers
vim.opt.rnu = true       -- Relative line numbers by default
-- hidden characters (controlled by keymapping)
vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:»,precedes:«,eol:↲"
-- indent
vim.opt.expandtab = true -- Tab become spaces
vim.opt.shiftwidth = 4   -- Indent 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.fillchars:append { diff = "╱" }

vim.opt.termguicolors = true -- colors
-- undo dir
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
local home = os.getenv('HOME')
if home == nil then
    home = os.getenv('USERPROFILE')
end
if home ~= nil then
    vim.opt.undodir = home .. '/.vim/undodir'
end

-- folds
vim.opt.foldenable = false   -- no fold at startup
vim.opt.foldlevel = 99
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- search
vim.opt.hlsearch = true
vim.opt.incsearch = true -- should be the default
-- scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Floaterm style
vim.g.floaterm_title = 'Terminal [$1/$2]'
-- Undotree style
vim.g.undotree_WindowLayout = 0
vim.g.undotree_SetFocusWhenToggle = 1

-- ## Diagnostics
vim.diagnostic.config({
    virtual_text = true,
    float = {
        border = 'rounded',
    }
})

-- ## Keys
local _ = (function()
    -- helper for remapping
    local function noremap(mode, lhs, rhs, opts)
        local options = { noremap = true }
        if opts then
            options = vim.tbl_extend('force', options, opts)
        end
        vim.keymap.set(mode, lhs, rhs, options)
    end
    -- toggle relative line number
    noremap('n', '<leader>0', function() vim.o.relativenumber = not vim.o.relativenumber end)
    -- toggle show hidden characters (like eol, tab, etc.)
    noremap('n', '<leader>$', function() vim.o.list = not vim.o.list end)
    -- turn off search highlight
    noremap('n', '<leader> ', vim.cmd.nohlsearch)
    -- cursor movement
    -- 15 lines is about where the text moves and I can still see what's going on
    noremap('n', '<C-d>', '15j')     -- bukl move down
    noremap('n', '<C-u>', '15k')     -- bulk move up
    noremap('n', 'n', 'nzz')         -- move to next match and center
    noremap('n', 'N', 'Nzz')         -- move to previous match and center
    -- Move to next '_', uppercase letter, or word boundary
    noremap('n', '<S-l>', function() editorapi.jump_half_word(nil) end)
    noremap('n', 'df<S-l>', function() editorapi.jump_half_word("d", "f") end)
    noremap('n', 'dt<S-l>', function() editorapi.jump_half_word("d" ,"t") end)
    noremap('n', 'cf<S-l>', function() editorapi.jump_half_word("c", "f") end)
    noremap('n', 'ct<S-l>', function() editorapi.jump_half_word("c" ,"t") end)

    -- line movement (note: the : cannot be replaced by <cmd>)
    noremap('v', '<A-j>', [[:m '>+1<cr>gv=gv]]) -- move selection down
    noremap('v', '<A-k>', [[:m '<-2<cr>gv=gv]]) -- move selection up
    -- turn off recording so I don't accidentally hit it
    noremap('n', 'q', '<nop>')
    noremap('n', 'Q', '<nop>')
    -- change window size
    noremap('n', '<C-w>>', '<C-w>20>')
    noremap('n', '<C-w><', '<C-w>20<')
    noremap('n', '<C-w>+', '<C-w>10+')
    noremap('n', '<C-w>-', '<C-w>10-')
    -- copy to system clipboard (see extra.lua)
    noremap('v', '<leader>y', '"ay')
    -- convert between Rust /// doc and JS /** doc */
    noremap('n', '<leader>J', '0f/wBR/**<esc>A */<esc>')
    noremap('v', '<leader>J', '<esc>\'<lt>O<esc>0C/**<esc>\'>o<esc>0C */<esc><cmd>\'<lt>,\'>s/\\/\\/\\// */<cr>gv`<lt>koj=<cmd>nohl<cr>')
    noremap('n', '<leader>R', '0f*wBR///<esc>A<esc>xxx')
    noremap('v', '<leader>R', '<esc>\'<lt>dd\'>ddgv<esc><cmd>\'<lt>,\'>s/\\*/\\/\\/\\//<cr>gv`<lt>koj=<cmd>nohl<cr>')
    -- jumping to diagnostics
    noremap('n', '[d', function() editorapi.jump_diagnostic(-1, false) end)
    noremap('n', ']d', function() editorapi.jump_diagnostic(1, false) end)
    noremap('n', '[D', function() editorapi.jump_diagnostic(-1, true) end)
    noremap('n', ']D', function() editorapi.jump_diagnostic(-1, true) end)
    -- toggle comment
    noremap('n', '<leader>c', vim.cmd.CommentToggle)
    noremap('v', '<leader>c', "V<cmd>'<,'>CommentToggle<cr>gv")

    -- view change
    -- toggle undotree
    noremap('n', '<leader>u', vim.cmd.UndotreeToggle)
    noremap('n', '<leader>w', editorapi.editview_swap_files)
    noremap('n', '<leader>dl', function() editorapi.editview_duplicate(true) end)
    noremap('n', '<leader>dh', function() editorapi.editview_duplicate(false) end)

    -- floaterm
    noremap({'n', 't'}, [[<C-\>]], editorapi.editview_floaterm_toggle)
    noremap({'n', 't'}, [[<leader><C-\>]], editorapi.editview_floaterm_new)
    noremap({'n', 't'}, '<C-n>', editorapi.editview_floaterm_cycle)
    noremap('t', '<C-w>', editorapi.editview_terminal_escape)

    -- telescopers
    noremap('n', '<leader>fr', editorapi.editview_openfinder_last)
    noremap({'n', 't'}, '<leader>ff', editorapi.editview_openfinder_file)
    noremap({'n', 't'}, '<leader>fg', editorapi.editview_openfinder_live_grep)
    noremap({'n', 't'}, '<leader>fb', editorapi.editview_openfinder_buffer)
    noremap('n', '<leader>fs', editorapi.editview_openfinder_symbol)
    noremap('n', 'gr', editorapi.editview_openfinder_reference)
    noremap('n', 'gd', editorapi.editview_openfinder_definition)
    noremap('n', 'gi', editorapi.editview_openfinder_implementation)
    noremap('n', '<leader>vd', editorapi.editview_openfinder_diagnostic)
    -- ai coder
    noremap('n', '<leader>bb', editorapi.editview_aicoder_open)
    noremap({'n', 't'}, '<leader>bg', editorapi.aicoder_close)
    noremap({'n', 't'}, '<leader>bv', editorapi.aicoder_open_or_accept_diff)
    noremap({'n', 't'}, '<leader>bd', editorapi.aicoder_deny_diff)
    noremap('n', '<leader>bl', function() editorapi.aicoder_send(false) end)
    noremap('v', '<leader>bl', function() editorapi.aicoder_send(true) end)
    noremap('n', '<leader>gs', editorapi.diffview_git_view_or_status)
    noremap('n', '<leader>gd', editorapi.diffview_git_diff_new)

    -- focus on tree (edit mode and diff mode)
    noremap('n', '<leader>t', function() editorapi.open_file_tree(false) end)
    noremap('n', '<leader>T', function() editorapi.open_file_tree(true) end)


    -- Other key mappings that requires plugin to be loaded first
    -- telescope.lua
    -- lsp-config.lua
    -- nvim-tree.lua
end)()
