import numpy as np
import collections
import numbers
import zmq
import sys
import six
import traceback
import struct


def parseTensors(bytes):
    key = b"TENSOR_BYTES"
    out = []
    tensorlst = []
    while True:
        ind = bytes.find(key)
        if ind == -1: break
        out.append(bytes[:ind])
        length = struct.unpack('q', bytes[ind+len(key) : ind+len(key)+8])[0]
        tensorlst.append(byte2np(bytes[ind+len(key)+8:ind+len(key)+8+length]))
        bytes = bytes[ind+len(key)+8+length:]
    out.append(bytes)
    return "".join(s.decode() + ("TENSORLIST[{}]".format(i) if i+1 != len(out) else "")
                   for i, s in enumerate(out)), tensorlst

def byte2np(bytes):
    dim = struct.unpack('q', bytes[:8])[0]
    shape = [0 for i in range(dim)]
    for d in range(dim):
        shape[d] = struct.unpack('q', bytes[8+d*8:8+d*8+8])[0]
    arr = np.frombuffer(bytes[8+d*8+16:-1], dtype='double')
    return arr

def serialize(x):
    key = b"TENSOR_BYTES"
    if x is None:
        return 'nil'
    elif isinstance(x, six.string_types):
        return '"{0}"'.format(x)
    elif type(x) == bool:
        return 'true' if x else 'false'
    elif isinstance(x, numbers.Number):
        return str(x)
    elif isinstance(x, np.ndarray):
        return 'nil'
    elif isinstance(x, collections.Mapping):
        return '{' + ",".join(['[{0}]={1}'.format(serialize(k), serialize(v))
                               for k, v in x.items()]) + '}'
    elif isinstance(x, collections.Iterable):
        return '{' + ",".join(map(serialize, x)) + '}'
    else:
        print("Cannot serialize variable of type {0}".format(type(x)))
        raise Exception("Cannot serialize variable of type {0}".format(type(x)))


def listener(port):
    context = zmq.Context()
    socket = context.socket(zmq.REP)
    print("binding to tcp://*:{}".format(port))
    socket.bind("tcp://*:{}".format(port))
    print("Server is listening...")
    while True:
        data = socket.recv()
        if data == "":
            break
        elif data[0] == ord('a'):
            res = "connected"
        else:
            try:
                f = data[0]
                arg = data[1:]
                arg, TENSORLIST = parseTensors(arg)
                if f == ord('e'):
                    res = serialize(eval(arg))
                elif f == ord('x'):
                    exec(arg)
                    res = 'nil'
            except:
                res = 'nil'
                traceback.print_exc()
        socket.send(res.encode())

if __name__ == "__main__":
    assert len(sys.argv) == 2
    listener(sys.argv[1])
