
package main

import (
	"bytes"
	"encoding/binary"
	"log"
	"os"
)

const (
	EI_CLASS             = 4
	EI_DATA              = 5
	EI_VERSION           = 6
	EI_OSABI             = 7
	ELFCLASS64           = 2
	ELFDATA2LSB          = 1
	EV_CURRENT           = 1
	ELFOSABI_FREEBSD     = 9
	ET_REL               = 1
	EM_RISCV             = 243
	SHT_NULL             = 0
	SHT_PROGBITS         = 1
	SHT_SYMTAB           = 2
	SHT_STRTAB           = 3
	SHT_RELA             = 4
	SHF_ALLOC            = 2
	SHF_EXECINSTR        = 4
	SHF_WRITE            = 1
	STB_LOCAL            = 0
	STB_GLOBAL           = 1
	STT_NOTYPE           = 0
	STT_FILE             = 4
	STT_FUNC             = 2
	STT_SECTION          = 3
	SHN_ABS              = 0xFFF1
	R_RISCV_PCREL_HI20   = 23
	R_RISCV_PCREL_LO12_I = 24
)

type Elf64_Ehdr struct {
	E_ident     [16]byte
	E_type      uint16
	E_machine   uint16
	E_version   uint32
	E_entry     uint64
	E_phoff     uint64
	E_shoff     uint64
	E_flags     uint32
	E_ehsize    uint16
	E_phentsize uint16
	E_phnum     uint16
	E_shentsize uint16
	E_shnum     uint16
	E_shstrndx  uint16
}

type Elf64_Shdr struct {
	Sh_name      uint32
	Sh_type      uint32
	Sh_flags     uint64
	Sh_addr      uint64
	Sh_offset    uint64
	Sh_size      uint64
	Sh_link      uint32
	Sh_info      uint32
	Sh_addralign uint64
	Sh_entsize   uint64
}

type Elf64_Sym struct {
	St_name  uint32
	St_info  byte
	St_other byte
	St_shndx uint16
	St_value uint64
	St_size  uint64
}

type Elf64_Rela struct {
	R_offset uint64
	R_info   uint64
	R_addend int64
}

func Elf64_R_Info(symIdx, typ uint64) uint64 {
	return (symIdx << 32) | typ
}

