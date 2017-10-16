MakeCommand("goto_definition", "ctags.goto_definition", 0)

n_tags = 0
tags = {}
base_path = "./"

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

    return file_name
end

function read_tags()
    count = 0
    local tag_file = assert(io.open(get_tag_filename(CurView().Buf.Path), "r"))
    -- Using gmatch for some reason can block the micro editor
    -- So we do it manually
    --for name,file,search_str in line:gmatch("(.*)\t(.*)\t(.*)\t") do 
    for line in tag_file:lines() do
        fields = line:split("\t")
        tag_name = fields[1]
        filename = fields[2]
        search_str = fields[3]
    messenger:AddLog("---" .. line .. "---")
        if ((tag_name ~= nil) and (filename ~= nil) and (search_str ~= nil)) then
            search_str = search_str:sub(2, search_str:len()-3):gsub("%(", "%%("):gsub("%)", "%%)")
            tags[tag_name] = {["filename"] = filename, ["search_str"] = search_str}
            count = count + 1
        end
    end
    tag_file:close()
    return count
end

function goto_definition()
    start_block, end_block = getTextLoc()
    tag_name = getText(start_block, end_block)

    local desired_path = abspath(tags[tag_name]["filename"])
    if (abspath(CurView().Buf.Path) ~= desired_path) then
        CurView():AddTab(true)
        CurView():Open(desired_path)
    else
        CurView().Cursor:ResetSelection()
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