local telescope = require('telescope')
telescope.setup({
    defaults = {
        mappings = {
            i = {
                ["<A-j>"] = "move_selection_next",
                ["<A-k>"] = "move_selection_previous",
            }
        }
    },
    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown { }
        }
    }
})
telescope.load_extension("ui-select")
