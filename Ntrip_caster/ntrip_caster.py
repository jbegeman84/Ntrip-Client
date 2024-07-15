import socket
import threading
import time
import random

NTRIP_SOURCE_TABLE = """SOURCETABLE 200 OK
Server: GNSS Spider 7.9.0.386/1.0
Date: Fri, 12 Jul 2024 21:07:47 GMT
Content-Type: text/plain
Content-Length: 1206

STR;BOCA;BOCA;RTCM 3;;2;GPS+GLO;;;26.38;-80.11;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FLFR;FLFR;RTCM 3;;2;GPS+GLO;;;27.59;-80.40;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FLHO;FLHO;RTCM 3;;2;GPS+GLO;;;30.61;-83.15;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FLIT;FLIT;RTCM 3;;2;GPS+GLO;;;27.03;-80.48;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FTLD;FTLD;RTCM 3;;2;GPS+GLO;;;26.12;-80.34;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;LAUD;LAUD;RTCM 3;;2;GPS+GLO;;;26.20;-80.17;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;PBCH;PBCH;RTCM 3;;2;GPS+GLO;;;26.85;-80.22;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;STEW;STEW;RTCM 3;;2;GPS+GLO;;;27.19;-80.22;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;SBST;SBST;RTCM 3;;2;GPS+GLO;;;27.81;-80.49;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FLND;FLND;RTCM 3;;2;GPS+GLO;;;25.97;-80.17;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;OKCB;OKCB;RTCM 3;;2;GPS+GLO;;;27.27;-80.86;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FLFD;FLFD;RTCM 3;;2;GPS+GLO;;;27.60;-80.82;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FLAA;FLAA;RTCM 3;;2;GPS+GLO;;;26.17;-80.83;0;0;Leica GNSS Spider;none;B;Y;9600;
STR;FLHC;FLHC;RTCM 3;;2;GPS+GLO;;;26.73;-80.90;0;0;Leica GNSS Spider;none;B;Y;9600;
ENDSOURCETABLE.
"""

def generate_rtcm_data():
    # Generate random RTCM data
    return bytes([random.randint(0, 255) for _ in range(1024)])

def handle_client(client_socket, client_address):
    print(f"New connection from {client_address}")
    try:
        while True:
            request = client_socket.recv(1024).decode('utf-8').strip()
            if not request:
                break
            
            print(f"Received request: {request}")
            if "GET /" in request:
                if " " in request:
                    mount_point = request.split(" ")[1].strip("/")
                    if not mount_point:
                        response = NTRIP_SOURCE_TABLE
                        time.sleep(3)
                        client_socket.sendall(response.encode('utf-8'))
                        print("Sent source table")
                    else:
                        while True:
                            rtcm_data = generate_rtcm_data()
                            client_socket.sendall(rtcm_data)
                            time.sleep(1)  # Simulate RTCM data stream
                            print(f"Sent RTCM data to {client_address}")
            else:
                client_socket.sendall(b"HTTP/1.1 400 Bad Request\r\n\r\n")
                break
    finally:
        print(f"Connection closed from {client_address}")
        client_socket.close()

def start_server(host='127.0.0.1', port=2101):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(5)
    print(f"Server listening on {host}:{port}")

    while True:
        client_socket, client_address = server_socket.accept()
        client_thread = threading.Thread(target=handle_client, args=(client_socket, client_address))
        client_thread.start()

if __name__ == "__main__":
    start_server()
