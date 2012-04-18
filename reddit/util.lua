local ltn12 = require "ltn12"
local sock = require "socket"
local url = require "socket.url"
local http = require "socket.http"
local sockselect = socket.select

local util = {}

util.escape = url.escape

function util.setUseragent(s)
	http.USERAGENT = s
end

function util.sleep(sec)
	sockselect(nil, nil, sec)
end

function util.urlParamEncode(t)
	local escape = util.escape
	local _t = {}
	table.foreach(t, function(k,v)
		_t[#_t+1] = escape(k).."="..escape(v)
	end)
	return table.concat(_t, "&")
end

function util.validateAuth(auth)
	if not type(auth) == "table" then
		error "Auth must be a table."
	elseif not type(auth.modhash) == "string" then
		error "Auth modhash must be a string."
	elseif not type(auth.cookie) == "string" then
		error "Auth cookie must be a string."
	end
end

function util.updateAuth(auth, res)
	if auth and res.data and res.data.modhash then
		auth.modhash = res.data.modhash
	end
end

function util.getRequest(url, cookie)
	local res = {}
	local reqt = {
		url = url,
		method = "GET",
		sink = ltn12.sink.table(res),
	}
	if cookie then reqt.headers = {cookie = cookie} end

	local _, code, h, s = http.request(reqt)

	return table.concat(res), code, h, s
end

function util.postRequest(url, body, cookie)
	local res = {}
	if type(body) == "table" then
		body = util.urlParamEncode(body)
	end
	local headers = {
		["content-length"] = body:len(),
		["content-type"] = "application/x-www-form-urlencoded"
	}
	if cookie then headers.cookie = cookie end
	local _, code, h, s = http.request {
		url = url,
		method = "POST",
		headers = headers,
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(res),
	}
	return table.concat(res), code, h, s
end

util.setUseragent "StreamLogger-by-TurplePurtle"

return util
