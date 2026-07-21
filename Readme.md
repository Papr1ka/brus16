# Brus-16 fpga implementation

The repository contains the implementation of the [Brus-16 educational game console](https://github.com/true-grue/Brus-16).

![Connection demo](https://github.com/Papr1ka/Brus-16_media/blob/main/fpga_1920_1280_preview.jpg?raw=true)

Gameplay videos:

https://github.com/user-attachments/assets/1e40cc49-c51c-4474-aa89-dd89034edd95

https://github.com/user-attachments/assets/afb5e501-f497-4eca-b2d6-a9d5f201da5c

### Contents

- [Architecture](#architecture).
- [Board-specific](#board-specific).
- [Write games to SD card](#write-games-to-sd-card).
- [Build firmware for a new game](#build-firmware-for-a-new-game).
- [PMOD joystick kit connection](#pmod-joystick-kit-connection).
- [Simulation](#simulation).
- [Tests](#tests).


### Architecture

More general information can be found [here](https://github.com/true-grue/Brus-16?tab=readme-ov-file#architecture).

This [article in Russian](https://habr.com/ru/companies/yadro/articles/1040288/) provides a detailed history of the console's development and describes its key architectural features.

#### Key notes

CPU:
- The **Single-cycle** processor calculates the next frame and enters the wait state.
- After the resume signal, it **continues** its work from the previous location.
- [ISA is available here](https://true-grue.github.io/Brus-16/isa.html).

GPU:

- **No framebuffer**.
- Uses a frame representation in the form of a 640x480x64 matrix, where each of the 64 bits indicates the intersection of a rectangle with a specific pixel, rect_left <= x < rect_right && rect_top <= y < rect_bottom for each rect for each pixel.
- Due to the properties of rectangles, the 640x480 matrix is represented as two arrays of 640 and 480 and is calculated during copying.
- During operation, the GPU obtains a 64-bit vector of rectangle collisions with the current pixel and passes the rectangle indices through a tree of multiplexers.
- The color is sent to the output based on the index from a mux tree.

All components of Brus-16 have been implemented.

### Board-specific

Currently supported FPGA boards:

- [Tang Nano 9K](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html).
- [Tang Nano 20K](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html).
- [Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html).

Board specific files are:
- src/brus16_top.sv (ELVDS instantination for HDMI)
- src/pll_generic.sv

If desired, the project can be adapted relatively quickly for another board.

system_clk clock frequency = **25.2 MHz**.

### Write games to SD card

1. Make sure your SD card is SDHC or SDXC.
2. Make sure there is no important data on the SD card. (The data will be overwritten in raw format, starting from sector 0).
3. Generate an SD card image with games.

`python tools\make_sd_image.py {folder with games in .bin} {sd_image.bin}`

4. Get the DeviceID of the SD card.

`wmic diskdrive list brief` on Windows.

5. Copy {sd_image.bin} to the SD card.

`dd if={sd_image.bin} of={DeviceID} bs={SIZE}`

> dd for windows http://www.chrysocome.net/dd

SIZE - A number, greater than size of {sd_image.bin} according to the dd format:

Examples:
- For most files: **16M** (~511 games)
- For fantastic files: **1G**  (32 752 games)
- For fairy tale files: **32G**  (over a million games!)

6. Insert the SD card in the board.

To nagivate, use `select` and `start` buttons on any connected DualShock2 Joystick.

If you **don't have an SD card**, just ignore this option.
There is an old variant, described in the next section.

### Build firmware for a new game

1. Generate program memory and data memory initialization files (code.hex, data.hex) from the game's binary file. (a tool will replace files in the **firm/** folder)

`python tools/gen_fpga_firm.py {game}.bin firm`

2. Open the corresponding project with GOWIN EDA (gowin/{board}.gprj).

> For the tang nano 9k, I recommend to use one of the older versions of EDA (I use 1.9.8.11_Education), since newer versions do not infer True Dual Port BSRAM correctly and return the error "ERROR (PA2122): Not supported ... (DPB) WRITE_MODE0 = 2'b10, please change write mode WRITE_MODE0 = 2'b00 or 2'b01." Alternatively, you can create a DPB using the IP Generator in newer versions.

3. Change lines 5-10 in the src/constants.svh file.
4. Run all and program your device.

Important project settings:
| Setting | Value |
| :-:     | :-:   |
| Synthesize/General, Top Module/Entity | brus16_top |
| Synthesize/General, Include Path | ..\src |
| Synthesize/General, Verilog Language | System Verilog 2017 |
| Dual-Purpose Pin, Use SSPI as regular IO | True |
| Dual-Purpose Pin, Use CPU as regular IO (tp25k) | True |

### PMOD joystick kit connection

[PMOD Joystick](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2).

#### Tang Nano 9K

| Joystick 1          || 
| :-:      | :-:       |
| PMOD pin | Board pin |
| 3.3V     | 3.3V      |
| GND      | GND       |
| SCLK     | 32        |
| MISO     | 31        |
| MOSI     | 49        |
| ~CS1     | 48        |

#### Tang Nano 20k

| Joystick 1          || Joystick 2          ||
| :-:      | :-:       | :-:      | :-:       |
| PMOD pin | Board pin | PMOD pin | Board pin |
| 3.3V     | 3.3V      | 3.3V     | 3.3V      |
| GND      | GND       | GND      | GND       |
| SCLK     | 52        | SCLK     | 17        |
| MISO     | 71        | MISO     | 19        |
| MOSI     | 53        | MOSI     | 20        |
| ~CS1     | 72        | ~CS2     | 18        |

#### Tang Primer 25k

PMOD joystick: G11 PMOD group.

[PMOD DVI](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DVI): F5 PMOD group.

PMOD TF-Card: A11 PMOD group.

### Simulation

Simulation via Verilator.

Dependencies:
- C++ compiler
- verilator
- freeglut + freeglut-devel
- make

Uncomment SIM, DISABLE_CONTROLLERS and comment GOWIN, TN9K/TN20K/TP25K in constants.svh.

Run:
```
verilator -f verilator_vga.f
make -j -C obj_dir -f Vbrus16_top.mk Vbrus16_top
./obj_dir/Vbrus16_top 
```


### Tests

Dependencies:
- cocotb
- icarus verilog >= 13.0
- make

Run:

`cd tests && make all`
