-- # General Configuration

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
-- diff
vim.cmd([[
:set diffopt+=internal,algorithm:patience,indent-heuristic
:set diffopt+=linematch:60
]])

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
    local jump_half_word = function(action, flag)
        -- Save current position
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        -- Search pattern: _ or [A-Z] or word boundary (\<)
        local pattern = [[\(_\w\|\u\|\<\)]]
        -- Search forward, no [W]rap and go to [e]nd
        local found = vim.fn.search(pattern, 'We')
        if found == 0 then
            -- Not found, restore cursor
            vim.api.nvim_win_set_cursor(0, {row, col})
            return
        end
        if action == nil then
            return
        end
        if action == 'd' or action == 'c' then
            local new_row, new_col = unpack(vim.api.nvim_win_get_cursor(0))
            vim.api.nvim_win_set_cursor(0, {row, col})
            -- enter visual mode
            vim.cmd('normal! v')
            if flag == 't' then
                vim.api.nvim_win_set_cursor(0, {new_row, new_col - 1})
            else
                vim.api.nvim_win_set_cursor(0, {new_row, new_col})
            end
            vim.cmd('normal! d')
            if action == 'c' then
                vim.cmd('startinsert')
            end
            return
        end
    end
    noremap('n', '<S-l>', function() jump_half_word(nil) end)
    noremap('n', 'df<S-l>', function() jump_half_word("d", "f") end)
    noremap('n', 'dt<S-l>', function() jump_half_word("d" ,"t") end)
    noremap('n', 'cf<S-l>', function() jump_half_word("c", "f") end)
    noremap('n', 'ct<S-l>', function() jump_half_word("c" ,"t") end)

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
    -- swap left and right buffers
    noremap('n', '<leader>w', function()
        vim.cmd.NvimTreeClose()
        vim.api.nvim_input("<C-w>r")
        vim.defer_fn(function ()
            vim.cmd.NvimTreeOpen()
            vim.api.nvim_input("<C-w>l")
        end, 1)
    end)
    -- convert between Rust /// doc and JS /** doc */
    noremap('n', '<leader>J', '0f/wBR/**<esc>A */<esc>')
    noremap('v', '<leader>J', '<esc>\'<lt>O<esc>0C/**<esc>\'>o<esc>0C */<esc><cmd>\'<lt>,\'>s/\\/\\/\\// */<cr>gv`<lt>koj=<cmd>nohl<cr>')
    noremap('n', '<leader>R', '0f*wBR///<esc>A<esc>xxx')
    noremap('v', '<leader>R', '<esc>\'<lt>dd\'>ddgv<esc><cmd>\'<lt>,\'>s/\\*/\\/\\/\\//<cr>gv`<lt>koj=<cmd>nohl<cr>')
    -- jumping to diagnostics
    local show_diag_float = function()
        vim.defer_fn(function()
            vim.diagnostic.open_float({ scope = 'cursor' })
        end, 50)
    end
    noremap('n', '[d', function()
        vim.diagnostic.jump({ count = -1})
        show_diag_float()
    end)
    noremap('n', ']d', function()
        vim.diagnostic.jump({ count = 1})
        show_diag_float()
    end)
    noremap('n', '[D', function()
        vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
        show_diag_float()
    end)
    noremap('n', ']D', function()
        vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
        show_diag_float()
    end)
    -- toggle comment
    noremap('n', '<leader>c', vim.cmd.CommentToggle)
    noremap('v', '<leader>c', "V<cmd>'<,'>CommentToggle<cr>gv")
    -- toggle undotree
    noremap('n', '<leader>u', vim.cmd.UndotreeToggle)

    -- ## window integration
    local buftype = function(bufnr)
        local filetype
        local buftype
        if bufnr ~= nil then
            filetype = vim.bo[bufnr].filetype
            buftype = vim.bo[bufnr].buftype
        else
            filetype = vim.bo.filetype
            buftype = vim.bo.buftype
        end
        if filetype == "NvimTree" then
            return "tree"
        end
        if filetype == "claude-notify" then
            return "notif"
        end
        if buftype ~= "terminal" then
            if vim.api.nvim_buf_get_name(bufnr or 0):match("claude[/\\]proposed$") ~= nil
            then
                return "aidiff"
            end
            return "file"
        end
        if filetype == "floaterm" then
            return "floaterm"
        end
        -- the only non-floaterm terminal environment
        -- we have right now is claude/ai
        return "fileterm"
    end
    -- toggle floaterm
    noremap('n', [[<C-\>]], vim.cmd.FloatermToggle)
    noremap('t', [[<C-\>]], vim.cmd.FloatermToggle)
    -- (inside floaterm only) new floaterm
    noremap('t', [[<leader><C-\>]], function()
        if buftype() ~= "floaterm" then return end
        vim.cmd.FloatermNew();
    end)
    noremap('n', [[<leader><C-\>]], function()
        if buftype() ~= "floaterm" then return end
        vim.cmd.FloatermNew();
    end)
    -- escape terminal (claude)
    noremap('n', '<esc>', function()
        if buftype() ~= "fileterm" then return end
        vim.cmd("close")
    end)
    noremap('t', '<C-w>', function()
        vim.cmd("stopinsert");
        -- for non-floaterm, also execute a C-w to be ready to switch focus
        -- defer to let UI update (to show "NORMAL")
        vim.defer_fn(function()
            vim.api.nvim_input("<C-w>")
        end, 30)
    end)
    -- cycle through terminals when floaterm is open
    local cycle_floaterm = function()
        if buftype() ~= "floaterm" then return end
        vim.cmd.FloatermNext()
    end
    noremap('t', '<C-n>', cycle_floaterm)
    noremap('n', '<C-n>', cycle_floaterm)
    -- auto startinsert when entering non-floaterm
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            if buftype() ~= "fileterm" then return end
            vim.cmd("startinsert")
        end
    })

    -- if the current tab is the aidiff tab
    local is_aidiff_open = function()
        -- actually check visibility of all windows
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local bufnr = vim.api.nvim_win_get_buf(winid)
            if buftype(bufnr) == "aidiff" then
                return true
            end
        end
        return false
    end
    -- make the active window and the tree the only editor windows open
    local rectify_win_then = function(cb)
        local b = buftype()
        if b == "tree" or b == "floaterm" or is_aidiff_open() then
            vim.notify("operation not supported on current window", vim.log.levels.WARN)
            return
        end
        local window = vim.api.nvim_get_current_win();
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if winid ~= window then
                local bufnr = vim.api.nvim_win_get_buf(winid)
                if buftype(bufnr) ~= "notif" then
                    vim.api.nvim_win_hide(winid)
                end
            end
        end
        vim.cmd.NvimTreeOpen()
        vim.api.nvim_input("<C-w>l")
        vim.defer_fn(cb, 30)
    end
    -- duplicate split view to other side
    local duplicate_view = function(right)
        rectify_win_then(function()
            if right then
                vim.api.nvim_input('<C-w>v<C-W>l')
            else
                vim.api.nvim_input('<C-w>v')
            end
        end)
    end
    noremap('n', '<leader>dl', function() duplicate_view(true) end)
    noremap('n', '<leader>dh', function() duplicate_view(false) end)

    -- ## AI Coder integration
    -- open ai coder
    noremap('n', '<leader>bb', function()
        if buftype() == "fileterm" then return end -- don't do anything if we are already in terminal
        rectify_win_then(vim.cmd.ClaudeCode)
    end)
    -- close (hide) ai coder
    noremap('n', '<leader>bh', function()
        if is_aidiff_open() then
            vim.api.nvim_input("<C-w>gt")
            vim.notify("<leader>bo to open aidiff again", vim.log.levels.WARN)
            return
        end
        if buftype() == "fileterm" then return end -- don't do anything if we are already in terminal
        for _, winid in ipairs(vim.api.nvim_list_wins()) do
            local bufnr = vim.api.nvim_win_get_buf(winid)
            if buftype(bufnr) == "fileterm" then
                vim.api.nvim_win_hide(winid)
            end
        end
        vim.cmd.ClaudeCodeNotificationDismiss()
    end)
    -- open/accept diff
       local open_or_accept_aidiff = function()
        -- see if the aidiff is currently visible
        if is_aidiff_open() then
            -- make sure no unsaved modifications in all opened windows
            for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local bufnr = vim.api.nvim_win_get_buf(winid)
                local buft = buftype(bufnr)
                if buft == "aidiff" or buft == "file" then
                    if vim.bo[bufnr].modified then
                        vim.notify("diff is unsaved, must save before accepting", vim.log.levels.WARN)
                        return
                    end
                end
            end
            -- close the diff and accept it
            vim.cmd.CodeDiff()
            vim.cmd.ClaudeCodeDiffAccept()
            vim.defer_fn(function()
                -- close any dangling aidiff buffers
                for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                    if buftype(bufnr) == "aidiff" then
                        vim.api.nvim_buf_delete(bufnr, {force=false})
                    end
                end
            end, 1000)
            vim.notify("accepted aidiff", vim.log.levels.WARN)
            return
        end
        for _, winid in ipairs(vim.api.nvim_list_wins()) do
            local bufnr = vim.api.nvim_win_get_buf(winid)
            if buftype(bufnr) == "aidiff" then
                -- if diff buf exists, we can likely go to it
                -- with C-Wgt (next tabpage)
                vim.api.nvim_input("<C-w>gt")
                vim.notify("showing aidiff", vim.log.levels.WARN)
                return
            end
        end
        -- open diff in new tabpage
        vim.cmd.ClaudeCodeOpenCodeDiff()
        vim.notify("opened aidiff", vim.log.levels.WARN)
    end
    noremap('n', '<leader>bo', open_or_accept_aidiff)
    noremap('t', '<leader>bo', open_or_accept_aidiff)
    -- deny diff
    noremap('n', '<leader>bn', function()
        -- note we allow denying without the diff open
        -- say we forgot some instruction and want to deny the output
        -- without checking
        if is_aidiff_open() then
            -- force close the buffer
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if buftype(bufnr) == "aidiff" then
                    vim.api.nvim_buf_delete(bufnr, {force=true})
                end
            end
            vim.cmd.CodeDiff()
            vim.cmd.ClaudeCodeDiffDeny()
            return
        end
        vim.notify("denied aidiff", vim.log.levels.WARN)
    end)
    -- send to aicoder
    noremap('n', '<leader>bl', function()
        local b = buftype()
        if b == "fileterm" or is_aidiff_open() then return end -- don't do anything if we are already in terminal
        if b == "tree" then
            vim.cmd.ClaudeCodeTreeAdd()
            vim.cmd.ClaudeCodeFocus()
            return
        end
        rectify_win_then(function()
            vim.cmd("ClaudeCodeAdd %")
            vim.defer_fn(function()
                if buftype() ~= "fileterm" then
                    vim.cmd("stopinsert")
                    vim.api.nvim_input("<C-w>l")
                    vim.cmd("startinsert")
                end
            end, 100)
        end)
    end)
    noremap('v', '<leader>bl', function()
        local b = buftype()
        if b == "fileterm" or b == "tree" or is_aidiff_open() then return end -- don't do anything if we are already in terminal
        rectify_win_then(function()
            vim.api.nvim_input("gv<cmd>ClaudeCodeSend<cr>")
            vim.defer_fn(function()
                if buftype() ~= "fileterm" then
                    vim.cmd("stopinsert")
                    vim.api.nvim_input("<C-w>l")
                    vim.cmd("startinsert")
                end
            end, 100)
        end)
    end)


    -- Other key mappings, see
    -- telescope.lua
    -- lsp-config.lua
    -- nvim-tree.lua
end)()
