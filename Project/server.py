MAPS_API_KEY = 'AIzaSyAiM0Jo9_SlIThyCjKCZ5EP1S4UjxlH6Mo'
MAPS_API_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'

from errno import EMSGSIZE
import sys
import asyncio
import time
import aiohttp
import json
import logging

from sympy import false, true

SERVER_PORTS = {
    "Bernard": 12571,
    "Clark": 12572,
    "Jaquez": 12573,
    "Johnson": 12574,
    "Juzang": 12575,
}
SERVER_NEIGHBOR = {
    "Bernard": ["Jaquez", "Johnson", "Juzang"],
    "Clark": ["Juzang", "Jaquez"],
    "Jaquez": ["Bernard", "Clark"],
    "Johnson": ["Bernard", "Juzang"],
    "Juzang": ["Bernard", "Clark", "Johnson"],
}
LOCAL_HOST ='127.0.0.1'

class ServerMessage:
    def __init__(self, server_name, timestamp, message):
        self.server_name = server_name
        if timestamp > 0:
            self.timestamp = f"+{timestamp}"
        else:
            self.timestamp = f"-{timestamp}"
        self.client_message = message

    def get_coordinates(self):
        coordinate = self.client_message.split()[1]
        first_sign = coordinate.find('+')
        second_sign = coordinate.rfind('+')
        if first_sign != -1 and first_sign == second_sign:
            second_sign = coordinate.rfind('-')
            if first_sign > second_sign:
                temp = first_sign
                first_sign = second_sign
                second_sign = temp
        else:
            first_sign = coordinate.find('-')
            second_sign = coordinate.find('-')
        latitude = coordinate[first_sign:second_sign]
        longitude = coordinate[second_sign:]
        if latitude[0] == '+':
            latitude = latitude[1:]
        if longitude[0] == '+':
            longitude = longitude[1:]
        return "{},{}".format(latitude, longitude)

    async def get_near_place(self, coordinate, radius, max_result, key):
        async with aiohttp.ClientSession() as session:
            url = "{}location={}&radius={}&key={}".format(MAPS_API_URL, coordinate, radius, key)
            async with session.get(url) as resp:
                response = await resp.json()
        if len(response["results"]) <= int(max_result):
            return json.dumps(response, indent=3)
        else:
            response["results"] = response["results"][0:int(max_result)]
            return json.dumps(response, indent=3)

    def reply_IAMAT(self):
        return f"AT {self.server_name} {self.timestamp} {self.client_message}"

    async def reply_WHATSAT(self, radius, max_result):
        coordinate = self.get_coordinates()
        response = await self.get_near_place(coordinate, radius*1000, max_result, MAPS_API_KEY)
        return f"AT {self.server_name} {self.timestamp} {self.client_message} {response}"

class Server:
    history = dict()

    def __init__(self, server_name, ip_address, port):
        self.server_name = server_name
        self.ip_address = ip_address
        self.port = port 

    def valid_IAMAT(self, message):
        if message[0] == "IAMAT" and len(message) == 4:
            try:
                float(message[3])
                return true
            except:
                try:
                    int(message[3])
                    return true
                except:
                    return false
        else:
            return false

    def valid_WHATSAT(self, message):
        if message[0] == "WHATSAT" and len(message) == 4:
            try:
                float(message[2])
            except:
                return false
            try:
                int(message[3])
            except:
                return false
            return true
        else: 
            return false

    def valid_propagate(self, message):
        if message[0] == "AT" and len(message) == 6:
            if message[1].split('/')[-1] in SERVER_NEIGHBOR[self.server_name]:
                try:
                    float(message[5])
                except:
                    try:
                        int(message[5])
                    except:
                        return false
                try:
                    float(message[2][1:])
                except:
                    try:
                        int(message[2][1:])
                    except:
                        return false
                return true
            else:
                return false
        else:
            return false

    async def propagate(self, message):
        propagate_hist = message.split()[1].split('/')[1:]
        if self.server_name in propagate_hist:
            return 
        else:
            message = "{} {}/{} {}".format(message.split()[0], message.split()[1], self.server_name, ' '.join(message.split()[2:]))
            for neighbor in SERVER_NEIGHBOR[self.server_name]:
                try:
                    logging.info("Send propagate message to server {}".format(neighbor))
                    reader, writer = await asyncio.open_connection(self.ip_address, SERVER_PORTS[neighbor])
                    writer.write(message.encode())
                    await writer.drain()
                    writer.close()
                except:
                    logging.warning("Error with propagate message to server {}".format(neighbor))

    async def handle_connection(self, reader, writer):
        data = await reader.read()
        client_raw_message = data.decode()
        client_message = client_raw_message.split()
        try:
            # IAMAT message from client
            if self.valid_IAMAT(client_message):
                logging.info("Recieved IAMAT message: {}".format(' '.join(client_message)))
                server_reply = ServerMessage(self.server_name, time.time() - float(client_message[-1]), " ".join(client_message[1:]))
                self.history[client_message[1]] = client_message[1:]
                reply_message = server_reply.reply_IAMAT()
                await self.propagate(reply_message)
                logging.info("Reply with message: {}".format(reply_message))
                writer.write(reply_message.encode())
                await writer.drain()
                writer.close()
                await writer.wait_closed()
            # WHATSAT message from client
            elif self.valid_WHATSAT(client_message):
                if client_message[1] in self.history:
                    logging.info("Recieved WHATSAT message: {}".format(' '.join(client_message)))
                    server_reply = ServerMessage(self.server_name, time.time() - float(self.history[client_message[1]][-1]), " ".join(self.history[client_message[1]]))
                    radius = float(client_message[2])
                    max_result = int(client_message[3])
                    if radius <= 50 and max_result <= 20:
                        reply_message = await server_reply.reply_WHATSAT(radius, max_result)
                        logging.info("Reply with message: {}".format(reply_message))
                        writer.write(reply_message.encode())
                        await writer.drain()
                        writer.close()
                        await writer.wait_closed()
                    else:
                        raise Exception("Recieved invalid radius or information bound: {}".format(' '.join(client_message)))
                else:
                    raise Exception("Recieved unrecognized client: {}".format(client_message[1]))
            # propagate message from server
            elif self.valid_propagate(client_message):
                logging.info("Recieved propagate message: {}".format(' '.join(client_message)))
                self.history[client_message[3]] = client_message[3:]
                await self.propagate(' '.join(client_message))
            else:
                raise Exception("Recieved invalid command: {}".format(' '.join(client_message)))
        except Exception as error:
            logging.warning(repr(error))
            server_reply = f"? {' '.join(client_message)}"
            writer.write(server_reply.encode())
            await writer.drain()
            writer.close()
            await writer.wait_closed()

    async def run(self):
        server = await asyncio.start_server(self.handle_connection, self.ip_address, self.port)
        await server.serve_forever()
        server.close()

def main():
    if len(sys.argv) != 2:
        print("Error: too many or missing arguments. ")
        sys.exit(1)
    server_name = sys.argv[1]
    if server_name not in SERVER_PORTS:
        print("Error: invalid server name: ", server_name)
        sys.exit(1)
    logging.basicConfig(filename='server_{}.log'.format(server_name), level=logging.INFO)
    logging.info("Start log for server {}".format(server_name))
    server = Server(server_name, LOCAL_HOST, SERVER_PORTS[server_name])
    asyncio.run(server.run())

if __name__ == '__main__':
    main()