typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

// --- Memory Map Constants ---
#define UART       ((volatile uint32_t *)0x00002004)
#define SDC_BUF    ((volatile uint8_t  *)0x00003000)
#define SDC_ADDR   ((volatile uint32_t *)0x00003200)
#define SDC_READ   ((volatile uint32_t *)0x00003204)
#define SDC_READY  ((volatile uint32_t *)0x00003220)
#define SDC_AVAIL  ((volatile uint32_t *)0x00003228)
#define SDRAM_BASE ((volatile uint8_t  *)0x80000000)

// Safe Unaligned Memory Readers
static inline uint16_t get16(const uint8_t *b, int o) {
    return b[o] | (b[o+1] << 8);
}
static inline uint32_t get32(const uint8_t *b, int o) {
    return b[o] | (b[o+1] << 8) | (b[o+2] << 16) | (b[o+3] << 24);
}

// Print to UART
void print(const char *s) {
    while (*s) { *UART = *s++; }
}

// Read exactly 1 sector to a destination buffer
void read_sector(uint32_t lba, uint8_t *dst) {
    *SDC_ADDR = lba;
    *SDC_READ = 1;
    while (*SDC_READY == 0); // Wait ready
    while (*SDC_AVAIL == 0); // Wait cache
    
    // Copy out of your 0x3000 cache into RAM/Stack
    for (int i = 0; i < 512; i++) {
        dst[i] = SDC_BUF[i];
    }
}

void main() {
    uint8_t buf[512];
    print("\nBoot ROM Start\n");

    // 1. Check Sector 0 for MBR or VBR
    read_sector(0, buf);
    uint32_t vbr_lba = 0;
    if (buf[0] != 0xEB && buf[0] != 0xE9) { 
        vbr_lba = get32(buf, 454); // Read Partition 1 LBA from MBR
        read_sector(vbr_lba, buf);
    }

    // 2. Parse FAT32 VBR
    uint16_t rsvd_secs = get16(buf, 14);
    uint8_t  num_fats  = buf[16];
    uint32_t fat_size  = get32(buf, 36);
    uint8_t  sec_p_clus= buf[13];
    uint32_t root_clus = get32(buf, 44);

    uint32_t fat_lba   = vbr_lba + rsvd_secs;
    uint32_t data_lba  = fat_lba + (num_fats * fat_size);

    // 3. Search Root Directory for "OPENSBI BIN"
    uint32_t clus = root_clus;
    uint32_t target_clus = 0;
    uint32_t file_size = 0;

    print("Searching SD...\n");
    while (clus >= 2 && clus < 0x0FFFFFF8) {
        uint32_t clus_lba = data_lba + (clus - 2) * sec_p_clus;
        for (int s = 0; s < sec_p_clus; s++) {
            read_sector(clus_lba + s, buf);
            for (int i = 0; i < 512; i += 32) {
                if (buf[i] == 0x00) goto done_search; // End of Dir
                if (buf[i] == 0xE5 || (buf[i+11] & 0x08)) continue; // Deleted/VolLabel

                // Check Name (11 characters)
                int match = 1;
                const char *tgt = "OPENSBI BIN"; 
                for(int j=0; j<11; j++) {
                    if(buf[i+j] != tgt[j]) match = 0;
                }
                
                if (match) {
                    target_clus = (get16(buf, i+20) << 16) | get16(buf, i+26);
                    file_size = get32(buf, i+28);
                    goto load_file;
                }
            }
        }
        // Read FAT Table to find Next Cluster
        read_sector(fat_lba + ((clus * 4) / 512), buf);
        clus = get32(buf, (clus * 4) % 512) & 0x0FFFFFFF;
    }

done_search:
load_file:
    if (!target_clus) {
        print("ERR: opensbi.bin NOT FOUND!\n");
        while(1);
    }

    // 4. Load the File to 0x80000000
    print("Loading file to SDRAM...\n");
    uint8_t *dst = SDRAM_BASE;
    clus = target_clus;
    uint32_t loaded = 0;

    while (clus >= 2 && clus < 0x0FFFFFF8) {
        uint32_t clus_lba = data_lba + (clus - 2) * sec_p_clus;
        for (int s = 0; s < sec_p_clus && loaded < file_size; s++) {
            read_sector(clus_lba + s, dst);
            dst += 512;
            loaded += 512;
            if ((loaded % 32768) == 0) print("."); // Print progress bar!
        }
        
        // Read FAT Table to find Next Cluster
        read_sector(fat_lba + ((clus * 4) / 512), buf);
        clus = get32(buf, (clus * 4) % 512) & 0x0FFFFFFF;
    }

    print("\nBooting OpenSBI!\n");

    // 5. Jump to OpenSBI!
    void (*boot)(uint64_t, uint64_t) = (void *)0x80000000;
    boot(0, 0); // Passes a0=0 (Hart ID) and a1=0 (DTB Address)
}
