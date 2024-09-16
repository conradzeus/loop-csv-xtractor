-- >>===================================================================================================<<
-- ||`..bbbbbbbbbb`....bbbbbbbbb`....bbbbb`.......bbbbbbbbbbbbb`..bbbbbb`..bbbbbb`..bbbbbb`..bbbbbbbbbbb||
-- ||`..bbbbbbbb`..bbbb`..bbbb`..bbbb`..bb`..bbbb`..bbbbbbbbbbbbb`..bbbbbb`..bbbbbb`..bbbbbb`..bbbbbbbbb||
-- ||`..bbbbbb`..bbbbbbbb`..`..bbbbbbbb`..`..bbbb`..bbbbbbbbbbbbbbb`..bbbbbb`..bbbbbb`..bbbbbb`..bbbbbbb||
-- ||`..bbbbbb`..bbbbbbbb`..`..bbbbbbbb`..`.......bbbbbbb`.....bbbbbb`..bbbbbb`..bbbbbb`..bbbbbb`..bbbbb||
-- ||`..bbbbbb`..bbbbbbbb`..`..bbbbbbbb`..`..bbbbbbbbbbbbbbbbbbbbbb`..bbbbbb`..bbbbbb`..bbbbbb`..bbbbbbb||
-- ||`..bbbbbbbb`..bbbbb`..bbb`..bbbbb`..b`..bbbbbbbbbbbbbbbbbbbb`..bbbbbb`..bbbbbb`..bbbbbb`..bbbbbbbbb||
-- ||`........bbbb`....bbbbbbbbb`....bbbbb`..bbbbbbbbbbbbbbbbbb`..bbbbbb`..bbbbbb`..bbbbbb`..bbbbbbbbbbb||
-- ||bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb||
-- ||`..bbbbbb`..`...b`......`.......bbbbbbbbbb`.bbbbbbbbbbb`..bbb`...b`......bbbb`....bbbbb`.......bbbb||
-- ||b`..bbb`..bbbbbbb`..bbbb`..bbbb`..bbbbbbb`.b..bbbbbb`..bbb`..bbbbb`..bbbbbb`..bbbb`..bb`..bbbb`..bb||
-- ||bb`..b`..bbbbbbbb`..bbbb`..bbbb`..bbbbbb`.bb`..bbbb`..bbbbbbbbbbbb`..bbbb`..bbbbbbbb`..`..bbbb`..bb||
-- ||bbbb`..bbbbbbbbbb`..bbbb`.b`..bbbbbbbbb`..bbb`..bbb`..bbbbbbbbbbbb`..bbbb`..bbbbbbbb`..`.b`..bbbbbb||
-- ||bb`..b`..bbbbbbbb`..bbbb`..bb`..bbbbbb`......b`..bb`..bbbbbbbbbbbb`..bbbb`..bbbbbbbb`..`..bb`..bbbb||
-- ||b`..bbb`..bbbbbbb`..bbbb`..bbbb`..bbb`..bbbbbbb`..bb`..bbb`..bbbbb`..bbbbbb`..bbbbb`..b`..bbbb`..bb||
-- ||`..bbbbbb`..bbbbb`..bbbb`..bbbbbb`..`..bbbbbbbbb`..bbb`....bbbbbbb`..bbbbbbbb`....bbbbb`..bbbbbb`..||
-- >>===================================================================================================<<

-- this lua script will export your .nki's sample loop-point parameters (start,end) 
-- to a .csv file organized by group index!
-- useful if you need to pull loop points to reference for any reason...
-- big shouts to Gablux for providing the starting point for this script,
-- and ED for making me use my brain even tho he knows i hate doing that.
-- 
-- //conrad 

local kt = Kontakt

INSTRUMENT_IDX = 0 -- Assuming you only have one NKI loaded and it is the first you loaded

loop_data = {}

-- Function to extract file name from path
local function getFileName(filePath)
    -- Find the last occurrence of '/' or '\\' in the file path
    local name = filePath:match("^.+[\\/](.+)$") or filePath
    return name
end

-- Function to extract numeric part from filename
local function extractNumber(fileName)
    local number = fileName:match("(%d+)")
    return tonumber(number) or 0
end

-- Collect loop data
for zone_idx = 0, kt.get_num_zones(INSTRUMENT_IDX) - 1 do
    local file        = kt.get_zone_sample(INSTRUMENT_IDX, zone_idx)
    local loop_start  = kt.get_sample_loop_start(INSTRUMENT_IDX, zone_idx, 0)
    local loop_length = kt.get_sample_loop_length(INSTRUMENT_IDX, zone_idx, 0)
    local loop_end    = loop_start + loop_length
    local group_idx   = kt.get_zone_group(INSTRUMENT_IDX, zone_idx)

    -- Initialize table for the group index if it doesn't exist
    if not loop_data[group_idx] then
        loop_data[group_idx] = {}
    end

    -- Append data for each zone with the file name only
    table.insert(loop_data[group_idx], {
        ['file']        = getFileName(file),
        ['loop_start']  = loop_start,
        ['loop_end']    = loop_end
    })
end

-- Function to sort files by their numeric part
local function sortFilesByNumber(files)
    table.sort(files, function(a, b)
        return extractNumber(a.file) < extractNumber(b.file)
    end)
end

-- Function to get desktop path based on the operating system
local function getDesktopPath()
    local home = os.getenv("HOME")
    if home then
        -- Assume the desktop path based on OS
        local osName = os.getenv("OS") or ""
        if osName:find("Windows") then
            -- For Windows, use the 'USERPROFILE' environment variable
            return os.getenv("USERPROFILE") .. "\\Desktop\\loop_data.csv"
        else
            -- For macOS and Linux, 'HOME' should be sufficient
            return home .. "/Desktop/loop_data.csv"
        end
    else
        -- Fallback to current directory if HOME is not found
        return "loop_data.csv"
    end
end

-- Get the path to save the file
local output_file_path = getDesktopPath()

-- Open file for writing
local output_file = io.open(output_file_path, "w")

if output_file then
    -- Write CSV header without Loop Length
    output_file:write("Group Index,File,Loop Start,Loop End\n")

    -- Sort group indices
    local sorted_group_indices = {}
    for group_idx in pairs(loop_data) do
        table.insert(sorted_group_indices, group_idx)
    end
    table.sort(sorted_group_indices)

    -- Write data organized by group index
    for _, group_idx in ipairs(sorted_group_indices) do
        -- Sort files in each group by their numeric part
        sortFilesByNumber(loop_data[group_idx])

        for _, data in ipairs(loop_data[group_idx]) do
            output_file:write(("%d,%s,%d,%d\n"):format(
                group_idx,
                (data.file or ""),
                (data.loop_start or 0),
                (data.loop_end or 0)
            ))
        end

        -- Add a blank line after each group
        output_file:write("\n")
    end

    output_file:close()
    print("Loop data successfully written to " .. output_file_path)
else
    print("Error opening file for writing")
end
