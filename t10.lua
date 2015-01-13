#!/usr/local/openresty/luajit/bin/luajit

require 'socket'

threads = {}

function get(host, file)
    local co = coroutine.create(function()
        download(host, file)
    end)
    table.insert(threads, co)
end

function dispatch()
    local i = 1
    local conns = {}
    while true do
        if threads[i] == nil then
            if threads[1] == nil then break end
            i=1
            conns = {}
        end
        local status, res = coroutine.resume(threads[i])
        --print(i, status, res)
        if not res then
            table.remove(threads, i)
        else
            i = i + 1
            table.insert(conns, res)
            if #conns == #threads then
                socket.select(conns)
            end
        end
    end
end

function download(host, file)
    local c = assert(socket.connect(host, 80))
    local count = 0
    c:send('GET '.. file .. ' HTTP/1.0\r\n\r\n')

    while true do
        local s, status, partial = receive(c)
        count = count + #(s or partical)
        if status == 'closed' then break end
    end
    c:close()
    print(file, count)
end

function receive(conn)
    conn:settimeout(0)
    local s, status, partial = conn:receive(2^10)
    if status == 'timeout' then
        coroutine.yield(conn)
    end
    return s or partial, status
end

--[[
host = 'www.homeinns.com'
get(host, '/list/shanghai')
get(host, '/list/wuhan')
get(host, '/list/beijing')
get(host, '/list/shenzhen')
--]]

---[[
host = 'www.w3.org'
get(host, '/TR/html401/')
get(host, '/TR/json-ld-api/')
get(host, '/TR/WD-HTTP-NG-interfaces/')
get(host, '/TR/html5/')
--]]

dispatch()
