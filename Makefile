ASM=nasm
BUILD=build

all: $(BUILD)/dunbar.img

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/boot.bin: boot.asm | $(BUILD)
	$(ASM) -f bin boot.asm -o $(BUILD)/boot.bin

$(BUILD)/stage2.bin: stage2.asm | $(BUILD)
	$(ASM) -f bin stage2.asm -o $(BUILD)/stage2.bin

$(BUILD)/dunbar.img: $(BUILD)/boot.bin $(BUILD)/stage2.bin
	cat $(BUILD)/boot.bin $(BUILD)/stage2.bin > $(BUILD)/dunbar.img
	truncate -s 16384 $(BUILD)/dunbar.img

clean:
	rm -rf $(BUILD)

.PHONY: all clean
