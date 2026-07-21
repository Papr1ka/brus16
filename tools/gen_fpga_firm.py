import os
import sys
import pathlib


def load(filename):
    with open(filename, 'rb') as f:
        buf = f.read()
        vals = [int.from_bytes(buf[i:i + 2], byteorder='little') for i in range(0, len(buf), 2)]
        code_size, data_size, *mem = vals
        return mem[:code_size], mem[code_size:]

def hex_generator(memory):
    return (f"{hex(val & 0xffff)[2:]:0>4}" for val in memory)

def save_memory(program_path, folder_path, control_core):
    code, data = load(program_path)
    os.makedirs(folder_path, exist_ok=True)
    norm = lambda path: os.path.join(folder_path, path)
    code_fname = norm("code_rom.hex" if control_core else "code.hex")
    data_fname = norm("data_rom.hex" if control_core else "data.hex")

    with open(code_fname, "w") as file:
        file.write("\n".join(hex_generator(code)) + "\n")

    with open(data_fname, "w") as file:
        file.write("\n".join(hex_generator(data)) + "\n")
    
    print(f"Gen completed:\nIn: {program_path}\nOut: {code_fname}\nOut: {data_fname}")

save_memory(
    os.path.abspath(sys.argv[1]),
    os.path.abspath(sys.argv[2]),
    len(sys.argv) > 3 and sys.argv[3] == '--control'
)
