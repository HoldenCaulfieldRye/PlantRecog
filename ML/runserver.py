import socket
import sys
import struct
import os, os.path
import cPickle as pickle
import run

# Constants
SOCKET = "/tmp/ipc_imageproc"
CFG = os.path.dirname(os.path.abspath(__file__))+'/run.cfg'


# Recogniser Host Task
class HostTask(object):
    def __init__(self):
        self.cfg = run.get_options(CFG, 'run')
        self.recogniser = run.get_recogniser(self.cfg,'all')

    def run_task(self,args):    
        try:
            if len(args) < 3:
                raise run.MyError(run.INVALID_COMMAND_ARGS)
            self.recogniser(args[2:])
            return run.NO_ERROR
        except run.MyError as e:
            return e.value


# Receives a full buffer of data over a socket, uses a structured
# set size to know when the transfer is complete
def recv_size(the_socket):
    #data length is packed into 4 bytes
    total_len=0;total_data=[];size=sys.maxint
    size_data=sock_data='';recv_size=4096
    while total_len<size:
        sock_data=the_socket.recv(recv_size)
        if not total_data:
            if len(sock_data)>4:
                size_data+=sock_data
                size=struct.unpack('>i', size_data[:4])[0]
                recv_size=size
                if recv_size>524288:recv_size=524288
                total_data.append(size_data[4:])
            else:
                size_data+=sock_data
        else:
            total_data.append(sock_data)
        total_len=sum([len(i) for i in total_data])
    return ''.join(total_data)


# Main server accepts a stream socket for AF_UNIX, using a 
# /tmp/file and processed tasks according to hosttask class
# replies with the result of the task
def host_server():
    # Setup the host task
    task = HostTask()
    # Remove the socket if its already there
    if os.path.exists( SOCKET ):
        os.remove( SOCKET )
    # Setup the unix domain socket
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.bind( SOCKET )
    s.listen(5)
    # Start the server
    while True:
       conn, addr = s.accept()
       data = recv_size(conn)
       parsed_data = pickle.loads(data)
       result = task.run_task(parsed_data)
       conn.send(str(result))
       conn.close()


if __name__ == '__main__':
    host_server()
