import collections
import numbers
import zmq
import sys
import six
import traceback


def serialize(x):
    if x is None:
        return 'nil'
    elif isinstance(x, six.string_types):
        return '"{0}"'.format(x)
    elif type(x) == bool:
        return 'true' if x else 'false'
    elif isinstance(x, numbers.Number):
        return str(x)
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
        data = socket.recv().decode()
        if data == "":
            break
        elif data == 'a':
            res = "connected"
        else:
            try:
                f, arg = data.split(' ', 1)
                if f == 'e':
                    res = 'l' + serialize(eval(arg))
                elif f == 'x':
                    exec(arg)
                    res = 'lnil'
            except:
                res = 'lnil'
                traceback.print_exc()
        socket.send(res.encode('ascii'))

if __name__ == "__main__":
    assert len(sys.argv) == 2
    listener(sys.argv[1])
