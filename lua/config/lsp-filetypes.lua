local SERVERS = {
    lua_ls = { config = true },
    pyright = {}
}
local FILE_TYPES = {
    lua = { "lua_ls" },
    python = { "pyright" },
}
local warn = function(msg) vim.notify("lsp_filetypes: "..msg, vim.log.levels.WARN) end
-- Autocommand to auto-load LSP configs based on filetype
vim.api.nvim_create_autocmd("FileType", {
    callback = function()
        local ft = vim.bo.filetype
        local servers = FILE_TYPES[ft]
        if not servers then
            return
        end
        FILE_TYPES[ft] = nil -- remove the config for the file type that we already enabled
        for _, s in ipairs(servers) do
            local config = SERVERS[s]
            if config then
                SERVERS[s] = nil    -- remove the config for the server that we enabled
                if config.config then
                    require("config.lsp."..s)
                    require("config.lsp").enable(s)
                    warn("enabled server '"..s.."' for file type '"..ft.."'")
                end
            end
        end
    end
})
