"""
Control core ROM, changes games from the SD card.
"""

from brus16 import *


"""
Addr    Descr
base+0  clk_div
base+1  cs
base+2  txdata
base+3  rxdata
"""
SPI_BASE = 65531

BUTTONS = 65528
GAME_CORE_RESET = 65529
CONTROL_CORE_SEL = 65530

GAME_CORE_CODE_BASE = 16384
GAME_CORE_DATA_BASE = 24576

"""
SYS_CLK = 25.2 MHz
SPI frequency = SYS_CLK / ((clk_div + 1) * 2)
SLOW for initialization
FAST for memory read
"""
SPI_CLK_DIV_SLOW = 62 # ~ 200  KHz
SPI_CLK_DIV_FAST = 0  # ~ 12.6 MHz

GAME_SWITCH_DELAY_MS = 0

def CMD(number, arg):
    """
    6 bytes
    Bit position    Width   Value   Description
    47              1       0       Start bit
    46              1       1       Transmission bit
    45:40           6       x       Command index
    39:8            32      x       Argument
    7:1             7       x       CRC7
    0               1       1       End bit
    
    In SPI mode only CMD0 and CMD8 require valid CRC
    """
    crc = 0xff          # dummy
    if (number == 0):   # CMD0 (not yet in SPI mode)
        crc = 0x95
    elif (number == 8): # CMD8 (always require crc)
        crc = 0x87

    return ','.join(str(val) for val in [
        (number & 0x3f) | 0x40, # cmd
        arg >> 24 & 0xff,       # byte 3
        arg >> 16 & 0xff,       # byte 2
        arg >> 8  & 0xff,       # byte 1
        arg       & 0xff,       # byte 0
        crc
    ])

STRING_BUFFER = []

def uart_print(string):
    global STRING_BUFFER
    
    byte_idx = len(STRING_BUFFER) // 2
    call = f"uart_print({byte_idx})"
    STRING_BUFFER += [ord(ch) for ch in (string + "\n")] + [0]

    if len(STRING_BUFFER) % 2 == 1:
        STRING_BUFFER += [0] # alignment to word size
    
    return call

NEXT = 1
PREV = 0

