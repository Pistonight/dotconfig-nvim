require("claudecode").setup {
    auto_start = true,
    terminal = {
        provider = "native",
        split_width_percentage = 0.4,
        cwd_provider = function(ctx)
            return ctx.cwd
        end,
    },
    diff_opts = {
        open_in_curent_tab = false,
    }
}
