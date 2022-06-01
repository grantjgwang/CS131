import sys
import asyncio
import json
import logging

SERVER_PORTS = {
    "Bernard": 12571,
    "Clark":   12572,
    "Jaquez":  12573,
    "Johnson": 12574,
    "Juzang":  12575,
}
LOCAL_HOST ='127.0.0.1'

class Client:
    def __init__(self, ip_address, client_port):
        self.ip_address = ip_address
        self.port = client_port 
        self.max_length = 1000000
    
    async def send(self, message):
        print("Send message: {}".format(message))
        reader, writer = await asyncio.open_connection(self.ip_address, self.port)
        writer.write(message.encode())
        writer.write_eof()
        data = await reader.read(self.max_length)
        print("Received message: {}".format(data.decode()))
        writer.close()

def main():
    if len(sys.argv) != 2:
        print("Invalid arguments. ")
        sys.exit()
    client_name = sys.argv[1]
    if client_name not in SERVER_PORTS:
        print("Error: invalid client name: ", client_name)
        sys.exit()
    print("=== Start log for client {} ===".format(client_name))
    client = Client(LOCAL_HOST, SERVER_PORTS[client_name])
    message = input()
    while message != "q":
        asyncio.run(client.send(message))
        message = input()

if __name__ == '__main__':
    main()