save_game('sd_loader.bin', f'''
def main():
    # wait 1 SEC
    wait_ms(1000)
    {uart_print("Control core start")}

    # SD card initialization
    error = sd_init()
    if (error):
        {uart_print("Init failed")}
        wait() # infinite wait until power-off + power-on

    # start  (buttons[12]) -> next
    # select (buttons[15]) -> prev

    while 1:
        buttons = peek({BUTTONS})

        if (buttons >> 12 & 1):
            read_game({NEXT})
            wait_ms({GAME_SWITCH_DELAY_MS})
        elif (buttons >> 15 & 1):
            read_game({PREV})
            wait_ms({GAME_SWITCH_DELAY_MS})

def wait_ms(ms):
    ms_passed = 0
    while ms_passed < ms:
        # Inner cycle = 9 instructions
        # 1 ms = 25 200 instructions (25.2 MHz / 1000)
        # 25_200 / 9 = 2800 iterations
        i = 0
        while i < 2800:
            i += 1
        ms_passed += 1

def uart_send(char):
    poke(-1, char)
    wait()

def uart_print(buff_idx):
    word = STRING_BUFFER[buff_idx]
    ch = word >> 8 & 0xff
    high = 1
    while (ch != 0):
        uart_send(ch)
        if high:
            ch = word & 0xff
            high = 0
        else:
            buff_idx += 1
            word = STRING_BUFFER[buff_idx]
            ch = word >> 8 & 0xff
            high = 1

def digit_to_hex_char(d):
    return d + 48 + (d > 9) * 7

def debug_val(x):
    d = (x >> 12) & 15
    uart_send(digit_to_hex_char(d))
    d = (x >> 8) & 15
    uart_send(digit_to_hex_char(d))
    d = (x >> 4) & 15
    uart_send(digit_to_hex_char(d))
    d = x & 15
    uart_send(digit_to_hex_char(d))
    uart_send({ord('\n')})

def spi_set_clkdiv(div):
    {SPI_BASE}[0] = div

def spi_set_cs(cs):
    {SPI_BASE}[1] = cs

def spi_rw(wdata):
    {SPI_BASE}[2] = wdata
    wait()
    return {SPI_BASE}[3]

def spi_wait_high(cycles):
    spi_set_cs(1)
    i = 0
    while i < cycles:
        spi_rw(0xff)
        i += 8
    spi_set_cs(0)

def spi_wait_for_val(val):
    resp = spi_rw(0xff)
    while (resp != val):
        resp = spi_rw(0xff)

def sd_command(cmd, arg0, arg1, arg2, arg3, crc):
    if (cmd != 0x4c): # CMD12, cs must be 0
        spi_wait_high(8)

    spi_rw(cmd)
    spi_rw(arg0)
    spi_rw(arg1)
    spi_rw(arg2)
    spi_rw(arg3)
    spi_rw(crc)

    retry = 0
    resp = spi_rw(0xff)

    # in R1 response, bit 7 always must be 0
    while (retry < 255) & (resp >> 7 & 1):
        resp = spi_rw(0xff)
        retry += 1
    
    return resp

def sd_init():
    {uart_print("SD init started")}
    spi_set_clkdiv({SPI_CLK_DIV_SLOW})

    spi_wait_high(80)

    # CMD0
    resp = sd_command({CMD(0, 0)})

    if (resp != 1):
        {uart_print("Fail on CMD0")}
        debug_val(resp)
        return 1
    # CMD8
    resp = sd_command({CMD(8, 0x000001aa)})

    if (resp != 1):
        {uart_print("Fail, not SDHC card")}
        return 1

    resp = spi_rw(0xff) # r7, byte 1
    resp = spi_rw(0xff) # r7, byte 2
    resp = spi_rw(0xff) # r7, byte 3

    if (resp != 1):
        {uart_print("Fail, 2.7-3.6V not supported")}
        return 1

    resp = spi_rw(0xff) # r7, byte 4

    if (resp != 0xaa):
        {uart_print("Pattern fail")}
        return 1

    # Initialization start, CMD55 + CMD41
    retry = 0
    resp = 1 # resp must be 0 (not IDLE)
    while (retry < 500) & (resp):
        resp = sd_command({CMD(55, 0)})
        resp = sd_command({CMD(41, 0x40000000)})
        retry += 1
        wait_ms(10)
    
    if (resp != 0):
        {uart_print("Init timeout")}
        debug_val(resp)
        return 1

    # CMD16, set sector size
    resp = sd_command({CMD(16, 512)})

    if (resp != 0):
        {uart_print("Fail on setting sector size")}
        return 1
    
    {uart_print("Init success")}
    spi_set_clkdiv({SPI_CLK_DIV_FAST})
    spi_set_cs(1)
    return 0

def sd_initiate_read(sector_lo, sector_hi, offset):
    # return state, when next spi_rw(0xff)
    # will return data at specified sector and offset

    # CMD18, READ_MULTIPLE_BLOCK
    resp = sd_command(
        0x52,
        sector_hi >> 8 & 0xff,
        sector_hi      & 0xff,
        sector_lo >> 8 & 0xff,
        sector_lo      & 0xff,
        0xff
    )

    if (resp != 0):
        {uart_print("CMD18 fail")}
        debug_val(sector_lo)
        debug_val(sector_hi)
        debug_val(offset)

    spi_wait_for_val(0xfe)
    
    SD_CURR_OFFSET = 0
    while (SD_CURR_OFFSET != offset):
        spi_rw(0xff)
        SD_CURR_OFFSET += 1

    {uart_print("Read initiated")}

def read_next_word():
    if SD_CURR_OFFSET == 512:
        spi_rw(0xff) # skip crc
        spi_rw(0xff) # skip crc
        # new sector
        spi_wait_for_val(0xfe)
        SD_CURR_OFFSET = 0
    
    low = spi_rw(0xff)
    high = spi_rw(0xff)
    SD_CURR_OFFSET += 2
    return high << 8 | low

def sd_stop_read():
    resp = sd_command(
        0x4c, # CMD12
        0, 0, 0, 0,
        0xff
    )
    # wait while sd is busy
    while (resp != 0xff):
        resp = spi_rw(0xff)

    {uart_print("Read stopped")}
    
def read_game(flag):
    sd_initiate_read(GAME_SECTOR_LO, GAME_SECTOR_HI, GAME_OFFSET)

    # prev game addr
    prev_sd_sector_lo = read_next_word()
    prev_sd_sector_hi = read_next_word()
    prev_sd_offset    = read_next_word()

    # next game addr
    next_sd_sector_lo = read_next_word()
    next_sd_sector_hi = read_next_word()
    next_sd_offset    = read_next_word()

    sd_stop_read()

    if (flag == {PREV}):
        sd_initiate_read(prev_sd_sector_lo, prev_sd_sector_hi, prev_sd_offset)
        GAME_SECTOR_LO = prev_sd_sector_lo
        GAME_SECTOR_HI = prev_sd_sector_hi
        GAME_OFFSET    = prev_sd_offset
    else:
        sd_initiate_read(next_sd_sector_lo, next_sd_sector_hi, next_sd_offset)
        GAME_SECTOR_LO = next_sd_sector_lo
        GAME_SECTOR_HI = next_sd_sector_hi
        GAME_OFFSET    = next_sd_offset
        
    {uart_print("Reading game at")}
    debug_val(GAME_SECTOR_LO)
    debug_val(GAME_SECTOR_HI)
    debug_val(GAME_OFFSET)

    # skip sectors and offsets
    i = 0
    while i < 6:
        read_next_word()
        i += 1

    code_size = read_next_word()
    data_size = read_next_word()
    {uart_print("code size:")}
    debug_val(code_size)
    {uart_print("data size:")}
    debug_val(data_size)

    if (code_size == 0):
        sd_stop_read()
        return

    poke({GAME_CORE_RESET}, 1)
    poke({CONTROL_CORE_SEL}, 1)

    # override game core code memory
    base = {GAME_CORE_CODE_BASE}
    i = 0
    while i < code_size:
        word = read_next_word()
        poke(base + i, word)
        i += 1

    # clear game core data memory
    base = {GAME_CORE_DATA_BASE}
    i = 0
    while i < 8192:
        poke(base + i, 0)
        i += 1

    # override game core data memory
    base = {GAME_CORE_DATA_BASE}
    i = 0
    while i < data_size:
        word = read_next_word()
        poke(base + i, word)
        i += 1
    
    poke({CONTROL_CORE_SEL}, 0)
    poke({GAME_CORE_RESET}, 0)
    
    sd_stop_read()
    spi_set_cs(1)

SD_CURR_OFFSET = 0
# addr = GAME_SECTOR * 512 + GAME_OFFSET
GAME_SECTOR_LO = 0
GAME_SECTOR_HI = 0
GAME_OFFSET = 0

STRING_BUFFER = {[int.from_bytes(STRING_BUFFER[i:i+2], 'big') for i in range(0, len(STRING_BUFFER), 2)]}
''')
