CC   = gcc
RASM = rasm
ECHO = echo

CCFLAGS = -W -Wall
RASMFLAGS =

ALL = bin2m12 cge2bin gfx \
      up-xmas2018.bin up-xmas2018.m12

all: $(ALL)

bin2m12: tools/bin2m12.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^

cge2bin: tools/cge2bin.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

gfx:
	@$(ECHO) "GEN	GFX"
	@./cge2bin -x 0 -y 0 -w 8 -h 25 ./data/snowman.txt ./data/wish.bin
	@./cge2bin -x 8 -y 0 -w 8 -h 25 ./data/snowman.txt ./data/merry.bin
	@./cge2bin -x 16 -y 0 -w 8 -h 25 ./data/snowman.txt ./data/xmas.bin
	@./cge2bin -x 24 -y 0 -w 8 -h 25 ./data/snowman.txt ./data/2018.bin
	@./cge2bin -x 32 -y 0 -w 8 -h 25 ./data/snowman.txt ./data/snowman.bin
	@./cge2bin -x 0 -y 0 -w 8 -h 25 ./data/rodolph.txt ./data/flush.bin
	@./cge2bin -x 8 -y 0 -w 8 -h 25 ./data/rodolph.txt ./data/up.bin
	@./cge2bin -x 16 -y 0 -w 8 -h 25 ./data/rodolph.txt ./data/gift.bin
	@./cge2bin -x 24 -y 0 -w 8 -h 25 ./data/rodolph.txt ./data/santa.bin
	@./cge2bin -x 32 -y 0 -w 8 -h 25 ./data/rodolph.txt ./data/rodolph.bin
	@./cge2bin -x 32 -y 0 -w 8 -h 25 ./data/greets.txt ./data/greets.bin
	
up-xmas2018.bin: up-xmas2018.asm
	@$(ECHO) "RASM	$@"
	@$(RASM) $(RASMFLAGS) $^ -o $(basename $@)

%.m12: %.bin
	@$(ECHO) "M12	$@"
	@./bin2m12 $< $@ UP-XMAS

clean:
	@$(ECHO) "CLEANING UP..."
	@rm -f bin2m12 cge2bin up-xmas2018.bin
	@find $(BUILD_DIR) -name "*.o" -exec rm -f {} \;
	@find $(BUILD_DIR) -name "*.m12" -exec rm -f {} \;
