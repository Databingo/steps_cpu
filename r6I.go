package main

// original //https://github.com/dylanobata/rv32-toolchain
import (
	"bufio"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
)

func save_binary_instruction(instr string) {
	if fs, err := os.OpenFile("binary_instructions.txt", os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0666); err == nil {
		_, err = fs.WriteString(instr + "\n")
		//_, err = fs.WriteString("Answer:" + "\n" + RESP + "\n")
		if err != nil {
			panic(err)
		}
		fs.Close()
	}
}

func reserveString(s string) string {
	runes := []rune(s)
	for i, j := 0, len(runes)-1; i < j; i, j = 1+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	return string(runes)
}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

// important think what is separator for Tokens, .and: is not, is the part of a token
func SplitOn(r rune) bool { return r == ',' || r == ' ' || r == '\t' || r == '(' || r == ')' } // delimiters to split on

func isValidImmediate(s string) (int64, error) {
	var imm1, imm2, imm3 int64
	var err1, err2, err3 error
	imm1, err1 = strconv.ParseInt(s, 10, 32) // check if s is a decimal number

	if strings.HasPrefix(s, "0x") {
		imm2, err2 = strconv.ParseInt(s[2:], 16, 64) // check if s is hex
	} else if strings.HasPrefix(s, "-0x") {
		imm2, err2 = strconv.ParseInt(string(s[0])+s[3:], 16, 64) // ignore the "0x" part but include the '-'
	} else if strings.HasPrefix(s, "0b") {
		imm3, err3 = strconv.ParseInt(s[2:], 2, 64) // check if s is binary
	} else if strings.HasPrefix(s, "-0b") {
		imm3, err3 = strconv.ParseInt(string(s[0])+s[3:], 2, 64)
	}

	if err1 != nil && err2 != nil && err3 != nil {
		return 0, errors.New("Invalid immediate value")
	} else if err1 == nil {
		return imm1, nil
	} else if err2 == nil {
		return imm2, nil
	} else {
		return imm3, nil
	}
}

