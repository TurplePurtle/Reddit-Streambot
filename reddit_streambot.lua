--------------------------------
-- 2012-04-12 Santiago Jaramillo
-- This script gets links in the Plounge that match "stream" in the title
--------------------------------

local reddit = require "reddit.api"

reddit.util.setUseragent "StreamLogger-by-TurplePurtle"

local function fread(name, opt)
	local f = io.open(name, "r")
	if f then
		local res = f:read(opt)
		f:close()
		return res
	end
end

local function fwrite(name, data)
	local f = io.open(name, "w")
	f:write(data) f:flush() f:close()
end

function table.filter(t, fn)
	local ft = {}
	for i=1,#t do
		if fn(t[i], i, t) then ft[#ft+1] = t[i] end
	end
	return ft
end

local function matchesStream(link)
	local data = link.data
	if data.title:lower():match("stream")
	or data.is_self and data.selftext:lower():match("stream") then
		return true
	end
	return false
end

local function printLinkInfo(_, link)
	local data = link.data
	local title = data.title
	if #title > 32 then title = title:sub(1,30)..".." end

	print(os.date(nil, data.created_utc), data.author, title)
end

local function getStreams(url)
	local submissions = reddit.getJson(url).data.children
	local streams = table.filter(submissions, matchesStream)
	return streams, submissions
end

local function getAuthData()
	local user, passwd = arg[1], arg[2]
	assert(user and passwd, "No username or password provided (CL args)")
	print("Logging in as " .. user)
	return reddit.login(user, passwd)
end

local function titlefmt(user, title)
	return string.format("[%s] %s", user, title)
end

local function main()
	local savefile = "reddit_streambot.dat"
	local newestLink = fread(savefile, "*number")
	if not newestLink then
		print "Last link id not found. Continue? (y/n)"
		if io.read() ~= "y" then return end
	end

	local authdata = assert(getAuthData(), "Error: Unable to log in.")

	local baseUrl = "http://api.reddit.com/r/MLPLounge/new?sort=new&limit=30"
	local streams, links, firstLink, lastLink

	print("--------------------------------")
	print("-- Current date-time: ", os.date(), "\n")

	for i=1,1 do
		if lastLink then
			streams, links = getStreams(baseUrl .. "&after=" .. lastLink)
		else
			streams, links = getStreams(baseUrl)
		end
		if not firstLink then firstLink = links[1] end
		lastLink = links[#links].data.name

		for i=#streams,1,-1 do
			local link = streams[i].data

			if not newestLink or (newestLink and link.created_utc > newestLink) then
				local submitTitle = titlefmt(link.author, link.title)
				print(link.created_utc, "-Submitting "..submitTitle)
				reddit.util.sleep(5)
				if authdata then
					local res = reddit.submit(submitTitle, false, "http://www.reddit.com"..link.permalink, "mylittlestreamlog", authdata)
					-- if res.json.ratelimit then
						-- print("Waiting for ratelimit", res.json.ratelimit)
						-- reddit.util.sleep(res.json.ratelimit)
					-- end
				end
			end
		end
	end
	print("Most recent link utc time was", firstLink.data.created_utc)
	fwrite(savefile, firstLink.data.created_utc)
	print("--------------------------------")
end

main()
