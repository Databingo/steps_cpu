package main

import (
	"bufio"
	"encoding/binary"
	"errors"
	"fmt"
	//"io"
	//"debug/elf"
	"bytes"
	"log"
	"os"
	"strconv"
	"strings"
	//"reflect"
	"io/ioutil"
	"slices"
)

// find SHT
// elf-shoff\
// elf-shsize64-> SHT
// elf-shnum/

// find Shstrtab
// elf-> e_shstrndx(.shstrtab index in SHT) -> Section header of .shstrtab -> sh_offset + sh_size -> .shstrtab

// find Section
// elf-shoff-sht-offset + elf-shoff-sht-size -> section_content

// find Section_name
// elf-shoff-sht-namendx + .shstrtab -> name

// align
// 4 .text
// 8 .data .rela.text .symtab
// 1 .strtab .shstrtab (no need align)
func align8(data interface{}) []byte {
        if s, ok := data.(string); ok {
	    data = []byte(s)
	}
	buf := new(bytes.Buffer)
	_ = binary.Write(buf, binary.LittleEndian, data)
	bytes := buf.Bytes()
	padding := 8 - len(bytes)%8
	if padding == 8 {
		padding = 0
	}
	padded := make([]byte, len(bytes)+padding)
	copy(padded, bytes)
	return padded
}

func align_x(data interface{}, align int) []byte {
        if s, ok := data.(string); ok {
	    data = []byte(s)
	}
	buf := new(bytes.Buffer)
	_ = binary.Write(buf, binary.LittleEndian, data)
	bytes := buf.Bytes()
	padding := align - len(bytes)%align
	if padding == align {
		//padding = 0
	    return bytes
	}
	padded := make([]byte, len(bytes)+padding)
	copy(padded, bytes)
	return padded
}

func byted(data interface{}) []byte{
	buf := new(bytes.Buffer)
	_ = binary.Write(buf, binary.LittleEndian, data)
	bytes := buf.Bytes()
	return  bytes
}

type Elf64_header struct {
	Ident     [16]byte
	Type      uint16
	Machine   uint16
	Version   uint32
	Entry     uint64
	Phoff     uint64
	Shoff     uint64 // start of SHT section header table (e_shnum * e_shentsize|64 = whole table of SHT)
	Flags     uint32
	Ehsize    uint16
	Phentsize uint16
	Phnum     uint16
	Shentsize uint16
	Shnum     uint16 // number of entries of SHT
	Shstrndx  uint16 // index of the SHT entry that contains all the section names -- if no, 0 must be SHT index for .shstrtab section
}

// sht's type
const SHT_NULL = 0
const SHT_PROGBITS = 1
const SHT_SYMTAB = 2
const SHT_STRTAB = 3
const SHT_RELA = 4
// sht's flag
const SHF_WRITE = 1 // writable during execution
const SHF_ALLOC = 2 // load when run
const SHF_EXECINSTR = 4 


type SHT struct {
	Name      uint32
	Type      uint32 // 0 unused|1 program|2 symbol|3 string|4 relocation entries with addends|5 symbol hash|6 dynamic linking|7 notes|8 bss|9 relocation no addends|10 reserved|11 dynamic linker symbol...
	Flags     uint64 // 1 writable|2 occupies memory during exection|4 executable|0x10 might by merged|0x20 contains null-terminated strings|0x40 sh_info contains SHT index
	Addr      uint64
	Offset    uint64 // section offset
	Size      uint64 // section size
	Link      uint32
	Info      uint32
	Addralign uint64
	Entsize   uint64
}

// symtab info's binding
const STB_LOCAL = 0  // local visiable
const STB_GLOBAL = 1 // global visiable
const STB_WEAK = 2   // coverable global

// symtab info's type
const STT_NOTYPE = 0 // undefined
const STT_OBJECT = 1
const STT_FUNC = 2
const STT_SECTION = 3
const STT_FILE = 4

type Elf64_sym struct { // 24 bytes
	Name  uint32 // offset in string table
	Info  uint8  // H4:binding and L4:type
	Other uint8  // reserved, currently holds 0
	Shndx uint16 // section index the symbol in
	Value uint64
	Size  uint64
}

const R_RISCV_PCREL_HI20 = 23
const R_RISCV_PCREL_LO12_I = 24

type Elf64_rela struct {
	Offset uint64  // modified instruction's offset in .text
	Info uint64   // sym index and relocation type
	Addend int16   // A constant addend used in the reloction calculation 加数
}

func write2f(text string, name string) {
	fi, _ := os.Create(name)
	defer fi.Close()
	fi.WriteString(text)
}
func append2f(instr string, name string) {
	if fs, err := os.OpenFile(name, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0666); err == nil {
		_, err = fs.WriteString(instr + "\n")
		check(err)
		fs.Close()
	}
}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func SplitOn(r rune) bool { return r == ',' || r == ' ' || r == '\t' || r == '(' || r == ')' } // delimiters to split on

func isValidImmediate(s string) (int64, error) {
	var imm1, imm2, imm3 int64
	var err1 = errors.New("error_init")
	var err2 = errors.New("error_init")
	var err3 = errors.New("error_init")
	imm1, err1 = strconv.ParseInt(s, 10, 32) // check if s is a decimal number

	if strings.HasPrefix(s, "0x") {
		imm2, err2 = strconv.ParseInt(s[2:], 16, 64) // check if s is hex
		fmt.Println(s, "imm2:", imm2, err2)
	} else if strings.HasPrefix(s, "-0x") {
		imm2, err2 = strconv.ParseInt(string(s[0])+s[3:], 16, 64) // ignore the "0x" part but include the '-'
		if imm2 == 0 {
			imm2, err2 = strconv.ParseInt(string(s[0])+"1"+strings.Repeat("0", len(s[3:])*4), 2, 64)
			fmt.Println("imm2:", string(s[0])+"1"+strings.Repeat("0", len(s[3:])*4))
		}

	} else if strings.HasPrefix(s, "0b") {
		imm3, err3 = strconv.ParseInt(s[2:], 2, 64) // check if s is binary
	} else if strings.HasPrefix(s, "-0b") {
		imm3, err3 = strconv.ParseInt(string(s[0])+s[3:], 2, 64)
		if imm3 == 0 {
			imm3, err3 = strconv.ParseInt(string(s[0])+"1"+s[3:], 2, 64)
		}
	}

	if err1 != nil && err2 != nil && err3 != nil {
		fmt.Println(s)
		return 0, errors.New("Invalid immediate value")
	} else if err1 == nil {
		return imm1, nil
	} else if err2 == nil {
		return imm2, nil
	} else {
		return imm3, nil
	}
}
func isValidImmediate_u(s string) (int64, uint64, error) {
	var sign int64
	var imm1, imm2, imm3 uint64
	var err1 = errors.New("error_init")
	var err2 = errors.New("error_init")
	var err3 = errors.New("error_init")

	//imm1, err1 = strconv.ParseUint(s, 10, 32) // check if s is a decimal number

	if strings.HasPrefix(s, "0x") {
		imm2, err2 = strconv.ParseUint(s[2:], 16, 64) // check if s is hex
		fmt.Println("+imm2:", imm2, err2)
	} else if strings.HasPrefix(s, "-0x") {
		imm2, err2 = strconv.ParseUint(s[3:], 16, 64) // check if s is binary
		fmt.Println("-imm2:", imm2, err2)
	} else if strings.HasPrefix(s, "0b") {
		imm3, err3 = strconv.ParseUint(s[2:], 2, 64) // check if s is binary
	} else if strings.HasPrefix(s, "-0b") {
		imm3, err3 = strconv.ParseUint(s[3:], 2, 64) // check if s is binary
	} else if strings.HasPrefix(s, "-") {
		imm1, err1 = strconv.ParseUint(s[1:], 10, 64) // check if s is binary
	} else {
		imm1, err1 = strconv.ParseUint(s, 10, 64) // check if s is a decimal number
	}

	if strings.HasPrefix(s, "-") {
		sign = 1
	}

	if err1 != nil && err2 != nil && err3 != nil {
		fmt.Println(".", err1)
		fmt.Println("..", err2)
		fmt.Println("...", err3)
		fmt.Println(s)
		return 0, 0, errors.New("Invalid immediate value")
	} else if err1 == nil {
		return sign, imm1, nil
	} else if err2 == nil {
		return sign, imm2, nil
	} else {
		return sign, imm3, nil
	}
}

