require('os')
require('sys')
local stringx = require('pl.stringx')

local bridge = {}

-- TCP ports linger 2 minutes after they're closed, kind of annoying
local port = torch.random(40000, 50000)
local zmq = require('lzmq')

local function deserialize(arg)
  if string.sub(arg, 1, 1) == 'l' then
    local data = string.sub(arg, 2)
    return assert(loadstring("return " .. data))()
  end
end

local function serialize(arg)
  if type(arg) == "string" then
    return '"' .. arg .. '"'
  elseif type(arg) == "number" then
    return arg
  elseif type(arg) == "table" then
    if arg[1] ~= nil and arg[0] == nil and arg[-1] == nil then
      local lst = '['
      for i=1, #arg do
        lst = lst .. serialize(arg[i]) .. ','
      end
      return lst .. ']'
    else
      local tbl = '{'
      for k, v in pairs(arg) do
        tbl = tbl .. serialize(k) .. ':' .. serialize(v) .. ','
      end
      return tbl .. '}'
    end
  else
    error("Cannot serialize this type")
  end
end

function bridge.init()
  os.execute(string.format("python3 worker.py %d &", port))

  local context = zmq.context()
  local requester, err = context:socket{zmq.REQ, 
    connect = "tcp://localhost:" .. port
  }
  bridge.conn = requester
  bridge.conn:send("a")
  assert(bridge.conn:recv() == "connected")
end


function bridge.is_connected() 
  bridge.conn:send("a")
  if bridge.conn:poll(30) and bridge.conn:recv() == "connected" then
    return true
  end
  return false
end

function bridge.eval(code, args)
  -- Evaluate python code and returns serialized result
  -- Can serialize: lists, dicts, int, float, bool, string
  --      with arbitrary nesting
  if args then
    for k, v in pairs(args) do
      bridge.conn:send("x " .. k .. "=" .. serialize(v))
      bridge.conn:recv()
    end
  end
  bridge.conn:send("e "..code)

  return deserialize(bridge.conn:recv())
end

function bridge.exec(code)
  -- Evaluate python code and returns serialized result
  -- Can serialize: lists, dicts, int, float, bool, string
  --      with arbitrary nesting
  bridge.conn:send("x "..code)
  bridge.conn:recv()
end

return bridge
