-- local puts = require("tools/debugtool")
require("tools/string")

local function last_character(s)
	return string.utf8_sub(s, -1, -1)
end

local function fly_fixed(input, env)
	local cands = {}
	local prev_cand_ok = false
	local config = env.engine.schema.config
	local schema_id = config:get_string("translator/dictionary") -- 多方案共用字典取主方案名称
	local reversedb = ReverseLookup(schema_id)
	local preedit_code = env.engine.context:get_commit_text()
	for cand in input:iter() do
		local cand_text_code = tonumber(utf8.codepoint(cand.text, 1))
		if
			(19968 <= cand_text_code)
			and (cand_text_code <= 117777)
			and (#preedit_code % 2 ~= 0)
			and (not preedit_code:find('%['))
			and (preedit_code:match("^.+[andefwosr]$") or preedit_code:match("^[andefwosr]$"))
		then
			local last_char = last_character(cand.text)
			local yin_code = reversedb:lookup(last_char):gsub("%l%[%l%l", "")
			local preedit_last_code = preedit_code:sub(-1, -1)
			if yin_code and (yin_code:match(preedit_last_code)) then
				yield(cand)
				prev_cand_ok = false
			else
				table.insert(cands, cand)
				prev_cand_ok = true
			end
		elseif preedit_code:match("^%l%l%[%l$") and (utf8.len(cand.text) > 1) then
		elseif prev_cand_ok then
			table.insert(cands, cand)
			prev_cand_ok = true
		else
			yield(cand)
			prev_cand_ok = false
		end

		if #cands > 50 then
			break
		end
	end

	for _, cand in ipairs(cands) do
		yield(cand)
	end
end

return { filter = fly_fixed }
