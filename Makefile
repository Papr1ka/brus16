PYTHON       := python3
SCRIPT       := tools/gen_fpga_firm.py
GW_SHELL_LATEST  := /mnt/c/Gowin/Gowin_V1.9.11.03_Education_x64/IDE/bin/gw_sh.exe
GW_SHELL_9K := /mnt/c/Gowin/Gowin_V1.9.8.11_Education/IDE/bin/gw_sh.exe

GW_SHELL := $(GW_SHELL_9K)

GAMES_DIR    := games
PLATFORMS_DIR := gowin
OUTPUT_DIR   := output
PLATFORMS := tn9k tn20k tp25k

GAME_FILES   := $(wildcard $(GAMES_DIR)/*.bin)
GAME_NAMES   := $(basename $(notdir $(GAME_FILES)))


TN9K_FILES := $(foreach g,$(GAME_NAMES),$(OUTPUT_DIR)/tn9k/$(g).fs)
TN20K_FILES := $(foreach g,$(GAME_NAMES),$(OUTPUT_DIR)/tn20k/$(g).fs)
TP25K_FILES := $(foreach g,$(GAME_NAMES),$(OUTPUT_DIR)/tp25k/$(g).fs)


tn9k: $(TN9K_FILES)
tn20k: $(TN20K_FILES)
tp25k: $(TP25K_FILES)

all: tn9k tn20k tp25k


define build_rule
$(OUTPUT_DIR)/$(1)/$(2).fs: $(GAMES_DIR)/$(2).bin $(PLATFORMS_DIR)/$(1).tcl
	mkdir -p $(OUTPUT_DIR)/$(1)
	$(PYTHON) $(SCRIPT) $$< firm
	cd $(PLATFORMS_DIR) && $(GW_SHELL) $(1).tcl
	cp $(PLATFORMS_DIR)/impl/pnr/$(1).fs $$@
endef

$(foreach p,$(PLATFORMS),$(foreach g,$(GAME_NAMES),$(eval $(call build_rule,$(p),$(g)))))

clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: all clean
