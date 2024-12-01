local M = {}
local Job = require('plenary.job')

-- URL encoding function
local function url_encode(str)
  if str then
    str = str:gsub("\n", " "):gsub("([^%w _%%%-%.~])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = str:gsub(" ", "+")
  end
  return str
end

-- Function to read the current line
function M.read_current_line(lang)
  lang = lang or "en"  -- Default to English if no language is provided
  local line = vim.api.nvim_get_current_line()
  local encoded_line = url_encode(line)
  local tts_url = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=" .. encoded_line .. "&tl=" .. lang
  Job:new({
    command = 'curl',
    args = { '-s', tts_url, '-o', 'output.mp3' },
    on_exit = function(j, return_val)
      if return_val == 0 then
        Job:new({
          command = 'mpv',
          args = { 'output.mp3' },
          detached = true,
        }):start()
      else
        error("Failed to fetch TTS audio")
      end
    end,
  }):start()
end

-- Function to read the selected text
function M.read_selected_text(range, lang)
  lang = lang or "en"  -- Default to English if no language is provided
  local start_line = range[1]
  local end_line = range[2]
  local lines = vim.fn.getline(start_line, end_line)
  local text = table.concat(lines, " ")
  local encoded_text = url_encode(text)
  local tts_url = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=" .. encoded_text .. "&tl=" .. lang
  Job:new({
    command = 'curl',
    args = { '-s', tts_url, '-o', 'output.mp3' },
    on_exit = function(j, return_val)
      if return_val == 0 then
        Job:new({
          command = 'mpv',
          args = { 'output.mp3' },
          detached = true,
        }):start()
      else
        error("Failed to fetch TTS audio")
      end
    end,
  }):start()
end

-- Define commands
vim.api.nvim_create_user_command('ReadCurrentLine', function(opts)
  M.read_current_line(opts.args)
end, { nargs = '?' })  -- nargs = '?' allows zero or one argument

vim.api.nvim_create_user_command('ReadSelectedText', function(opts)
  M.read_selected_text({opts.line1, opts.line2}, opts.args)
end, { range = true, nargs = '?' })  -- nargs = '?' allows zero or one argument

return M
