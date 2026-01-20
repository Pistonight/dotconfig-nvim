local M = {}

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local bufid = event.buf
        local key_opts = { buffer = bufid }
        -- keys that only work when LSP is attached (so they are buffer-local)
        vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, key_opts)
        vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, key_opts)
        vim.keymap.set('n', 'K', function() vim.lsp.buf.hover({ border = "rounded" }) end, key_opts)
        vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, key_opts)
        -- code action menu
        vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, key_opts)
        -- signature help in input mode
        vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, key_opts)
        -- enable inlay hints (currently disabled by default)
        vim.lsp.inlay_hint.enable(true, { bufid })
        vim.cmd("hi LspInlayHint guifg=#d8d8d8 guibg=#3a3a3a")
        vim.keymap.set({'n', 'v'}, '<leader>i', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, key_opts)
    end
})
-- Remove if no longer needed
-- https://github.com/neovim/neovim/issues/30985 workaround for LSP error from rust-analyzer
for _, method in ipairs({
    'textDocument/diagnostic',
    'textDocument/semanticTokens/full/delta',
    'textDocument/inlayHint',
    'workspace/diagnostic'
}) do
    local default_diagnostic_handler = vim.lsp.handlers[method]
    vim.lsp.handlers[method] = function(err, result, context, config)
        if err ~= nil then
            if err.code == -32802 then
                return
            end
            if err.code == -32603 then
                return
            end
        end

        return default_diagnostic_handler(err, result, context, config)
    end
end

-- ensure dependencies are loaded
require("lspconfig")
require("mason-lspconfig")

function M.enable(lspserver)
    vim.lsp.enable(lspserver)
end

return M
