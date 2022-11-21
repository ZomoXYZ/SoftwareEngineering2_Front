extends Node

const Schema_http = "https"
const Schema_ws = "wss"
const Host = "wan.zomo.dev"
const Port = 443
const Path = "/api/v1"

#const Schema_http = "http"
#const Schema_ws = "ws"
#const Host = "10.242.19.199"
#const Port = 8080
#const Path = ""

const BASE_URL = "%s://%s:%s%s" % [Schema_http, Host, Port, Path]
const WS_URL = "%s://%s:%s%s/ws" % [Schema_ws, Host, Port, Path]

