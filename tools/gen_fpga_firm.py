import os
import sys
import pathlib


HEADER_MI = """#File_format=Hex
#Address_depth=8192
#Data_width=16
"""

HEADER_COE = """memory_initialization_radix=16;
memory_initialization_vector="""

def load(filename):
    with open(filename, 'rb') as f:
        buf = f.read()
        vals = [int.from_bytes(buf[i:i + 2], byteorder='little') for i in range(0, len(buf), 2)]
        code_size, data_size, *mem = vals
        return mem[:code_size], mem[code_size:]

def hex_generator(memory):
    return (f"{hex(val & 0xffff)[2:]:0>4}" for val in memory)

def save_memory(program_path, folder_path):
    code, data = load(program_path)
    os.makedirs(folder_path, exist_ok=True)
    program_name = pathlib.Path(os.path.basename(program_path)).stem
    print(program_name)
    norm = lambda path: os.path.join(folder_path, path)

    with open(norm(f"{program_name}_code.mi"), "w") as file:
        file.write(HEADER_MI + "\n".join(hex_generator(code)) + "\n")
    
    with open(norm(f"{program_name}_data.mi"), "w") as file:
        file.write(HEADER_MI + "\n".join(hex_generator(data)) + "\n")

    with open(norm(f"{program_name}_code.coe"), "w") as file:
        file.write(HEADER_COE + ",\n".join(hex_generator(code)) + ";\n")

    with open(norm(f"{program_name}_data.coe"), "w") as file:
        file.write(HEADER_COE + ",\n".join(hex_generator(data)) + ";\n")
    
    with open(norm(f"{program_name}_code.hex"), "w") as file:
        file.write("\n".join(hex_generator(code)) + "\n")

    with open(norm(f"{program_name}_data.hex"), "w") as file:
        file.write("\n".join(hex_generator(data)) + "\n")

save_memory(
    os.path.abspath(sys.argv[1]),
    os.path.abspath(sys.argv[2])
)
