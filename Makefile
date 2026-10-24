CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3
.PHONY: all clean check test motion reference
all: build/smw-nes-physics-v0.2.nes
build:
	mkdir -p build
build/assets.stamp: tools/generate_assets.py levels/test_level.json | build
	$(PYTHON) tools/generate_assets.py
	touch $@
build/main.o: src/main.s src/hardware.inc src/state.inc src/physics.s src/level.s src/render.s src/entities.s src/audio.s build/assets.stamp
	$(CA65) -g -I . -I src src/main.s -o $@
build/smw-nes-physics-v0.2.nes: build/main.o nes.cfg
	$(LD65) -C nes.cfg $< -o $@ -m build/rom.map -Ln build/labels.txt --dbgfile build/rom.dbg
check: all
	$(PYTHON) tests/validate_rom.py
reference:
	$(PYTHON) tools/identify_snes.py "$(ROM)" --output docs/reference-identification.json
test: check
	bash tests/run_emulator.sh
	bash tests/run_motion.sh
motion: all
	bash tests/run_motion.sh
clean:
	rm -rf build
