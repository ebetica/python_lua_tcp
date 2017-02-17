local bridge = require('bridge.lua')
bridge.init()
bridge.exec([[import numpy as np
def asdf():
  return {
    'key': "hi",
    2: "bye",
    3: ["this", "is", "a", "list"]
  }
]])

print(bridge.eval("asdf()"))
