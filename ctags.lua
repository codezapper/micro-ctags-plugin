MakeCommand("goto_definition", "ctags.goto_definition", 0)

n_tags = 0
tags = {}

function string.startsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function getTextLoc()
    local v = CurView()
    local a, b, c = nil, nil, v.Cursor

    if c:HasSelection() then
        if c.CurSelection[1]:GreaterThan(-c.CurSelection[2]) then
            a, b = c.CurSelection[2], c.CurSelection[1]
        else
            a, b = c.CurSelection[1], c.CurSelection[2]
        end
    else
        local eol = string.len(v.Buf:Line(c.Loc.Y))
        a, b = c.Loc, Loc(eol, c.Y)
    end
    return Loc(a.X, a.Y), Loc(b.X, b.Y)
end

function getText(start_block, end_block)
    return CurView().Buf:Line(start_block.Y):sub(start_block.X+1,end_block.X)
end

function read_tags()
    count = 0
    local file = assert(io.open("/home/gabriele/PythonCodeExercises/SearchPlayer/tags", "r"))
    -- Using gmatch for some reason can block the micro editor
    -- So we do it manually
    --for name,file,search_str in line:gmatch("(.*)\t(.*)\t(.*)\t") do 
    for line in file:lines() do
        if (line:find("\t")) then
            tag_name = line:sub(1, line:find("\t")-1)
            partial_line = line:sub(line:find("\t")+1, line:len())
            if (partial_line:find("\t") ~= nil) then
                file_name = partial_line:sub(1, partial_line:find("\t")-1)

                if (string.startsWith(file_name, "./")) then
                    file_name = file_name:sub(3,file_name:len())
                end
                search_str = partial_line:sub(partial_line:find("\t")+2, partial_line:len()-5):gsub("%(", "%%("):gsub("%)", "%%)")
                tags[tag_name] = {["file_name"] = file_name, ["search_str"] = search_str}
            end
            count = count + 1
        end
    end
    file:close()
    return count
end

function goto_definition()
    start_block, end_block = getTextLoc()
    tag_name = getText(start_block, end_block)

    local desired_path = tags[tag_name]["file_name"]
    if (CurView().Buf.Path ~= desired_path) then
        CurView():AddTab(true)
        CurView():Open(desired_path)
    end
    messenger:AddLog("---" .. tags[tag_name]["search_str"] .. "---")
    for line_index = 0, CurView().Buf.NumLines,1 do
        if (CurView().Buf:Line(line_index):match(tags[tag_name]["search_str"])) then
            CurView().Cursor.Y = line_index
            CurView().Cursor:Relocate()
        end
    end
end

function onViewOpen(view)
    if (n_tags == 0) then
        n_tags = read_tags()
    end
end
