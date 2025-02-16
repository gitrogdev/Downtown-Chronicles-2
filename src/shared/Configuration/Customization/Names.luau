--This script contains all config relating to name handling
local config = {}

config.ForbiddenCharacters = {
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
    "!", "\"", "#", "%$", "%%", "&", "/", "%(", "%)", "=",
    "~", "ˇ", "%^", "˘", "°", "˛", "`", "˙", "´", "˝",
    "¸", "¨", "'", "?", "¨", "%+", "%*", "¸",
    "\\", "|", "€", "÷", "×",
    "%[", "%]", "¤",
    "@", "{", "}", "§", ";", ",", "<", ":", ">", "_", "  "
}
config.MaxLength = 32
config.MinLength = 2

return config