local cmp = require('cmp')
cmp.setup({
    -- completion menu kep mapping
    mapping = {
        -- accept completion
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        -- trigger completion
        ['<C-n>'] = cmp.mapping.complete(),
        -- abort completion
        ['<C-e>'] = cmp.mapping.abort(),
        -- nagivate
        ['<A-k>'] = cmp.mapping.select_prev_item(),
        ['<A-j>'] = cmp.mapping.select_next_item(),
    },

    -- Installed sources:
    sources = {
        { name = 'buffer',                 keyword_length = 2 }, -- source current buffer
        { name = 'path' },                     -- file paths
        { name = 'nvim_lsp',               keyword_length = 2 }, -- from language server
        { name = 'nvim_lsp_signature_help' },  -- display function signatures with current parameter emphasized
        { name = 'nvim_lua',               keyword_length = 2 }, -- complete neovim's Lua runtime API such vim.lsp.*
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    formatting = {
        fields = { 'abbr', 'kind' },
    },
})

