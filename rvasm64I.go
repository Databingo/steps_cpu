package main

import (
	"bufio"
	"encoding/binary"
	"errors"
	"fmt"
	//"io"
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

func SplitOn(r rune) bool { return r == ',' || r == ' ' || r == '\t' || r == '(' || r == ')' } // delimiters to split on

func isValidImmediate(s string) (int64, error) {
	var imm1, imm2, imm3 int64
	//var err1, err2, err3 error
	var err1 = errors.New("error_init")
	var err2 = errors.New("error_init")
	var err3 = errors.New("error_init")
	imm1, err1 = strconv.ParseInt(s, 10, 32) // check if s is a decimal number

	if strings.HasPrefix(s, "0x") {
		imm2, err2 = strconv.ParseInt(s[2:], 16, 64) // check if s is hex
	} else if strings.HasPrefix(s, "-0x") {
		imm2, err2 = strconv.ParseInt(string(s[0])+s[3:], 16, 64) // ignore the "0x" part but include the '-'
		if imm2 == 0 {
			imm2, err2 = strconv.ParseInt(string(s[0])+"1"+strings.Repeat("0", len(s[3:])*4), 2, 64)
			//fmt.Println("imm2:", string(s[0])+"1"+strings.Repeat("0", len(s[3:])*4))
		}

	} else if strings.HasPrefix(s, "0b") {
		imm3, err3 = strconv.ParseInt(s[2:], 2, 64) // check if s is binary
	} else if strings.HasPrefix(s, "-0b") {
		imm3, err3 = strconv.ParseInt(string(s[0])+s[3:], 2, 64)
		//fmt.Println("s:", s)
		//fmt.Println("imm3:", imm3)
		//fmt.Println("lens:", len(s))
		// -00000000000 = 100000000000 = 1100000000000  = -2048
		// -000000000000 = 1000000000000 = 11000000000000  = -4096
		//if imm3 == 0 && len(s) >= 14 {
		//    imm3, err3 = strconv.ParseInt(string(s[0])+"1"+s[3:], 2, 64)
		//}
		if imm3 == 0 {
			imm3, err3 = strconv.ParseInt(string(s[0])+"1"+s[3:], 2, 64)
			//fmt.Println("imm3:", string(s[0])+"1"+s[3:])
		}
		//fmt.Println("imm3:", imm3)
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
	}

	if len(os.Args) != 2 {
		fmt.Println("Usage:", os.Args[0], "FILE.s")
	}
	file, err := os.Open(os.Args[1])
	check(err)
	defer file.Close()

	scanner0 := bufio.NewScanner(file) // stores content from file
	scanner0.Split(bufio.ScanLines)

	var code []string
	var instruction uint32
	var address uint32 = 0
	lineCounter := 1

	symbolTable := make(map[string]int64, 100)
	const UNKNOWN = -1
	//    literalPool := make(map[string]int64, 100)

	//writer := bufio.NewWriter()
	var real_instr strings.Builder




	// zero pass
	// translate pseudo-instruction to real-instruction
	for scanner0.Scan() {
	        origin_instr := scanner0.Text() + "\n"
		line := strings.Split(scanner0.Text(), "#")[0]
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
			//fmt.Printf("lable:%s\n", label)
			//symbolTable[label] = int64(address)
			if len(code) >= 2 {
				switchOnOp = code[1]
				code = code[1:]
			} else {
				continue
			}
		}
		switch switchOnOp {
		case "li":
			if len(code) != 3 && len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			imm, err := isValidImmediate(code[2])
			//op, opFound := opBin[code[0]]
			//rd, rdFound := regBin[code[1]]
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			fmt.Printf("line %d, imm: 0x%X=0b%b=%d\n", lineCounter, imm, imm, imm)
			if imm > 0x7fffffffffffffff || imm < -0x1000000000000000 {
				fmt.Printf("Li: Error on line %d: Immediate value %d=0x%X out of range (should be between 0x%X and 0x7ffff )\n", lineCounter, imm, imm, -0x1000000000000000)
				os.Exit(0)
			}
			if label != ":" {
				fmt.Printf("%s: \n", label)
				real_instr.WriteString(label+":\n")
			}
			//if -0x1000 < imm && imm <= 0x7ff {
			//    instr := "addi " + code[1] + ", x0, " + code[2] + "\n"
			//	fmt.Println(instr)
			//	real_instr.WriteString(instr)
			//}

			load_32 := func(imm int64) int {
				sign_bit := imm >> 63 & 1
				l12 := imm & 0xfff // 12 bits
				l12_sign_bit := l12 >> 11 & 1
				fmt.Printf("l12: 0b%b\n", l12)
				//fmt.Printf("l_sign: 0b%b\n", sign_bit)
				h20 := imm >> 12
				if l12_sign_bit == 1 {
				        //h20 = h20 + 1
					//l12 = (0x1000 - l12)
					if sign_bit ==1{h20 = h20 + 1 
					   l12 = (0x1000 - l12) } 
					if sign_bit ==0{h20 = h20 + 1 
					   l12 = -(0x1000 - l12) }
				}
				//w32 := h20 + l12
				//fmt.Printf("h20: 0b%b, 0x%x, -0x%x\n", h20, h20, ^h20+1)
				//fmt.Printf("w32: 0b%b, 0x%x, -0x%x\n", w32, w32, ^w32+1)
				if h20 != 0 {
				    ins := fmt.Sprintf("lui %s, %#x\n", code[1], h20)
				        real_instr.WriteString(ins)
				}
				if l12 != 0 {
				    ins := fmt.Sprintf("addi %s, %s, %#x\n", code[1], code[1], l12)
				        real_instr.WriteString(ins)
				}
				return 0
			}
			//-----
				h_imm := imm >> 32
				if h_imm != 0 {
				load_32(h_imm)
				ins := fmt.Sprintf("slli x31, x31, 32\naddi x30, x31, 0\n")
				        real_instr.WriteString(ins)
				    }
				l_imm := imm << 32 >> 32
				if l_imm != 0 {
				load_32(l_imm)
				    }
				    //fmt.Println(l_imm, h_imm)
				    if l_imm !=0 && h_imm !=0 {
					ins := fmt.Sprintf("add x31, x31, x30\n")
				        real_instr.WriteString(ins)
				    }
				    //continue


			//----
			//if 0x7ff < imm && imm <= 0x7fffffff || -0x100000000 < imm && imm <= -0x1000 {
			//	load_32(imm)
			//}

			////----
			//if -0x8000000000000000 < imm && imm <= -0x100000000 || 0x7fffffff < imm && imm <= 0x7fffffffffffffff {
			//	h_imm := imm >> 32
			//	load_32(h_imm)
			//	ins := fmt.Sprintf("slli x31, x31, 32\naddi x30, x31, 0\n")
			//	        real_instr.WriteString(ins)
			//	l_imm := imm << 32 >> 32
			//	load_32(l_imm)
			//	ins = fmt.Sprintf("add x31, x31, x30\n")
			//	        real_instr.WriteString(ins)
			//}
			//if !opFound || !rdFound {
			//	fmt.Println("Invalid register on line", lineCounter)
			//	os.Exit(0)
			//}
			//instruction = uint32(imm)<<12 | rd<<7 | op

		default:
			real_instr.WriteString(origin_instr)
			//fmt.Println("Syntax Error on line: ", lineCounter)
			//os.Exit(0)
		}
		lineCounter++
		address += 4
		//os.Exit(0)

	}
	
	fmt.Println("print real_instr")
	fmt.Println(real_instr.String())
	fmt.Println("print real_instr finished")
	fmt.Println("zero pass fininshed.")

	scanner := bufio.NewScanner(strings.NewReader(real_instr.String())) // stores content from file
	scanner.Split(bufio.ScanLines)
	// first pass
	fmt.Println("start first pass.")
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

		case "addi", "addiw", "slti", "sltiu", "xori", "ori", "andi", "jalr": // Instruction format: op rd, rs1, imm     or      label:  op rd, rs1, imm
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

		case "slli", "slliw", "srli", "srliw", "srai", "sraiw": // Instruction format: op rd, rs1, imm     or      label: rd, rs1, imm
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

		default:
			fmt.Println("1 Syntax Error on line: ", lineCounter, switchOnOp)
			os.Exit(0)
		}
		lineCounter++
		address += 4

	}

	for key, element := range symbolTable {
		fmt.Println("Key:", key, "Element:", element)
	}
	// reset file to start and reinitialize scanner
	//_, err = file.Seek(0, io.SeekStart)
	//scanner = bufio.NewScanner(file)
	//scanner.Split(bufio.ScanLines)

	// set up write file for machine code comparison
	f, err := os.Create("add.o") //("asm-tests/asm-u-bin/beq-mc-u.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	// set up file header table
	f.Write([]byte{0x7F, 0x45, 0x4C, 0x46, // indicates elf file
		0x01,                                     // identifies 32 bit format
		0x01,                                     // specify little endian
		0x01,                                     // current elf version
		0x00,                                     // target platform, usually set to 0x0 (System V)
		0x00,                                     // ABI version
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // zero padding
		0x01, 0x00, // object relocatable file
		0xF3, 0x00, // specify machine RISC-V
		0x01, 0x00, 0x00, 0x00, // specify original elf version
		0x00, 0x00, 0x00, 0x80, // program entry address
		0x34, 0x00, 0x00, 0x00, // points to start of program header table
		0x00, 0x00, 0x00, 0x00, // points to start of section header table
		0x00, 0x00, 0x00, 0x00, // e_flags
		0x34, 0x00, // specify size of header, 52 bytes for 32-bit format
		0x00, 0x00, // size of program header table entry
		0x00, 0x00, // contains number of entries in program header table
		0x00, 0x00, // size of section header entry
		0x00, 0x00, // number of entries in the section header table
		0x00, 0x00, // index of the section header table entry that contains the section names
	})

	scanner = bufio.NewScanner(strings.NewReader(real_instr.String())) // stores content from file
	scanner.Split(bufio.ScanLines)
	// second pass
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
			fmt.Printf("imm: 0x%X, 0b%b\n", imm, imm)
			//if imm > 1048575 || imm < 0 {
			if imm > 0x7ffff || imm < -0x100000 {
				fmt.Printf("Lui: Error on line %d: Immediate value %d=0x%X out of range (should be between 0x%X and 0x7ffff )\n", lineCounter, imm, imm, -0x100000)
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

		case "addi", "addiw", "slti", "sltiu", "xori", "ori", "andi", "jalr": // op rd, rs1, immediate
			if len(code) != 4 {
				fmt.Println("Incorrect argument count on line: ", lineCounter)
			}
			imm, err := isValidImmediate(code[3])
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
				os.Exit(0)
			}
			if imm > 2047 || imm < -2048 { //0x7ff -0x1000
				fmt.Printf("Error on line %d: Immediate value out of range (should be between -2048 and 2047) with %d \n", lineCounter, imm)
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
				fmt.Println("Incorrect argument count on line: ", lineCounter)
				os.Exit(0)
			}
			imm, err := isValidImmediate(code[3])
			if err != nil {
				fmt.Printf("Error on line %d: %s\n", lineCounter, err)
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
				fmt.Printf("imm: %06b\n", imm)
				fmt.Printf("op: %b\n", op)
				fmt.Printf("%032b\n", instruction)
				fmt.Printf("000000 %06b %05b 101 %05b 0010011\n", imm, rs1, rd)
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

		default:
			fmt.Println("2 Syntax Error on line: ", lineCounter, switchOnOp)
			os.Exit(0)
		}
		//fmt.Printf("Address: 0x%08x     Line: %d     Instruction:  0x%08x\n", address, lineCounter, instruction)
		fmt.Printf("Address: 0x%08x     Line: %d     Instruction:  0x%08x, %032b\n", address, lineCounter, instruction, instruction)
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
