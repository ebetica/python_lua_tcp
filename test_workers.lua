local bridge = require('bridge')
bridge.init()
local x = {
  ['tbl'] = 1,
  [3] = {3, 4, 5},
  [10] = "test string"
}
bridge.exec([[import numpy as np
def asdf(x):
  print(x)
  return {
    'key': "hi",
    2: "bye",
    3: ["this", "is", "a", "list"]
  }
]])

print(bridge.eval("asdf(tbl)", {tbl = x}))

