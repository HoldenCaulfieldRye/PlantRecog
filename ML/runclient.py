import socket
import sys
import struct
import os, os.path
import cPickle as pickle

SOCKET = "/tmp/ipc_imageproc"


def process_images(command_list):
    if os.path.exists( SOCKET ):
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect( SOCKET )
        # Setup the data to have the size prefix
        data = pickle.dumps(command_list)
        s.sendall(struct.pack('>i', len(data))+data) 
        # Receive response
        data = s.recv(1024)               
        print data
        s.close()                          
    else:
        print 'Socket not open, please ensure server is running'

if __name__ == '__main__':
    process_images(sys.argv)
