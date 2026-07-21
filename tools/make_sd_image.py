import sys
import os
from pathlib import Path

"""
byte order = little
Output file:
    [game_1, game_2, ..., game_n]
Game:
    prev game sd_sector (4 bytes) (2 word)
    prev game sd_offset (2 bytes) (1 word)
    next game sd_sector (4 bytes) (2 words)
    prev game sd_offset (2 bytes) (1 word)
    code_size           (2 bytes) (1 word)
    data_size           (2 bytes) (1 word)
    code                (code_size * 2 bytes) (code_size words)
    data                (data_size * 2 bytes) (data_size words)

First game's prev values point to last game
Last game's next values point to first game    

=> Cyclic game switch.
"""

def calc_sec_offset(num_words, curr_sector, curr_offset):
    sm = num_words * 2 + curr_offset
    sectors = sm >> 9
    offset = sm - (sectors << 9)
    sector = curr_sector + sectors
    return sector, offset

def make_image(input_dir, output_file):
    print("Opening", output_file)

    game_counter = 0

    sd_sector = 0
    sd_offset = 0

    prev_game_sector = 0
    prev_game_offset = 0
    last_game_next_fpos = 0

    with open(output_file, 'wb') as o_file:
        for file in os.listdir(input_dir):
            path = Path(os.path.join(input_dir, file)).absolute()
            if path.is_file() and path.suffix == ".bin":
                with open(path, 'rb') as i_file:
                    header = i_file.read(4)
                    body = i_file.read(8192 * 4)
                    code_size = int.from_bytes(header[0:2], byteorder='little')
                    data_size = int.from_bytes(header[2:4], byteorder='little')

                    next_sector, next_offset = calc_sec_offset(code_size + data_size + 8, sd_sector, sd_offset)

                    # prev game sector + offset
                    o_file.write(prev_game_sector.to_bytes(length=4, byteorder='little', signed=False)) 
                    o_file.write(prev_game_offset.to_bytes(length=2, byteorder='little', signed=False))
                    
                    prev_game_sector = sd_sector
                    prev_game_offset = sd_offset
                    sd_sector = next_sector
                    sd_offset = next_offset

                    last_game_next_fpos = o_file.tell()
                    # next game sector + offset
                    o_file.write(sd_sector.to_bytes(length=4, byteorder='little', signed=False)) 
                    o_file.write(sd_offset.to_bytes(length=2, byteorder='little', signed=False))

                    # game data
                    o_file.write(header + body)
                
                game_counter += 1
                print("Operation completed:", file)
            else:
                print("Operation skipped:", file)

        # rewrite first game's prev game sector + offset
        o_file.seek(0)
        o_file.write(prev_game_sector.to_bytes(length=4, byteorder='little', signed=False)) 
        o_file.write(prev_game_offset.to_bytes(length=2, byteorder='little', signed=False))

        # rewrite last game's next game sector + offset
        o_file.seek(last_game_next_fpos)
        o_file.write(int(0).to_bytes(length=4, byteorder='little', signed=False)) 
        o_file.write(int(0).to_bytes(length=2, byteorder='little', signed=False))

    print("Completed,", game_counter, "games")

if __name__ == "__main__":
    make_image(sys.argv[1], sys.argv[2])