func main() {
	regBin := map[string]uint32{ // t0-6 a0-7 could bu use
		"x0": 0b00000, "zero": 0b00000,
		"x1": 0b00001, "ra": 0b00001, // return address
		"x2": 0b00010, "sp": 0b00010, // stack pointer
		"x3": 0b00011, "gp": 0b00011, // global pointer
		"x4": 0b00100, "tp": 0b00100, // thread pointer
		"x5": 0b00101, "t0": 0b00101, // tmp t0-6
		"x6": 0b00110, "t1": 0b00110, // tmp
		"x7": 0b00111, "t2": 0b00111, // tmp
		"x8": 0b01000, "s0": 0b01000, "fp": 0b01000, // frame pointer
		"x9": 0b01001, "s1": 0b01001,
		"x10": 0b01010, "a0": 0b01010, // function argument a0-7  (a0,a1 returned value)
		"x11": 0b01011, "a1": 0b01011,
		"x12": 0b01100, "a2": 0b01100,
		"x13": 0b01101, "a3": 0b01101,
		"x14": 0b01110, "a4": 0b01110,
		"x15": 0b01111, "a5": 0b01111,
		"x16": 0b10000, "a6": 0b10000,
		"x17": 0b10001, "a7": 0b10001,
		"x18": 0b10010, "s2": 0b10010, //saved register s0-11
		"x19": 0b10011, "s3": 0b10011,
		"x20": 0b10100, "s4": 0b10100,
		"x21": 0b10101, "s5": 0b10101,
		"x22": 0b10110, "s6": 0b10110,
		"x23": 0b10111, "s7": 0b10111,
		"x24": 0b11000, "s8": 0b11000,
		"x25": 0b11001, "s9": 0b11001,
		"x26": 0b11010, "s10": 0b11010,
		"x27": 0b11011, "s11": 0b11011,
		"x28": 0b11100, "t3": 0b11100, // tmp
		"x29": 0b11101, "t4": 0b11101, // tmp
		"x30": 0b11110, "t5": 0b11110, // tmp
		"x31": 0b11111, "t6": 0b11111, // tmp
	}

	opBin := map[string]uint32{
		"lui":   0b00000000000000000000000000110111,
		"auipc": 0b00000000000000000000000000010111,
		"jal":   0b00000000000000000000000001101111,
		"jalr":  0b00000000000000000000000001100111,

		"beq":  0b00000000000000000000000001100011,
		"bne":  0b00000000000000000001000001100011,
		"blt":  0b00000000000000000100000001100011,
		"bge":  0b00000000000000000101000001100011,
		"bltu": 0b00000000000000000110000001100011,
		"bgeu": 0b00000000000000000111000001100011,

		"lb":  0b00000000000000000000000000000011,
		"lbu": 0b00000000000000000100000000000011,
		"lh":  0b00000000000000000001000000000011,
		"lhu": 0b00000000000000000101000000000011,
		"lw":  0b00000000000000000010000000000011,
		"lwu": 0b00000000000000000110000000000011,
		"ld":  0b00000000000000000011000000000011,

		"sb": 0b00000000000000000000000000100011,
		"sh": 0b00000000000000000001000000100011,
		"sw": 0b00000000000000000010000000100011,
		"sd": 0b00000000000000000011000000100011,

		"addi":  0b00000000000000000000000000010011,
		"addiw": 0b00000000000000000000000000011011,
		"slti":  0b00000000000000000010000000010011,
		"sltiu": 0b00000000000000000011000000010011,
		"xori":  0b00000000000000000100000000010011,
		"ori":   0b00000000000000000110000000010011,
		"andi":  0b00000000000000000111000000010011,

		"slli":  0b00000000000000000001000000010011,
		"slliw": 0b00000000000000000001000000011011,
		"srli":  0b00000000000000000101000000010011,
		"srliw": 0b00000000000000000101000000011011,
		"srai":  0b01000000000000000101000000010011,
		"sraiw": 0b01000000000000000101000000011011,

		"add":  0b00000000000000000000000000110011,
		"addw": 0b00000000000000000000000000111011,
		"sub":  0b01000000000000000000000000110011,
		"subw": 0b01000000000000000000000000111011,
		"sll":  0b00000000000000000001000000110011,
		"sllw": 0b00000000000000000001000000111011,
		"slt":  0b00000000000000000010000000110011,
		"sltu": 0b00000000000000000011000000110011,
		"xor":  0b00000000000000000100000000110011,
		"srl":  0b00000000000000000101000000110011,
		"srlw": 0b00000000000000000101000000111011,
		"sra":  0b01000000000000000101000000110011,
		"sraw": 0b01000000000000000101000000111011,
		"or":   0b00000000000000000110000000110011,
		"and":  0b00000000000000000111000000110011,

		"ecall":  0b00000000000000000000000001110011,
		"ebreak": 0b00000000000100000000000001110011,

		// privilege
		"sret": 0b00010000001000000000000001110011,
		"mret": 0b00110000001000000000000001110011,
		"wfi":  0b00010000010100000000000001110011,
	}

	if len(os.Args) != 2 {
		fmt.Println("Usage:", os.Args[0], "FILE.s")
	}
	file, err := os.Open(os.Args[1])
	check(err)
	defer file.Close()

	////////
	// 0pass parse directive
	// .section
	// .text .data .rodata .bss
	// .symtab .strtab .shstrtab
	//
	// .byte .string .half .word .dword .zero .align .equ 8
	fmt.Println("start 0pass.")
	fmt.Println("ELF header inital:")
	var elf_header Elf64_header
	elf_header.Ident = [16]byte{
		0x7F, 0x45, 0x4C, 0x46, // Magic number indicates ELF file (.ELF)
		0x02,                                     // ei_class|0 Invalid|1 32-bit|2 64-bit
		0x01,                                     // ei_data specify|0 Invalid|1 2's complete little endian|2 2's complete bit endian
		0x01,                                     // ei_version current elf version
		0x09,                                     // ei_osabi target platform|0 NONE/UNIX System V|1 HP-UX|2 NetBSD|3 Linux|9 FreeBSD
		0x00,                                     // ei_abiverison ABI version
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // ei_padding zero padding
	}
	elf_header.Type = 0x0001        // 0 No type|1 Relocatable file|2 Executable file|3 Shared object file|4 Core file
	elf_header.Machine = 0x00F3     // 0 No machine|62 AMDx86-64|183 ARMaarh64|0xF3 RISC-V
	elf_header.Version = 0x00000001 // e_version specify original elf version
	elf_header.Entry = 0x0          // e_entry program entry address -- 0 for relocatable file set final entry point by linker
	elf_header.Phoff = 0x0          // e_phoff points to start of program header table --  0 for relocatable file (no program headers)
	//-------
	elf_header.Shoff = 0x40         // e_shoff points to start of section header table --  no 0 have to be the start of SHT  (e_shnum * e_shentsize = whole table of SHT) = elf_heaser.Ehsize ? 
	elf_header.Flags = 0x00000004   // e_flags  // 0x4 for LP64D ABI  (EF_RISCV_FLOAT_ABI_DOUBLE) fit for RV64G
	elf_header.Ehsize = 0x0040      // e_ehsize specify size of This header, 52 bytes(0x34) for 32-bit format, 64 bytes(0x40) for 64-bit ?
	elf_header.Phentsize = 0x0      // e_phentsize size of program header table entry -- 0 for relocatable
	elf_header.Phnum = 0x0          // e_phnum contains number of entries in program header table --
	elf_header.Shentsize = 0x0040   // e_shentsize size of section header entry -- 64 for Elf64_shdr
	//-------
	elf_header.Shnum = 0x0 //#
	//-------
	elf_header.Shstrndx = 0x1 //# 0 indicate SHN_UNDEF no section header string table ** -- if no, 0 must be SHT index for .shstrtab section

	//buf := new(bytes.Buffer)
	//_ = binary.Write(buf, binary.LittleEndian, &elf_header)
	//elf_header_bytes := buf.Bytes()
	//fmt.Println(elf_header_bytes)

	// .out Usually format:
	// ----------------
	// ELF header 64bytes
	// Section Header Table (SHT) 0 (starts at "e_shoff" in ELF header) 64bytes
	// Section Header Table (SHT) 1 shstrtab 64bytes
	// Section Header Table (SHT) 2 text 64bytes
	// Content of section 1, .shstrtab
	// Content of section 2, .text
	// Content of section 3, .data
	// Content of section 4, .rodata
	// Content of section 5, .symtab
	// Content of section 6, .strtab
	// Content of section 7, .rela.text
	// Content of section 8, ...
	// ----------------
	// each entrie of SHT is 64 bytes, sh_offset is the exactly offset from beginning of file to the start point of this section's context, e.g., .text's sh_offset is 64, after ELF header
	// Must need a Non Section for the first section header
	var sht SHT
	sht.Name = 0     // 0 for null
	sht.Type = 0x00000000 // 0 for sh_null
	sht.Flags = 0x0000000000000000
	sht.Addr = 0x0000000000000000
	sht.Offset = 0 // need calculate
	sht.Size = 0   // need calculate
	sht.Link = 0x00000000
	sht.Info = 0x00000000
	sht.Addralign = 0x0000000000000000 //?
	sht.Entsize = 0x0000000000000000
	fmt.Println("SHT Section header NON inital:")
	var sht0 SHT
	sht0.Name = 0          //0x00000001   // offset in shstrtab
	sht0.Type = 0x00000000 // 0 for sh_null
	sht0.Flags = 0x0000000000000000
	sht0.Addr = 0x0000000000000000
	sht0.Offset = 0 // need calculate
	sht0.Size = 0   // need calculate
	sht0.Link = 0x00000000
	sht0.Info = 0x00000000
	sht0.Addralign = 0x0000000000000000 //?
	sht0.Entsize = 0x0000000000000000
	buf_sht0 := new(bytes.Buffer)
	_ = binary.Write(buf_sht0, binary.LittleEndian, &sht0)
	sht0_bytes := buf_sht0.Bytes()
	fmt.Println(sht0_bytes)
	fmt.Println("--------#")
	fmt.Println(len(sht0_bytes))

	fmt.Println("SHT .shstrtab Section header inital:")
	var sht1 SHT
	sht1.Name = 1          // sh_name //0x00000001   // offset in shstrtab
	sht1.Type = 0x00000003 // sh_type 3_SHT_STRTAB // 3 for sh_strtab
	sht1.Flags = 0x0000000000000000
	sht1.Addr = 0x0000000000000000 // sh_addr virtual address at exection?
	sht1.Offset = 64 * 5           // need calculate // sh_offset (with sh_size to locate whole section content)
	sht1.Size = 28                 // need calculate
	sht1.Link = 0x00000000
	sht1.Info = 0x00000000
	sht1.Addralign = 0x0000000000000001 //?
	sht1.Entsize = 0x0000000000000000
	//	buf_sht1 := new(bytes.Buffer)
	//	_ = binary.Write(buf_sht1, binary.LittleEndian, &sht1)
	//	sht1_bytes := buf_sht1.Bytes()
	//	fmt.Println(sht1_bytes)
	//	fmt.Println("--------#")
	//	fmt.Println(len(sht1_bytes))
	//Find Section name string
	//Elf64_hdr -> Elf64_Shdr(SHT) -> Section header of .x -> sh_name(index in .shstrtab) -> section name string in .shstrtab
	//Elf64_hdr -> e_shstrndx(.shstrtab index in SHT) -> Section header of .shstrtab -> sh_offset + sh_size -> .shstrtab

	fmt.Println("SHT .strtab Section header inital:")
	var sht2 SHT
	sht2.Name = 11         // sh_name offset in shstrtab
	sht2.Type = 0x00000003 // sh_type
	sht2.Flags = 0x0000000000000000
	sht2.Addr = 0x0000000000000000 // sh_addr virtual address at exection?
	sht2.Offset = 64*4 + 28        // need calculate // sh_offset (with sh_size to locate whole section content)
	sht2.Size = 160                // need calculate
	sht2.Link = 0x00000000
	sht2.Info = 0x00000000
	sht2.Addralign = 0x0000000000000001 //?
	sht2.Entsize = 0x0000000000000000
	//buf_sht2 := new(bytes.Buffer)
	//_ = binary.Write(buf_sht2, binary.LittleEndian, &sht2)
	//sht2_bytes := buf_sht2.Bytes()
	//fmt.Println(sht2_bytes)
	//fmt.Println("--------#")
	//fmt.Println(len(sht2_bytes))

	fmt.Println("SHT .symtab Section header inital:")
	var sht3 SHT
	sht3.Name = 11         // sh_name offset in shstrtab
	sht3.Type = 0x00000002 // sh_type
	sht3.Flags = 0x0000000000000000
	sht3.Addr = 0x0000000000000000      // sh_addr virtual address at exection?
	sht3.Offset = 64*4 + 28             // need calculate // sh_offset (with sh_size to locate whole section content)
	sht3.Size = 160                     // need calculate
	sht3.Link = 0x00000002              // .strtab index 2 in .shstrtab
	sht3.Info = 0x00000001              // first no local symbol in syms
	sht3.Addralign = 0x0000000000000008 //? Good practice for alignment
	sht3.Entsize = 0x18                 //24 each sym record size is 24 bytes
	//buf_sht3 := new(bytes.Buffer)
	//_ = binary.Write(buf_sht3, binary.LittleEndian, &sht3)
	//sht3_bytes := buf_sht3.Bytes()
	//fmt.Println(sht3_bytes)
	//fmt.Println("--------#")
	//fmt.Println(len(sht3_bytes))

	fmt.Println("SHT .text Section header inital:")
	var sht4 SHT
	sht4.Name = 11         // sh_name offset in shstrtab
	sht4.Type = 0x00000001 // sh_type
	sht4.Flags = 0x0000000000000000
	sht4.Addr = 0x0000000000000000 // sh_addr virtual address at exection?
	sht4.Offset = 64*4 + 28        // need calculate // sh_offset (with sh_size to locate whole section content)
	sht4.Size = 160                // need calculate
	sht4.Link = 0x00000000
	sht4.Info = 0x00000000
	sht4.Addralign = 0x0000000000000008 //?
	sht4.Entsize = 0x0000000000000000
	//buf_sht4 := new(bytes.Buffer)
	//_ = binary.Write(buf_sht4, binary.LittleEndian, &sht4)
	//sht4_bytes := buf_sht4.Bytes()
	//fmt.Println(sht4_bytes)
	//fmt.Println("--------#")
	//fmt.Println(len(sht4_bytes))

	fmt.Println("SHT .data Section header inital:")
	var sht5 SHT
	sht5.Name = 11         // sh_name offset in shstrtab
	sht5.Type = 0x00000001 // sh_type
	sht5.Flags = 0x0000000000000000
	sht5.Addr = 0x0000000000000000 // sh_addr virtual address at exection?
	sht5.Offset = 64*4 + 28        // need calculate // sh_offset (with sh_size to locate whole section content)
	sht5.Size = 160                // need calculate
	sht5.Link = 0x00000000
	sht5.Info = 0x00000000
	sht5.Addralign = 0x0000000000000008 //?
	sht5.Entsize = 0x0000000000000000
	//buf_sht5 := new(bytes.Buffer)
	//_ = binary.Write(buf_sht5, binary.LittleEndian, &sht5)
	//sht5_bytes := buf_sht5.Bytes()
	//fmt.Println(sht5_bytes)
	//fmt.Println("--------#")
	//fmt.Println(len(sht5_bytes))

	fmt.Println("SHT .rela.text Section header inital:")
	var sht6 SHT
	sht6.Name = 11         // sh_name offset in shstrtab
	sht6.Type = 0x00000001 // sh_type
	sht6.Flags = 0x0000000000000000
	sht6.Addr = 0x0000000000000000 // sh_addr virtual address at exection?
	sht6.Offset = 64*4 + 28        // need calculate // sh_offset (with sh_size to locate whole section content)
	sht6.Size = 160                // need calculate
	sht6.Link = 0x00000000
	sht6.Info = 0x00000000
	sht6.Addralign = 0x0000000000000008 //?
	sht6.Entsize = 0x0000000000000000
	//buf_sht6 := new(bytes.Buffer)
	//_ = binary.Write(buf_sht6, binary.LittleEndian, &sht6)
	//sht6_bytes := buf_sht6.Bytes()
	//fmt.Println(sht6_bytes)
	//fmt.Println("--------#")
	//fmt.Println(len(sht6_bytes))

	var sym Elf64_sym
	sym.Name = 0  //uint32 // offset in string table
	sym.Info = 0  //# uint8 // H4:binding and L4:type
	sym.Other = 0 //uint8 // reserved, currently holds 0
	sym.Shndx = 0 //uint16 // section index the symbol in
	sym.Value = 0 //# uint64  for relocatable .o file it's symbol's offset in its section
	sym.Size = 0  //#uint64  for function it's its size

	fmt.Println(".symtab 0 inital:")
	var sym0 Elf64_sym
	sym0.Name = 0  //uint32 // offset in string table
	sym0.Info = 0  //# uint8 // H4:binding and L4:type
	sym0.Other = 0 //uint8 // reserved, currently holds 0
	sym0.Shndx = 0 //uint16 // section index the symbol in
	sym0.Value = 0 //# uint64  for relocatable .o file it's symbol's offset in its section
	sym0.Size = 0  //#uint64  for function it's its size
	//buf_sym1 := new(bytes.Buffer)
	//_ = binary.Write(buf_sym0, binary.LittleEndian, &sym0)
	//sym0_bytes := buf_sym0.Bytes()
	//fmt.Println(smy0_bytes)
	//fmt.Println("--------#")
	//fmt.Println(len(sym0_bytes))

	fmt.Println(".sym1 _start inital:")
	var sym1 Elf64_sym
	sym1.Name = 1  // points to "_start" in .strtab
	sym1.Info = 0  //# uint8 // H4:binding and L4:type
	sym1.Other = 0 //uint8 // reserved, currently holds 0
	sym1.Shndx = 4 //uint16 // section index the symbol in (.text)
	sym1.Value = 0 //# uint64  for relocatable .o file it's symbol's offset in its section
	sym1.Size = 0  //#uint64  for function it's its size

	fmt.Println(".sym2 msg inital:")
	var sym2 Elf64_sym
	sym2.Name = 0  // points to "_start" in .strtab
	sym2.Info = 0  //# uint8 // H4:binding and L4:type
	sym2.Other = 0 //uint8 // reserved, currently holds 0
	sym2.Shndx = 5 //uint16 // section index the symbol in (.data)
	sym2.Value = 0 //# uint64  for relocatable .o file it's symbol's offset in its section
	sym2.Size = 0  //#uint64  for function it's its size

	//Find symbol string
	//Elf64_hdr -> e_shoff + e_shnum * e_shentsize -> Elf64_Shdr(SHT) -> Section header of .symtab -> sh_offset + sh_size -> .symtab -> st_name -> byte start point in .strtab to null
	//Elf64_hdr -> e_shoff + e_shnum * e_shentsize -> Elf64_Shdr(SHT) -> Section header of .strtab -> sh_offset + sh_size -> .strtab
	scanner0 := bufio.NewScanner(file) // stores content from file
	scanner0.Split(bufio.ScanLines)
	var copy_instr strings.Builder

	//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	var section_in string
	var label_in string
	var shts []SHT
	var shstrtab []string
	var text []byte
	var data []byte
	symtab_ := []Elf64_sym{sym}// symtab_ array and strtab are same order
	strtab := []string{"\x00"}
	var relatext []Elf64_rela
	//var no_local_sym_1st uint32
       
	//elf
	//sht0
	shstrtab = append(shstrtab,"\x00")
	shts = append(shts, sht) // strings array shts and shstrtab are same order
	elf_header.Shnum += 1 
	//sht1
	shstrtab = append(shstrtab,".shstrtab\x00")
	shts = append(shts, sht)
	elf_header.Shnum += 1 
	
	for scanner0.Scan() {
		raw_instr := scanner0.Text() + "\n"
		line := strings.Split(scanner0.Text(), "#")[0]
		code := strings.FieldsFunc(line, SplitOn)
		if len(code) == 0 {
			continue
		}
		switchOnOp := code[0]
		directive := ""
		suf_directive := ""
		if strings.HasPrefix(switchOnOp, ".") {
			//directive = strings.TrimPrefix(code[0], ".")
			directive = code[0]
			suf_directive = strings.Join(code[1:len(code)], " ")
                        //if !strings.HasPrefix(code[1], "."){
			//fmt.Println("Directive:", directive, "|Suf_directive:", suf_directive)
			//}
			if directive == ".global" {
			    fmt.Println("Directive:", directive, "//Suf_directive:", suf_directive)
			    fmt.Println("create .symtab entry + .strtab entry, add .symtab to .shstrtab")
			    if !slices.Contains(shstrtab, ".strtab\x00") {
			        //sht + shstrtab
	                        elf_header.Shnum += 1 
	                        shts = append(shts, sht)
	                        shstrtab = append(shstrtab, ".strtab\x00")
			    }
			    if !slices.Contains(shstrtab, ".symtab\x00") {
			        //sht + shstrtab
	                        elf_header.Shnum += 1 
	                        shts = append(shts, sht)
	                        shstrtab = append(shstrtab, ".symtab\x00")
			    }

	                    sym.Name = uint32(len(strings.Join(strtab,"")))  //#uint32 // offset in string table
			    fmt.Println("sym.Name:--|", sym.Name)

	                    sym.Info = (STB_GLOBAL << 4 | STT_FUNC)    //# H4:binding and L4:type
	                    sym.Other = 0 //uint8 // reserved, currently holds 0
	                    //sym.Shndx = uint16(slices.Index(shstrtab, section_in))//0 //#uint16 // section index the symbol in
			    //fmt.Println("-::", section_in, uint16(slices.Index(shstrtab, section_in)))//0 //#uint16 // section index the symbol in
	                    sym.Value = 0 //# uint64  for relocatable .o file it's symbol's offset in its section
	                    sym.Size = 0  //#uint64  for function it's its size   -- uint64(len(align8("H\n")))                   
			    //sym + str + data
			    symtab_ = append(symtab_, sym)
			    strtab = append(strtab, suf_directive+"\x00")
			}

			if directive == ".section" {
			    fmt.Println("Directive:", directive, "||Suf_directive:", suf_directive)
			    fmt.Println("create SHT(s) + .shstrtab entry + section[]byte")
			    section_in = suf_directive + "\x00"
			    //sht
	                    elf_header.Shnum += 1 
	                    shts = append(shts, sht)
	                    shstrtab = append(shstrtab,suf_directive+"\x00")
			}
			if directive == ".string" {
			    fmt.Println("Directive:", directive, "||Suf_directive:", suf_directive)
			    fmt.Println("check label_in + check strtab + edit symtab")
			    fmt.Println("strtab:", strtab)
			    sym_index := slices.Index(strtab, label_in+"\x00")
			    fmt.Println("label_in-:", label_in, sym_index)
			    fmt.Println("sym_e:", symtab_[sym_index])
			    //pad8 :=  align8(suf_directive)
			    pad8 :=  align_x(suf_directive, 8)
	                    //symtab_[sym_index].Name = 1  // points to "_start" in .strtab
	                    symtab_[sym_index].Info = ( symtab_[sym_index].Info >> 4 | STT_OBJECT  ) //# uint8 // H4:binding and L4:type
	                    //symtab_[sym_index].Other = 0 //uint8 // reserved, currently holds 0
	                    symtab_[sym_index].Shndx = uint16(slices.Index(shstrtab, section_in))//4 //uint16 // section index the symbol in (.text)
	                    symtab_[sym_index].Value = uint64(len(data)) //# uint64  for relocatable .o file it's symbol's offset in its section
	                    symtab_[sym_index].Size = uint64(len(pad8))  //#uint64  for function it's its size
			    //sym + str + data
                            data = append(data, pad8...)

			}
		

		} else if strings.HasSuffix(switchOnOp, ":") {
			label_in = strings.TrimSuffix(code[0], ":")
		        sym_index := slices.Index(strtab, label_in+"\x00")
			    fmt.Println("|-:sym.Name",len(strings.Join(strtab,"")),  "strtab:", strtab, "section_in:", section_in)
			if sym_index == -1 {
	                    //sym.Name = uint32(len(strings.Join(strtab,"")))  //#uint32 // offset in string table
	                    sym.Info = (STB_LOCAL << 4 | STT_FUNC)    //# H4:binding and L4:type
	                    sym.Other = 0 //uint8 // reserved, currently holds 0
	                    sym.Shndx = uint16(slices.Index(shstrtab, section_in))//0 //#uint16 // section index the symbol in
			    //fmt.Println("-::", section_in, uint16(slices.Index(shstrtab, section_in)))//0 //#uint16 // section index the symbol in
	                    sym.Value = 0 //# uint64  for relocatable .o file it's symbol's offset in its section
	                    sym.Size = 0  //#uint64  for function it's its size   -- uint64(len(align8("H\n")))                   
			    //sym + str
			    //symtab_ = append(symtab_, sym)
			    //strtab = append(strtab, label_in+"\x00")
			    //local symbols should be in front of global symbols in symtab
			    //symtab_ = append(symtab_[:1+1], symtab_[1:]...)
			    //symtab_[1] = sym
			    symtab_ = slices.Insert(symtab_, 1, sym)
			    strtab = slices.Insert(strtab, 1, label_in+"\x00")
			} else {
			    fmt.Println("=|=shndx:", uint16(slices.Index(shstrtab, section_in)), strtab, "section_in:", section_in, "sym_index:", sym_index, "symbal:", strtab[sym_index])
			    symtab_[sym_index].Shndx = uint16(slices.Index(shstrtab, section_in))//0 //#uint16 // section index the symbol in
					    }
			copy_instr.WriteString(raw_instr)
		} else {
			copy_instr.WriteString(raw_instr)
		}
         	    fmt.Println(shstrtab, strtab, text, data, shts, section_in, label_in, "x|")
	}
	////////

	//scanner := bufio.NewScanner(strings.NewReader(real_instr.String()))
	//scanner.Split(bufio.ScanLines)
	// 1pass trans pseudo to real
	//scanner1 := bufio.NewScanner(file) // stores content from file
	//scanner1.Split(bufio.ScanLines)
	scanner1 := bufio.NewScanner(strings.NewReader(copy_instr.String())) // stores content from file
	scanner1.Split(bufio.ScanLines)

	var code []string
	var instruction uint32
	var address uint32 = 0
	lineCounter := 1

	symbolTable := make(map[string]int64, 100)
	const UNKNOWN = -1
	//    literalPool := make(map[string]int64, 100)

	var real_instr strings.Builder

	// translate pseudo-instruction to real-instruction
	fmt.Println("start 1pass.")
	for scanner1.Scan() {
		origin_instr := scanner1.Text() + "\n"
		line := strings.Split(scanner1.Text(), "#")[0]
		code = strings.FieldsFunc(line, SplitOn)
		if len(code) == 0 {
			lineCounter++
			continue
		}
		switchOnOp := code[0]
		label := ""
		//var label string
		if strings.HasSuffix(switchOnOp, ":") {
			label = strings.TrimSuffix(code[0], ":")
			real_instr.WriteString(label + ":\n") // separate label: to a independent line
			if len(code) >= 2 {
				switchOnOp = code[1]
				code = code[1:]
			} else {
				//origin_instr = strings.TrimLeft(origin_instr, " ")
				//real_instr.WriteString(origin_instr)
				continue
			}
		}
		switch switchOnOp {
		case "li": // assembly use 0x and decimal with -+ meets the KISS, at least one way to go through first
			if len(code) != 3 && len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			sign, imm, err := isValidImmediate_u(code[2])
			if err != nil {
				fmt.Printf("~Error on line %d: %s, %s \n", lineCounter, err, line)
				os.Exit(0)
			}
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			if label != "" {
				ins = fmt.Sprintf("%s:\n", label)
				//real_instr.WriteString(ins)
			}
			/////////////////////////-- deploy 3
			// lui +0x800>>12; addi -(a<<12)#for h32; srli 11; ori 11; srli 11; ori 11; srli 10, ori 10; r sub 2 instruction for main
			/////////////////////////-- deploy 2
			ins = fmt.Sprintf("addi %s, %s, %#x\n", code[1], "x0", 0) // for 0 or clean reg
			real_instr.WriteString(ins)
			if imm == 0xffffffffffffffff {
				ins = fmt.Sprintf("addi %s, %s, %#x\n", code[1], "x0", 1) // for 0 or clean reg
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("xori %s, %s, -1\naddi %s, %s, 1\n", code[1], code[1], code[1], code[1])
				real_instr.WriteString(ins)
				continue

			}
			// 高 20 位
			h20 := imm >> 44 & 0xfffff
			if h20 != 0 {
				ins = fmt.Sprintf("lui %s, %#x\n", code[1], h20)
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("srli %s, %s, %#x\n", code[1], code[1], 1) // righ shift to concat with 11 to 12
				real_instr.WriteString(ins)
			}
			// 次 11 位
			c11 := imm >> 33 & 0x7ff
			if c11 != 0 {
				ins = fmt.Sprintf("ori %s, %s, %#x\n", code[1], code[1], c11)
				real_instr.WriteString(ins)
			}
			// 中 11 位
			sf := 11
			z11 := imm >> 22 & 0x7ff
			if z11 != 0 {
				ins = fmt.Sprintf("slli %s, %s, %#x\n", code[1], code[1], sf)
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("ori %s, %s, %#x\n", code[1], code[1], z11)
				real_instr.WriteString(ins)
				sf = 0
			}
			// 低 11 位
			sf += 11
			d11 := imm >> 11 & 0x7ff
			if d11 != 0 {
				ins = fmt.Sprintf("slli %s, %s, %#x\n", code[1], code[1], sf)
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("ori %s, %s, %#x\n", code[1], code[1], d11)
				real_instr.WriteString(ins)
				sf = 0
			}
			// 末 11 位
			sf += 11
			m11 := imm & 0x7ff
			if m11 != 0 && (d11 != 0 || z11 != 0 || c11 != 0 || h20 != 0) {
				ins = fmt.Sprintf("slli %s, %s, %#x\n", code[1], code[1], sf)
				real_instr.WriteString(ins)
			}
			if m11 != 0 {
				ins = fmt.Sprintf("ori %s, %s, %#x\n", code[1], code[1], m11)
				real_instr.WriteString(ins)
				sf = 0
			}
			// 左移
			if sf != 0 && imm != 0 {
				ins = fmt.Sprintf("slli %s, %s, %#x\n", code[1], code[1], sf)
				real_instr.WriteString(ins)

			}

			// 取补码还原负数
			if sign == 1 {
				ins = fmt.Sprintf("xori %s, %s, -1\naddi %s, %s, 1\n", code[1], code[1], code[1], code[1])
				real_instr.WriteString(ins)

			}

		case "j": // PC尾跳转 j offset|jump to pc+offset
			//if len(code) != 2 && len(code) != 3 {
			//	fmt.Println("Incorrect argument count on line: ", lineCounter)
			//	os.Exit(0)
			//}
			//lab := code[1]
			//ins := fmt.Sprintf("jal x0, %s\n", lab)
			//fmt.Printf("%s: \n", ins)
			//if err != nil {
			//	fmt.Printf("~Error on line %d: %s, %s \n", lineCounter, err, line)
			//	os.Exit(0)
			//}
			//if label != "" {
			//	real_instr.WriteString(label + ":\n")
			//}

			//ins = fmt.Sprintf("jal x0, %s\n", lab)

			//real_instr.WriteString(ins)
			//fmt.Printf("%s: \n", ins)
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			//ins = fmt.Sprintf("jal x0, 0 # %s\n", code[1]) //calculate offset by linker?
			ins = fmt.Sprintf("jal x0, %s\n", code[1]) // calculate offset by linker?
			real_instr.WriteString(ins)
		case "jr": // 寄存器尾跳转 jr rs|jump to rs+0 (imm default 0)
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("jalr x0, %s, 0\n", code[1])
			real_instr.WriteString(ins)
		case "jal": // PC跳转 jal offset|jump to pc+imm|save pc+4 to x1 (retrun default x1)
			if len(code) == 2 { // different from real: jal rd, imm
				ins := fmt.Sprintf("# %s\n", line)
				real_instr.WriteString(ins)
				//ins = fmt.Sprintf("jal x1, 0 # %s\n", code[1])//should calculate offset by linker?
				ins = fmt.Sprintf("jal x1, %s\n", code[1]) //should calculate offset by linker?
				real_instr.WriteString(ins)
			} else {
				origin_instr = strings.TrimLeft(origin_instr, " ")
				real_instr.WriteString(origin_instr)
			}
		case "jalr": // 寄存器跳转 jalr rs |jump to rs|save pc+4 to x1 (imm defalut 0, retrun default x1)
			if len(code) == 2 { // different from real: jal rd, imm
				ins := fmt.Sprintf("# %s\n", line)
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("jalr x1, %s, 0\n", code[1])
				real_instr.WriteString(ins)
			} else {
				origin_instr = strings.TrimLeft(origin_instr, " ")
				real_instr.WriteString(origin_instr)
			}
		case "la", "lla": // 装入地址 (lla for certainly pc-related address, la is not sure) (+- 2GB) larger use li
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			    if !slices.Contains(shstrtab, ".rela.text\x00") {
			        fmt.Println("create .rela.text")
			        //sht + shstrtab
	                        elf_header.Shnum += 1 
	                        shts = append(shts, sht)
	                        shstrtab = append(shstrtab, ".rela.text\x00")
			    }
			fmt.Println(`
		                 for .rela.text: 
			         Entry: (24 bytes)
				 Elf64_Addr r_offset: instruction addr(index in .text) 0x0000000000000000
				 Elf64_Xword r_infor: type:R_RISCV_PCREL_HI20=18 << 32 | symbol_index:index of symbol in .symtab(defined in .data section)  0x0000000100000012
				 Elf64_Sxword r_addend: 0 for PC-relative 0x0000000000000000
				 `)
			//ins := fmt.Sprintf("auipc %s, %%pcrel_hi(%s)\n", code[1], code[2]) // hi = (rela_addr + 0x800) >> 12
			ins = fmt.Sprintf("auipc %s, 0 # R_RISCV_PCREL_HI20 %s \n", code[1], code[2]) // hi = (rela_addr + 0x800) >> 12
			real_instr.WriteString(ins)
			fmt.Println(`
		                 for .rela.text: 
			         Entry: (24 bytes)
				 Elf64_Addr r_offset: instruction addr(index in .text) 0x0000000000000004
				 Elf64_Xword r_infor: type:R_RISCV_PCREL_LO12_I=19 << 32 | symbol_index:index of symbol in .symtab(defined in .data section)  0x0000000100000013
				 Elf64_Sxword r_addend: 0 for PC-relative 0x0000000000000000
				 `)
			//ins = fmt.Sprintf("addi  %s, %s, %%pcrel_lo(%s)\n", code[1], code[1], code[2]) // lo = rela_addr  - (hi << 12)
			ins = fmt.Sprintf("addi  %s, %s, 0 # R_RISCV_PCREL_LO12_I %s \n", code[1], code[1], code[2]) // lo = rela_addr  - (hi << 12)
			real_instr.WriteString(ins)
		case "call": //auipc x1, offset[31:12]; jalr x1, offset[11:0](x1) 调用远距离过程(save pc+4)
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("auipc x1, 0 # %s\n", code[1])
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("jalr x1, x1, 0 # %s\n", code[1])
			real_instr.WriteString(ins)
		case "tail": //auipc x6, offset[32:12]; jalr x0, x6, offset[11:0] 尾调用远距离子过程(discard pc+4)
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("auipc x6, 0 # %s\n", code[1])
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("jalr x0, x6, 0 # %s\n", code[1])
			real_instr.WriteString(ins)
		case "nop": // 空操作
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = "addi x0, x0, 0\n"
			real_instr.WriteString(ins)
		case "mv": // 复制寄存器
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("addi %s, %s, 0\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "not": // 取反
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("xori %s, %s, -1\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "ret": // 从子过程中返回
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = "jalr x0, x1, 0\n"
			real_instr.WriteString(ins)
		case "neg": // 取负 neg rd, rs
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("sub %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "negw": // 取负字 negw rd, rs
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("subw %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "seqz": // 等于零时置位 seqz rd, rs
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("sltiu %s, %s, 1\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "snez": // 不为零时置位 snez rd, rs
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("sltu %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "sltz": // 小于零时置位 sltz rd, rs
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("sltz %s, %s, x0\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "sgtz": // 大于零时置位 sgtz rd, rs
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("sgtz %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "beqz": // 等于零时分支 beqz rs, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("beq %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "bnez": // 不等于零时分支 bnez rs, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("bne %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "blez": // 小于等于零时分支 blez rs, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("bge x0, %s, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "bgez": // 大于等于零时分支 bgez rs, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("bge %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "bltz": // 小于零时分支 bltz rs, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("blt %s, x0, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "bgtz": // 大于零时分支 bgtz rs, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("blt x0, %s, %s\n", code[1], code[2])
			real_instr.WriteString(ins)
		case "bgt": // 大于时分支 bgt rs, rt, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins) // blt rs1 比 rs2 ...
			ins = fmt.Sprintf("blt %s, %s, %s\n", code[2], code[1], code[3])
			real_instr.WriteString(ins)
		case "ble": // 小于等于时分支 ble rs, rt, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("bge %s, %s, %s\n", code[2], code[1], code[3])
			real_instr.WriteString(ins)
		case "bgtu": // 无符号大于时分支 bgtu rs, rt, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("bltu %s, %s, %s\n", code[2], code[1], code[3])
			real_instr.WriteString(ins)
		case "bleu": // 无符号小于等于时分支 bleu rs, rt, offset
			ins := fmt.Sprintf("# %s\n", line)
			real_instr.WriteString(ins)
			ins = fmt.Sprintf("bgeu %s, %s, %s\n", code[2], code[1], code[3])
			real_instr.WriteString(ins)
		case "lb", "lh", "lw", "ld": // 读全局符号 lb rd, symbol (+- 2GB)
			if len(code) == 3 { // different from real: lb rd, imm(rs)
				ins := fmt.Sprintf("# %s\n", line)
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("auipc %s, 0 # %s\n", code[1], code[2])
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("%s %s, 0(%s) # %s\n", code[0], code[1], code[1], code[2])
				real_instr.WriteString(ins)
			} else {
				origin_instr = strings.TrimLeft(origin_instr, " ")
				real_instr.WriteString(origin_instr)
			}
		case "sb", "sh", "sw", "sd": // 写全局符号 sb rd, symbol, rt (+- 2GB)
			_, err := strconv.Atoi(code[2])
			if err != nil { // different from real: sb rd, imm(rs)
				ins := fmt.Sprintf("# %s\n", line)
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("auipc %s, 0 # %s\n", code[3], code[2])
				real_instr.WriteString(ins)
				ins = fmt.Sprintf("%s %s, 0(%s) # %s\n", code[0], code[1], code[3], code[2])
				real_instr.WriteString(ins)
			} else {
				origin_instr = strings.TrimLeft(origin_instr, " ")
				real_instr.WriteString(origin_instr)
			}
		default:
			origin_instr = strings.TrimLeft(origin_instr, " ")
			real_instr.WriteString(origin_instr)
		}
		//os.Exit(0)

	}

	fmt.Println("print real_instr")
	fmt.Println(real_instr.String())
	write2f(real_instr.String(), "tmp.txt")

	// 2pass count label address; check grammar
	fmt.Println("start 2pass.")
	scanner := bufio.NewScanner(strings.NewReader(real_instr.String()))
	scanner.Split(bufio.ScanLines)
	for scanner.Scan() {
		line := strings.Split(scanner.Text(), "#")[0] // get any text before the comment "#" and ignore any text after it
		code = strings.FieldsFunc(line, SplitOn)      // break code into its operation and operands
		if len(code) == 0 {                           // filter out whitespace
			lineCounter++
			continue
		}
		switchOnOp := code[0] // check if first entry of code is a label or an op
		if strings.HasSuffix(switchOnOp, ":") {
			label := strings.TrimSuffix(code[0], ":")
			symbolTable[label] = int64(address) // if label exists in symbolTable, update value to valid address
			if len(code) >= 2 {                 // opcode is in code[1] if code[0] is a label
				switchOnOp = code[1]
				code = code[1:]
			} else {
				continue
			}
		}

		switch switchOnOp {
		case "lui", "auipc", "jal": // Instruction format:  op  rd, imm     or      label: op  rd, imm
			if len(code) != 3 && len(code) != 4 {
				fmt.Println("lui1 Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 4 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
			if len(code) == 4 {
				label := strings.TrimSuffix(code[0], ":")
				_, exists := symbolTable[label]
				if exists {
					symbolTable[label] = int64(address) // if label exists in symbolTable, update value to valid address
				}
			}

		case "beq", "bne", "blt", "bge", "bltu", "bgeu": // Instruction format:  op rs1, rs2, label     or     label: op    rs1,rs2, label
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
			if len(code) == 4 {
				_, exists := symbolTable[code[3]]
				if !exists {
					symbolTable[code[3]] = UNKNOWN // if symbol is not in symbolTable, create entry with flag -1
				}
			}
			if len(code) == 5 {
				label := strings.TrimSuffix(code[0], ":")
				_, exists := symbolTable[code[0]]
				if exists { // check if label exists in symbol table
					symbolTable[label] = int64(address)
				}
				_, exists = symbolTable[code[4]]
				if !exists {
					symbolTable[code[4]] = UNKNOWN
				}
			}

		case "lb", "lh", "lw", "lwu", "lbu", "lhu", "ld": // Instruction format: op rd, imm(rs1)     or      label: op rd, imm(rs1)
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
			if len(code) == 5 {
				label := strings.TrimSuffix(code[0], ":")
				_, exists := symbolTable[code[0]]
				if exists {
					symbolTable[label] = int64(address) // if label exists in symbolTable, update value to valid address
				}
			}

		case "sb", "sh", "sw", "sd": // Instruction format: op rs2, imm(rs1)      or      label: op rs2, imm(rs1)
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
			if len(code) == 5 {
				label := strings.TrimSuffix(code[0], ":")
				_, exists := symbolTable[code[0]]
				if exists {
					symbolTable[label] = int64(address) // if label exists in symbolTable, update value to valid address
				}
			}

		case "addi", "addiw", "slti", "sltiu", "xori", "ori", "andi", "jalr": // Instruction format: op rd, rs1, imm     or      label:  op rd, rs1, imm
			//special form: jalr offset(rs1)?? is real (len(code)==3)
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("addi ori 1 Incorrect argument count on line: ", lineCounter, line)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
			if len(code) == 5 {
				label := strings.TrimSuffix(code[0], ":")
				_, exists := symbolTable[label]
				if exists {
					symbolTable[label] = int64(address)
				}
			}

		case "slli", "slliw", "srli", "srliw", "srai", "sraiw": // Instruction format: op rd, rs1, imm     or      label: rd, rs1, imm
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("slli 1 Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
			if len(code) == 5 {
				label := strings.TrimSuffix(code[0], ":")
				_, exists := symbolTable[label]
				if exists {
					symbolTable[label] = int64(address) // if label exists in symbolTable, update value to valid address
				}
			}

		case "add", "addw", "sub", "subw", "sll", "sllw", "slt", "sltu", "xor", "srl", "srlw", "sra", "sraw", "or", "and": // Instruction format: op rd, rs1, rs2       or      label: op rd, rs1, rs2
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}

		case "ecall", "ebreak": // Instruction format: op       or      label: op
			if len(code) != 1 && len(code) != 2 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 2 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
			// check if imm has a constant definition

		default:
			fmt.Println("1 Syntax Error on line: ", lineCounter, switchOnOp, line)
			os.Exit(0)
		}
		lineCounter++
		address += 4

	}

	for key, element := range symbolTable {
		fmt.Println("Key:", key, "Element:", element)
	}

	// 2.5pass create entry of .rela.text
	fmt.Println("start 2.5pass.")
	address = 0
	lineCounter = 1
	//instructionBuffer := make([]byte, 4)                               // buffer to store 4 bytes
	scanner = bufio.NewScanner(strings.NewReader(real_instr.String())) // stores content from file
	scanner.Split(bufio.ScanLines)
	for scanner.Scan() {
		line := strings.Split(scanner.Text(), "#")[0] // get any text before the comment "#" and ignore any text after it
		code = strings.FieldsFunc(line, SplitOn)      // split into  operation, operands, and/or labels
		if len(code) == 0 {                           // code is whitespace, ignore it
			lineCounter++
			continue
		}
		switchOnOp := code[0] // check if first entry of code is a label or an op
		if strings.HasSuffix(switchOnOp, ":") {
			if len(code) >= 2 { // opcode is in code[1] if code[0] is a label
				switchOnOp = code[1]
				code = code[1:] // reindex array so that op is at index 0
			} else {
				continue
			}
		}
		switch switchOnOp { // switch on operation
		case "auipc":
			if len(code) != 3 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			//auipc reg, 0 # R_RISCV_PCREL_HI20 arg
			if code[2] == "0"  && strings.Contains(scanner.Text(), "R_RISCV_PCREL_HI20") {
			    cs := strings.Split(scanner.Text(), " ")
			    sy := cs[len(cs)-2] // ending with \n
			    idx := slices.Index(strtab, sy+"\x00")
			    fmt.Println("create .rela.text entry for HI20: of", sy, idx, "at line:", lineCounter, "address:", address)
                            var rela Elf64_rela 
                            rela.Offset = uint64(address)//uint64 modified instruction's offset in .text
                            rela.Info = (uint64(idx) << 32) | R_RISCV_PCREL_HI20 //uint64   // sym index and relocation type
                            rela.Addend = int16(0)// int16   // A constant addend used in the reloction calculation 加数
			    fmt.Printf("%+v\n", rela)
			    relatext = append(relatext, rela)
			}
		case "addi": // op rd, rs1, immediate
			if len(code) != 4 {
				fmt.Println("ori 2 Incorrect argument count on line: ", lineCounter)
			}
			//addi reg, reg 0 # R_RISCV_PCREL_LO12_I arg
			if code[3] == "0"  && strings.Contains(scanner.Text(), "R_RISCV_PCREL_LO12_I") {
			    cs := strings.Split(scanner.Text(), " ")
			    sy := cs[len(cs)-2] // ending with \n
			    idx := slices.Index(strtab, sy+"\x00")
			    fmt.Println("create .rela.text entry for LO12_I.: of", sy, idx, "at line:", lineCounter, "address:", address)
                            var rela Elf64_rela 
                            rela.Offset = uint64(address)//uint64 modified instruction's offset in .text
                            rela.Info = (uint64(idx) << 32) | R_RISCV_PCREL_LO12_I //uint64   // sym index and relocation type
                            rela.Addend = int16(0)// int16   // A constant addend used in the reloction calculation 加数
			    fmt.Printf("%+v\n", rela)
			    relatext = append(relatext, rela)
			}

		default:
			//os.Exit(0)
		}
		lineCounter++
		address += 4
	    }








	// reset file to start and reinitialize scanner
	//_, err = file.Seek(0, io.SeekStart)
	//scanner = bufio.NewScanner(file)
	//scanner.Split(bufio.ScanLines)

	// set up write file for machine code comparison
	f, err := os.Create("add.o")       //("asm-tests/asm-u-bin/beq-mc-u.txt")
	ff, err := os.Create("combined.o") //("asm-tests/asm-u-bin/beq-mc-u.txt")
	fff, err := os.Create("caled.o") //("asm-tests/asm-u-bin/beq-mc-u.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	// set up file header table

	//f.Write([]byte{
	//	////// e_ident[16]
	//	0x7F, 0x45, 0x4C, 0x46, // Magic number indicates ELF file (0x7f E L F)
	//	0x02,                                     // ei_class 01 for 32-bit 02 for 64-bit
	//	0x01,                                     // ei_data specify little endian
	//	0x01,                                     // ei_version current elf version
	//	0x09,                                     // ei_osabi target platform, usually set to 0x0 (System V) 9 for FreeBSD
	//	0x00,                                     // ei_abiverison ABI version
	//	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // ei_padding zero padding
	//	//////
	//	0x01, 0x00, // e_type object 1 for ET_REL relocatable file
	//	0xF3, 0x00, // e_machine specify machine 0xf3 for RISC-V
	//	0x01, 0x00, 0x00, 0x00, // e_version specify original elf version
	//	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // e_entry program entry address -- 0 for relocatable file set final entry point by linker
	//	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // e_phoff points to start of program header table --  0 for relocatable file (no program headers)
	//	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // e_shoff points to start of section header table --  no 0 have to be the start of SHT
	//	0x04, 0x00, 0x00, 0x00, // e_flags  // 0x4 for LP64D ABI  (EF_RISCV_FLOAT_ABI_DOUBLE) fit for RV64G
	//	0x40, 0x00, // e_ehsize specify size of header, 52 bytes(0x34) for 32-bit format, 64 bytes(0x40) for 64-bit ?
	//	0x00, 0x00, // e_phentsize size of program header table entry -- 0 for relocatable
	//	0x00, 0x00, // e_phnum contains number of entries in program header table --
	//	0x40, 0x00, // e_shentsize size of section header entry -- 64 for Elf64_shdr
	//	0x00, 0x00, // e_shnum number of entries in the section header table -- no 0 must be actual number of section headers
	//	0x00, 0x00, // e_shstrndx index of the section header table entry that contains the section names -- no 0 must be SHT index for .shstrtab section
	//})

	//f.Write([]byte{0x7F, 0x45, 0x4C, 0x46, // indicates elf file
	// 		0x01,                                     // identifies 32 bit format
	// 		0x01,                                     // specify little endian
	// 		0x01,                                     // current elf version
	// 		0x00,                                     // target platform, usually set to 0x0 (System V)
	// 		0x00,                                     // ABI version
	// 		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // zero padding
	// 		0x01, 0x00, // object relocatable file
	// 		0xF3, 0x00, // specify machine RISC-V
	// 		0x01, 0x00, 0x00, 0x00, // specify original elf version
	// 		0x00, 0x00, 0x00, 0x80, // program entry address
	// 		0x34, 0x00, 0x00, 0x00, // points to start of program header table
	// 		0x00, 0x00, 0x00, 0x00, // points to start of section header table
	// 		0x00, 0x00, 0x00, 0x00, // e_flags
	// 		0x34, 0x00, // specify size of header, 52 bytes for 32-bit format
	// 		0x00, 0x00, // size of program header table entry
	// 		0x00, 0x00, // contains number of entries in program header table
	// 		0x00, 0x00, // size of section header entry
	// 		0x00, 0x00, // number of entries in the section header table
	// 		0x00, 0x00, // index of the section header table entry that contains the section names
	// 	})
	// 3pass trans assembly to binary
	fmt.Println("start 3pass.")
	address = 0
	lineCounter = 1
	instructionBuffer := make([]byte, 4)                               // buffer to store 4 bytes
	scanner = bufio.NewScanner(strings.NewReader(real_instr.String())) // stores content from file
	scanner.Split(bufio.ScanLines)
	for scanner.Scan() {
		line := strings.Split(scanner.Text(), "#")[0] // get any text before the comment "#" and ignore any text after it
		code = strings.FieldsFunc(line, SplitOn)      // split into  operation, operands, and/or labels
		if len(code) == 0 {                           // code is whitespace, ignore it
			lineCounter++
			continue
		}
		switchOnOp := code[0] // check if first entry of code is a label or an op
		if strings.HasSuffix(switchOnOp, ":") {
			if len(code) >= 2 { // opcode is in code[1] if code[0] is a label
				switchOnOp = code[1]
				code = code[1:] // reindex array so that op is at index 0
			} else {
				continue
			}
		}
		switch switchOnOp { // switch on operation
		case "lui", "auipc":
			if len(code) != 3 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			imm, err := isValidImmediate(code[2])
			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			if err != nil {
				fmt.Printf("-Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			if imm < -0x80000 || imm > 0xfffff { // for assembler create lui 0x800 in li
				fmt.Printf("Lui: Error on line %d: Immediate value %d=0x%X out of range (should be between 0x%X and 0x7ffff )\n", lineCounter, imm, imm, -0x80000)
				os.Exit(0)
			}
			if !opFound || !rdFound {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}
			instruction = uint32(imm)<<12 | rd<<7 | op

		case "jal":
			if len(code) != 3 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			label, labelFound := symbolTable[code[2]]
			if !labelFound {
				fmt.Println("Error: label not found", label, code)
				os.Exit(0)
			}
			if !opFound && !rdFound {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}
			label = label - int64(address)
			//instruction = (uint32(label)&0x80000)<<11 | (uint32(label)&0x7FE)<<20 | (uint32(label)&0x400)<<19 | (uint32(label)&0x7F800)<<11 | rd<<7 | op
			instruction = (uint32(label)&0x80000)<<12 | (uint32(label)&0x7FE)<<20 | (uint32(label)&0x800)<<9 | (uint32(label) & 0xFF000) | rd<<7 | op
			fmt.Printf("jarlabel: %d, %b\n", label, uint32(label))
			fmt.Printf("instruction: %b\n", instruction)

		case "beq", "bne", "blt", "bge", "bltu", "bgeu": // op rs1, rs2, imm
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			label, labelFound := symbolTable[code[3]]
			if !labelFound {
				fmt.Printf("On line %d: label not found\n", lineCounter)
				os.Exit(0)
			}
			label = label - int64(address)
			fmt.Println("Label:", label)
			op, opFound := opBin[code[0]]
			rs1, rs1Found := regBin[code[1]]
			rs2, rs2Found := regBin[code[2]]
			if opFound && rs1Found && rs2Found {
				instruction = (uint32(label)&0x800)<<20 | (uint32(label)&0x7E0)<<20 | rs2<<20 | rs1<<15 | (uint32(label)&0x1E)<<7 | (uint32(label)&0x400)>>3 | op
			} else if !rs1Found || !rs2Found {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}

		case "lb", "lh", "lw", "lwu", "lbu", "lhu", "ld": // op rd, imm(rs1)
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			imm, err := isValidImmediate(code[2])
			if err != nil {
				fmt.Printf("!!Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			rs1, rs1Found := regBin[code[3]]
			if opFound && rdFound && rs1Found {
				instruction = uint32(imm)<<20 | rs1<<15 | rd<<7 | op
			} else {
				if !opFound {
					fmt.Println("Invalid operation on line", lineCounter)
					os.Exit(0)
				} else if !rdFound || !rs1Found {
					fmt.Println("Invalid register on line", lineCounter)
					os.Exit(0)
				}
			}

		case "sb", "sh", "sw", "sd": // op rs2, imm(rs1)
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			imm, err := isValidImmediate(code[2])
			if err != nil {
				fmt.Printf("@Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			op, opFound := opBin[code[0]]
			rs2, rs2Found := regBin[code[1]]
			rs1, rs1Found := regBin[code[3]]
			if opFound && rs1Found && rs2Found {
				instruction = (uint32(imm)&0xFE0)<<20 | rs2<<20 | rs1<<15 | (uint32(imm)&0x1F)<<7 | op
			} else if !rs1Found || !rs2Found {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}

		case "addi", "addiw", "slti", "sltiu", "xori", "ori", "andi", "jalr": // op rd, rs1, immediate
			if len(code) != 4 {
				fmt.Println("ori 2 Incorrect argument count on line: ", lineCounter)
			}
			//fmt.Println(line)
			imm, err := isValidImmediate(code[3])
			if err != nil {
				fmt.Printf("$Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			//if imm > 0xfff || imm < -2048 { //0x7ff -0x1000  0xfff for sltiu
			if imm > 2047 || imm < -2048 { //0x7ff -0x800
				fmt.Printf("Error on line %d: Immediate value out of range (should be between -2048=-0x1000 and 4094=0xfff) with %d \n", lineCounter, imm)
				os.Exit(0)
			}
			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			rs1, rs1Found := regBin[code[2]]
			if opFound && rdFound && rs1Found {
				instruction = uint32(imm)<<20 | rs1<<15 | rd<<7 | op
			} else if !rdFound || !rs1Found {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}

		case "slli", "slliw", "srli", "srliw", "srai", "sraiw": // op rd, rs1, immediate(shamt)
			if len(code) != 4 {
				fmt.Println("slli Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			imm, err := isValidImmediate(code[3])
			if err != nil {
				fmt.Printf("!Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			if (switchOnOp == "slliw" || switchOnOp == "srliw" || switchOnOp == "sraiw") && imm > 31 {
				fmt.Printf("Error on line %d: Immediate value out of range (should be between 0 and 31), get %d\n", lineCounter, imm)
				os.Exit(0)
			}
			if imm > 63 {
				fmt.Printf("Error on line %d: Immediate value out of range (should be between 0 and 63), get %d\n", lineCounter, imm)
				os.Exit(0)
			}
			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			rs1, rs1Found := regBin[code[2]]
			if opFound && rdFound && rs1Found {
				instruction = uint32(imm)<<20 | rs1<<15 | rd<<7 | op
			} else if !rdFound || !rs1Found {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}

		case "add", "addw", "sub", "subw", "sll", "sllw", "slt", "sltu", "xor", "srl", "srlw", "sra", "sraw", "or", "and": // op rd, rs1, rs2
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			rs1, rs1Found := regBin[code[2]]
			rs2, rs2Found := regBin[code[3]]
			if opFound && rdFound && rs1Found && rs2Found {
				instruction = rs2<<20 | rs1<<15 | rd<<7 | op // code[0]=op, code[1]=rd, code[2]=rs1 code[3]=rs2
			} else if !rdFound || !rs1Found || !rs2Found {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}

		case "ecall", "ebreak":
			if len(code) != 1 {
				fmt.Println("Too many arguments on line: ", lineCounter)
				os.Exit(0)
			}
			instruction = opBin[code[0]]

		default:
			fmt.Println("2 Syntax Error on line: ", lineCounter, switchOnOp)
			os.Exit(0)
		}
		ins := fmt.Sprintf("%032b", instruction)
		addr := fmt.Sprintf("%08b", address)
		addrd := fmt.Sprintf("%05d", address)
		little_endian_ins := ins[24:32] + " " + ins[16:24] + " " + ins[8:16] + " " + ins[0:8]
		append2f(little_endian_ins+" // Addr: "+addrd+" "+addr+" "+ins+" "+line, "binary_instructions.txt")
		lineCounter++
		address += 4

		//write machine code to file for comparisons
		//f.WriteString(fmt.Sprintf("0x%08x\n", instruction))
		// put instruction into b buffer
		binary.LittleEndian.PutUint32(instructionBuffer, instruction)
		f.Write(instructionBuffer)

	}
	txt, _ := ioutil.ReadFile("add.o")

	elf_header.Shnum = 0x7 //sht0 1shstrtab 2strtab 3symtab 4text 5data 6relatext
	//-------
	buf := new(bytes.Buffer)
	_ = binary.Write(buf, binary.LittleEndian, &elf_header)
	elf_header_bytes := buf.Bytes()
	fmt.Println(elf_header_bytes)

	shstrtab_data := []byte("\x00" + ".shstrtab\x00" + ".strtab\x00" + ".symtab\x00" + ".text\x00" + ".data\x00" + ".rela.text\x00")
	strtab_data := []byte("\x00" + "_start\x00" + "msg\x00")
	//dat := align8([]byte("H\n"))
	dat := align8("H\n")
	fmt.Println("---------###--------:", dat)
	symtab := make([]Elf64_sym, 3)
	symtab[0] = sym0

	sym1.Name = sym0.Name + uint32(len("\x00")) // points to "_start" in .strtab
	sym1.Info = (STB_GLOBAL<<4 | STT_FUNC)      //# uint8 // H4:binding and L4:type
	sym1.Shndx = 4                              //uint16 // section index the symbol in (.text)
	sym1.Size = uint64(len(txt))                //#uint64  for function it's its size
	symtab[1] = sym1

	sym2.Name = sym1.Name + uint32(len("_start\x00")) // points to "msg" in .strtab
	sym2.Info = (STB_GLOBAL<<4 | STT_OBJECT)          //# uint8 // H4:binding and L4:type
	sym2.Shndx = 5                                    //uint16 // section index the symbol in (.data)
	sym2.Size = uint64(len(align8("H\n")))                    //#uint64  for function it's its size
	symtab[2] = sym2
	buf_symtab := new(bytes.Buffer)
	for _, sym := range symtab {
		_ = binary.Write(buf_symtab, binary.LittleEndian, &sym)
	}
	symtab_data := buf_symtab.Bytes()
	fmt.Println(symtab_data)
	fmt.Println("--------#")
	fmt.Println(len(symtab_data))

	relatext_data := []byte("relatext_data")

	//-----------shstrtab h
	sht1.Name = sht0.Name + uint32(len("\x00")) // offset in shstrtab
	fmt.Println("--------###", sht1.Name)
	sht1.Offset = uint64(elf_header.Ehsize + elf_header.Shentsize*elf_header.Shnum) //data offset
	sht1.Size = uint64(len(shstrtab_data))
	buf_sht1 := new(bytes.Buffer)
	_ = binary.Write(buf_sht1, binary.LittleEndian, &sht1)
	sht1_bytes := buf_sht1.Bytes()
	fmt.Println(sht1_bytes)
	fmt.Println("--------#")
	fmt.Println(len(sht1_bytes))

	//-----------strtab h
	sht2.Name = sht1.Name + uint32(len(".shstrtab\x00")) // offset in shstrtab
	sht2.Offset = sht1.Offset + sht1.Size
	sht2.Size = uint64(len(strtab_data))
	buf_sht2 := new(bytes.Buffer)
	_ = binary.Write(buf_sht2, binary.LittleEndian, &sht2)
	sht2_bytes := buf_sht2.Bytes()
	fmt.Println(sht2_bytes)
	fmt.Println("--------#")
	fmt.Println(len(sht2_bytes))

	//-----------symtab h
	sht3.Name = sht2.Name + uint32(len(".strtab\x00")) // offset in shstrtab
	sht3.Offset = sht2.Offset + sht2.Size
	sht3.Size = uint64(len(symtab_data))
	sht3.Link = 0x00000002 // .strtab index 2 in .shstrtab
	buf_sht3 := new(bytes.Buffer)
	_ = binary.Write(buf_sht3, binary.LittleEndian, &sht3)
	sht3_bytes := buf_sht3.Bytes()
	fmt.Println(sht3_bytes)
	fmt.Println("--------#")
	fmt.Println(len(sht3_bytes))

	//-----------text h
	sht4.Name = sht3.Name + uint32(len(".symtab\x00")) // offset in shstrtab
	sht4.Offset = sht3.Offset + sht3.Size
	sht4.Size = uint64(len(txt))
	buf_sht4 := new(bytes.Buffer)
	_ = binary.Write(buf_sht4, binary.LittleEndian, &sht4)
	sht4_bytes := buf_sht4.Bytes()
	fmt.Println(sht4_bytes)
	fmt.Println("--------#")
	fmt.Println(len(sht4_bytes))

	//-----------data h
	sht5.Name = sht4.Name + uint32(len(".text\x00")) // offset in shstrtab
	sht5.Offset = sht4.Offset + sht4.Size
	sht5.Size = uint64(len(dat))
	buf_sht5 := new(bytes.Buffer)
	_ = binary.Write(buf_sht5, binary.LittleEndian, &sht5)
	sht5_bytes := buf_sht5.Bytes()
	fmt.Println(sht5_bytes)
	fmt.Println("--------#")
	fmt.Println(len(sht5_bytes))

	//-----------rela.text h
	sht6.Name = sht5.Name + uint32(len(".data\x00")) // offset in shstrtab
	sht6.Offset = sht5.Offset + sht5.Size
	sht6.Size = uint64(len(relatext_data))
	buf_sht6 := new(bytes.Buffer)
	_ = binary.Write(buf_sht6, binary.LittleEndian, &sht6)
	sht6_bytes := buf_sht6.Bytes()
	fmt.Println(sht6_bytes)
	fmt.Println("--------#")
	fmt.Println(len(sht6_bytes))

	combined := append(elf_header_bytes, sht0_bytes...)
	combined = append(combined, sht1_bytes...)
	combined = append(combined, sht2_bytes...)
	combined = append(combined, sht3_bytes...)
	combined = append(combined, sht4_bytes...)
	combined = append(combined, sht5_bytes...)
	combined = append(combined, sht6_bytes...)
	combined = append(combined, shstrtab_data...)
	combined = append(combined, strtab_data...)
	combined = append(combined, symtab_data...)
	combined = append(combined, txt...)
	combined = append(combined, dat...)
	combined = append(combined, relatext_data...)
	fmt.Println("combined:")
	fmt.Println("----------#")
	fmt.Println(len(txt))
	fmt.Println(combined)
	ff.Write(combined)


	elf_header.Shnum = uint16(len(shstrtab))
	elf_header.Shoff = uint64(elf_header.Ehsize)  // after elf_header, e_shoff points to start of section header table --  no 0 have to be the start of SHT  (e_shnum * e_shentsize = whole table of SHT)
	//elf_header_bytes = byted(elf_header)
	fmt.Println("shts SHT list:", shts, len(shts))
	sec_offset := uint64(0)
	cal_bytes := []byte{}
	cal_bytes = append(cal_bytes, byted(elf_header)...)
	for idx, sht := range shts {
	shtp := &shts[idx]
	shstr := shstrtab[idx]
	switch shstr {
	    case "\x00":
		fmt.Println("SHT Section header of NON XYY name startfrom:", idx, uint32(len(strings.Join(shstrtab[0:idx], ""))), "length:", len(byted(shtp)))
		shtp.Name = uint32(len(strings.Join(shstrtab[0:idx], "")))    // 0 for null
	        shtp.Type = uint32(0)
	        shtp.Flags = uint64(0)
	        shtp.Addr = uint64(0)
	        shtp.Offset = uint64(0)
	        shtp.Size = uint64(0)
		// prepare for next loop sec
		sec_offset = elf_header.Shoff + uint64(elf_header.Shentsize * elf_header.Shnum) + shtp.Size // prepare offset for first section .shstrtab
		fmt.Println("set_offset:::", sec_offset)
	        shtp.Link = uint32(0)
	        shtp.Info = uint32(0)
	        shtp.Addralign = uint64(0)
	        shtp.Entsize = uint64(0)
	        cal_bytes = append(cal_bytes, byted(shtp)...)
	    case ".shstrtab\x00":
	        fmt.Println("SHT Section header of .shstrtab }}}:")
		fmt.Println("SHT Section header of NON YXY name startf:", uint32(len(strings.Join(shstrtab[0:idx], ""))), "length:", len(byted(shtp)))
		shtp.Name = uint32(len(strings.Join(shstrtab[0:idx], "")))    // 0 for null
	        shtp.Type = uint32(3)// sh_type 3_SHT_STRTAB 
	        shtp.Flags = uint64(0)//?
	        shtp.Addr = uint64(0)// ?sh_addr virtual address at exection?
	        shtp.Offset = sec_offset   
	        shtp.Size = uint64(len(strings.Join(shstrtab, "")))   // need calculate
		// prepare for next loop sec
		sec_offset += shtp.Size
		fmt.Println("set_offset:::", sec_offset)
	        shtp.Link = uint32(0) //0
	        shtp.Info = uint32(0) //
	        shtp.Addralign = uint64(1) //?
	        shtp.Entsize = uint64(0)
	        cal_bytes = append(cal_bytes, byted(shtp)...)
	    case ".strtab\x00":
	        fmt.Println("SHT Section header of .strtab }}}:")
		shtp.Name = uint32(len(strings.Join(shstrtab[0:idx], "")))    // 0 for null
	        shtp.Type = uint32(3)
	        shtp.Flags = uint64(0)
	        shtp.Addr = uint64(0)
	        shtp.Offset = sec_offset  
	        shtp.Size = uint64(len(strings.Join(strtab, "")))   // need calculate
		// prepare for next loop sec
		sec_offset += shtp.Size
	        shtp.Link = uint32(0)//0
	        shtp.Info = uint32(0)
	        shtp.Addralign = uint64(1)
	        shtp.Entsize = uint64(0)
	        cal_bytes = append(cal_bytes, byted(shtp)...)
	    case ".symtab\x00":
	        fmt.Println("SHT Section header of .symtab }}}:")
		shtp.Name = uint32(len(strings.Join(shstrtab[0:idx], "")))    // 0 for null
	        shtp.Type = uint32(2)
	        shtp.Flags = uint64(0)
	        shtp.Addr = uint64(0)
	        shtp.Offset = sec_offset // have to be padded with  Addralign value 
	        shtp.Size = uint64(24*len(symtab_))  // need calculate and no need padding
		// prepare for next loop sec
		sec_offset += shtp.Size
	        shtp.Link = uint32(slices.Index(shstrtab, ".strtab\x00")) // link to dependency SHT's index, calculated by (.strtab index in array .shstrtab) 
	        //shtp.Info = uint32(0) // first no-local symbol index in sym list
		for idn, sym := range symtab_{
		    if sym.Info >> 4 == 1{ //local symbols should be in front of global symbols in symtab
	               shtp.Info = uint32(idn) // first no-local symbol index in sym list
		       break
		    }
		}
	        shtp.Addralign = uint64(8)
	        shtp.Entsize = uint64(24)
	        cal_bytes = append(cal_bytes, byted(shtp)...)
	    case ".text\x00":
	        fmt.Println("SHT Section header of .text }}}:")
		shtp.Name = uint32(len(strings.Join(shstrtab[0:idx], "")))    // 0 for null
	        shtp.Type = uint32(SHT_PROGBITS)  // include .text .data .rodata what for define program
	        shtp.Flags = uint64(SHF_ALLOC | SHF_EXECINSTR)
	        shtp.Addr = uint64(0)
	        shtp.Offset = sec_offset  // have to be padded with  Addralign value 
	        shtp.Size = uint64(len(txt))   // need calculate and no need padding
		// prepare for next loop sec
		sec_offset += shtp.Size
	        shtp.Link = uint32(0)//0
	        shtp.Info = uint32(0)
	        shtp.Addralign = uint64(4) // instruction is 32 bits aka aligned by 4 bytes
	        shtp.Entsize = uint64(0)
	        cal_bytes = append(cal_bytes, byted(shtp)...)
	    case ".data\x00":
	        fmt.Println("SHT Section header of .data }}}:")
		shtp.Name = uint32(len(strings.Join(shstrtab[0:idx], "")))    // 0 for null
	        shtp.Type = uint32(SHT_PROGBITS)
	        shtp.Flags = uint64(SHF_ALLOC | SHF_WRITE)
	        shtp.Addr = uint64(0)
	        shtp.Offset = sec_offset  // have to be padded with  Addralign value 
	        shtp.Size = uint64(len(data)) // need calculate and no need padding 
		// prepare for next loop sec
		sec_offset += shtp.Size
	        shtp.Link = uint32(0)//0
	        shtp.Info = uint32(0)
	        shtp.Addralign = uint64(8)
	        shtp.Entsize = uint64(0)
	        cal_bytes = append(cal_bytes, byted(shtp)...)
	    case ".rela.text\x00":
	        fmt.Println("SHT Section header of .rela.text }}}:")
		shtp.Name = uint32(len(strings.Join(shstrtab[0:idx], "")))    // 0 for null
	        shtp.Type = uint32(SHT_RELA)
	        shtp.Flags = uint64(0)  // SHF_INFO_LINK for relocation section
	        shtp.Addr = uint64(0)  // not loaded into memory
	        shtp.Offset = sec_offset  // have to be padded with  Addralign value 
	        shtp.Size = uint64(24*len(relatext))   // need calculate and no need padding
		// prepare for next loop sec
		sec_offset += shtp.Size
	        shtp.Link = uint32(slices.Index(shstrtab, ".symtab\x00")) // link to dependency SHT's index, calculated by (.symtab index in array .shstrtab) 
	        shtp.Info = uint32(slices.Index(shstrtab, ".text\x00")) // must info to be relocation section
	        shtp.Addralign = uint64(8)
	        shtp.Entsize = uint64(24)
	        cal_bytes = append(cal_bytes, byted(shtp)...)
	}
	        fmt.Printf("{{%d, %+v\n", idx, sht)
	}

	for _, shstr := range  shstrtab {
	    switch shstr {
            case "\x00":
	    case ".shstrtab\x00":
	        cal_bytes = append(cal_bytes,[]byte(strings.Join(shstrtab, ""))...)
	        fmt.Println("caled .shstrtab")
	    case ".strtab\x00":
	        cal_bytes = append(cal_bytes,[]byte(strings.Join(strtab, ""))...)
	    case ".symtab\x00":
		for idx, _ := range symtab_{
	        symtab_[idx].Name = uint32(len(strings.Join(strtab[:idx],"")))  //#uint32 // offset in string table
	        cal_bytes = append(cal_bytes, byted(symtab_[idx])...)
	    }
	    case ".text\x00":
	        cal_bytes = append(cal_bytes, txt...)
	    case ".data\x00":
	        cal_bytes = append(cal_bytes, data...)
	    case ".rela.text\x00":
		for _, rela := range relatext {
	        cal_bytes = append(cal_bytes, byted(rela)...)
	    }
	    }
	}

	fff.Write(cal_bytes)

	//fmt.Println("shstrtab string list:", shstrtab, len(shstrtab))
	//for idx, shstr := range shstrtab {
	//		    fmt.Printf("==%d, %+v\n", idx, shstr)
	//}
	//fmt.Println("strtab string list:", strtab, len(strtab))
	//for idx, str := range strtab {
	//		    fmt.Printf("==%d, %+v\n", idx, str)
	//}
	//fmt.Println("symtab_ Elf64_sym list:", symtab_, len(symtab_))
	//for idx, sym := range symtab {
	//		    fmt.Printf("==%d, %+v\n", idx, sym)
	//}
	////text, data byte list
	//fmt.Println("relatext Elf64_rela list:", relatext, len(relatext))
	//for idx, rela := range relatext {
	//		    fmt.Printf("==%d, %+v\n", idx, rela)
	//}
	//fmt.Println("cal_bytes:")
	//fmt.Println(cal_bytes)


	// fmt.Println("shts SHT list:", shts, len(shts))
	// fmt.Println("shstrtab string list:", shstrtab, len(shstrtab))
	// fmt.Println("strtab string list:", strtab, len(strtab))
	// fmt.Println("symtab_ Elf64_sym list:", symtab_, len(symtab_))
	// //text, data byte list
	// fmt.Println("relatext Elf64_rela list:", relatext, len(relatext))
}
