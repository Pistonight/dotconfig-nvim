local M = {}


M.config = {
  width_ratio = 0.9,
}

local float_win = nil
local float_buf = nil

local function create_float_window(buf)
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * M.config.width_ratio)
  local height = ui.height
  local col = ui.width - width

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = 0,
    col = col,
    style = "minimal",
    border = "none",
  }

  float_buf = buf or vim.api.nvim_create_buf(false, true)
  float_win = vim.api.nvim_open_win(float_buf, true, opts)

  return float_win, float_buf
end

local function close_float()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    vim.api.nvim_win_close(float_win, true)
  end
  float_win = nil
  float_buf = nil
end

function M.open_diff(file1, file2)
  close_float()

  local win, buf = create_float_window()

  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

  if file1 then
    vim.cmd("edit " .. vim.fn.fnameescape(file1))
    vim.cmd("diffthis")
  end

  if file2 then
    vim.cmd("vsplit " .. vim.fn.fnameescape(file2))
    vim.cmd("diffthis")
  end

  vim.keymap.set("n", "q", function()
    close_float()
  end, { buffer = true, nowait = true })
end

function M.setup()
  local original_diffthis = vim.cmd.diffthis

  vim.api.nvim_create_user_command("DiffFloat", function(opts)
    local args = vim.split(opts.args, " ")
    M.open_diff(args[1], args[2])
  end, { nargs = "*", complete = "file" })

  vim.api.nvim_create_autocmd("OptionSet", {
    pattern = "diff",
    callback = function()
      if vim.v.option_new == "1" and not float_win then
        local current_buf = vim.api.nvim_get_current_buf()
        local current_file = vim.api.nvim_buf_get_name(current_buf)

        vim.schedule(function()
          vim.cmd("diffoff")

          close_float()
          local win, _ = create_float_window()

          vim.cmd("edit " .. vim.fn.fnameescape(current_file))
          vim.cmd("diffthis")

          vim.keymap.set("n", "q", function()
            close_float()
          end, { buffer = true, nowait = true })
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function()
      if vim.wo.diff and not float_win then
        local current_buf = vim.api.nvim_get_current_buf()
        local current_file = vim.api.nvim_buf_get_name(current_buf)

        if current_file ~= "" then
          vim.schedule(function()
            vim.cmd("diffoff!")

            close_float()
            local win, _ = create_float_window()

            vim.cmd("edit " .. vim.fn.fnameescape(current_file))
            vim.cmd("diffthis")

            vim.keymap.set("n", "q", function()
              close_float()
            end, { buffer = true, nowait = true })
          end)
        end
      end
    end,
  })
end

return M