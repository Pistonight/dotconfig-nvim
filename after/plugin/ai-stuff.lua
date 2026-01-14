-- Claude Code plugin configuration for Neovim integration
require("claudecode").setup {
    -- Automatically start the Claude Code server when Neovim opens
    auto_start = true,

    -- Terminal settings for the Claude Code CLI interface
    terminal = {
        -- Use Neovim's built-in terminal emulator
        provider = "native",
        -- Terminal takes up 40% of the window width when opened as a split
        split_width_percentage = 0.4,
        -- Function to determine the working directory for the terminal
        -- Uses the current working directory from the context
        cwd_provider = function(ctx)
            return ctx.cwd
        end,
    },

    -- Diff view options for reviewing code changes
    diff_opts = {
        -- Open diffs in a new tab instead of the current one
        open_in_curent_tab = false,
    }
}