func main() {
	// golang 1.13
	// 0b/0B for binary
	// 0o/0O for octol
	// 0x/0X for hexadecimal
	regBin := map[string]uint32{
		"x0": 0b00000, "zero": 0b00000,
		"x1": 0b00001, "ra": 0b00001,
		"x2": 0b00010, "sp": 0b00010,
		"x3": 0b00011, "gp": 0b00011,
		"x4": 0b00100, "tp": 0b00100,
		"x5": 0b00101, "t0": 0b00101,
		"x6": 0b00110, "t1": 0b00110,
		"x7": 0b00111, "t2": 0b00111,
		"x8": 0b01000, "s0": 0b01000, "fp": 0b01000,
		"x9": 0b01001, "s1": 0b01001,
		"x10": 0b01010, "a0": 0b01010,
		"x11": 0b01011, "a1": 0b01011,
		"x12": 0b01100, "a2": 0b01100,
		"x13": 0b01101, "a3": 0b01101,
		"x14": 0b01110, "a4": 0b01110,
		"x15": 0b01111, "a5": 0b01111,
		"x16": 0b10000, "a6": 0b10000,
		"x17": 0b10001, "a7": 0b10001,
		"x18": 0b10010, "s2": 0b10010,
		"x19": 0b10011, "s3": 0b10011,
		"x20": 0b10100, "s4": 0b10100,
		"x21": 0b10101, "s5": 0b10101,
		"x22": 0b10110, "s6": 0b10110,
		"x23": 0b10111, "s7": 0b10111,
		"x24": 0b11000, "s8": 0b11000,
		"x25": 0b11001, "s9": 0b11001,
		"x26": 0b11010, "s10": 0b11010,
		"x27": 0b11011, "s11": 0b11011,
		"x28": 0b11100, "t3": 0b11100,
		"x29": 0b11101, "t4": 0b11101,
		"x30": 0b11110, "t5": 0b11110,
		"x31": 0b11111, "t6": 0b11111,
	}
	csrBin := map[string]uint32{
		"mvendorid":  0xF11, // MRO mvendorid Vendor ID
		"marchid":    0xF12, // MRO Architecture ID
		"mimpid":     0xF13, // MRO Implementation ID
		"mhartid":    0xF14, // MRO Hardware thread ID
		"mconfigptr": 0xF15, // MRO Pointer to configuration data structure
		"mstatus":    0x300, // MRW Machine status register *
		"misa":       0x301, // MRW ISA and extensions
		"medeleg":    0x302, // MRW Machine exception delegation register
		"mideleg":    0x303, // MRW Machine interrupt delegation register
		"mie":        0x304, // MRW Machine interrupt-enable register *
		"mtvec":      0x305, // MRW Machine trap-handler base address *
		"mcounteren": 0x306, // MRW Machine counter enable
		"mtvt":       0x307, // MRW Machine Trap-Handler vector table base address
		"mstatush":   0x310, // MRW Additional machine status register, RV32 only
		"mscratch":   0x340, // MRW Scratch register for machine trap handlers *
		"mepc":       0x341, // MRW Machine exception program counter *
		"mcause":     0x342, // MRW Machine trap casue *
		"mtval":      0x343, // MRW Machine bad address or instruction *
		"mip":        0x344, // MRW Machine interrupt pending *
		"mtinst":     0x34A, // MRW Machine trap instruction (transformed)
		"mtval2":     0x34B, // MRW Machine bad guset physical address
		"menvcfg":    0x30A, // MRW Machine environment configuration register
		"menvcfgh":   0x31A, // MRW Additional machine env. conf. register, RV32 only
		"mseccfg":    0x747, // MRW Machine security configuration register
		"mseccfgh":   0x757, // MRW Additional machine security conf. register, RV32 only
		"pmpcfg0":    0x3A0, // MRW Physical memory protection configuration.
		"pmpcfg1":    0x3A1, // MRW Physical memory protection configuration, RV32 only.
		"pmpcfg2":    0x3A2, // MRW Physical memory protection configuration.
		"pmpcfg3":    0x3A3, // MRW Physical memory protection configuration.
		"pmpcfg14":   0x3AE,
		"pmpcfg15":   0x3AF,
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
		"lh":  0b00000000000000000001000000000011,
		"lw":  0b00000000000000000010000000000011,
		"lbu": 0b00000000000000000100000000000011,
		"lhu": 0b00000000000000000101000000000011,

		"sb": 0b00000000000000000000000000100011,
		"sh": 0b00000000000000000001000000100011,
		"sw": 0b00000000000000000010000000100011,

		"addi":  0b00000000000000000000000000010011,
		"slti":  0b00000000000000000010000000010011,
		"sltiu": 0b00000000000000000011000000010011,
		"xori":  0b00000000000000000100000000010011,
		"ori":   0b00000000000000000110000000010011,
		"andi":  0b00000000000000000111000000010011,

		"slli": 0b00000000000000000001000000010011,
		"srli": 0b00000000000000000101000000010011,
		"srai": 0b01000000000000000101000000010011,

		"add":  0b00000000000000000000000000110011,
		"sub":  0b01000000000000000000000000110011,
		"sll":  0b00000000000000000001000000110011,
		"slt":  0b00000000000000000010000000110011,
		"sltu": 0b00000000000000000011000000110011,
		"xor":  0b00000000000000000100000000110011,
		"srl":  0b00000000000000000101000000110011,
		"sra":  0b01000000000000000101000000110011,
		"or":   0b00000000000000000110000000110011,
		"and":  0b00000000000000000111000000110011,

		"ecall":  0b00000000000000000000000001110011,
		"ebreak": 0b00000010000000000000000001110011,

		"csrrw":  0b00000000000000000001000001110011, //000000000000_00000_001_00000_1110011 // CSRRW
		"csrrs":  0b00000000000000000010000001110011, //000000000000_00000_010_00000_1110011 // CSRRS
		"csrrc":  0b00000000000000000011000001110011, //000000000000_00000_011_00000_1110011 // CSRRC
		"csrrwi": 0b00000000000000000101000001110011, //000000000000_00000_101_00000_1110011 // CSRRWI
		"csrrsi": 0b00000000000000000110000001110011, //000000000000_00000_110_00000_1110011 // CSRRSI
		"csrrci": 0b00000000000000000111000001110011, //000000000000_00000_111_00000_1110011 // CSRRCI

		"fence":   0b00000000000000000000000000001111, //_0000_0000_0000_00000_000_00000_0001111 // FENCE
		"fence.i": 0b00000000000000000001000000001111, //_0000_0000_0000_00000_001_00000_0001111 // FENCE.I
	}

	if len(os.Args) != 2 {
		fmt.Println("Usage:", os.Args[0], "FILE.s")
	}
	file, err := os.Open(os.Args[1])

	check(err)

	defer file.Close()

	scanner := bufio.NewScanner(file) // stores content from file
	scanner.Split(bufio.ScanLines)

	var code []string
	var instruction uint32
	var address uint32 = 0 // assembly line number
	lineCounter := 1

	symbolTable := make(map[string]int64, 100)
	const UNKNOWN = -1
	//    literalPool := make(map[string]int64, 100)
	for scanner.Scan() { // first pass
		line := strings.Split(scanner.Text(), "#")[0] // get any text before the comment "#" and ignore any text after it
		//------------Lexer-----------
		code = strings.FieldsFunc(line, SplitOn) // break code into its operation and operands
		//fmt.Println(code)
		if len(code) == 0 { // filter out whitespace
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
		if strings.HasPrefix(switchOnOp, ".") {
		    fmt.Println(switchOnOp)
		}

		//------------Parser?-----------
		fmt.Println("Parser see:", switchOnOp)
		switch switchOnOp {
		case "lui", "auipc", "jal": // Instruction format:  op  rd, imm     or      label: op  rd, imm
			if len(code) != 3 && len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
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

		case "lb", "lh", "lw", "lbu", "lhu": // Instruction format: op rd, imm(rs1)     or      label: op rd, imm(rs1)
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

		case "sb", "sh", "sw": // Instruction format: op rs2, imm(rs1)      or      label: op rs2, imm(rs1)
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

		case "addi", "slti", "sltiu", "xori", "ori", "andi", "jalr": // Instruction format: op rd, rs1, imm     or      label:  op rd, rs1, imm
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
				_, exists := symbolTable[label]
				if exists {
					symbolTable[label] = int64(address)
				}
			}

		case "slli", "srli", "srai": // Instruction format: op rd, rs1, imm     or      label: rd, rs1, imm
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
				_, exists := symbolTable[label]
				if exists {
					symbolTable[label] = int64(address) // if label exists in symbolTable, update value to valid address
				}
			}

		case "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and": // Instruction format: op rd, rs1, rs2       or      label: op rd, rs1, rs2
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
		case "csrrw", "csrrs", "csrrc": // Instruction format: op, rd, csr, rs1    or    label:  op, rd, csr, rs1
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
		case "csrrwi", "csrrsi", "csrrci": // Instruction format: op, rd, csr, imm    or    label:  op, rd, csr, imm
			if len(code) != 4 && len(code) != 5 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			if len(code) == 5 && !strings.HasSuffix(code[0], ":") && len(code[0]) > 1 {
				fmt.Printf("%s not a valid label\n", code[0])
				os.Exit(0)
			}
		case ".section": 
			fmt.Println(switchOnOp, lineCounter)

		default:
			fmt.Println(switchOnOp, "Syntax Error on line: ", lineCounter)
			os.Exit(0)
		}
		lineCounter++
		address += 4

	}

	for key, element := range symbolTable {
		fmt.Println("Key:", key, "Element:", element)
	}
	// reset file to start and reinitialize scanner
	_, err = file.Seek(0, io.SeekStart) // (offset, whence)
	scanner = bufio.NewScanner(file)
	scanner.Split(bufio.ScanLines)

	// set up write file for machine code comparison
	f, err := os.Create("add.o") //("asm-tests/asm-u-bin/beq-mc-u.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	// set up file header table
	//f.Write([]byte{0x7F, 0x45, 0x4C, 0x46, // indicates elf file
	//	//0x01,                                     // identifies 32 bit format
	//	0x02,                                     // identifies 64 bit format
	//	0x01,                                     // specify little endian
	//	0x01,                                     // current elf version
	//	0x00,                                     // target platform, usually set to 0x0 (System V)
	//	0x00,                                     // ABI version
	//	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // zero padding
	//	0x01, 0x00, // object relocatable file
	//	0xF3, 0x00, // specify machine RISC-V
	//	0x01, 0x00, 0x00, 0x00, // specify original elf version
	//	//0x00, 0x00, 0x00, 0x80, // program entry address
	//	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, // program entry address
	//	//0x34, 0x00, 0x00, 0x00, // points to start of program header table
	//	0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,// points to start of program header table
	//	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,// points to start of section header table
	//	0x00, 0x00, 0x00, 0x00, // e_flags
	//	//0x34, 0x00, // specify size of header, 52 bytes for 32-bit format
	//	0x40, 0x00, // specify size of header, 64 bytes for 64-bit format
	//	0x00, 0x00, // size of program header table entry
	//	0x00, 0x00, // contains number of entries in program header table
	//	0x00, 0x00, // size of section header entry
	//	0x00, 0x00, // number of entries in the section header table
	//	0x00, 0x00, // index of the section header table entry that contains the section names
	//})

        //https://scratchpad.avikdas.com/elf-explanation/elf-explanation.html
	// ELF File Structure
	//ELF header 64Byte
	//SHT 0 64Byte .text
	//SHT 1 64Byte .shstrtab
	//SHT 2 64Byte .data
	//...

        // ELF header (64 Bytes for 64-bit format) (Little endian)
	f.Write([]byte{
		0x7F, 0x45, 0x4C, 0x46,                   // ELF magic number (delete(0x7f)E(0x45)L(0x4c)F(0x46) in ascii)
		0x02,                                     // EI_CLASS: 64-bit Architecture ELF64
		0x01,                                     // EI_DATA: little endian, 2's complement.
		0x01,                                     // EI_VERSION: ELF version 1 
		0x00,                                     // EI_OSABI: System V "None", evquivalent to UNIX - System - V, default version
		0x00,                                     // EI_ABIVERSION (usually 0 for System V)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // EI_PAD: padding (for consistence of ELF header size to 16 bytes) and for future compatibility
		0x01, 0x00, // e_type: ET_REL (relocatable file, means linkable to be executable or a shared file such as .so); 0x0200 means Static executable
		0xF3, 0x00, // e_machine: RISC-V (two bytes, 0xF300 for RISC-V, 0x3e00 for AMD X86-64)
		0x01, 0x00, 0x00, 0x00, // e_version: original ELF version, current version
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, // e_entry: entry point address (0x0 for relocatable files) transfer control when starting process, needed for executables 0x80000000
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // e_phoff: program header table offset (0 for relocatable) start of program heasers
		0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // e_shoff: section header table offset (64 bytes from start, just after this 64-bit ELF header)start of section heasers
		0x00, 0x00, 0x00, 0x00, // e_flags none by the ELF specifications by now
		0x40, 0x00, // e_ehsize: ELF header size (64 bytes) (for 32-bit format it's 0x40 aka 52 Bytes)
		0x00, 0x00, // e_phentsize: program header entry size (0 for relocatable because relocatable don't have a Program Header Table), for 64-bit architectures is 0x38 aka 56 bytes
		0x00, 0x00, // e_phnum: number of entries in program header table (0 for relocatable)
		0x40, 0x00, // e_shentsize: section header entry size (64 bytes for 64-bit)
		0x03, 0x00, // e_shnum: number of entries in section header table (e.g., .text, .shstrtab, null) (.shstrtab Section Header String Table holds section names)
		0x00, 0x00, // e_shstrndx: index of the section header string table, means the second(0,1...) entry in Section Header Table is .shstrtab section
	})

        // Section Header Table (64 Bytes for 64-bit format) (Little endian)

        // sh of .shstrtab
	f.Write([]byte{
		0x01, 0x00, 0x00, 0x00,                                     // name offset in .shstrtab as null-terminated ASCII string Offset into the section header string table (index into .shstrtab)
		0x03, 0x00, 0x00, 0x00,                                     // type PROGBITS                                            Type of the section (e.g., SHT_PROGBITS, SHT_STRTAB)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // flags allocatable + executabel                           Section flags (e.g., SHF_ALLOC)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // address                                                  Virtual address of the section (set to 0x0 for relocatable files)
		0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // offset, the resides address of this section in ELF file  File offset where section's data begins
		0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // size, how many bytes the section takes up in this file   Size of the section data
		0x00, 0x00, 0x00, 0x00,                                     // link, links to another section header by index           Link to another section (e.g., for symbol tables)
		0x00, 0x00, 0x00, 0x00,                                     // info, extra infomation                                   Additional info (depends on section type)
		0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // address alignment constraint in bytes                    Section alignment in memory (usually power of 2)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // entry size                                               Size of each entry in the section, or 0 if no entries
	}) 

        // sh of .text
	f.Write([]byte{
		0x04, 0x00, 0x00, 0x00,                                     // name offset in .shstrtab as null-terminated ASCII string Offset into the section header string table (index into .shstrtab)
		0x01, 0x00, 0x00, 0x00,                                     // type PROGBITS                                            Type of the section (e.g., SHT_PROGBITS, SHT_STRTAB)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // flags allocatable + executabel                           Section flags (e.g., SHF_ALLOC)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // address                                                  Virtual address of the section (set to 0x0 for relocatable files)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // offset, the resides address of this section in ELF file  File offset where section's data begins
		0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // size, how many bytes the section takes up in this file   Size of the section data
		0x00, 0x00, 0x00, 0x00,                                     // link, links to another section header by index           Link to another section (e.g., for symbol tables)
		0x00, 0x00, 0x00, 0x00,                                     // info, extra infomation                                   Additional info (depends on section type)
		0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // address alignment constraint in bytes                    Section alignment in memory (usually power of 2)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // entry size                                               Size of each entry in the section, or 0 if no entries
	}) 
      
        // sh of .data
	f.Write([]byte{
		0x08, 0x00, 0x00, 0x00,                                     // name offset in .shstrtab as null-terminated ASCII string Offset into the section header string table (index into .shstrtab)
		0x01, 0x00, 0x00, 0x00,                                     // type PROGBITS                                            Type of the section (e.g., SHT_PROGBITS, SHT_STRTAB)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // flags allocatable + executabel                           Section flags (e.g., SHF_ALLOC)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // address                                                  Virtual address of the section (set to 0x0 for relocatable files)
		0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // offset, the resides address of this section in ELF file  File offset where section's data begins
		0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // size, how many bytes the section takes up in this file   Size of the section data
		0x00, 0x00, 0x00, 0x00,                                     // link, links to another section header by index           Link to another section (e.g., for symbol tables)
		0x00, 0x00, 0x00, 0x00,                                     // info, extra infomation                                   Additional info (depends on section type)
		0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // address alignment constraint in bytes                    Section alignment in memory (usually power of 2)
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,             // entry size                                               Size of each entry in the section, or 0 if no entries
	}) 

