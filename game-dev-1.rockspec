rockspec_format = "3.0"
package = "game"
version = "dev-1"

source = {
    url = ".",
}

description = {
    summary = "Tecs starter game",
    license = "UNLICENSED",
}

dependencies = {
    "lua == 5.1",
    "tecs2d == dev-1",
}

build = {
    type = "builtin",
    modules = {},
}
