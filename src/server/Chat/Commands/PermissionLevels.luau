--All permission levels associated with the group
local config = {}

config.GroupId = 3939011
config.Roles = {
    [150] = 1; --Helper
    [175] = 2; --Designer
    [200] = 3; --Moderator
    [250] = 4; --Lead Moderator
    [254] = 5; --Developer
    [255] = 6; --Lead Developer
}

return config