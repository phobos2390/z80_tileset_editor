assembled_bin = build/main_z80bin
emulator_bin = build/z80_sdl_emulator/z80_emulator
persistence_file = build/persistence.txt
assembler = z80_sdl_emulator/spasm-ng/spasm

emulator: 
	mkdir -p build
	cd build; cmake3 ..
	cd build; make

run: emulator assemble
	$(emulator_bin) $(assembled_bin) $(persistence_file)

valgrind: emulator assemble
	valgrind $(emulator_bin) $(assembled_bin) $(persistence_file)

assembler: 
	cd z80_sdl_emulator/spasm-ng && make


assemble: emulator assembler
	$(assembler)	-I z80_sdl_emulator/src/assembler\
			-I src/assembler src/assembler/main.asm\
			$(assembled_bin)


#build:
#	mkdir -p build
#	cd build; cmake ..


clean: 
	@rm -rf build 
	@rm -rf z80_sdl_emulator/src/emulator/emulator_constants.h
	@rm -rf z80_sdl_emulator/src/assembler/assembler_constants.asm
