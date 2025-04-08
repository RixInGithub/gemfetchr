--[[
	gemfetchr
		a barebones gemini client for lua, using only luasec (and partially luasocket, but that comes preinstalled with luasec lol)
]]

local function splitByNl(a)
	local b={}
	for c in(a):gmatch("([^\n]*)\n?")do(table.insert)(b,c)end
	return(b)
end

local function isoGarblesToUtf8(isoWtf)
	return (isoWtf:gsub(".", function(a)
		local b = string.byte(a)
		if(b<128)then;return(a)end
		return(string.char)(192+math.floor(b/64),128+(b%64))
	end))
end

local describe = (function(a)
	local b={}
	for c,d in ipairs(splitByNl(a)) do
		local e,f=d:match("^(%d+)=(.*)$")
		b[tonumber(e)]=f
	end
	return(b)
end)([[10=Input
11=Sensitive Input
20=Success
30=Temporary Redirect
31=Permanent Redirect
40=Temporary Failure
41=Server Unavailable
42=CGI Error
43=Proxy Error
44=Slow Down
50=Permanent Failure
51=Not Found
52=Gone
53=Proxy Request Refused
59=Bad Request
60=Client Certificate Required
61=Certificate Not Authorised
62=Certificate Not Valid]])

local function main(u, props, sess)
	local toReturn = {}
	xpcall(function()
		local ssl = require("ssl")
		local socket = require("socket")
		local url = require("socket.url")
		local tcp = socket.tcp()
		local uTbl = url.parse(u)
		tcp:connect(uTbl.host,tonumber(uTbl.port)or(1965))
		local tls = assert(ssl.wrap(tcp, {
			mode = "client",
			protocol = "tlsv1_2",
			options = "all"
		}))
		assert(tls:dohandshake())
		tls:send(u.."\r\n")
		local res = tls:receive("*a")
		tls:close()
		local pretty = res:gsub("\r\n?", "\n") -- autoformat to \n, way ezier
		local linez = splitByNl(pretty)
		local stat = tonumber(linez[1]:match("^%d+"))
		-- error("test")
		toReturn={
			raw=res,
			status=stat,
			extraStat=linez[1]:sub(#tostring(stat)+2),
			txt=res:sub(#linez[1]+1):gsub("^[\r][\n]","")
		}
		if describe[stat]==nil then
			stat = math.floor(stat/10)*10 -- eg, handle 14 as 10, handle 22 as 20 (too (get it?))
			toReturn.status=stat
		end
		if math.floor(stat/10)==3 and props.follow3x and sess[1]<props.maxRedirs then
			sess[1]=sess[1]+1
			toReturn=main(toReturn.extraStat,props,sess)
			return
		end
		if(props.follow3x)then(function()toReturn.endedIn=(u)end)()end
		if(string.find(toReturn.extraStat,";"))then
			(print)(toReturn.extraStat:sub(string.find(toReturn.extraStat,";")+1))
		end
	end,function(e)
		toReturn={err=e}
	end)
	return toReturn
end

return (function(props) -- make a wrapper func that takes props as args, returns another wrapper that takes url and calls main with url+props+pregenerated session details
	return (function(u)
		return main(u, {
			follow3x = true,
			maxRedirs = 5,
			table.unpack(props)
		}, {0})
	end)
end)