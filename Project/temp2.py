import asyncio
async def main():
    reader, writer = await asyncio.open_connection('127.0.0.1', 12572)
    writer.write("IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 1621464827.959498503".encode())
    data = await reader.readline()
    print('Received: {}'.format(data.decode()))
    writer.close()
if __name__ == '__main__':
    asyncio.run(main())