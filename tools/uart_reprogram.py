import serial
import sys

SERIAL_PORT = 'COM6'
BAUDRATE = 115200

PROG_MEM_BASE = 0
DATA_MEM_BASE = 8192


def load(filename):
    with open(filename, 'rb') as f:
        buf = f.read()
        vals = [int.from_bytes(buf[i:i + 2], byteorder='little') for i in range(0, len(buf), 2)]
        code_size, data_size, *mem = vals
        return mem[:code_size], mem[code_size:code_size+data_size]


def build_firmware_packets(prog_mem, data_mem) -> bytes:
    packets = bytearray()

    def nibbles(value: int):
        return [
            value & 0xF,
            (value >> 4) & 0xF,
            (value >> 8) & 0xF,
            (value >> 12) & 0xF,
        ]

    # reset=1, we=0
    packets.append(0xF2)

    def add_write(addr: int, data: int):
        nib_addr = nibbles(addr)
        nib_data = nibbles(data)

        # Set addr word
        packets.append(0xA0 | nib_addr[0])
        packets.append(0xB0 | nib_addr[1])
        packets.append(0xC0 | nib_addr[2])
        packets.append(0xD0 | nib_addr[3])

        # Set data word
        packets.append(0x00 | nib_data[0])
        packets.append(0x10 | nib_data[1])
        packets.append(0x20 | nib_data[2])
        packets.append(0x30 | nib_data[3])

        # we=1, reset=1
        packets.append(0xF3)
        # we=0, reset=1
        packets.append(0xF2)

    for addr, word in enumerate(prog_mem, start=PROG_MEM_BASE):
        add_write(addr, word)

    for addr, word in enumerate(data_mem, start=DATA_MEM_BASE):
        add_write(addr, word)

    # reset=0, we=0
    packets.append(0xF0)

    return bytes(packets)

def main(filename):
    prog_mem, data_mem = load(filename)
    firmware_bytes = build_firmware_packets(prog_mem, data_mem)

    try:
        with serial.Serial(SERIAL_PORT, BAUDRATE, timeout=1) as ser:
            for byte in firmware_bytes:
                ser.write(bytes([byte]))
            print("Firmware has been sent")

            with open("uart.log", 'w') as f:
                while True:
                    recv = ser.read()

                    if len(recv) != 0:
                        ch = chr(recv[0])
                        print(ch, end='')
                        f.write(ch)

    except Exception as e:
        print(f"Serial error: {e}")

if __name__ == "__main__":
    main(sys.argv[1])
