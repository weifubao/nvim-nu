local log = require("nu.log")
local vim = vim

local M = {}

local all_cmds = {}

local function cmd_names_from_cmd(cmd)
    local Job = require('plenary.job')

    log.debug("Running shell command", cmd)

    local proc = Job:new({
        command = "sh",
        args = { "-c", cmd },
        cwd = '.',
        enable_recording = true,
    })
    proc:start()
    proc:wait()

    if proc.code ~= 0 then
        log.error("Command failure:\n", table.concat(proc:stderr_result(), '\n'))
        return {}
    end
    return proc:result()
end

function M.init(cmd_names)
    if type(cmd_names) == "table" then
        all_cmds = cmd_names
    elseif type(cmd_names) == "function" then
        all_cmds = cmd_names()
    elseif type(cmd_names) == "string" then
        all_cmds = cmd_names_from_cmd(cmd_names)
    else
        log.error("all_cmd_names is expected to be a table, function or string. Got", type(cmd_names))
    end
    log.debug("Initialised nu lsp cmd_names to", table.concat(all_cmds, " "))
end

local function cmds_to_check(content, row, col)
    local cur_row = string.sub(content[row], 0, col + 1) -- Only until col is necessary
    log.trace("Completing line:", cur_row)
    local tokens = {}
    for token in string.gmatch(cur_row, "[^%s]+") do
        table.insert(tokens, token)
    end
    local result = {}
    local tokens_len = #tokens
    if tokens_len >= 2 then -- if more than 2 elements
        table.insert(result, {
            cmd_text = tokens[tokens_len - 1] .. " " .. tokens[tokens_len],
            is_sub_cmd = true
        })
    end
    if tokens_len >= 1 then
        table.insert(result, {
            cmd_text = tokens[tokens_len],
            is_sub_cmd = false
        })
    end
    log.trace("Found following tokens to complete", vim.inspect(result))
    return result
end

local function find_commands(text)
    local results = {}
    local text_first_char = text:sub(1, 1)
    for _, cmd in ipairs(all_cmds) do
        if string.find(cmd, text) ~= nil then
            table.insert(results, cmd)
        end
        if cmd:sub(1, 1) > text_first_char then
            break
        end
    end
    log.trace("Found", #results, "matching cmds for", text, "(", vim.inspect(results), ")")
    return results
end

return M