func main() {
	textData := []byte{
		0x17, 0x05, 0x00, 0x00,
		0x13, 0x05, 0x15, 0x00,
		0x13, 0x05, 0x10, 0x00,
		0x13, 0x06, 0x10, 0x00,
		0x13, 0x08, 0x40, 0x00,
		0x73, 0x00, 0x00, 0x00,
		0x13, 0x05, 0x00, 0x00,
		0x13, 0x08, 0x10, 0x00,
		0x73, 0x00, 0x00, 0x00,
	}
	dataData := []byte{'A'}
	shstrtabData := []byte("\x00.text\x00.data\x00.shstrtab\x00.symtab\x00.strtab\x00.rela.text\x00")
	strtabData := []byte("\x00hello.s\x00_start\x00char_to_print\x00")

	textSectIdx := uint16(1)
	dataSectIdx := uint16(2)
	symtab := []Elf64_Sym{
		{},
		{St_name: 1, St_info: (STB_LOCAL << 4) | STT_FILE, St_shndx: SHN_ABS},
		{St_info: (STB_LOCAL << 4) | STT_SECTION, St_shndx: textSectIdx},
		{St_info: (STB_LOCAL << 4) | STT_SECTION, St_shndx: dataSectIdx},
		{St_name: 10, St_info: (STB_GLOBAL << 4) | STT_FUNC, St_shndx: textSectIdx, St_value: 0, St_size: uint64(len(textData))},
		{St_name: 17, St_info: (STB_GLOBAL << 4) | STT_NOTYPE, St_shndx: dataSectIdx, St_value: 0, St_size: 1},
	}
	symtabBuf := new(bytes.Buffer)
	binary.Write(symtabBuf, binary.LittleEndian, &symtab)
	symtabData := symtabBuf.Bytes()

	rela_text := []Elf64_Rela{
		{R_offset: 0x0, R_info: Elf64_R_Info(5, R_RISCV_PCREL_HI20), R_addend: 0},
		{R_offset: 0x4, R_info: Elf64_R_Info(5, R_RISCV_PCREL_LO12_I), R_addend: 0},
	}
	relaBuf := new(bytes.Buffer)
	binary.Write(relaBuf, binary.LittleEndian, &rela_text)
	relaData := relaBuf.Bytes()

	numSections := 7
	ehdr := Elf64_Ehdr{
		E_type: ET_REL, E_machine: EM_RISCV, E_version: EV_CURRENT,
		E_flags: 0x4,
		E_ehsize: 64, E_shentsize: 64, E_shnum: uint16(numSections), E_shstrndx: 3,
	}
	ehdr.E_ident = [16]byte{0x7F, 'E', 'L', 'F', ELFCLASS64, ELFDATA2LSB, EV_CURRENT, ELFOSABI_FREEBSD}

	shdrs := make([]Elf64_Shdr, numSections)
	shdrs[0] = Elf64_Shdr{}

	currentOffset := uint64(binary.Size(ehdr))
	makeShdr := func(name uint32, typ uint32, flags, align, entsize uint64, data []byte) Elf64_Shdr {
		sh := Elf64_Shdr{
			Sh_name: name, Sh_type: typ, Sh_flags: flags,
			Sh_offset: currentOffset, Sh_size: uint64(len(data)),
			Sh_addralign: align, Sh_entsize: entsize,
		}
		currentOffset += uint64(len(data))
		return sh
	}

	shdrs[1] = makeShdr(1, SHT_PROGBITS, SHF_ALLOC|SHF_EXECINSTR, 4, 0, textData)
	shdrs[2] = makeShdr(7, SHT_PROGBITS, SHF_ALLOC|SHF_WRITE, 1, 0, dataData)
	shdrs[3] = makeShdr(13, SHT_STRTAB, 0, 1, 0, shstrtabData)
	shdrs[4] = makeShdr(23, SHT_SYMTAB, 0, 8, uint64(binary.Size(Elf64_Sym{})), symtabData)
	shdrs[5] = makeShdr(31, SHT_STRTAB, 0, 1, 0, strtabData)
	shdrs[6] = makeShdr(39, SHT_RELA, 0, 8, uint64(binary.Size(Elf64_Rela{})), relaData)

	shdrs[4].Sh_link = 5
	shdrs[4].Sh_info = 4
	shdrs[6].Sh_link = 4
	shdrs[6].Sh_info = 1

	ehdr.E_shoff = currentOffset

	f, err := os.Create("hello.o")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	fileBuf := new(bytes.Buffer)
	binary.Write(fileBuf, binary.LittleEndian, &ehdr)
	if int(shdrs[1].Sh_offset) > fileBuf.Len() {
		fileBuf.Write(make([]byte, int(shdrs[1].Sh_offset)-fileBuf.Len()))
	}

	fileBuf.Write(textData)
	fileBuf.Write(dataData)
	fileBuf.Write(shstrtabData)
	fileBuf.Write(symtabData)
	fileBuf.Write(strtabData)
	fileBuf.Write(relaData)

	shtBuf := new(bytes.Buffer)
	binary.Write(shtBuf, binary.LittleEndian, &shdrs)
	if int(ehdr.E_shoff) > fileBuf.Len() {
		fileBuf.Write(make([]byte, int(ehdr.E_shoff)-fileBuf.Len()))
	}
	fileBuf.Write(shtBuf.Bytes())

	if _, err := f.Write(fileBuf.Bytes()); err != nil {
		log.Fatal(err)
	}

	log.Println("hello.o created successfully.")
}
