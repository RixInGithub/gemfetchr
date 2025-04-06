package = "gemfetchr"
version = "0-0"
source = {
	url = "https://github.com/RixInGithub/gemfetchr/archive/refs/heads/main.zip" -- lets not waste time cloning a git repo, ok?
}
description = {
	summary = "a barebones gemini client for lua, using only luasec (and partially luasocket, but that comes preinstalled with luasec lol)",
	license = "MIT",
	homepage = "https://github.com/RixInGithub/gemfetchr"
}
dependencies = {
	"lua >= 5.3, < 5.5",
	"luasec"
}
build = {
	type = "builtin",
	modules = {
		gemfetchr = "gemfetchr.lua"
	}
}