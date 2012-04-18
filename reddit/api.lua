--[[
Reddit api. Currently supported functions are (all prepended by "reddit."):

login(user, passwd)
getJson(url, auth)
submit(title, isSelf, content, subreddit, auth)
comment(thing_id, text, auth)
]]

local json = require "json"
local util = require "reddit.util"

local reddit = {util=util}

function reddit.login(user, passwd)
	local url = "https://ssl.reddit.com/api/login/" .. user
	local postData = {
		api_type = "json",
		user = user,
		passwd = passwd,
	}

	local res = util.postRequest(url, postData)
	local data = json.decode(res).json.data

	if data and data.modhash and data.cookie then
		return {
			user=user,
			modhash=data.modhash,
			session=data.cookie,
			cookie="reddit_session="..util.escape(data.cookie)}
	end
end

function reddit.getJson(url, auth)
	local res, code = util.getRequest(url, auth and auth.cookie)

	res = json.decode(res)
	util.updateAuth(auth, res)

	return res, code
end

function reddit.submit(title, isSelf, content, subreddit, auth)
	util.validateAuth(auth)
	local url = "http://www.reddit.com/api/submit"
	local postData = {
		title = title,
		sr = subreddit,
		kind = isSelf and "self" or "link",
		uh = auth.modhash,
		[isSelf and "text" or "url"] = content,
		api_type = "json"
	}
	local res, code = util.postRequest(url, postData, auth.cookie)

	res = json.decode(res)
	util.updateAuth(auth, res)

	return res, code
end

function reddit.comment(thing_id, text, auth)
	util.validateAuth(auth)
	local url = "http://www.reddit.com/api/comment"
	local postData = {
		thing_id = thing_id,
		text = text,
		uh = auth.modhash,
		api_type = "json"
	}
	local res, code = util.postRequest(url, postData, auth.cookie)

	res = json.decode(res)
	util.updateAuth(auth, res)

	return res, code
end

return reddit
