MakeCommand("goto_definition", "ctags.goto_definition", 0)

n_tags = {}
tags = {}
tag_filename = ""
base_path = "."

function string.startsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-- Shamelessly copied and adapted from the snippets.lua plugin

function getTextLoc()
    local v = CurView()
    local a, b, c = nil, nil, v.Cursor

    if (not c:HasSelection()) then
        v.Cursor:WordLeft()
        startX = v.Cursor.X
        v.Cursor:WordRight()
        endX = v.Cursor.X
        v.Cursor:SetSelectionStart(Loc(startX, v.Cursor.Y))
        v.Cursor:SetSelectionEnd(Loc(endX, v.Cursor.Y))
    end

    if c.CurSelection[1]:GreaterThan(-c.CurSelection[2]) then
        a, b = c.CurSelection[2], c.CurSelection[1]
    else
        a, b = c.CurSelection[1], c.CurSelection[2]
    end

    return Loc(a.X, a.Y), Loc(b.X, b.Y)
end

function getText(start_block, end_block)
    return CurView().Buf:Line(start_block.Y):sub(start_block.X+1,end_block.X)
end

function string:split(sep)
   local sep, fields = sep or "/", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

function abspath(filename)
	local cmd = "readlink -f " .. filename .. " 2>&1"
	local f = assert(io.popen(cmd, "r"))
	ret_value = assert(f:read("*a"))
	f:close()
	return ret_value:gsub("\n","")
end

function get_tag_filename(current_file)
    path_parts = current_file:split()
    max_depth = 10
    found = false

    for i = 1, #path_parts-1 do
        base_path = base_path .. "/" .. path_parts[i] .. "/"
    end

    for i = 0, max_depth do
        file_name = base_path .. "tags"
        local file = io.open(file_name, "r")
        if file ~= nil then
            file:close(file_name)
            found = true
            break
        end
        base_path = base_path .. "../"
    end

    return abspath(file_name)
end

function read_tags()
    count = 0
    local tag_file = io.open(tag_filename, "r")
    if (tag_file == nil) then
        return
    end
    -- Using gmatch for some reason can block the micro editor
    -- So we do it manually
    --for name,file,search_str in line:gmatch("(.*)\t(.*)\t(.*)\t") do 
    tags[tag_filename] = {}
    for line in tag_file:lines() do
        fields = line:split("\t")
        tag_name = fields[1]
        filename = fields[2]
        search_str = fields[3]

        if ((tag_name ~= nil) and (filename ~= nil) and (search_str ~= nil)) then
            search_str = search_str:sub(2, search_str:len()-3):gsub("%(", "%%("):gsub("%)", "%%)")
            if (tags[tag_filename][tag_name] == nil) then
                tags[tag_filename][tag_name] = {}
            end
            tags[tag_filename][tag_name][#tags[tag_filename][tag_name]] = {["filename"] = filename, ["search_str"] = search_str}
            count = count + 1
        end
    end
    tag_file:close()
    return count
end

function goto_definition()
    start_block, end_block = getTextLoc()
    tag_name = getText(start_block, end_block)

    if (tags[tag_filename][tag_name] == nil) then
        return
    end

    -- abspath is an expensive operation, doing it when reading
    -- the tags file would make opening the view too slow

    -- If there's no definition in the current view,
    -- byt default open the first one
    found_index = 0
    tag_data = {}
    for i = 0, #tags[tag_filename][tag_name] do
        tag_data = tags[tag_filename][tag_name][i]
        if (abspath(tag_data["filename"]) == abspath(CurView().Buf.Path)) then
            found_index = i
        end
    end

    tag_data = tags[tag_filename][tag_name][found_index]

    local desired_path = abspath(tag_data["filename"])
    if (abspath(CurView().Buf.Path) ~= desired_path) then
        CurView():AddTab(false)
        CurView():Open(desired_path)
    else
        CurView().Cursor:ResetSelection()
    end

    CurView().Cursor:ResetSelection()
    CurView().Cursor:Relocate()

    for line_index = 0, CurView().Buf.NumLines do
        if (CurView().Buf:Line(line_index):match(tag_data["search_str"])) then
            CurView().Cursor.Y = line_index
            break
        end
    end

    CurView():Relocate()
end

function onViewOpen(view)
    tag_filename = get_tag_filename(CurView().Buf.Path)
    if (n_tags[tag_filename] == nil) then
        n_tags[tag_filename] = read_tags()
    end
end

BindKey("F12", "ctags.goto_definition")