// .shstrtab section content; .text .data .shstrtab
f.Write([]byte{
    0x00, 0x45, 0x45, 0x00,     // Null terminator for the string table + ".text" string
    0x46, 0x46, 0x46, 0x00,     // ".data" string
    0x4C, 0x4C, 0x4C, 0x00,     // ".shstrtab" string
})

// .text section content: machine code for the instructions
f.Write([]byte{
    0x00, 0x00, 0x00, 0x13, // addi a0, x0, 5
    0x01, 0x00, 0x00, 0x13, // addi a0, a0, 1
})

// .data section content: string "Hello, world!"
f.Write([]byte{
    0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x2C, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64, 0x21, 0x00, 0x00,
})











	// second pass
	//------------Generater-----------
	address = 0
	lineCounter = 1
	instructionBuffer := make([]byte, 4) // buffer to store 4 bytes
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
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			if imm > 1048575 || imm < 0 {
				fmt.Printf("Error on line %d: Immediate value out of range (should be between 0 and 1048575)\n", lineCounter)
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
				fmt.Println("Error: label not found")
				os.Exit(0)
			}
			if !opFound && !rdFound {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}
			label = label - int64(address)
			instruction = (uint32(label)&0x80000)<<11 | (uint32(label)&0x7FE)<<20 | (uint32(label)&0x400)<<19 | (uint32(label)&0x7F800)<<11 | rd<<7 | op

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

		case "lb", "lh", "lw", "lbu", "lhu": // op rd, imm(rs1)
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			imm, err := isValidImmediate(code[2])
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
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

		case "sb", "sh", "sw": // op rs2, imm(rs1)
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			imm, err := isValidImmediate(code[2])
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
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

		case "addi", "slti", "sltiu", "xori", "ori", "andi", "jalr": // op rd, rs1, immediate
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			imm, err := isValidImmediate(code[3])
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			if imm > 2047 || imm < -2048 {
				fmt.Printf("Error on line %d: Immediate value out of range (should be between -2048 and 2047)\n", lineCounter)
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

		case "slli", "srli", "srai": // op rd, rs1, immediate
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			imm, err := isValidImmediate(code[3])
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			if imm > 31 {
				fmt.Printf("Error on line %d: Immediate value out of range (should be between 0 and 31)")
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

		case "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and": // op rd, rs1, rs2
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
		case "csrrw", "csrrs", "csrrc": // op, rd, csr, rs1
			if len(code) != 4 {
				fmt.Println("Incorrec argument count on line: ", lineCounter)
				os.Exit(0)
			}
			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			csr, csrFound := csrBin[code[2]]
			rs1, rs1Found := regBin[code[3]]
			fmt.Println(code)
			fmt.Println(opFound, csrFound, rdFound, rs1Found)
			if opFound && csrFound && rdFound && rs1Found {
				instruction = csr<<20 | rs1<<15 | rd<<7 | op
			} else if !csrFound || !rdFound || !rs1Found {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}
		case "csrrwi", "csrrsi", "csrrci": // op, rd, csr, imm
			if len(code) != 4 {
				fmt.Println("Incorrec argument count on line: ", lineCounter)
				os.Exit(0)
			}

			imm, err := isValidImmediate(code[3])
			//fmt.Println("imm:", imm)
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			if imm > 31 {
				fmt.Printf("Error on line %d: Immediate value out of range (shoud be between 0 and 31)")
				os.Exit(0)
			}

			zimm := 0x00000000 | uint32(imm)
			//fmt.Println("zimm:", zimm)

			op, opFound := opBin[code[0]]
			rd, rdFound := regBin[code[1]]
			csr, csrFound := csrBin[code[2]]
			//fmt.Println(opFound, csrFound, rdFound, zimm)
			if opFound && csrFound && rdFound {
				instruction = csr<<20 | zimm<<15 | rd<<7 | op
			} else if !csrFound || !rdFound {
				fmt.Println("Invalid register on line", lineCounter)
				os.Exit(0)
			}
		case ".section": 
		        instruction = 0x88888888
			fmt.Println("p2", switchOnOp, lineCounter)

		default:
			fmt.Println("Syntax Error on line: ", lineCounter)
			os.Exit(0)
		}
		//fmt.Printf("Address: 0x%08x     Line: %d     Instruction:  0x%08x\n", address, lineCounter, instruction)
		//fmt.Printf("Address: 0x%08x     Line: %d     Instruction:  0x%08x, %032b\n", address, lineCounter, instruction, instruction)
		fmt.Printf("Address: 0x%08x     Line: %d     Instruction:  0x%08x, %032b, %s\n", address, lineCounter, instruction, instruction, code)
		ins := fmt.Sprintf("%032b", instruction)
		addr := fmt.Sprintf("%08b", address)
		addrd := fmt.Sprintf("%03d", address)
		little_endian_ins := ins[24:32] + " " + ins[16:24] + " " + ins[8:16] + " " + ins[0:8]
		save_binary_instruction(little_endian_ins + " // Addr: " + addrd + " " + addr + " " + ins + " " + line)
		lineCounter++
		address += 4

		//write machine code to file for comparisons
		//f.WriteString(fmt.Sprintf("0x%08x\n", instruction))
		// put instruction into b buffer
		binary.LittleEndian.PutUint32(instructionBuffer, instruction)
		f.Write(instructionBuffer)
	}
}

