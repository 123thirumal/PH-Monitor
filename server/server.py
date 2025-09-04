import firebase_admin  # type: ignore
from firebase_admin import credentials, db  # type: ignore
import serial.tools.list_ports  # type: ignore
import serial  # type: ignore
import time
import re
from datetime import datetime
import threading
import socket

# Create global serial instance
serialInst = serial.Serial()
# ... your serial port setup here ...

# Function to handle socket connections
def socket_server():
    HOST = "0.0.0.0"
    PORT = 12345

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print(f"📡 Socket server listening on {HOST}:{PORT}")

        while True:
            conn, addr = s.accept()
            with conn:
                print(f"🔌 Connected by {addr}")
                data = conn.recv(1024).decode().strip()
                if data in ["Increase", "Reduce"]:
                    print(f"➡ Sending to Arduino: {data}")
                    serialInst.write(f"{data}\n".encode())
                else:
                    print(f"Unknown command: {data}")

# Start socket server in a separate thread
threading.Thread(target=socket_server, daemon=True).start()

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r"database.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://smart-ph-detector-default-rtdb.firebaseio.com/'
    })

# Detect and open serial port
ports = serial.tools.list_ports.comports()
serialInst = serial.Serial()
for i, onePort in enumerate(ports):
    print(f"{i}: {onePort}")

val = input("Select Port (only number, e.g., 3 for COM3): ")
portVar = "COM" + str(val)

serialInst.baudrate = 9600
serialInst.port = portVar
serialInst.open()

# Reference to base Firebase path
ref = db.reference("/ph_data")

# Function to generate entry names like "entry1", "entry2", ...
def get_next_entry_name():
    data = ref.get()
    if data:
        next_index = len(data) + 1
    else:
        next_index = 1
    return f"entry{next_index}"


# Function to send data to Firebase
def send_ph_to_firebase(ph):
    timestamp = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    entry_name = get_next_entry_name()
    
    data = {
        "timestamp": timestamp,
        "pH": ph,
    }
    
    ref.child(entry_name).set(data)
    print(f"✅ Sent to Firebase: {entry_name} → {data}")

# Main loop to read and upload pH data
while True:
    try:
        if serialInst.in_waiting:
            raw_data = serialInst.readline().decode('utf-8').strip()
            matches = re.findall(r"-?\d+\.\d+", raw_data)

            if matches:
                ph = float(matches[0])
                print("📏 pH:", ph)
                send_ph_to_firebase(ph)
            else:
                print(f"⚠ Ignored invalid data: {raw_data}")

        time.sleep(1)

    except serial.SerialException as e:
        print(f"❌ Serial connection error: {e}")
        break