local function check_stroke(cand, inp, db)
    local inp_stroke = inp:match("[viuoa]+")
    if not inp_stroke or not db then
        return false
    end
    local lookup = db:lookup(cand.text)
    lookup = lookup:gsub("h", "v")
    lookup = lookup:gsub("s", "i")
    lookup = lookup:gsub("p", "u")
    lookup = lookup:gsub("n", "u")
    lookup = lookup:gsub("z", "i")
    for stroke in lookup:gmatch("(%w+)%s?") do
        if stroke:match("^" .. inp_stroke) then
            return true
        end
    end
    return false
end

local function pinyin_to_shuangpin(py)
    if not py then
        return nil
    end
    py = py:gsub("^([jqxy])u$", "%1v")
    py = py:gsub("^zh", "Z")
    py = py:gsub("^sh", "S")
    py = py:gsub("^ch", "C")
    py = py:gsub("^z", "F")
    py = py:gsub("^s", "W")
    py = py:gsub("^c", "M")
    py = py:gsub("^h", "N")
    py = py:gsub("^r", "T")
    py = py:gsub("^k", "P")
    py = py:gsub("^([aoe])([iounr])", "Q%1%2")
    py = py:gsub("^([aoe])(ng?)", "Q%1%2")
    py = py:gsub("^([aoe])", "Q%1")
    py = py:gsub("iang", "Z")
    py = py:gsub("uang", "Q")
    py = py:gsub("ang", "F")
    py = py:gsub("ian", "Q")
    py = py:gsub("uan", "M")
    py = py:gsub("an", "W")
    py = py:gsub("uai", "P")
    py = py:gsub("ai", "L")
    py = py:gsub("iao", "X")
    py = py:gsub("ao", "B")
    py = py:gsub("ia", "C")
    py = py:gsub("ua", "F")
    py = py:gsub("a", "C")
    py = py:gsub("iong", "B")
    py = py:gsub("ong", "T")
    py = py:gsub("ou", "X")
    py = py:gsub("uo", "Y")
    py = py:gsub("o", "M")
    py = py:gsub("eng", "S")
    py = py:gsub("en", "Z")
    py = py:gsub("ei", "P")
    py = py:gsub("er", "F")
    py = py:gsub("ie", "S")
    py = py:gsub("ue", "L")
    py = py:gsub("e", "N")
    py = py:gsub("ing", "Y")
    py = py:gsub("in", "G")
    py = py:gsub("iu", "T")
    py = py:gsub("ui", "G")
    py = py:gsub("i", "J")
    py = py:gsub("un", "P")
    py = py:gsub("u", "D")
    py = py:gsub("v", "M")
    return py:lower()
end

local function correct_preedit(text, inp, db)
    if not db then
        return nil
    end
    if inp:len() < 2 then
        return nil
    end
    local inp = inp:sub(1, 2)
    local lookup = db:lookup(text)
    for pinyin in lookup:gmatch("(%w+)%s?") do
        local shuangpin = pinyin_to_shuangpin(pinyin)
        if shuangpin and shuangpin == inp then
            return pinyin
        end
    end
    return nil
end

local function filter(input, env)
    local input_text = env.engine.context.input
    for cand in input:iter() do
        local cand_inp = input_text:sub(cand.start + 1, cand._end)
        if utf8.len(cand.text) == 1 then
            local preedit = correct_preedit(cand.text, cand_inp, env.pinyin_db)
            if preedit then
                if cand_inp:len() > 2 then
                    preedit = preedit .. "." .. cand_inp:sub(3)
                end
                if cand._end < input_text:len() then
                    preedit = preedit .. " "
                end
                cand:get_genuine().preedit = preedit
            end
        else
            -- assume phrases do not have any strokes
            local preedit = ""
            local i = 0
            for text in cand.text:gmatch(utf8.charpattern) do
                i = i + 1
                local inp = cand_inp:sub(i*2-1, i*2)
                local char_preedit = correct_preedit(text, inp, env.pinyin_db)
                if preedit:len() > 0 then
                    preedit = preedit .. " "
                end
                if char_preedit then
                    preedit = preedit .. char_preedit
                else
                    preedit = preedit .. inp
                end
            end
            cand.preedit = preedit
        end
        local has_stroke = cand_inp:match("[viuoa]")
        if not has_stroke then
            yield(cand)
        elseif check_stroke(cand, cand_inp, env.stroke_db) then
            yield(cand)
        end
    end
end

local function init(env)
    env.stroke_db = ReverseDb("build/stroke.reverse.bin")
    env.pinyin_db = ReverseDb("build/quad.reverse.bin")
end

return { init = init, func = filter }
