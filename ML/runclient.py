import socket
import sys
import struct
import os, os.path
import cPickle as pickle
import run

SOCKET = "/tmp/ipc_imageproc"

# Checks whether a proper int returned
def isInt_try(v):
    try:     i = int(v)
    except:  return False
    return True


def process_images(command_list):
    if os.path.exists( SOCKET ):
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect( SOCKET )
        # Setup the data to have the size prefix
        data = pickle.dumps(command_list)
        s.sendall(struct.pack('>i', len(data))+data) 
        # Receive response
        data = s.recv(1024)               
        s.close()                          
        if isInt_try(data):
            sys.exit(int(data))
        else:
            sys.exit(run.SERVER_ERROR)
    else:
        print 'Socket not open, please ensure server is running'
        sys.exit(run.SERVER_ERROR)

if __name__ == '__main__':
    process_images(sys.argv)