// target rv64 add
//1. instructio "csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci", "fence", "fence.i"
//2. pseudo instruction support
//3. assembler directive support

//Name  Description
//.alig  nAlign next data item on specified byte boundary (0=byte, 1=half, 2=word, 3=double)
//.ascii  Store the string in the Data segment but do not add null terminator
//.asciz  Store the string in the Data segment and add null terminator
//.byte  Store the listed value(s) as 8 bit bytes
//.data  Subsequent items stored in Data segment at next available address
//.double  Store the listed value(s) as double precision floating point
//.end_macro  End macro definition. See .macro
//.eqv  Substitute second operand for first. First operand is symbol, second operand is expression (like #define)
//.extern  Declare the listed label and byte length to be a global data field
//.floating  Store the listed value(s) as single precision floating point
//.globl  Declare the listed label(s) as global to enable referencing from other files
//.half  Store the listed value(s) as 16 bit halfwords on halfword boundary
//.include  Insert the contents of the specified file. Put filename in quotes.
//.macro  Begin macro definition. See .end_macro
//.section  Allows specifying sections without .text or .data directives. Included for gcc comparability
//.space  Reserve the next specified number of bytes in Data segment
//.strings  Alias for .asciz
//.text  Subsequent items (instructions) stored in Text segment at next available address
//.word  Store the listed value(s) as 32 bit words on word boundary
