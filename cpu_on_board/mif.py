with open('../binary_instructions.txt', 'r') as f, open ('mem.mif', 'w') as out:
    #out.write("DEPTH = 19999:\nWIDTH = 8;\nADDRESS_RADIX = DEC;\nDATA_RADIX = BIN;\nCONTENT BEGIN\n")
    addr = 0
    for line in f:
        byte = line.split("//")[0]
        #byte = byte.strip()
        byte = byte.replace(" ", "")
        if byte:
            #out.write(f"{addr} : {byte};\n")
            out.write(f"{byte}\n")
            addr += 1
    #out.write("END;\n")
