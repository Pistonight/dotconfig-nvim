
local editorapi = require("editorapi")

local M = {}

-- helper for remapping
local function noremap(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

---Setup global keymaps
function M.setup()
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
end

---Setup key maps for nvim tree buffer
function M.setup_nvim_tree(bufnr)
    local function opts(desc)
        return {
            desc = 'nvim-tree: ' .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true
        }
    end
    local api = require("nvim-tree.api")
    vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts('Info'))
    vim.keymap.set('n', 'O', api.node.navigate.parent_close, opts('Close parent'))
    vim.keymap.set('n', 'P', api.node.navigate.parent, opts('Go to parent'))
    vim.keymap.set('n', 'm', api.fs.rename_sub, opts('Move'))
    vim.keymap.set('n', 'o', api.node.open.edit, opts('Open'))
    vim.keymap.set('n', 'v', require("editorapi").editview_open_split , opts('Open: vertical'))
    vim.keymap.set('n', 's', api.node.open.horizontal, opts('Open: split'))
    vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
    vim.keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
    vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
    vim.keymap.set('n', 'd', api.fs.remove, opts('Delete'))
    vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
    vim.keymap.set('n', 'x', api.fs.cut, opts('Cut'))
    vim.keymap.set('n', 'r', api.fs.rename_sub, opts('Rename'))
    vim.keymap.set('n', '-', api.marks.toggle, opts('Select'))
    vim.keymap.set('n', 'bd', api.marks.bulk.delete, opts('Delete: selected'))
    vim.keymap.set('n', 'bm', api.marks.bulk.move, opts('Move: selected'))
    vim.keymap.set('n', '[', api.node.navigate.diagnostics.prev, opts('Prev diagnostic'))
    vim.keymap.set('n', ']', api.node.navigate.diagnostics.next, opts('Next diagnostic'))
    vim.keymap.set('n', 'B', api.tree.toggle_no_buffer_filter, opts('Toggle opened'))
    vim.keymap.set('n', 'H', api.tree.toggle_hidden_filter, opts('Toggle dotfiles'))
    vim.keymap.set('n', 'I', api.tree.toggle_gitignore_filter, opts('Toggle gitignore'))
    vim.keymap.set('n', 'q', api.tree.close, opts('Close'))
    vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
    vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy absolute path'))
    vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy name'))
    vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy relative path'))
    vim.keymap.set('n', 'g?', api.tree.toggle_help, opts('Help'))
end

return M
