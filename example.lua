local bridge = require('bridge')
bridge.init()
local x = {
  ['tbl'] = 1,
  [30] = true,
  [3] = {3, 4, 5},
  [10] = "test string",
  ['c'] = torch.randn(5, 5)
}
print(x['c'])
bridge.exec([=[import numpy as np
def asdf(x):
  print(x)
  return {
    'key': "hi",
    2: "bye",
    3: ["this", "is", "a", "list"],
    4: np.array([[0, 1], [2, 3]])
  }
]=])

print(bridge.eval("asdf(tbl)", {tbl = x}))

