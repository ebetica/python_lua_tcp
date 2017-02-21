This code helps you hook up torch to Python. Just copy it into your codebase,
and require bridge to continue. See example for example. Maybe someday it'll be
a luarocks installable thing :)

```
pip3 install pyzmq six
luarocks install lzmq
luarocks install struct
```

vs: [fb.python](https://github.com/facebook/fblualib/blob/master/fblualib/python/README.md): Uses TCP for communication,
so it'll be slower to transfer large tensors but probably easier to install. Also
will work across the network if you really wanted to control a remote python
instance somewhere... but that's not implemented and will require some small tweaks.
