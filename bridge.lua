require('os')
require('sys')
local struct = require('struct')
local stringx = require('pl.stringx')

local bridge = {}

-- TCP ports linger 2 minutes after they're closed, kind of annoying
local port = torch.random(40000, 50000)
local zmq = require('lzmq')

local function deserialize(arg)
  return assert(loadstring("return " .. arg))()
end

local function serialize(arg)
  if type(arg) == "string" then
    return '"' .. arg .. '"'
  elseif type(arg) == "number" then
    return arg
  elseif type(arg) == "boolean" then
    return (arg and "True" or "False")
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
  elseif type(arg) == 'userdata' and string.find(arg:type(), "Tensor") then
    local f = torch.MemoryFile()
    f:binary()
    f:writeLong(arg:dim())
    for i = 1, arg:dim() do
      f:writeLong(arg:size(i))
    end
    arg:contiguous():storage():write(f)
    data = f:storage():string()
    return 'TENSOR_BYTES' .. struct.pack('l', #data) .. data
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
      bridge.conn:send("x" .. k .. "=" .. serialize(v))
      bridge.conn:recv()
    end
  end
  bridge.conn:send("e"..code)

  return deserialize(bridge.conn:recv())
end

function bridge.exec(code)
  -- Evaluate python code and returns serialized result
  -- Can serialize: lists, dicts, int, float, bool, string
  --      with arbitrary nesting
  bridge.conn:send("x"..code)
  bridge.conn:recv()
end

return bridge
