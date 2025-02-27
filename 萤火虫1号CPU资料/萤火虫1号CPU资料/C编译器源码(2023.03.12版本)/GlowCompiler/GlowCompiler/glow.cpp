/**********************************************/
/*
/*		ө���1��C���������	2022  ����
/*
/**********************************************/

#include "pch.h"
#include "c.h"
#define I(f) l_##f

static char rcsid[] = "$Id$";

unsigned char optimize;	//�Ż��ȼ�,0��Ϊ���Ż�
static int cseg;		//��¼��ǰ��

/****************************************CPUָ������****************************************/

#define REGISTER_FILE_SP 0						//��ջҳָ��
#define REGISTER_FILE_RET_VALUE 2				//��������ֵ�Ĵ�����ַ
#define REGISTER_FILE_OP_FUNC_LOP 10			//���㺯����������Ĵ�����ַ
#define REGISTER_FILE_OP_FUNC_ROP 18			//���㺯���Ҳ������Ĵ�����ַ
#define REGISTER_FILE_OP_FUNC_DOP 26			//���㺯��Ŀ�Ĳ������Ĵ�����ַ
#define REGISTER_FILE_OP_FUNC_RET 34			//���㺯����ŷ��ص�ַ�ļĴ�����ַ
#define REGISTER_FILE_OP_FUNC_CACHE 37			//���㺯���������Ĵ�����ַ
#define REGISTER_FILE_OP_FUNC_CACHE_SKIP 19		//���㺯����������С

#define ROM_SIZE 1048576			//ROM��С
#define VA_ARG_BUF_SIZE 1024		//�ɱ������������С
unsigned long sp0_init_romaddr;		//ջҳ��8λ��ʼ��ֵ����ROM��ַ
unsigned long sp1_init_romaddr;		//ջҳ��8λ��ʼ��ֵ����ROM��ַ
unsigned long romentry;				//ROM�����תָ���ַ
unsigned long ramallocaddr;			//RAM�ڴ�����ַ(ȫ�ֳ�ʼ��)
unsigned char romdata[ROM_SIZE];	//ROM����
unsigned long rom_cp;				//ROMʹ�ü���(ȫ�ֳ�ʼ��)
unsigned long rom_cp_max;			//ROMʹ�����ֵ

struct CPU_O{
	enum {
		REG_X = -1, REG_F = 256
	};
	short ra;
	short a0;
	short a1;
	short a2;
}cpu;

/*����Ϊ��ָ��*/
void ROM_ADD_INS(unsigned char, unsigned char); //ROM���ָ��
void RF_ASGN_IMMNUM(unsigned char); //RF����������
void A_ASGN_IMMNUM(unsigned char); //A����������
void A0_ASGN_IMMNUM(unsigned char); //A0����������
void A1_ASGN_IMMNUM(unsigned char); //A1����������
void A2_ASGN_IMMNUM(unsigned char); //A2����������
void RA_ASGN_IMMNUM(unsigned char); //RA����������
void B_ASGN_IMMNUM(unsigned char); //B����������
void RAM_ASGN_IMMNUM(unsigned char); //RAM����������
void IO0_ASGN_IMMNUM(unsigned char); //IO0����������
void IO1_ASGN_IMMNUM(unsigned char); //IO1����������

void RF_ASGN_ALU(unsigned char); //RF����ALU
void A_ASGN_ALU(unsigned char); //A����ALU
void A0_ASGN_ALU(unsigned char); //A0����ALU
void A1_ASGN_ALU(unsigned char); //A1����ALU
void A2_ASGN_ALU(unsigned char); //A2����ALU
void RA_ASGN_ALU(unsigned char); //RA����ALU
void B_ASGN_ALU(unsigned char); //B����ALU
void RAM_ASGN_ALU(unsigned char); //RAM����ALU
void IO0_ASGN_ALU(unsigned char); //IO0����ALU
void IO1_ASGN_ALU(unsigned char); //IO1����ALU

void A_ASGN_RF(void); //A����RF
void A0_ASGN_RF(void); //A0����RF
void A1_ASGN_RF(void); //A1����RF
void A2_ASGN_RF(void); //A2����RF
void RA_ASGN_RF(void); //RA����RF
void B_ASGN_RF(void); //B����RF
void RAM_ASGN_RF(void); //RAM����RF
void ALU_ASGN_RF(unsigned char); //ALU����RF
void IO0_ASGN_RF(void); //IO0����RF
void IO1_ASGN_RF(void); //IO1����RF

void RF_ASGN_RAM(void); //RF����RAM
void A_ASGN_RAM(void); //A����RAM
void A0_ASGN_RAM(void); //A0����RAM
void A1_ASGN_RAM(void); //A1����RAM
void A2_ASGN_RAM(void); //A2����RAM
void RA_ASGN_RAM(void); //RA����RAM
void B_ASGN_RAM(void); //B����RAM
void ALU_ASGN_RAM(unsigned char); //ALU����RAM
void IO0_ASGN_RAM(void); //IO0����RAM
void IO1_ASGN_RAM(void); //IO1����RAM

void RF_ASGN_IO0(void); //RF����IO0
void A_ASGN_IO0(void); //A����IO0
void A0_ASGN_IO0(void); //A0����IO0
void A1_ASGN_IO0(void); //A1����IO0
void A2_ASGN_IO0(void); //A2����IO0
void RA_ASGN_IO0(void); //RA����IO0
void B_ASGN_IO0(void); //B����IO0
void RAM_ASGN_IO0(void); //RAM����IO0
void ALU_ASGN_IO0(unsigned char); //ALU����IO0
void IO0_ASGN_IO0(void); //IO0����IO0
void IO1_ASGN_IO0(void); //IO1����IO0

void RF_ASGN_IO1(void); //RF����IO1
void A_ASGN_IO1(void); //A����IO1
void A0_ASGN_IO1(void); //A0����IO1
void A1_ASGN_IO1(void); //A1����IO1
void A2_ASGN_IO1(void); //A2����IO1
void RA_ASGN_IO1(void); //RA����IO1
void B_ASGN_IO1(void); //B����IO1
void RAM_ASGN_IO1(void); //RAM����IO1
void ALU_ASGN_IO1(unsigned char); //ALU����IO1
void IO0_ASGN_IO1(void); //IO0����IO1
void IO1_ASGN_IO1(void); //IO1����IO1

void PC_ASGN_A2A1A0(void); //PC����A2A1A0 (��������ת)
void IFALU_PC_ASGN_A2A1A0(unsigned char); //�ж�ALU���,����PC�Ƿ����A2A1A0 (������ת)
void IFRF_PC_ASGN_A2A1A0(void); //�ж�RF���,����PC�Ƿ����A2A1A0 (������ת)

void NOP(); //�ղ���

/*����Ϊ���ָ��*/
void A2A1A0_ASGN_IMMNUM(unsigned long); //A2A1A0����������
void A2A1A0_ASGN_IMMNUM_O(unsigned long); //A2A1A0����������,���Ż�
void PC_ASGN_IMMNUM(unsigned long); //PC����������(��������ת)
void IFALU_PC_ASGN_IMMNUM(unsigned char, unsigned long); //�ж�ALU���,����PC�Ƿ���������� (������ת)
void IFRF_PC_ASGN_IMMNUM(unsigned long); //�ж�RF���,����PC�Ƿ���������� (������ת)

/*�޸�ROM����*/
void MODIFY_A2A1A0(unsigned long, unsigned long); //�޸�A2A1A0

/*����Ϊ�����Ż������ָ��*/
void A_ASGN__RF(unsigned char); //A����RF
void A0_ASGN__RF(unsigned char); //A0����RF
void A1_ASGN__RF(unsigned char); //A1����RF
void A2_ASGN__RF(unsigned char); //A2����RF
void RA_ASGN__RF(unsigned char); //RA����RF
void B_ASGN__RF(unsigned char); //B����RF
void RAM_ASGN__RF(unsigned char); //RAM����RF
void ALU_ASGN__RF(unsigned char, unsigned char); //ALU����RF
void IO0_ASGN__RF(unsigned char); //IO0����RF
void IO1_ASGN__RF(unsigned char); //IO1����RF

void _RF_ASGN_IMMNUM(unsigned char, unsigned char); //RF����������
void _RF_ASGN_ALU(unsigned char, unsigned char); //RF����ALU
void _RF_ASGN_RAM(unsigned char); //RF����RAM
void _RF_ASGN_IO0(unsigned char); //RF����IO0
void _RF_ASGN_IO1(unsigned char); //RF����IO1

void RF_ASGN__RAM(unsigned long); //RF����RAM
void A_ASGN__RAM(unsigned long); //A����RAM
void A0_ASGN__RAM(unsigned long); //A0����RAM
void A1_ASGN__RAM(unsigned long); //A1����RAM
void A2_ASGN__RAM(unsigned long); //A2����RAM
void RA_ASGN__RAM(unsigned long); //RA����RAM
void B_ASGN__RAM(unsigned long); //B����RAM
void ALU_ASGN__RAM(unsigned char, unsigned long); //ALU����RAM
void IO0_ASGN__RAM(unsigned long); //IO0����RAM
void IO1_ASGN__RAM(unsigned long); //IO1����RAM

void _RAM_ASGN_IMMNUM(unsigned long, unsigned char); //RAM����������
void _RAM_ASGN_ALU(unsigned long, unsigned char); //RAM����ALU
void _RAM_ASGN_RF(unsigned long); //RAM����RF
void _RAM_ASGN_IO0(unsigned long); //RAM����IO0
void _RAM_ASGN_IO1(unsigned long); //RAM����IO1

void _RAM_ASGN__RF(unsigned long, unsigned char); //RAM����RF
void _RF_ASGN__RAM(unsigned char, unsigned long); //RF����RAM

/*����Ϊ���Ż��ĵ�ָ��*/
void A0_ASGN_IMMNUM_O(unsigned char);

/*����Ϊ���Ż������ָ��*/
void A_ASGN__RF_O(unsigned char); //A����RF
void A0_ASGN__RF_O(unsigned char); //A0����RF
void A1_ASGN__RF_O(unsigned char); //A1����RF
void A2_ASGN__RF_O(unsigned char); //A2����RF
void RA_ASGN__RF_O(unsigned char); //RA����RF
void B_ASGN__RF_O(unsigned char); //B����RF
void RAM_ASGN__RF_O(unsigned char); //RAM����RF
void ALU_ASGN__RF_O(unsigned char, unsigned char); //ALU����RF
void IO0_ASGN__RF_O(unsigned char); //IO0����RF
void IO1_ASGN__RF_O(unsigned char); //IO1����RF

void _RF_ASGN_IMMNUM_O(unsigned char, unsigned char); //RF����������
void _RF_ASGN_ALU_O(unsigned char, unsigned char); //RF����ALU
void _RF_ASGN_RAM_O(unsigned char); //RF����RAM
void _RF_ASGN_IO0_O(unsigned char); //RF����IO0
void _RF_ASGN_IO1_O(unsigned char); //RF����IO1

void RF_ASGN__RAM_O(unsigned long); //RF����RAM
void A_ASGN__RAM_O(unsigned long); //A����RAM
void A0_ASGN__RAM_O(unsigned long); //A0����RAM
void A1_ASGN__RAM_O(unsigned long); //A1����RAM
void A2_ASGN__RAM_O(unsigned long); //A2����RAM
void RA_ASGN__RAM_O(unsigned long); //RA����RAM
void B_ASGN__RAM_O(unsigned long); //B����RAM
void ALU_ASGN__RAM_O(unsigned char, unsigned long); //ALU����RAM
void IO0_ASGN__RAM_O(unsigned long); //IO0����RAM
void IO1_ASGN__RAM_O(unsigned long); //IO1����RAM

void _RAM_ASGN_IMMNUM_O(unsigned long, unsigned char); //RAM����������
void _RAM_ASGN_ALU_O(unsigned long, unsigned char); //RAM����ALU
void _RAM_ASGN_RF_O(unsigned long); //RAM����RF
void _RAM_ASGN_IO0_O(unsigned long); //RAM����IO0
void _RAM_ASGN_IO1_O(unsigned long); //RAM����IO1

void _RAM_ASGN__RF_O(unsigned long, unsigned char); //RAM����RF
void _RF_ASGN__RAM_O(unsigned char, unsigned long); //RF����RAM


/*ALU����ģʽ����*/
enum {
	ALU_ADD = 0,	//A��B
	ALU_SUB,		//A��B
	ALU_ADD_C,		//A��B�����λ0x01
	ALU_SUB_C,		//A��B�����λ0x01
	ALU_EQUAL_C,	//A����B���0x01
	ALU_AND,		//A��B
	ALU_OR,			//A��B
	ALU_A_NOT,		//Aȡ��
	ALU_XOR,		//A���B
	ALU_A_BH_LSH,	//A��B���λ����1λ
	ALU_B_AL_RSH,	//B��A���λ����1λ
	ALU_A_AH_RSH,	//A��A���λ����1λ
	ALU_A_0_RSH,	//A��0����1λ
	ALU_A_0_LSH,	//A��0����1λ
	ALU_B_0_LSH,	//B��0����1λ
	ALU_MUL_L,		//A����B�����8λ
	ALU_MUL_H,		//A����B�����8λ
	ALU_DIV,		//A����B
	ALU_MOD,		//Aȡ��B
	ALU_A_ADD_1,	//A��1
	ALU_A_SUB_1,	//A��1
	ALU_A_ADD_1_C,	//A��1�����λ0x01
	ALU_A_SUB_1_C,	//A��1�����λ0x01
	ALU_OUTA,		//���A
	ALU_OUTB		//���B
};

/*��λ�Ż�����ֵ*/
void reset_cpu_o() {
	cpu.a0 = CPU_O::REG_X;
	cpu.a1 = CPU_O::REG_X;
	cpu.a2 = CPU_O::REG_X;
	cpu.ra = CPU_O::REG_X;
}

/*��ʼ��CPU�ڴ�ʹ�ü����Ȳ���*/
void glow_mem_alloc_init() {
	ramallocaddr = 0;
	rom_cp = 0;
	reset_cpu_o();
}

/****************************************�����ַ�������****************************************/

char* glow_string(const char* str);
char* glow_stringn(const char* str, int len);
void glow_string_init(void);

static struct string { 
	char* str;
	int len;
	struct string* link;
} *buckets[1024];

static int scatter[] = {	/* map characters to random values */
	2078917053, 143302914, 1027100827, 1953210302, 755253631,
	2002600785, 1405390230, 45248011, 1099951567, 433832350,
	2018585307, 438263339, 813528929, 1703199216, 618906479,
	573714703, 766270699, 275680090, 1510320440, 1583583926,
	1723401032, 1965443329, 1098183682, 1636505764, 980071615,
	1011597961, 643279273, 1315461275, 157584038, 1069844923,
	471560540, 89017443, 1213147837, 1498661368, 2042227746,
	1968401469, 1353778505, 1300134328, 2013649480, 306246424,
	1733966678, 1884751139, 744509763, 400011959, 1440466707,
	1363416242, 973726663, 59253759, 1639096332, 336563455,
	1642837685, 1215013716, 154523136, 593537720, 704035832,
	1134594751, 1605135681, 1347315106, 302572379, 1762719719,
	269676381, 774132919, 1851737163, 1482824219, 125310639,
	1746481261, 1303742040, 1479089144, 899131941, 1169907872,
	1785335569, 485614972, 907175364, 382361684, 885626931,
	200158423, 1745777927, 1859353594, 259412182, 1237390611,
	48433401, 1902249868, 304920680, 202956538, 348303940,
	1008956512, 1337551289, 1953439621, 208787970, 1640123668,
	1568675693, 478464352, 266772940, 1272929208, 1961288571,
	392083579, 871926821, 1117546963, 1871172724, 1771058762,
	139971187, 1509024645, 109190086, 1047146551, 1891386329,
	994817018, 1247304975, 1489680608, 706686964, 1506717157,
	579587572, 755120366, 1261483377, 884508252, 958076904,
	1609787317, 1893464764, 148144545, 1415743291, 2102252735,
	1788268214, 836935336, 433233439, 2055041154, 2109864544,
	247038362, 299641085, 834307717, 1364585325, 23330161,
	457882831, 1504556512, 1532354806, 567072918, 404219416,
	1276257488, 1561889936, 1651524391, 618454448, 121093252,
	1010757900, 1198042020, 876213618, 124757630, 2082550272,
	1834290522, 1734544947, 1828531389, 1982435068, 1002804590,
	1783300476, 1623219634, 1839739926, 69050267, 1530777140,
	1802120822, 316088629, 1830418225, 488944891, 1680673954,
	1853748387, 946827723, 1037746818, 1238619545, 1513900641,
	1441966234, 367393385, 928306929, 946006977, 985847834,
	1049400181, 1956764878, 36406206, 1925613800, 2081522508,
	2118956479, 1612420674, 1668583807, 1800004220, 1447372094,
	523904750, 1435821048, 923108080, 216161028, 1504871315,
	306401572, 2018281851, 1820959944, 2136819798, 359743094,
	1354150250, 1843084537, 1306570817, 244413420, 934220434,
	672987810, 1686379655, 1301613820, 1601294739, 484902984,
	139978006, 503211273, 294184214, 176384212, 281341425,
	228223074, 147857043, 1893762099, 1896806882, 1947861263,
	1193650546, 273227984, 1236198663, 2116758626, 489389012,
	593586330, 275676551, 360187215, 267062626, 265012701,
	719930310, 1621212876, 2108097238, 2026501127, 1865626297,
	894834024, 552005290, 1404522304, 48964196, 5816381,
	1889425288, 188942202, 509027654, 36125855, 365326415,
	790369079, 264348929, 513183458, 536647531, 13672163,
	313561074, 1730298077, 286900147, 1549759737, 1699573055,
	776289160, 2143346068, 1975249606, 1136476375, 262925046,
	92778659, 1856406685, 1884137923, 53392249, 1735424165,
	1602280572
};

static char* next, * strlimit;

/*��ʼ������(ȫ�ֳ�ʼ��)*/
void glow_string_init(void)
{
	int i;
	for (i = 0; i < 1024; ++i) buckets[i] = 0;
	next = 0;
	strlimit = 0;
}

char* glow_string(const char* str) {
	const char* s;

	for (s = str; *s; s++)
		;
	return glow_stringn(str, s - str);
}

char* glow_stringn(const char* str, int len) {
	int i;
	unsigned int h;
	const char* end;
	struct string* p;

	assert(str);
	for (h = 0, i = len, end = str; i > 0; i--)
		h = (h << 1) + scatter[*(unsigned char*)end++];
	h &= NELEMS(buckets) - 1;
	for (p = buckets[h]; p; p = p->link)
		if (len == p->len) {
			const char* s1 = str;
			char* s2 = p->str;
			do {
				if (s1 == end)
					return p->str;
			} while (*s1++ == *s2++);
		}

	{
		if (len + 1 >= strlimit - next) {
			int n = len + 4 * 1024;
			next = (char*)allocate(n, GLOW_ADDRDATA);
			strlimit = next + n;
		}
		p = (struct string*)allocate(sizeof * p, GLOW_ADDRDATA);
		p->len = len;
		for (p->str = next; str < end; )
			*next++ = *str++;
		*next++ = 0;
		p->link = buckets[h];
		buckets[h] = p;
		return p->str;
	}
}

/****************************************�ض����ַ����****************************************/

ADDRDATA ADDRDATA_ENTRY;		//��ַ�������(ȫ�ֳ�ʼ��)

/*��ѯ���½�addrdata,�����ظ�ָ��*/

ADDRDATA newaddrdata(char* name) {
	ADDRDATA p;
	ADDRDATA null_p = NULL;
	char* str_name;

	str_name = glow_string(name);
	for (p = ADDRDATA_ENTRY; p != NULL; p = p->link) {
		if (p->name == str_name)
			return p;
		else if (p->name == NULL)
			null_p = p;
	}
	if (null_p == NULL) {
		memset(p = (ADDRDATA)allocate(sizeof * p, GLOW_ADDRDATA), 0, sizeof * p);
		p->name = str_name;
		p->base = 0xffffffff;
		p->link = ADDRDATA_ENTRY;
		ADDRDATA_ENTRY = p;
		return p;
	}
	else {
		null_p->name = str_name;
		null_p->base = 0xffffffff;
		return null_p;
	}
}

void insertaddr(ADDRDATA q, unsigned long a_23_16, unsigned long a_15_8, unsigned long a_7_0, long offset) {
	ADDRSTR p;

	for (p = q->redirectaddr; p != NULL && p->file != NULL; p = p->link);
	if (p == NULL) {
		p = (ADDRSTR)allocate(sizeof * p, GLOW_ADDRDATA);
		p->link = q->redirectaddr;
		q->redirectaddr = p;
	}
	p->file = glow_string(src.file);
	p->a_23_16 = a_23_16;
	p->a_15_8 = a_15_8;
	p->a_7_0 = a_7_0;
	p->offset = offset;
}

/*����C�ļ��ھֲ��ض����ַ*/
void one_c_file_redirect_addr(CString* redirect_addr_err) {
	ADDRDATA p;

	for (p = ADDRDATA_ENTRY; p != NULL; p = p->link) {
		if (p->name != NULL && (*p->name == '$')) {
			if (p->base != 0xffffffff) {
				for (ADDRSTR redirect_addr = p->redirectaddr; redirect_addr != NULL && redirect_addr->file != NULL; redirect_addr = redirect_addr->link) {
					unsigned long addr = p->base + redirect_addr->offset;
					romdata[redirect_addr->a_7_0] = addr;
					romdata[redirect_addr->a_15_8] = addr >> 8;
					romdata[redirect_addr->a_23_16] = addr >> 16;
					redirect_addr->file = NULL;
				}
			}
			else for (ADDRSTR redirect_addr = p->redirectaddr; redirect_addr != NULL && redirect_addr->file != NULL; redirect_addr = redirect_addr->link)
				redirect_addr_err->Format(*redirect_addr_err + _T("%s:�ֲ��ض����ַ������δ֪��ַ��Ա%s\r\n"), (CString)redirect_addr->file, (CString)p->name);
			p->name = NULL;
		}
	}
}

/*����C�ļ�ȫ���ض����ַ*/
void all_c_file_redirect_addr(CString* redirect_addr_err) {
	ADDRDATA p;

	for (p = ADDRDATA_ENTRY; p != NULL; p = p->link) {
		if (p->name != NULL) {
			if (p->base != 0xffffffff) {
				for (ADDRSTR redirect_addr = p->redirectaddr; redirect_addr != NULL && redirect_addr->file != NULL; redirect_addr = redirect_addr->link) {
					unsigned long addr = p->base + redirect_addr->offset;
					romdata[redirect_addr->a_7_0] = addr;
					romdata[redirect_addr->a_15_8] = addr >> 8;
					romdata[redirect_addr->a_23_16] = addr >> 16;
				}
			}
			else for (ADDRSTR redirect_addr = p->redirectaddr; redirect_addr != NULL && redirect_addr->file != NULL; redirect_addr = redirect_addr->link)
				redirect_addr_err->Format(*redirect_addr_err + _T("%s:ȫ���ض����ַ������δ֪��ַ��Ա%s\r\n"), (CString)redirect_addr->file, (CString)p->name);
		}
	}
	deallocate(GLOW_ADDRDATA);
}

/*ջҳָ���ض����ַ*/
void sp_redirect_addr() {
	romdata[sp0_init_romaddr] = (ramallocaddr >> 8) + ((ramallocaddr & 0xff) != 0);
	romdata[sp1_init_romaddr] = (ramallocaddr >> 8) + ((ramallocaddr & 0xff) != 0) >> 8;
}

/*��������ض�����main����*/
void entry_redirect_to_main(CString* error_out_buf) {
	if (cseg == LIT) {
		romentry = rom_cp;
		PC_ASGN_IMMNUM(0);
	}
	unsigned long main_base = newaddrdata("main")->base;
	if (main_base != 0xffffffff)
		MODIFY_A2A1A0(romentry, main_base);
	else
		*error_out_buf += _T("main������ڵ�ַ����\r\n");
}

/****************************************CPU�Ĵ����ѹ���****************************************/

#define REG_SIZE 256 //�Ĵ�����С
#define REG_START (REGISTER_FILE_OP_FUNC_CACHE + REGISTER_FILE_OP_FUNC_CACHE_SKIP) //�Ĵ���������ʼλ��
short maxlocreg; //���Ĵ���ʹ������

struct Reg {
	enum {
		REG_FREE, REG_BUSY //�Ĵ���״̬,���л�æ
	} state;
	short life; //�Ĵ�������ֵ
} glowreg[REG_SIZE];

/*��ʼ��regalloc*/
void glow_regalloc_init() {
	short i;

	for (i = 0; i < REG_SIZE; ++i) {
		glowreg[i].state = Reg::REG_FREE;
		glowreg[i].life = 0;
	}
	maxlocreg = REG_START;
}

/*����һ�����мĴ���*/
short regalloc(unsigned char size, short life) {
	short i; unsigned char j;
	for (i = REG_START; i < REG_SIZE; ++i)
		if (glowreg[i].state == Reg::REG_FREE && i + size <= REG_SIZE) {
			for (j = 1; j < size && glowreg[i + j].state != Reg::REG_BUSY; ++j);
			if (j == size) {
				for (j = 0; j < size; ++j)
					glowreg[i + j].state = Reg::REG_BUSY;
				glowreg[i].life = life;
				if (i + size > maxlocreg)
					maxlocreg = i + size;
				return i;
			}
			i += j;
		}
	if (i + size > maxlocreg)
		maxlocreg = i + size;
	error("���regalloc�����Ĵ������, ֵΪ%d, �����趨��%d\n", i + size, REG_SIZE);
	return -1; //û�п��еļĴ���
}

/*�Ĵ�����������1,Ϊ0�ͷŸüĴ���*/
void regfree(short regaddr, unsigned char size) {
	unsigned char i;
	if (glowreg[regaddr].life == 1) {
		for (i = 0; i < size; ++i)
			glowreg[regaddr + i].state = Reg::REG_FREE;
	}
	if (glowreg[regaddr].life > 0)
		glowreg[regaddr].life -= 1;
}

/****************************************����CPUָ������****************************************/

#define LOC_OFFSET_CONST_P_OR(op) ((op) == Xop::XOP_LOC || (op) == Xop::XOP_OFFSET || (op) == Xop::XOP_CONST_P)
#define CTB_SP(offset, size) (((offset) + (size) - 1 & 255) < ((offset) & 255))

/*ջҳָ��װ����A2��A1�Ĵ���*/
void SP_TO_A2A1(long offset) {
	if ((offset & 0xffffff00) == 0) {
		A2_ASGN__RF_O(REGISTER_FILE_SP + 1);
		A1_ASGN__RF_O(REGISTER_FILE_SP);
	}
	else {
		A_ASGN__RF_O(REGISTER_FILE_SP);
		B_ASGN_IMMNUM(offset >> 8);
		A1_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_SP + 1);
		A2_ASGN_ALU(ALU_ADD);
	}
}

/*�Ĵ������ݺ�offset��Ӻ�װ����A2A1A0�Ĵ���*/
void REGISTER_TO_A2A1A0(unsigned char regaddr, unsigned char offset) {
	if (offset == 0) {
		A2_ASGN__RF_O(regaddr + 2);
		A1_ASGN__RF_O(regaddr + 1);
		A0_ASGN__RF_O(regaddr);
	}
	if (offset == 1) {
		A_ASGN__RF_O(regaddr);
		A0_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(regaddr + 1);
		A1_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(regaddr + 2);
		A2_ASGN_ALU(ALU_ADD);
	}
	if (offset > 1) {
		A_ASGN__RF_O(regaddr);
		B_ASGN_IMMNUM(offset);
		A0_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(regaddr + 1);
		A1_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(regaddr + 2);
		A2_ASGN_ALU(ALU_ADD);
	}
}

/*Դ������Ϊ��ַ,ȡ��������Ŀ�Ĳ�����*/
void DOP_ASGN_SOP_INDIR(Xop* d, Xop* s) {
	if (d->addrtype == Xop::XOP_REGISTER_FILE) {
		if (s->datatype == Xop::XOP_P) {
			if (s->addrtype == Xop::XOP_REGISTER_FILE) {
				for (int i = 0; i < d->datasize; ++i) {
					REGISTER_TO_A2A1A0(s->v.i, i);
					_RF_ASGN_RAM(d->v.i + i);
				}
			}
			else if (LOC_OFFSET_CONST_P_OR(s->addrtype)) {
				Xop dd = *s, ss = *s;
				ss.datatype = Xop::XOP_X;
				dd.addrtype = Xop::XOP_REGISTER_FILE;
				dd.v.i = regalloc(dd.datasize, 1);
				DOP_ASGN_SOP_INDIR(&dd, &ss);
				DOP_ASGN_SOP_INDIR(d, &dd);
				regfree(dd.v.i, dd.datasize);
			}
			else
				error("���DOP_ASGN_SOP_INDIR����Դ����������\n");
		}
		else if (s->datatype == Xop::XOP_X) {
			if (s->addrtype == Xop::XOP_LOC) {
				for (int i = 0; i < d->datasize; ++i) {
					insertaddr(s->entry, rom_cp + 3, rom_cp + 5, rom_cp + 7, s->v.i + i);
					_RF_ASGN__RAM(d->v.i + i, 0);
				}
				reset_cpu_o();
			}
			else if (s->addrtype == Xop::XOP_OFFSET) {
				int x = 0;

				if (CTB_SP(s->v.i, d->datasize)) {
					SP_TO_A2A1(s->v.i);
					do {
						A0_ASGN_IMMNUM_O(s->v.i + x);
						_RF_ASGN_RAM_O(d->v.i + x);
						++x;
					} while ((s->v.i + x & 255) != 0);
				}
				SP_TO_A2A1(s->v.i + x);
				for (; x < d->datasize; ++x) {
					A0_ASGN_IMMNUM_O(s->v.i + x);
					_RF_ASGN_RAM_O(d->v.i + x);
				}
			}
			else if (s->addrtype == Xop::XOP_CONST_P) {
				for (int i = 0; i < d->datasize; ++i) {
					_RF_ASGN__RAM_O(d->v.i + i, s->v.u + i);
				}
			}
			else
				error("���DOP_ASGN_SOP_INDIR����Դ����������\n");
		}
		else
			error("���DOP_ASGN_SOP_INDIR����Դ����������\n");
	}
	else
		error("���DOP_ASGN_SOP_INDIR����Ŀ�Ĳ���������\n");
}

/*��ַת������*/
void addr_convert(Xop* d, Xop* l, Xop* r) {
	Xop sd, sl, sr;

	if (d != NULL && d->datatype == Xop::XOP_X)
		sd = *d;
	else
		sd.addrtype = Xop::XOP_VOID;
	if (l != NULL && l->datatype != Xop::XOP_X)
		sl = *l;
	else {
		sl.addrtype = Xop::XOP_VOID;
		if (l != NULL)
			sl.datasize = l->datasize;
		else
			sl.datasize = 8;
	}
	if (r != NULL && r->datatype != Xop::XOP_X)
		sr = *r;
	else
		sr.addrtype = Xop::XOP_VOID;

	if (sd.addrtype == Xop::XOP_OFFSET && CTB_SP(sd.v.i, sl.datasize)) {
		sd.addrtype = Xop::XOP_REGISTER_FILE;
		sd.datatype = sl.datatype;
		sd.datasize = sl.datasize;
		sd.v.i = regalloc(sd.datasize, 1);
	}
	if (sl.addrtype == Xop::XOP_OFFSET && CTB_SP(sl.v.i, sl.datasize)) {
		sl.addrtype = Xop::XOP_REGISTER_FILE;
		l->datatype = Xop::XOP_X;
		sl.v.i = regalloc(sl.datasize, 1);
		DOP_ASGN_SOP_INDIR(&sl, l);
	}
	if (sr.addrtype == Xop::XOP_OFFSET && CTB_SP(sr.v.i, sr.datasize)) {
		sr.addrtype = Xop::XOP_REGISTER_FILE;
		r->datatype = Xop::XOP_X;
		sr.v.i = regalloc(sr.datasize, 1);
		DOP_ASGN_SOP_INDIR(&sr, r);
	}
	if (sd.addrtype == Xop::XOP_OFFSET && sl.addrtype == Xop::XOP_OFFSET && sr.addrtype == Xop::XOP_OFFSET) {
		if ((sd.v.i & 0xffffff00) == (sl.v.i & 0xffffff00) && (sl.v.i & 0xffffff00) == (sr.v.i & 0xffffff00)) {
			SP_TO_A2A1(sd.v.i);
		}
		else if ((sd.v.i & 0xffffff00) == (sl.v.i & 0xffffff00)) {
			sr.addrtype = Xop::XOP_REGISTER_FILE;
			r->datatype = Xop::XOP_X;
			sr.v.i = regalloc(sr.datasize, 1);
			DOP_ASGN_SOP_INDIR(&sr, r);
			SP_TO_A2A1(sd.v.i);
		}
		else if ((sd.v.i & 0xffffff00) == (sr.v.i & 0xffffff00)) {
			sl.addrtype = Xop::XOP_REGISTER_FILE;
			l->datatype = Xop::XOP_X;
			sl.v.i = regalloc(sl.datasize, 1);
			DOP_ASGN_SOP_INDIR(&sl, l);
			SP_TO_A2A1(sd.v.i);
		}
		else if ((sl.v.i & 0xffffff00) == (sr.v.i & 0xffffff00)) {
			sd.addrtype = Xop::XOP_REGISTER_FILE;
			sd.datatype = sl.datatype;
			sd.datasize = sl.datasize;
			sd.v.i = regalloc(sd.datasize, 1);
			SP_TO_A2A1(sl.v.i);
		}
		else {
			sl.addrtype = Xop::XOP_REGISTER_FILE;
			l->datatype = Xop::XOP_X;
			sl.v.i = regalloc(sl.datasize, 1);
			DOP_ASGN_SOP_INDIR(&sl, l);
			sr.addrtype = Xop::XOP_REGISTER_FILE;
			r->datatype = Xop::XOP_X;
			sr.v.i = regalloc(sr.datasize, 1);
			DOP_ASGN_SOP_INDIR(&sr, r);
			SP_TO_A2A1(sd.v.i);
		}
	}
	else if ((sd.addrtype == Xop::XOP_LOC || sd.addrtype == Xop::XOP_CONST_P) && (sl.addrtype == Xop::XOP_LOC || sl.addrtype == Xop::XOP_CONST_P) && sr.addrtype == Xop::XOP_OFFSET) {
		sr.addrtype = Xop::XOP_REGISTER_FILE;
		r->datatype = Xop::XOP_X;
		sr.v.i = regalloc(sr.datasize, 1);
		DOP_ASGN_SOP_INDIR(&sr, r);
	}
	else if ((sd.addrtype == Xop::XOP_LOC || sd.addrtype == Xop::XOP_CONST_P) && sl.addrtype == Xop::XOP_OFFSET && (sr.addrtype == Xop::XOP_LOC || sr.addrtype == Xop::XOP_CONST_P)) {
		sl.addrtype = Xop::XOP_REGISTER_FILE;
		l->datatype = Xop::XOP_X;
		sl.v.i = regalloc(sl.datasize, 1);
		DOP_ASGN_SOP_INDIR(&sl, l);
	}
	else if (sd.addrtype == Xop::XOP_OFFSET && (sl.addrtype == Xop::XOP_LOC || sl.addrtype == Xop::XOP_CONST_P) && (sr.addrtype == Xop::XOP_LOC || sr.addrtype == Xop::XOP_CONST_P)) {
		sd.addrtype = Xop::XOP_REGISTER_FILE;
		sd.datatype = sl.datatype;
		sd.datasize = sl.datasize;
		sd.v.i = regalloc(sd.datasize, 1);
	}
	else if (sd.addrtype == Xop::XOP_OFFSET && sl.addrtype == Xop::XOP_OFFSET) {
		if ((sd.v.i & 0xffffff00) == (sl.v.i & 0xffffff00)) {
			if (sr.addrtype == Xop::XOP_LOC || sr.addrtype == Xop::XOP_CONST_P) {
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				r->datatype = Xop::XOP_X;
				sr.v.i = regalloc(sr.datasize, 1);
				DOP_ASGN_SOP_INDIR(&sr, r);
			}
			SP_TO_A2A1(sd.v.i);
		}
		else {
			if (sr.addrtype == Xop::XOP_REGISTER_B) {
				sd.addrtype = Xop::XOP_REGISTER_FILE;
				sd.datatype = sl.datatype;
				sd.datasize = sl.datasize;
				sd.v.i = regalloc(sd.datasize, 1);
				SP_TO_A2A1(sl.v.i);
			}
			else {
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				l->datatype = Xop::XOP_X;
				sl.v.i = regalloc(sl.datasize, 1);
				DOP_ASGN_SOP_INDIR(&sl, l);
				if (sr.addrtype == Xop::XOP_LOC || sr.addrtype == Xop::XOP_CONST_P) {
					sd.addrtype = Xop::XOP_REGISTER_FILE;
					sd.datatype = sl.datatype;
					sd.datasize = sl.datasize;
					sd.v.i = regalloc(sd.datasize, 1);
				}
				else {
					SP_TO_A2A1(sd.v.i);
				}
			}
		}
	}
	else if (sd.addrtype == Xop::XOP_OFFSET && sr.addrtype == Xop::XOP_OFFSET) {
		if ((sd.v.i & 0xffffff00) == (sr.v.i & 0xffffff00)) {
			if (sl.addrtype == Xop::XOP_LOC || sl.addrtype == Xop::XOP_CONST_P) {
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				l->datatype = Xop::XOP_X;
				sl.v.i = regalloc(sl.datasize, 1);
				DOP_ASGN_SOP_INDIR(&sl, l);
			}
			SP_TO_A2A1(sd.v.i);
		}
		else {
			if (sl.addrtype == Xop::XOP_REGISTER_A) {
				sd.addrtype = Xop::XOP_REGISTER_FILE;
				sd.datatype = sl.datatype;
				sd.datasize = sl.datasize;
				sd.v.i = regalloc(sd.datasize, 1);
				SP_TO_A2A1(sr.v.i);
			}
			else {
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				r->datatype = Xop::XOP_X;
				sr.v.i = regalloc(sr.datasize, 1);
				DOP_ASGN_SOP_INDIR(&sr, r);
				if (sl.addrtype == Xop::XOP_LOC || sl.addrtype == Xop::XOP_CONST_P) {
					sd.addrtype = Xop::XOP_REGISTER_FILE;
					sd.datatype = sl.datatype;
					sd.datasize = sl.datasize;
					sd.v.i = regalloc(sd.datasize, 1);
				}
				else {
					SP_TO_A2A1(sd.v.i);
				}
			}
		}
	}
	else if (sl.addrtype == Xop::XOP_OFFSET && sr.addrtype == Xop::XOP_OFFSET) {
		if ((sl.v.i & 0xffffff00) == (sr.v.i & 0xffffff00)) {
			if (sd.addrtype == Xop::XOP_LOC || sd.addrtype == Xop::XOP_CONST_P) {
				sd.addrtype = Xop::XOP_REGISTER_FILE;
				sd.datatype = sl.datatype;
				sd.datasize = sl.datasize;
				sd.v.i = regalloc(sd.datasize, 1);
			}
			SP_TO_A2A1(sl.v.i);
		}
		else {
			sr.addrtype = Xop::XOP_REGISTER_FILE;
			r->datatype = Xop::XOP_X;
			sr.v.i = regalloc(sr.datasize, 1);
			DOP_ASGN_SOP_INDIR(&sr, r);
			if (sd.addrtype == Xop::XOP_LOC || sd.addrtype == Xop::XOP_CONST_P) {
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				l->datatype = Xop::XOP_X;
				sl.v.i = regalloc(sl.datasize, 1);
				DOP_ASGN_SOP_INDIR(&sl, l);
			}
			else {
				SP_TO_A2A1(sl.v.i);
			}
		}
	}
	else if (sd.addrtype == Xop::XOP_OFFSET) {
		if (sl.addrtype == Xop::XOP_LOC || sr.addrtype == Xop::XOP_LOC || sl.addrtype == Xop::XOP_CONST_P || sr.addrtype == Xop::XOP_CONST_P ||
			((sl.addrtype == Xop::XOP_REGISTER_A || sr.addrtype == Xop::XOP_REGISTER_B) && (sd.v.i & 0xffffff00) != 0)) {
			sd.addrtype = Xop::XOP_REGISTER_FILE;
			sd.datatype = sl.datatype;
			sd.datasize = sl.datasize;
			sd.v.i = regalloc(sd.datasize, 1);
		}
		else {
			SP_TO_A2A1(sd.v.i);
		}
	}
	else if (sl.addrtype == Xop::XOP_OFFSET) {
		if (sd.addrtype == Xop::XOP_LOC || sr.addrtype == Xop::XOP_LOC || sd.addrtype == Xop::XOP_CONST_P || sr.addrtype == Xop::XOP_CONST_P) {
			sl.addrtype = Xop::XOP_REGISTER_FILE;
			l->datatype = Xop::XOP_X;
			sl.v.i = regalloc(sl.datasize, 1);
			DOP_ASGN_SOP_INDIR(&sl, l);
		}
		else {
			SP_TO_A2A1(sl.v.i);
		}
	}
	else if (sr.addrtype == Xop::XOP_OFFSET) {
		if (sd.addrtype == Xop::XOP_LOC || sl.addrtype == Xop::XOP_LOC || sd.addrtype == Xop::XOP_CONST_P || sl.addrtype == Xop::XOP_CONST_P) {
			sr.addrtype = Xop::XOP_REGISTER_FILE;
			r->datatype = Xop::XOP_X;
			sr.v.i = regalloc(sr.datasize, 1);
			DOP_ASGN_SOP_INDIR(&sr, r);
		}
		else {
			SP_TO_A2A1(sr.v.i);
		}
	}
	if (d != NULL && sd.addrtype != Xop::XOP_VOID)
		*d = sd;
	if (l != NULL && sl.addrtype != Xop::XOP_VOID)
		*l = sl;
	if (r != NULL && sr.addrtype != Xop::XOP_VOID)
		*r = sr;
}

/*��������x�ֽ�����A�Ĵ���*/
void A_ASGN_OP(Xop* op, char x) {
	switch (op->addrtype) {
	case Xop::XOP_LOC:
		insertaddr(op->entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, op->v.i + x);
		A_ASGN__RAM(0);
		reset_cpu_o();
		break;
	case Xop::XOP_OFFSET:
		A0_ASGN_IMMNUM_O(op->v.i + x);
		A_ASGN_RAM();
		break;
	case Xop::XOP_REGISTER_FILE: A_ASGN__RF_O(op->v.i + x); break;
	case Xop::XOP_CONST:
		if (op->datatype == Xop::XOP_I)
			A_ASGN_IMMNUM(op->v.i >> (x * 8));
		else if (op->datatype == Xop::XOP_U)
			A_ASGN_IMMNUM(op->v.u >> (x * 8));
		else if (op->datatype == Xop::XOP_F) {
			if (op->datasize == 4) {
				float f = op->v.d;
				A_ASGN_IMMNUM(*((unsigned long*)&f) >> (8 * x));
			}
			else {
				double d = op->v.d;
				unsigned long* p = (unsigned long*)&d;
				if (x < 4)
					A_ASGN_IMMNUM(p[swap] >> (8 * x));
				else
					A_ASGN_IMMNUM(p[1 - swap] >> ((x - 4) * 8));
			}
		}
		else
			error("���A_ASGN_OP�������ɻ��������д���\n");
		break;
	case Xop::XOP_CONST_P: A_ASGN__RAM_O(op->v.u + x); break;
	case Xop::XOP_REGISTER_IO0: A_ASGN_IO0(); break;
	case Xop::XOP_REGISTER_IO1: A_ASGN_IO1(); break;
	case Xop::XOP_REGISTER_A: break;
	default: error("���A_ASGN_OP�������ɻ��������д���\n");
	}
}

/*��������x�ֽ�����B�Ĵ���*/
void B_ASGN_OP(Xop* op, char x) {
	switch (op->addrtype) {
	case Xop::XOP_LOC:
		insertaddr(op->entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, op->v.i + x);
		B_ASGN__RAM(0);
		reset_cpu_o();
		break;
	case Xop::XOP_OFFSET:
		A0_ASGN_IMMNUM_O(op->v.i + x);
		B_ASGN_RAM();
		break;
	case Xop::XOP_REGISTER_FILE: B_ASGN__RF_O(op->v.i + x); break;
	case Xop::XOP_CONST:
		if (op->datatype == Xop::XOP_I)
			B_ASGN_IMMNUM(op->v.i >> (x * 8));
		else if (op->datatype == Xop::XOP_U)
			B_ASGN_IMMNUM(op->v.u >> (x * 8));
		else if (op->datatype == Xop::XOP_F) {
			if (op->datasize == 4) {
				float f = op->v.d;
				B_ASGN_IMMNUM(*((unsigned long*)&f) >> (8 * x));
			}
			else {
				double d = op->v.d;
				unsigned long* p = (unsigned long*)&d;
				if (x < 4)
					B_ASGN_IMMNUM(p[swap] >> (8 * x));
				else
					B_ASGN_IMMNUM(p[1 - swap] >> ((x - 4) * 8));
			}
		}
		else
			error("���B_ASGN_OP�������ɻ��������д���\n");
		break;
	case Xop::XOP_CONST_P: B_ASGN__RAM_O(op->v.u + x); break;
	case Xop::XOP_REGISTER_IO0: B_ASGN_IO0(); break;
	case Xop::XOP_REGISTER_IO1: B_ASGN_IO1(); break;
	case Xop::XOP_REGISTER_B: break;
	default: error("���B_ASGN_OP�������ɻ��������д���\n");
	}
}

/*ALU���������������x�ֽ�*/
void OP_ASGN_ALU(Xop* op, char x, unsigned char aluaddr) {
	switch (op->addrtype) {
	case Xop::XOP_LOC:
		insertaddr(op->entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, op->v.i + x);
		_RAM_ASGN_ALU(0, aluaddr);
		reset_cpu_o();
		break;
	case Xop::XOP_OFFSET:
		A0_ASGN_IMMNUM_O(op->v.i + x);
		RAM_ASGN_ALU(aluaddr);
		break;
	case Xop::XOP_REGISTER_FILE: _RF_ASGN_ALU_O(op->v.i + x, aluaddr); break;
	case Xop::XOP_CONST_P: _RAM_ASGN_ALU_O(op->v.u + x, aluaddr); break;
	case Xop::XOP_REGISTER_IO0: IO0_ASGN_ALU(aluaddr); break;
	case Xop::XOP_REGISTER_IO1: IO1_ASGN_ALU(aluaddr); break;
	case Xop::XOP_REGISTER_A: A_ASGN_ALU(aluaddr); break;
	case Xop::XOP_REGISTER_B: B_ASGN_ALU(aluaddr); break;
	default: error("���OP_ASGN_ALU�������ɻ��������д���\n");
	}
}

/*Դ��������Ŀ�Ĳ�����*/
void DOP_ASGN_SOP(Xop* d, Xop* s) {
	Xop sd = *d, ss = *s;

	if (LOC_OFFSET_CONST_P_OR(sd.addrtype) && sd.datatype == Xop::XOP_P) {
		sd.addrtype = Xop::XOP_REGISTER_FILE;
		sd.v.i = regalloc(sd.datasize, 1);
		d->datatype = Xop::XOP_X;
		DOP_ASGN_SOP_INDIR(&sd, d);
		d->datatype = sd.datatype;
	}
	if (LOC_OFFSET_CONST_P_OR(sd.addrtype) && sd.datatype == Xop::XOP_X && LOC_OFFSET_CONST_P_OR(ss.addrtype) && ss.datatype != Xop::XOP_X) {
		addr_convert(&sd, &ss, NULL);
		for (int x = 0; x < ss.datasize; ++x) {
			A_ASGN_OP(&ss, x);
			OP_ASGN_ALU(&sd, x, ALU_OUTA);
		}
		if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
			DOP_ASGN_SOP(d, &sd);
			regfree(sd.v.i, sd.datasize);
		}
		if (ss.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(ss.v.i, ss.datasize);
	}
	else {
		if ((LOC_OFFSET_CONST_P_OR(sd.addrtype) && sd.datatype == Xop::XOP_X) || (sd.addrtype == Xop::XOP_REGISTER_FILE && sd.datatype == Xop::XOP_P)) {
			unsigned long cp[3];

			if (LOC_OFFSET_CONST_P_OR(ss.addrtype) && ss.datatype != Xop::XOP_X) {
				ss.addrtype = Xop::XOP_REGISTER_FILE;
				ss.v.i = regalloc(ss.datasize, 1);
				s->datatype = Xop::XOP_X;
				DOP_ASGN_SOP_INDIR(&ss, s);
				s->datatype = ss.datatype;
			}
			for (int x = 0; x < ss.datasize; ++x) {
				switch (sd.addrtype) {
				case Xop::XOP_LOC:
					insertaddr(sd.entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, sd.v.i + x);
					A2A1A0_ASGN_IMMNUM(0);
					reset_cpu_o();
					break;
				case Xop::XOP_OFFSET:
					if (x == 0)
						SP_TO_A2A1(sd.v.i);
					else if ((sd.v.i + x & 255) == 0)
						SP_TO_A2A1(sd.v.i + x);
					A0_ASGN_IMMNUM_O(sd.v.i + x);
					break;
				case Xop::XOP_CONST_P: A2A1A0_ASGN_IMMNUM_O(sd.v.u + x); break;
				case Xop::XOP_REGISTER_FILE: REGISTER_TO_A2A1A0(sd.v.i, x); break;
				default: error("���DOP_ASGN_SOP����Ŀ�Ĳ���������\n");
				}
				switch (ss.addrtype) {
				case Xop::XOP_LOC:
					RAM_ASGN_IMMNUM(0);
					cp[x] = rom_cp - 1;
					break;
				case Xop::XOP_OFFSET:
					if (x == 0) {
						RAM_ASGN_IMMNUM(ss.v.i);
					}
					else if (x == 1) {
						if ((ss.v.i & 0xffffff00) == 0)
							RAM_ASGN__RF(REGISTER_FILE_SP);
						else {
							A_ASGN__RF(REGISTER_FILE_SP);
							B_ASGN_IMMNUM(ss.v.i >> 8);
							RAM_ASGN_ALU(ALU_ADD);
							B_ASGN_ALU(ALU_ADD_C);
						}
					}
					else if (x == 2) {
						if ((ss.v.i & 0xffffff00) == 0)
							RAM_ASGN__RF(REGISTER_FILE_SP + 1);
						else {
							A_ASGN__RF(REGISTER_FILE_SP + 1);
							RAM_ASGN_ALU(ALU_ADD);
						}
					}
					else
						error("���DOP_ASGN_SOP�������ɻ��������д���\n");
					break;
				case Xop::XOP_CONST_P:
					RAM_ASGN_IMMNUM(ss.v.u >> (x * 8));
					break;
				case Xop::XOP_REGISTER_FILE:
					RAM_ASGN__RF_O(ss.v.i + x);
					break;
				case Xop::XOP_CONST:
					if (ss.datatype == Xop::XOP_I)
						RAM_ASGN_IMMNUM(ss.v.i >> (x * 8));
					else if (ss.datatype == Xop::XOP_U)
						RAM_ASGN_IMMNUM(ss.v.u >> (x * 8));
					else if (ss.datatype == Xop::XOP_F) {
						if (ss.datasize == 4) {
							float f = ss.v.d;
							RAM_ASGN_IMMNUM(*((unsigned long*)&f) >> (x * 8));
						}
						else {
							double d = ss.v.d;
							unsigned long* p = (unsigned long*)&d;
							if (x < 4)
								RAM_ASGN_IMMNUM(p[swap] >> (x * 8));
							else
								RAM_ASGN_IMMNUM(p[1 - swap] >> ((x - 4) * 8));
						}
					}
					else
						error("���DOP_ASGN_SOP����Դ����������\n");
					break;
				case Xop::XOP_REGISTER_IO0:
					if(ss.datatype == Xop::XOP_I || ss.datatype == Xop::XOP_U)
						RAM_ASGN_IO0();
					else
						error("���DOP_ASGN_SOP����Դ����������\n");
					break;
				case Xop::XOP_REGISTER_IO1:
					if (ss.datatype == Xop::XOP_I || ss.datatype == Xop::XOP_U)
						RAM_ASGN_IO1();
					else
						error("���DOP_ASGN_SOP����Դ����������\n");
					break;
				default: error("���DOP_ASGN_SOP����Դ����������\n");
				}
			}
			if (ss.addrtype == Xop::XOP_LOC)
				insertaddr(ss.entry, cp[2], cp[1], cp[0], ss.v.i);
		}
		else if (sd.addrtype == Xop::XOP_REGISTER_IO0 && sd.datatype == Xop::XOP_X && ss.datatype != Xop::XOP_X && ss.datasize == 1) {
			switch (ss.addrtype) {
			case Xop::XOP_LOC:
				insertaddr(ss.entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, ss.v.i);
				IO0_ASGN__RAM(0);
				reset_cpu_o();
				break;
			case Xop::XOP_OFFSET:
				SP_TO_A2A1(ss.v.i);
				A0_ASGN_IMMNUM_O(ss.v.i);
				IO0_ASGN_RAM();
				break;
			case Xop::XOP_CONST_P: IO0_ASGN__RAM_O(ss.v.u); break;
			case Xop::XOP_REGISTER_FILE: IO0_ASGN__RF_O(ss.v.i); break;
			case Xop::XOP_CONST: IO0_ASGN_IMMNUM(ss.v.u); break;
			case Xop::XOP_REGISTER_IO0: IO0_ASGN_IO0(); break;
			case Xop::XOP_REGISTER_IO1: IO0_ASGN_IO1(); break;
			default: error("���DOP_ASGN_SOP����Դ����������\n");
			}
		}
		else if (sd.addrtype == Xop::XOP_REGISTER_IO1 && sd.datatype == Xop::XOP_X && ss.datatype != Xop::XOP_X && ss.datasize == 1) {
			switch (ss.addrtype) {
			case Xop::XOP_LOC:
				insertaddr(ss.entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, ss.v.i);
				IO1_ASGN__RAM(0);
				reset_cpu_o();
				break;
			case Xop::XOP_OFFSET:
				SP_TO_A2A1(ss.v.i);
				A0_ASGN_IMMNUM_O(ss.v.i);
				IO1_ASGN_RAM();
				break;
			case Xop::XOP_CONST_P: IO1_ASGN__RAM_O(ss.v.u); break;
			case Xop::XOP_REGISTER_FILE: IO1_ASGN__RF_O(ss.v.i); break;
			case Xop::XOP_CONST: IO1_ASGN_IMMNUM(ss.v.u); break;
			case Xop::XOP_REGISTER_IO0: IO1_ASGN_IO0(); break;
			case Xop::XOP_REGISTER_IO1: IO1_ASGN_IO1(); break;
			default: error("���DOP_ASGN_SOP����Դ����������\n");
			}
		}
		else
			error("���DOP_ASGN_SOP�������ɻ��������д���\n");
		if (sd.addrtype == Xop::XOP_REGISTER_FILE && sd.addrtype != d->addrtype)
			regfree(sd.v.i, sd.datasize);
		if (ss.addrtype == Xop::XOP_REGISTER_FILE && ss.addrtype != s->addrtype)
			regfree(ss.v.i, ss.datasize);
	}
}

/*��λ��ַ��ƫ�Ƶ�ַ���ַ���������Ĵ�����*/
void LOC_OFFSET_CONST_P_TO_REGISTER_FILE(Xop* d, Xop* s) {
	if (d->addrtype == Xop::XOP_REGISTER_FILE && LOC_OFFSET_CONST_P_OR(s->addrtype) && s->datatype == Xop::XOP_X) {
		unsigned long cp[3];
		int x;
		for (x = 0; x < s->datasize; ++x) {
			switch (s->addrtype) {
			case Xop::XOP_LOC:
				_RF_ASGN_IMMNUM_O(d->v.i + x, 0);
				cp[x] = rom_cp - 1;
				break;
			case Xop::XOP_OFFSET:
				if (x == 0) {
					_RF_ASGN_IMMNUM_O(d->v.i, s->v.i);
				}
				else if (x == 1) {
					A_ASGN__RF(REGISTER_FILE_SP);
					if ((s->v.i & 0xffffff00) == 0) {
						_RF_ASGN_ALU(d->v.i + 1, ALU_OUTA);
					}
					else {
						B_ASGN_IMMNUM(s->v.i >> 8);
						_RF_ASGN_ALU(d->v.i + 1, ALU_ADD);
						B_ASGN_ALU(ALU_ADD_C);
					}
				}
				else if (x == 2) {
					A_ASGN__RF(REGISTER_FILE_SP + 1);
					if ((s->v.i & 0xffffff00) == 0)
						_RF_ASGN_ALU(d->v.i + 2, ALU_OUTA);
					else
						_RF_ASGN_ALU(d->v.i + 2, ALU_ADD);
				}
				break;
			case Xop::XOP_CONST_P:
				_RF_ASGN_IMMNUM_O(d->v.i + x, s->v.u >> (x * 8));
				break;
			}
		}
		if (s->addrtype == Xop::XOP_LOC)
			insertaddr(s->entry, cp[2], cp[1], cp[0], s->v.i);
	}
	else
		error("���LOC_OFFSET_CONST_P_TO_REGISTER_FILE�������ɻ��������д���\n");
}

/*3�ֽ�(24λ)�Ĵ�����1*/
void REGISTER_BYTE_3_ADD_1(unsigned char regaddr) {
	A_ASGN__RF_O(regaddr);
	RF_ASGN_ALU(ALU_A_ADD_1);
	B_ASGN_ALU(ALU_A_ADD_1_C);
	A_ASGN__RF(regaddr + 1);
	RF_ASGN_ALU(ALU_ADD);
	B_ASGN_ALU(ALU_ADD_C);
	A_ASGN__RF(regaddr + 2);
	RF_ASGN_ALU(ALU_ADD);
}

/*Դ��������Ŀ�Ĳ�����(�ṹ��)*/
void DOP_ASGN_SOP_B(Xop* d, Xop* s, unsigned long size) {
	Xop sd = *d, ss = *s;

	if (size <= 16 && LOC_OFFSET_CONST_P_OR(sd.addrtype) && (sd.datatype == Xop::XOP_P || sd.datatype == Xop::XOP_X)) {
		if (LOC_OFFSET_CONST_P_OR(ss.addrtype) && ss.datatype == Xop::XOP_B) {
			ss.datasize = size;
			DOP_ASGN_SOP(d, &ss);
		}
		else if (ss.addrtype == Xop::XOP_REGISTER_FILE && ss.datatype == Xop::XOP_B) {
			ss.datasize = size;
			ss.v.i = regalloc(size, 1);
			s->datatype = Xop::XOP_P;
			DOP_ASGN_SOP_INDIR(&ss, s);
			s->datatype = Xop::XOP_B;
			DOP_ASGN_SOP(d, &ss);
		}
		else
			error("���DOP_ASGN_SOP_B����Դ����������\n");
	}
	else {
		/*Ŀ�Ĳ�������ַָ��ָ���������ָ�����ݼ��ص��Ĵ���*/
		if (LOC_OFFSET_CONST_P_OR(sd.addrtype) && sd.datatype == Xop::XOP_P) {
			sd.addrtype = Xop::XOP_REGISTER_FILE;
			sd.v.i = regalloc(sd.datasize, 1);
			d->datatype = Xop::XOP_X;
			DOP_ASGN_SOP_INDIR(&sd, d);
			d->datatype = sd.datatype;
		}
		/*Ŀ�Ĳ�������ַ���ص��Ĵ���*/
		if (LOC_OFFSET_CONST_P_OR(sd.addrtype) && sd.datatype == Xop::XOP_X) {
			sd.addrtype = Xop::XOP_REGISTER_FILE;
			sd.datatype = Xop::XOP_P;
			sd.v.i = regalloc(sd.datasize, 1);
			LOC_OFFSET_CONST_P_TO_REGISTER_FILE(&sd, d);
		}
		/*Դ��������ַ���ص��Ĵ���*/
		if (LOC_OFFSET_CONST_P_OR(ss.addrtype) && ss.datatype == Xop::XOP_B) {
			ss.addrtype = Xop::XOP_REGISTER_FILE;
			ss.datatype = Xop::XOP_P;
			ss.v.i = regalloc(ss.datasize, 1);
			s->datatype = Xop::XOP_X;
			LOC_OFFSET_CONST_P_TO_REGISTER_FILE(&ss, s);
			ss.datatype = s->datatype = Xop::XOP_B;
		}
		if (sd.addrtype == Xop::XOP_REGISTER_FILE && sd.datatype == Xop::XOP_P && ss.addrtype == Xop::XOP_REGISTER_FILE && ss.datatype == Xop::XOP_B) {
			/*����޸ĵ�ԭ�Ĵ�������ԭ�Ĵ����������ڵ������򴴽��¼Ĵ���*/
			if (d->addrtype == Xop::XOP_REGISTER_FILE && glowreg[d->v.i].life > 1) {
				sd.v.i = regalloc(sd.datasize, 1);
				for (int i = 0; i < sd.datasize; ++i) {
					A_ASGN__RF(d->v.i + i);
					_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
				}
			}
			if (s->addrtype == Xop::XOP_REGISTER_FILE && glowreg[s->v.i].life > 1) {
				ss.v.i = regalloc(ss.datasize, 1);
				for (int i = 0; i < ss.datasize; ++i) {
					A_ASGN__RF(s->v.i + i);
					_RF_ASGN_ALU(ss.v.i + i, ALU_OUTA);
				}
			}
			/*������������ָ��*/
			if (size <= 256) {
				unsigned long label_0;
				unsigned char reg_cp = regalloc(1, 1);

				_RF_ASGN_IMMNUM(reg_cp, size - 1);
				label_0 = rom_cp >> 1;
				reset_cpu_o();
				REGISTER_TO_A2A1A0(ss.v.i, 0);
				A_ASGN_RAM();
				REGISTER_TO_A2A1A0(sd.v.i, 0);
				RAM_ASGN_ALU(ALU_OUTA);
				REGISTER_BYTE_3_ADD_1(ss.v.i);
				REGISTER_BYTE_3_ADD_1(sd.v.i);
				A_ASGN__RF(reg_cp);
				RF_ASGN_ALU(ALU_A_SUB_1);
				IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				regfree(reg_cp, 1);
			}
			else if (size <= 65536) {
				unsigned long label_0;
				unsigned char reg_cp = regalloc(2, 1);

				_RF_ASGN_IMMNUM(reg_cp, size - 1);
				_RF_ASGN_IMMNUM(reg_cp + 1, (size - 1) >> 8);
				label_0 = rom_cp >> 1;
				reset_cpu_o();
				REGISTER_TO_A2A1A0(ss.v.i, 0);
				A_ASGN_RAM();
				REGISTER_TO_A2A1A0(sd.v.i, 0);
				RAM_ASGN_ALU(ALU_OUTA);
				REGISTER_BYTE_3_ADD_1(ss.v.i);
				REGISTER_BYTE_3_ADD_1(sd.v.i);
				A_ASGN__RF(reg_cp);
				RF_ASGN_ALU(ALU_A_SUB_1);
				B_ASGN_ALU(ALU_A_SUB_1_C);
				A_ASGN__RF(reg_cp + 1);
				RF_ASGN_ALU(ALU_SUB);
				IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, label_0);

				regfree(reg_cp, 2);
			}
			else if (size <= 16777216) {
				unsigned long label_0;
				unsigned char reg_cp = regalloc(3, 1);

				_RF_ASGN_IMMNUM(reg_cp, size - 1);
				_RF_ASGN_IMMNUM(reg_cp + 1, (size - 1) >> 8);
				_RF_ASGN_IMMNUM(reg_cp + 2, (size - 1) >> 16);
				label_0 = rom_cp >> 1;
				reset_cpu_o();
				REGISTER_TO_A2A1A0(ss.v.i, 0);
				A_ASGN_RAM();
				REGISTER_TO_A2A1A0(sd.v.i, 0);
				RAM_ASGN_ALU(ALU_OUTA);
				REGISTER_BYTE_3_ADD_1(ss.v.i);
				REGISTER_BYTE_3_ADD_1(sd.v.i);
				A_ASGN__RF(reg_cp);
				RF_ASGN_ALU(ALU_A_SUB_1);
				B_ASGN_ALU(ALU_A_SUB_1_C);
				A_ASGN__RF(reg_cp + 1);
				RF_ASGN_ALU(ALU_SUB);
				B_ASGN_ALU(ALU_SUB_C);
				A_ASGN__RF(reg_cp + 2);
				RF_ASGN_ALU(ALU_SUB);
				IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, label_0);

				regfree(reg_cp, 3);
			}
			else
				error("���DOP_ASGN_SOP_B����size�������\n");
		}
		else
			error("���DOP_ASGN_SOP_B�������ɻ��������д���\n");
	}
	if ((sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) || (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype == Xop::XOP_REGISTER_FILE && sd.v.i != d->v.i))
		regfree(sd.v.i, sd.datasize);
	if ((ss.addrtype == Xop::XOP_REGISTER_FILE && s->addrtype != Xop::XOP_REGISTER_FILE) || (ss.addrtype == Xop::XOP_REGISTER_FILE && s->addrtype == Xop::XOP_REGISTER_FILE && ss.v.i != s->v.i))
		regfree(ss.v.i, ss.datasize);
}

/*�������ͼĴ�����*/
void REGISTER_FILE_ASGN_OP(Xop* d, Xop* s) {
	Xop sd = *d, ss = *s;
	if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
		switch (ss.addrtype) {
		case Xop::XOP_LOC: case Xop::XOP_OFFSET: case Xop::XOP_CONST_P:
			if (ss.datatype != Xop::XOP_X) {
				ss.datatype = Xop::XOP_X;
				if (sd.datasize > ss.datasize)
					sd.datasize = ss.datasize;
				DOP_ASGN_SOP_INDIR(&sd, &ss);
			}
			else
				error("���REGISTER_FILE_ASGN_OP�������ɻ��������д���\n");
			break;
		case Xop::XOP_REGISTER_FILE:
			if (sd.v.i != ss.v.i) {
				if (sd.datasize > ss.datasize)
					sd.datasize = ss.datasize;
				for (int i = 0; i < sd.datasize; ++i) {
					A_ASGN__RF(ss.v.i + i);
					_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
				}
			}
			break;
		case Xop::XOP_CONST:
			if (sd.datasize > ss.datasize)
				sd.datasize = ss.datasize;
			if (ss.datatype == Xop::XOP_U) {
				for (int i = 0; i < sd.datasize; ++i)
					_RF_ASGN_IMMNUM_O(sd.v.i + i, ss.v.u >> (i * 8));
			}
			else if (ss.datatype == Xop::XOP_I) {
				for (int i = 0; i < sd.datasize; ++i)
					_RF_ASGN_IMMNUM_O(sd.v.i + i, ss.v.i >> (i * 8));
			}
			else if (ss.datatype == Xop::XOP_F) {
				for (int i = 0; i < sd.datasize; ++i) {
					if (ss.datasize == 4) {
						float f = ss.v.d;
						_RF_ASGN_IMMNUM(sd.v.i + i, *((unsigned long*)&f) >> (8 * i));
					}
					else {
						double d = ss.v.d;
						unsigned long* p = (unsigned long*)&d;
						if (i < 4)
							_RF_ASGN_IMMNUM(sd.v.i + i, p[swap] >> (8 * i));
						else
							_RF_ASGN_IMMNUM(sd.v.i + i, p[1 - swap] >> ((i - 4) * 8));
					}
				}
			}
			else
				error("���REGISTER_FILE_ASGN_OP�������ɻ��������д���\n");
			break;
		case Xop::XOP_REGISTER_IO0: _RF_ASGN_IO0(sd.v.i); break;
		case Xop::XOP_REGISTER_IO1: _RF_ASGN_IO1(sd.v.i); break;
		default:
			error("���REGISTER_FILE_ASGN_OP�������ɻ��������д���\n");
		}
	}
	else
		error("���REGISTER_FILE_ASGN_OP�������ɻ��������д���\n");
}

unsigned long float_add_func_romaddr; //float�ӷ�������ڵ�ַ
unsigned long float_sub_func_romaddr; //float����������ڵ�ַ
unsigned long float_mul_func_romaddr; //float�˷�������ڵ�ַ
unsigned long float_div_func_romaddr; //float����������ڵ�ַ
unsigned long double_add_func_romaddr; //double�ӷ�������ڵ�ַ
unsigned long double_sub_func_romaddr; //double����������ڵ�ַ
unsigned long double_mul_func_romaddr; //double�˷�������ڵ�ַ
unsigned long double_div_func_romaddr; //double����������ڵ�ַ
void float_sub_func_gen();
void double_sub_func_gen();

/*float�ӷ���������,(��ʡ������,���ﲻ������ֵ,����������)*/
void float_add_func_gen() {
	if (float_add_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3, label_4, label_5;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 1;
		unsigned char reg_rsh_cp = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 3;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		float_add_func_romaddr = rom_cp >> 1;

		/*��������ͬ��ת��Ϊ����*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_ALU(ALU_XOR);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		B_ASGN_IMMNUM(0x80);
		RF_ASGN_ALU(ALU_XOR);
		float_sub_func_gen();
		PC_ASGN_IMMNUM(float_sub_func_romaddr);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��ȡָ��,�жϲ������Ƿ�Ϊ0�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��1.0*/
		A_ASGN_IMMNUM(0x80);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		RF_ASGN_ALU(ALU_OR);

		/*����С����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(reg_rsh_cp, ALU_SUB);
		B_ASGN_ALU(ALU_SUB);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		/*ָ�����Ϊ����,�Ҳ���������*/

		A_ASGN_IMMNUM(23);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, 0);
		/*����λ��С�ڵ���23,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 1, ALU_B_AL_RSH);
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_ADD_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_ADD_1_C, label_3);
		label_5 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);
		/*����λ������23,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 2, 0);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		A_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(reg_rop_index, ALU_OUTA);

		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*ָ�����Ϊ����,�����������*/

		A_ASGN_ALU(ALU_OUTB);
		B_ASGN_IMMNUM(24);
		label_5 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		/*����λ��С�ڵ���23,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		A_ASGN_ALU(ALU_A_SUB_1_C);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_B_AL_RSH);
		PC_ASGN_IMMNUM(label_3);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		/*����λ������23,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 2, 0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*24λβ�����*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_c);

		/*����н�λ,β������1λ,ָ����1*/
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_B_AL_RSH);
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_IMMNUM(-127);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*ָ��ת��Ϊԭ��ʽ*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x7f);
		RF_ASGN_ALU(ALU_XOR);

		/*װ��ָ���ͷ���*/
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_B_0_LSH);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*double�ӷ���������,(��ʡ������,���ﲻ������ֵ,����������)*/
void double_add_func_gen() {
	if (double_add_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3, label_4, label_5;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_rsh_cp = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 6;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		double_add_func_romaddr = rom_cp >> 1;

		/*��������ͬ��ת��Ϊ����*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		B_ASGN_ALU(ALU_XOR);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		B_ASGN_IMMNUM(0x80);
		RF_ASGN_ALU(ALU_XOR);
		double_sub_func_gen();
		PC_ASGN_IMMNUM(double_sub_func_romaddr);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��ȡָ��,�жϲ������Ƿ�Ϊ0�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_lop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_rop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*����С����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(reg_rsh_cp, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_lop_index + 1);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(reg_rop_index + 1);
		_RF_ASGN_ALU(reg_rsh_cp + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB);

		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		/*ָ�����Ϊ����,�Ҳ���������*/
		
		B_ASGN_IMMNUM(52);
		A_ASGN__RF(reg_rsh_cp);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, 0);
		/*����λ��С�ڵ���52,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 1, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 2, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 3, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 4, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 5, ALU_B_AL_RSH);
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		RF_ASGN_ALU(ALU_ADD);
		IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, label_3);
		label_5 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);
		/*����λ������52,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 6, 0);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		A_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(reg_rop_index, ALU_OUTA);
		A_ASGN__RF(reg_lop_index + 1);
		_RF_ASGN_ALU(reg_rop_index + 1, ALU_OUTA);

		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*ָ�����Ϊ����,�����������*/

		B_ASGN_IMMNUM(53);
		A_ASGN__RF(reg_rsh_cp);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		label_5 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		/*����λ��С�ڵ���52,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_SUB_1_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		RF_ASGN_ALU(ALU_SUB);
		A_ASGN_ALU(ALU_SUB_C);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_B_AL_RSH);
		PC_ASGN_IMMNUM(label_3);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		/*����λ������52,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 6, 0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);

		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*53λβ�����*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_ADD);

		/*����н�λ,β������1λ,ָ����1*/
		B_ASGN_ALU(ALU_ADD);
		A_ASGN_IMMNUM(0x1f);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_B_AL_RSH);
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_SUB_1_C);
		A_ASGN__RF(reg_rop_index + 1);
		RF_ASGN_ALU(ALU_SUB);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN_IMMNUM(0xfc);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*����β����1.0*/
		A_ASGN_IMMNUM(0x0f);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_AND);
		
		/*ָ��ת��Ϊԭ��ʽ,��װ��ָ���ͷ���*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x10);
		_RF_ASGN_ALU(reg_c, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN_IMMNUM(0xf0);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_OR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x10);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_c);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x3f);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_ALU(ALU_OUTA);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*float������������,(��ʡ������,���ﲻ������ֵ,����������)*/
void float_sub_func_gen() {
	if (float_sub_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3, label_4, label_5;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 1;
		unsigned char reg_rsh_cp = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 3;
		unsigned char reg_lsh_cp = REGISTER_FILE_OP_FUNC_CACHE + 4;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		float_sub_func_romaddr = rom_cp >> 1;

		/*��������ͬ��ת��Ϊ�ӷ�*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_ALU(ALU_XOR);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		B_ASGN_IMMNUM(0x80);
		RF_ASGN_ALU(ALU_XOR);
		float_add_func_gen();
		PC_ASGN_IMMNUM(float_add_func_romaddr);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��ȡָ��,�жϲ������Ƿ�Ϊ0�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		A_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_ALU(ALU_EQUAL_C);
		A_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_XOR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_XOR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��1.0*/
		A_ASGN_IMMNUM(0x80);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		RF_ASGN_ALU(ALU_OR);

		/*����С����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(reg_rsh_cp, ALU_SUB);
		B_ASGN_ALU(ALU_SUB);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		/*ָ�����Ϊ����,�Ҳ���������*/

		A_ASGN_IMMNUM(23);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, 0);
		/*����λ��С�ڵ���23,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 1, ALU_B_AL_RSH);
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_ADD_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_ADD_1_C, label_3);
		label_5 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);
		/*����λ������23,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 2, 0);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		A_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(reg_rop_index, ALU_OUTA);

		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*ָ�����Ϊ����,�����������*/

		A_ASGN_ALU(ALU_OUTB);
		B_ASGN_IMMNUM(24);
		label_5 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		/*����λ��С�ڵ���23,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		A_ASGN_ALU(ALU_A_SUB_1_C);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_B_AL_RSH);
		PC_ASGN_IMMNUM(label_3);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		/*����λ������23,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 2, 0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);

		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*24λβ�����*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);

		/*����н�λ,β��ȡ����1,����ȡ��*/
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		RF_ASGN_ALU(ALU_A_NOT);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β�����λ����1.0,β��Ϊ0��������Ϊ0*/
		_RF_ASGN_IMMNUM(reg_lsh_cp, 23);
		label_2 = rom_cp >> 1;
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(reg_lsh_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_2);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*����ָ����ת��Ϊԭ��ʽ*/
		B_ASGN_IMMNUM(23);
		A_ASGN__RF(reg_lsh_cp);
		B_ASGN_ALU(ALU_SUB);
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_SUB);
		B_ASGN_IMMNUM(128);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		A_ASGN_IMMNUM(126);
		B_ASGN__RF(reg_rop_index);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		B_ASGN__RF(reg_rop_index);
		A_ASGN_IMMNUM(0x7f);
		RF_ASGN_ALU(ALU_XOR);

		/*װ��ָ���ͷ���*/
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_B_0_LSH);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*double������������,(��ʡ������,���ﲻ������ֵ,����������)*/
void double_sub_func_gen() {
	if (double_sub_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3, label_4, label_5;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_rsh_cp = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 6;
		unsigned char reg_lsh_cp = REGISTER_FILE_OP_FUNC_CACHE + 7;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		double_sub_func_romaddr = rom_cp >> 1;

		/*��������ͬ��ת��Ϊ�ӷ�*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		B_ASGN_ALU(ALU_XOR);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		B_ASGN_IMMNUM(0x80);
		RF_ASGN_ALU(ALU_XOR);
		double_add_func_gen();
		PC_ASGN_IMMNUM(double_add_func_romaddr);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��ȡָ��*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_lop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_rop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		/*���������nan���nan*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*�Ҳ�������nan���nan*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*����������Ҳ�����������������nan*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*�Ҳ�������0����������*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*�Ҳ�������������������ȡ���������*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_XOR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*���������0�����������Ҳ�����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_XOR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*����������������������*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*����С����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(reg_rsh_cp, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_lop_index + 1);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(reg_rop_index + 1);
		_RF_ASGN_ALU(reg_rsh_cp + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB);

		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		/*ָ�����Ϊ����,�Ҳ���������*/

		B_ASGN_IMMNUM(52);
		A_ASGN__RF(reg_rsh_cp);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, 0);
		/*����λ��С�ڵ���52,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 1, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 2, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 3, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 4, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 5, ALU_B_AL_RSH);
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		RF_ASGN_ALU(ALU_ADD);
		IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, label_3);
		label_5 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);
		/*����λ������52,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_ROP + 6, 0);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		A_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(reg_rop_index, ALU_OUTA);
		A_ASGN__RF(reg_lop_index + 1);
		_RF_ASGN_ALU(reg_rop_index + 1, ALU_OUTA);

		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*ָ�����Ϊ����,�����������*/

		B_ASGN_IMMNUM(53);
		A_ASGN__RF(reg_rsh_cp);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		label_5 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		/*����λ��С�ڵ���52,ִ����λ*/
		label_3 = rom_cp >> 1;
		A_ASGN__RF(reg_rsh_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_SUB_1_C);
		A_ASGN__RF(reg_rsh_cp + 1);
		RF_ASGN_ALU(ALU_SUB);
		A_ASGN_ALU(ALU_SUB_C);
		label_4 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_B_AL_RSH);
		PC_ASGN_IMMNUM(label_3);
		MODIFY_A2A1A0(label_5, rom_cp >> 1);
		/*����λ������52,��0������ֵ*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_LOP + 6, 0);
		MODIFY_A2A1A0(label_4, rom_cp >> 1);

		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*53λβ�����*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_SUB);

		/*����н�λ,β��ȡ����1,����ȡ��*/
		B_ASGN_ALU(ALU_SUB);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		RF_ASGN_ALU(ALU_A_NOT);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β�����λ����1.0,β��Ϊ0��������Ϊ0*/
		_RF_ASGN_IMMNUM(reg_lsh_cp, 52);
		label_2 = rom_cp >> 1;
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		B_ASGN_IMMNUM(0x10);
		A_ASGN_ALU(ALU_MUL_H);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(reg_lsh_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_2);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*����ָ��*/
		B_ASGN__RF(reg_lsh_cp);
		A_ASGN_IMMNUM(52);
		B_ASGN_ALU(ALU_SUB);
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_rop_index + 1);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		B_ASGN__RF(reg_rop_index);
		A_ASGN_IMMNUM(0xfe);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(reg_rop_index + 1);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*����β����1.0*/
		A_ASGN_IMMNUM(0x0f);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_AND);

		/*ָ��ת��Ϊԭ��ʽ,��װ��ָ���ͷ���*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x10);
		_RF_ASGN_ALU(reg_c, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN_IMMNUM(0xf0);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_OR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x10);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_c);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x3f);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_ALU(ALU_OUTA);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*float�˷���������,(��ʡ������,���ﲻ������ֵ,����������)*/
void float_mul_func_gen() {
	if (float_mul_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 1;
		unsigned char reg_1 = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_2 = REGISTER_FILE_OP_FUNC_CACHE + 3;
		unsigned char reg_3 = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_4 = REGISTER_FILE_OP_FUNC_CACHE + 5;
		unsigned char reg_5 = REGISTER_FILE_OP_FUNC_CACHE + 6;
		unsigned char reg_h = REGISTER_FILE_OP_FUNC_CACHE + 7;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 8;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		float_mul_func_romaddr = rom_cp >> 1;

		/*��ȡָ��,�жϲ������Ƿ�Ϊ0�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(-128);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(127);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��1.0*/
		A_ASGN_IMMNUM(0x80);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		RF_ASGN_ALU(ALU_OR);

		/*24λβ�����*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_1, ALU_MUL_H);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_2, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_1);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF_O(reg_2);
		RF_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_1);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_3, ALU_ADD_C);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_4, ALU_ADD_C);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_5, ALU_ADD_C);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_ADD);

		/*ָ�����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_c, ALU_ADD_C);
		B_ASGN_ALU(ALU_XOR);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_RF();
		RF_ASGN_ALU(ALU_ADD);

		/*���24λ������λΪ1*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		/*ָ���ټ�1*/
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_SUB_1_C);
		A_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_SUB);
		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*β������1λ*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ָ��������*/
		A_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(-127);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		A_ASGN_IMMNUM(126);
		B_ASGN__RF(reg_rop_index);
		label_3 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_3, rom_cp >> 1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ָ��ת��Ϊԭ��ʽ*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x7f);
		RF_ASGN_ALU(ALU_XOR);

		/*װ��ָ���ͷ���*/
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_B_0_LSH);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_XOR);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*double�˷���������,(��ʡ������,���ﲻ������ֵ,����������)*/
void double_mul_func_gen() {
	if (double_mul_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_1 = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_2 = REGISTER_FILE_OP_FUNC_CACHE + 5;
		unsigned char reg_3 = REGISTER_FILE_OP_FUNC_CACHE + 6;
		unsigned char reg_4 = REGISTER_FILE_OP_FUNC_CACHE + 7;
		unsigned char reg_5 = REGISTER_FILE_OP_FUNC_CACHE + 8;
		unsigned char reg_6 = REGISTER_FILE_OP_FUNC_CACHE + 9;
		unsigned char reg_7 = REGISTER_FILE_OP_FUNC_CACHE + 10;
		unsigned char reg_8 = REGISTER_FILE_OP_FUNC_CACHE + 11;
		unsigned char reg_9 = REGISTER_FILE_OP_FUNC_CACHE + 12;
		unsigned char reg_10 = REGISTER_FILE_OP_FUNC_CACHE + 13;
		unsigned char reg_11 = REGISTER_FILE_OP_FUNC_CACHE + 14;
		unsigned char reg_12 = REGISTER_FILE_OP_FUNC_CACHE + 15;
		unsigned char reg_13 = REGISTER_FILE_OP_FUNC_CACHE + 16;
		unsigned char reg_h = REGISTER_FILE_OP_FUNC_CACHE + 17;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 18;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		double_mul_func_romaddr = rom_cp >> 1;

		/*��ȡָ��,�жϲ������Ƿ�Ϊ0�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_lop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_rop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*53λβ�����*/

		/* 0x0 byte0 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_1, ALU_MUL_H);

		/* 1x0 byte1 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_2, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_1);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF_O(reg_2);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x1 byte1 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_1);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_3, ALU_ADD_C);

		/* 2x0 byte2 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x1 byte2 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_4, ALU_ADD_C);

		/* 0x2 byte2 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x0 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_5, ALU_ADD_C);

		/* 2x1 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x2 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x3 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x0 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_6, ALU_ADD_C);

		/* 3x1 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x2 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x3 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x4 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 5x0 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_7, ALU_ADD_C);

		/* 4x1 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x2 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x3 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x4 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x5 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 0);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_8, ALU_ADD_C);

		/* 6x0 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);

		/* 5x1 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x2 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x3 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x4 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x5 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_9, ALU_ADD_C);

		/* 0x6 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x1 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);

		/* 5x2 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x3 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x4 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x5 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_10, ALU_ADD_C);

		/* 1x6 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x2 byte8 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);

		/* 5x3 byte8 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x4 byte8 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x5 byte8 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_8);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x6 byte8 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_8);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x3 byte9 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_11, ALU_ADD_C);

		/* 5x4 byte9 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_11);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x5 byte9 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_9);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_11);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x6 byte9 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_9);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_11);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x4 byte10 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_11);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_12, ALU_ADD_C);

		/* 5x5 byte10 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_10);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_11);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_12);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x6 byte10 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_10);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_11);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_12);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x5 byte11 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_11);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_12);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_13, ALU_ADD_C);

		/* 5x6 byte11 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_11);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_12);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_13);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x6 byte12 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_12);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_13);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_ADD);

		/*�����˷����*/
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(reg_6);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		RF_ASGN_ALU(ALU_OR);

		/*ָ�����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_rop_index + 1);
		RF_ASGN_ALU(ALU_ADD);

		/*���53λ������λΪ1*/
		A_ASGN_IMMNUM(0x0f);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		/*ָ���ټ�1*/
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_SUB_1_C);
		A_ASGN__RF(reg_rop_index + 1);
		RF_ASGN_ALU(ALU_SUB);
		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*β������1λ*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ָ��������*/
		B_ASGN__RF(reg_rop_index + 1);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		B_ASGN_IMMNUM(0x01);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_rop_index + 1);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN_IMMNUM(0xfc);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		B_ASGN__RF(reg_rop_index);
		A_ASGN_IMMNUM(0xfe);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(reg_rop_index + 1);
		label_3 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_3, rom_cp >> 1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*����β����1.0*/
		A_ASGN_IMMNUM(0x0f);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_AND);

		/*����λ���*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		RF_ASGN_ALU(ALU_XOR);

		/*ָ��ת��Ϊԭ��ʽ,��װ��ָ���ͷ���*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x10);
		_RF_ASGN_ALU(reg_c, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN_IMMNUM(0xf0);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_OR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x10);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_c);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x3f);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_ALU(ALU_OUTA);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*float������������,(��ʡ������,���ﲻ������ֵ,����������)*/
void float_div_func_gen() {
	if (float_div_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 1;
		unsigned char reg_lop_h = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_dop_h = REGISTER_FILE_OP_FUNC_CACHE + 3;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 7;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 8;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 9;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		float_div_func_romaddr = rom_cp >> 1;

		/*��ȡָ��,�жϲ������Ƿ�Ϊ0�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(-128);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(127);
		A_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_ALU(ALU_EQUAL_C);
		A_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN_IMMNUM(-128);
		A_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_ALU(ALU_EQUAL_C);
		A_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(127);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��1.0*/
		A_ASGN_IMMNUM(0x80);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		RF_ASGN_ALU(ALU_OR);

		/*24λβ�����*/
		_RF_ASGN_IMMNUM(reg_lop_h, 0);
		_RF_ASGN_IMMNUM(reg_cp, 24);
		label_1 = rom_cp >> 1;
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN__RF(reg_dop_h);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_lop_h);
		A_ASGN_ALU(ALU_SUB_C);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_OUTA);
		_RF_ASGN_IMMNUM(reg_lop_h, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN__RF(reg_lop_h);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		/*ָ�����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_SUB);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		B_ASGN_ALU(ALU_XOR);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_RF();
		RF_ASGN_ALU(ALU_SUB);

		/*���25λ������λΪ1*/
		A_ASGN__RF(reg_dop_h);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		/*β������1λ*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_B_AL_RSH);
		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*ָ���ټ�1*/
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ָ��������*/
		A_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(-127);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		A_ASGN_IMMNUM(126);
		B_ASGN__RF(reg_rop_index);
		label_3 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_3, rom_cp >> 1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ָ��ת��Ϊԭ��ʽ*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x7f);
		RF_ASGN_ALU(ALU_XOR);

		/*װ��ָ���ͷ���*/
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_B_0_LSH);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_XOR);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_rop_index);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*double������������,(��ʡ������,���ﲻ������ֵ,����������)*/
void double_div_func_gen() {
	if (double_div_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2, label_3;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_rop_index = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 11;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 12;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		double_div_func_romaddr = rom_cp >> 1;

		/*��ȡָ��*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_lop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_rop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_rop_index, ALU_XOR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		/*�������Ϊ��������nan*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*�Ҳ�����Ϊ��������nan*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*���Ҳ�������Ϊ0���nan*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0xff);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*���Ҳ�������Ϊ�����,���nan*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x00);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0xfc);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0xff);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*�������Ϊ0���0*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*�Ҳ�����Ϊ0��������*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*53λβ�����*/
		_RF_ASGN_IMMNUM(reg_cp, 53);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_sub + 4, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(reg_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_sub + 5, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_sub + 6, ALU_SUB);
		B_ASGN_ALU(ALU_SUB);
		A_ASGN_ALU(ALU_A_BH_LSH);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);

		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_OUTA);
		A_ASGN__RF(reg_sub + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_OUTA);
		A_ASGN__RF(reg_sub + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_OUTA);
		A_ASGN__RF(reg_sub + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 6, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);

		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		/*ָ�����*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_lop_index + 1);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(reg_rop_index + 1);
		RF_ASGN_ALU(ALU_SUB);

		/*���54λ������λΪ1*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN_IMMNUM(8);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_MUL_H, 0);
		/*β������1λ*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_B_AL_RSH);
		B_ASGN_ALU(ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_A_0_RSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_B_AL_RSH);
		label_2 = rom_cp;
		PC_ASGN_IMMNUM(0);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		/*ָ���ټ�1*/
		A_ASGN__RF(reg_rop_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(reg_rop_index + 1);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ָ��������*/
		B_ASGN__RF(reg_rop_index + 1);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		B_ASGN_IMMNUM(0x01);
		A_ASGN__RF(reg_rop_index);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_rop_index + 1);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN_IMMNUM(0xfc);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x7f);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OR);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);
		B_ASGN__RF(reg_rop_index);
		A_ASGN_IMMNUM(0xfe);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN_IMMNUM(0x03);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(reg_rop_index + 1);
		label_3 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_3, rom_cp >> 1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*����β����1.0*/
		A_ASGN_IMMNUM(0x0f);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_AND);

		/*����λ���*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		RF_ASGN_ALU(ALU_XOR);

		/*ָ��ת��Ϊԭ��ʽ,��װ��ָ���ͷ���*/
		A_ASGN__RF(reg_rop_index);
		B_ASGN_IMMNUM(0x10);
		_RF_ASGN_ALU(reg_c, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN_IMMNUM(0xf0);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_OR);
		A_ASGN__RF(reg_rop_index + 1);
		B_ASGN_IMMNUM(0x10);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_c);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x3f);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_ALU(ALU_OUTA);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*Ŀ�Ĳ�����������������ӡ����Ҳ�����*/
void DOP_ASGN_LOP_ADD_SUB_ROP(Xop* d, Xop* l, Xop* r, char control) {
	Xop sd = *d, sl = *l, sr = *r;
	unsigned char aluaddr, aluaddr_c;

	if (control != 0) {
		aluaddr = ALU_ADD;
		aluaddr_c = ALU_ADD_C;
	}
	else {
		aluaddr = ALU_SUB;
		aluaddr_c = ALU_SUB_C;
	}
	if (r->datatype == Xop::XOP_P || r->datatype == Xop::XOP_X) {
		Xop* rl = r;
		r = l;
		l = rl;
		sl = *l;
		sr = *r;
	}
	if (sl.datatype == Xop::XOP_X && (sr.datatype == Xop::XOP_I || sr.datatype == Xop::XOP_U)) {
		addr_convert(&sd, &sl, &sr);
		if (sl.datasize == 3) {
			if (sl.addrtype == Xop::XOP_LOC) {
				if (sr.datasize == 1) {
					unsigned long cp0, cp1, cp2;

					A_ASGN_IMMNUM(0);
					cp0 = rom_cp - 1;
					B_ASGN_OP(&sr, 0);
					OP_ASGN_ALU(&sd, 0, aluaddr);
					B_ASGN_ALU(aluaddr_c);

					A_ASGN_IMMNUM(0);
					cp1 = rom_cp - 1;
					OP_ASGN_ALU(&sd, 1, aluaddr);
					B_ASGN_ALU(aluaddr_c);

					A_ASGN_IMMNUM(0);
					cp2 = rom_cp - 1;
					OP_ASGN_ALU(&sd, 2, aluaddr);

					insertaddr(sl.entry, cp2, cp1, cp0, sl.v.i);
				}
				else {
					unsigned long cp0, cp1, cp2;
					unsigned char reg_c = regalloc(1, 1);

					A_ASGN_IMMNUM(0);
					cp0 = rom_cp - 1;
					B_ASGN_OP(&sr, 0);
					OP_ASGN_ALU(&sd, 0, aluaddr);
					B_ASGN_ALU(aluaddr_c);

					A_ASGN_IMMNUM(0);
					cp1 = rom_cp - 1;
					_RF_ASGN_ALU_O(reg_c, aluaddr_c);
					A_ASGN_ALU(aluaddr);
					B_ASGN_OP(&sr, 1);
					OP_ASGN_ALU(&sd, 1, aluaddr);
					B_ASGN_ALU(aluaddr_c);
					A_ASGN__RF_O(reg_c);
					B_ASGN_ALU(ALU_ADD);

					A_ASGN_IMMNUM(0);
					cp2 = rom_cp - 1;
					if (sr.datasize != 2) {
						A_ASGN_ALU(aluaddr);
						B_ASGN_OP(&sr, 2);
					}
					OP_ASGN_ALU(&sd, 2, aluaddr);

					insertaddr(sl.entry, cp2, cp1, cp0, sl.v.i);
					regfree(reg_c, 1);
				}
			}
			else if (sl.addrtype == Xop::XOP_OFFSET) {
				if ((sl.v.i & 0xffffff00) == 0) {
					if (sr.datasize == 1) {
						A_ASGN_IMMNUM(sl.v.i);
						B_ASGN_OP(&sr, 0);
						OP_ASGN_ALU(&sd, 0, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN__RF_O(REGISTER_FILE_SP);
						OP_ASGN_ALU(&sd, 1, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN__RF_O(REGISTER_FILE_SP + 1);
						OP_ASGN_ALU(&sd, 2, aluaddr);
					}
					else {
						unsigned char reg_c = regalloc(1, 1);

						A_ASGN_IMMNUM(sl.v.i);
						B_ASGN_OP(&sr, 0);
						OP_ASGN_ALU(&sd, 0, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN__RF_O(REGISTER_FILE_SP);
						_RF_ASGN_ALU_O(reg_c, aluaddr_c);
						A_ASGN_ALU(aluaddr);
						B_ASGN_OP(&sr, 1);
						OP_ASGN_ALU(&sd, 1, aluaddr);
						B_ASGN_ALU(aluaddr_c);
						A_ASGN__RF_O(reg_c);
						B_ASGN_ALU(ALU_ADD);

						A_ASGN__RF_O(REGISTER_FILE_SP + 1);
						if (sr.datasize != 2) {
							A_ASGN_ALU(aluaddr);
							B_ASGN_OP(&sr, 2);
						}
						OP_ASGN_ALU(&sd, 2, aluaddr);

						regfree(reg_c, 1);
					}
				}
				else {
					if (sr.datasize == 1) {
						unsigned char sp = regalloc(2, 1);

						A_ASGN__RF_O(REGISTER_FILE_SP);
						B_ASGN_IMMNUM(sl.v.i >> 8);
						_RF_ASGN_ALU_O(sp, ALU_ADD);
						B_ASGN_ALU(ALU_ADD_C);
						A_ASGN__RF_O(REGISTER_FILE_SP + 1);
						_RF_ASGN_ALU_O(sp + 1, ALU_ADD);

						A_ASGN_IMMNUM(sl.v.i);
						B_ASGN_OP(&sr, 0);
						OP_ASGN_ALU(&sd, 0, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN__RF_O(sp);
						OP_ASGN_ALU(&sd, 1, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN__RF_O(sp + 1);
						OP_ASGN_ALU(&sd, 2, aluaddr);

						regfree(sp, 2);
					}
					else {
						unsigned char sp, reg_c;

						sp = regalloc(2, 1);
						reg_c = regalloc(1, 1);

						A_ASGN__RF_O(REGISTER_FILE_SP);
						B_ASGN_IMMNUM(sl.v.i >> 8);
						_RF_ASGN_ALU_O(sp, ALU_ADD);
						B_ASGN_ALU(ALU_ADD_C);
						A_ASGN__RF_O(REGISTER_FILE_SP + 1);
						_RF_ASGN_ALU_O(sp + 1, ALU_ADD);

						A_ASGN_IMMNUM(sl.v.i);
						B_ASGN_OP(&sr, 0);
						OP_ASGN_ALU(&sd, 0, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN__RF_O(sp);
						_RF_ASGN_ALU_O(reg_c, aluaddr_c);
						A_ASGN_ALU(aluaddr);
						B_ASGN_OP(&sr, 1);
						OP_ASGN_ALU(&sd, 1, aluaddr);
						B_ASGN_ALU(aluaddr_c);
						A_ASGN__RF_O(reg_c);
						B_ASGN_ALU(ALU_ADD);

						A_ASGN__RF_O(sp + 1);
						if (sr.datasize != 2) {
							A_ASGN_ALU(aluaddr);
							B_ASGN_OP(&sr, 2);
						}
						OP_ASGN_ALU(&sd, 2, aluaddr);

						regfree(sp, 2);
						regfree(reg_c, 1);
					}
				}
			}
			else if (sl.addrtype == Xop::XOP_CONST_P) {
				
				if (sr.addrtype == Xop::XOP_CONST) {
					/*
					int x;
					for (x = 0; x < sl.datasize; ++x) {
						switch (sd.addrtype) {
						case Xop::XOP_LOC:
							insertaddr(sd.entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, sd.v.i + x);
							_RAM_ASGN_IMMNUM(0, (sl.v.u + sr.v.i) >> (x * 8));
							break;
						case Xop::XOP_OFFSET:
							A0_ASGN_IMMNUM(sd.v.i + x);
							NOP();
							RAM_ASGN_IMMNUM((sl.v.u + sr.v.i) >> (x * 8));
							break;
						case Xop::XOP_REGISTER_FILE:
							_RF_ASGN_IMMNUM_O(sd.v.i + x, (sl.v.u + sr.v.i) >> (x * 8));
							break;
						case Xop::XOP_CONST_P:
							_RAM_ASGN_IMMNUM_O(sd.v.u + x, (sl.v.u + sr.v.i) >> (x * 8));
							break;
						}
					}
					*/
					error("���DOP_ASGN_LOP_ADD_SUB_ROP����XOP_X��XOP_I�����Ҳ����������\n");
				}
				else {
					if (sr.datasize == 1) {
						A_ASGN_IMMNUM(sl.v.u);
						B_ASGN_OP(&sr, 0);
						OP_ASGN_ALU(&sd, 0, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN_IMMNUM(sl.v.u >> 8);
						OP_ASGN_ALU(&sd, 1, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN_IMMNUM(sl.v.u >> 16);
						OP_ASGN_ALU(&sd, 2, aluaddr);
					}
					else {
						unsigned char reg_c = regalloc(1, 1);

						A_ASGN_IMMNUM(sl.v.u);
						B_ASGN_OP(&sr, 0);
						OP_ASGN_ALU(&sd, 0, aluaddr);
						B_ASGN_ALU(aluaddr_c);

						A_ASGN_IMMNUM(sl.v.u >> 8);
						_RF_ASGN_ALU_O(reg_c, aluaddr_c);
						A_ASGN_ALU(aluaddr);
						B_ASGN_OP(&sr, 1);
						OP_ASGN_ALU(&sd, 1, aluaddr);
						B_ASGN_ALU(aluaddr_c);
						A_ASGN__RF_O(reg_c);
						B_ASGN_ALU(ALU_ADD);

						A_ASGN_IMMNUM(sl.v.u >> 16);
						if (sr.datasize != 2) {
							A_ASGN_ALU(aluaddr);
							B_ASGN_OP(&sr, 2);
						}
						OP_ASGN_ALU(&sd, 2, aluaddr);

						regfree(reg_c, 1);
					}
				}
			}
			else
				error("���DOP_ASGN_LOP_ADD_SUB_ROP����XOP_X��XOP_I�����Ҳ����������\n");
		}
		else
			error("���DOP_ASGN_LOP_ADD_SUB_ROP����XOP_X��XOP_I�������ɻ��������д���\n");
	}
	else if (sl.datatype == Xop::XOP_P && (sr.datatype == Xop::XOP_I || sr.datatype == Xop::XOP_U)) {
		addr_convert(&sd, &sl, &sr);
		if (sl.datasize == 3 && sr.datasize >= 2) {
			unsigned char reg_c = regalloc(1, 1);
			
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, aluaddr);
			B_ASGN_ALU(aluaddr_c);

			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 1);
			OP_ASGN_ALU(&sd, 1, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 2);
			if (sr.datasize != 2) {
				A_ASGN_ALU(aluaddr);
				B_ASGN_OP(&sr, 2);
			}
			OP_ASGN_ALU(&sd, 2, aluaddr);
			
			regfree(reg_c, 1);
		}
		else if (sl.datasize == 3 && sr.datasize == 1) {
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, aluaddr);
			B_ASGN_ALU(aluaddr_c);

			A_ASGN_OP(&sl, 1);
			OP_ASGN_ALU(&sd, 1, aluaddr);
			B_ASGN_ALU(aluaddr_c);

			A_ASGN_OP(&sl, 2);
			OP_ASGN_ALU(&sd, 2, aluaddr);
		}
		else
			error("���DOP_ASGN_LOP_ADD_SUB_ROP����XOP_P��XOP_I�������ɻ��������д���\n");
	}
	else if ((sl.datatype == Xop::XOP_I && sr.datatype == Xop::XOP_I) || (sl.datatype == Xop::XOP_U && sr.datatype == Xop::XOP_U)) {
		addr_convert(&sd, &sl, &sr);
		if (sl.datasize == 1 && sr.datasize == 1) {
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, aluaddr);
		}
		else if (sl.datasize == 2 && sr.datasize == 2) {
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, aluaddr);
			B_ASGN_ALU(aluaddr_c);

			A_ASGN_OP(&sl, 1);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 1);
			OP_ASGN_ALU(&sd, 1, aluaddr);

			regfree(reg_c, 1);
		}
		else if (sl.datasize == 4 && sr.datasize == 4) {
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, aluaddr);
			B_ASGN_ALU(aluaddr_c);

			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 1);
			OP_ASGN_ALU(&sd, 1, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 2);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 2);
			OP_ASGN_ALU(&sd, 2, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 3);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 3);
			OP_ASGN_ALU(&sd, 3, aluaddr);

			regfree(reg_c, 1);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, aluaddr);
			B_ASGN_ALU(aluaddr_c);

			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 1);
			OP_ASGN_ALU(&sd, 1, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 2);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 2);
			OP_ASGN_ALU(&sd, 2, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 3);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 3);
			OP_ASGN_ALU(&sd, 3, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 4);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 4);
			OP_ASGN_ALU(&sd, 4, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 5);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 5);
			OP_ASGN_ALU(&sd, 5, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 6);
			_RF_ASGN_ALU_O(reg_c, aluaddr_c);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 6);
			OP_ASGN_ALU(&sd, 6, aluaddr);
			B_ASGN_ALU(aluaddr_c);
			A_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);

			A_ASGN_OP(&sl, 7);
			A_ASGN_ALU(aluaddr);
			B_ASGN_OP(&sr, 7);
			OP_ASGN_ALU(&sd, 7, aluaddr);

			regfree(reg_c, 1);
		}
		else
			error("���DOP_ASGN_LOP_ADD_SUB_ROP����, XOP_I��XOP_I����, XOP_U��XOP_U����, ���ɻ��������д���\n");
	}
	else if (sl.datatype == Xop::XOP_F && sr.datatype == Xop::XOP_F) {
		unsigned long cp[3];

		sl.addrtype = Xop::XOP_REGISTER_FILE;
		sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
		REGISTER_FILE_ASGN_OP(&sl, l);
		sr.addrtype = Xop::XOP_REGISTER_FILE;
		sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
		REGISTER_FILE_ASGN_OP(&sr, r);
		for (int i = 0; i < 3; ++i) {
			_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
			cp[i] = rom_cp - 1;
		}
		if (sl.datasize == 4 && sr.datasize == 4) {
			/*float*/
			if (control != 0) {
				float_add_func_gen();
				PC_ASGN_IMMNUM(float_add_func_romaddr);
			}
			else {
				float_sub_func_gen();
				PC_ASGN_IMMNUM(float_sub_func_romaddr);
			}
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			/*double*/
			if (control != 0) {
				double_add_func_gen();
				PC_ASGN_IMMNUM(double_add_func_romaddr);
			}
			else {
				double_sub_func_gen();
				PC_ASGN_IMMNUM(double_sub_func_romaddr);
			}
		}
		else
			error("���DOP_ASGN_LOP_ADD_SUB_ROP�������ɻ��������д���\n");
		romdata[cp[0]] = rom_cp >> 1;
		romdata[cp[1]] = rom_cp >> 9;
		romdata[cp[2]] = rom_cp >> 17;
		if (LOC_OFFSET_CONST_P_OR(sd.addrtype)) {
			sd.addrtype = Xop::XOP_REGISTER_FILE;
			sd.datatype = sl.datatype;
			sd.datasize = sl.datasize;
			sd.v.i = REGISTER_FILE_OP_FUNC_DOP;
			DOP_ASGN_SOP(d, &sd);
		}
		else if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
			if (sd.v.i != REGISTER_FILE_OP_FUNC_DOP) {
				for (int i = 0; i < sd.datasize; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
				}
			}
		}
		else
			error("���DOP_ASGN_LOP_ADD_SUB_ROP�������ɻ��������д���\n");
		return;
	}
	else
		error("���DOP_ASGN_LOP_ADD_SUB_ROP�������ɻ��������д���\n");
	if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
		DOP_ASGN_SOP(d, &sd);
		regfree(sd.v.i, sd.datasize);
	}
	if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sl.v.i, sl.datasize);
	if (sr.addrtype == Xop::XOP_REGISTER_FILE && r->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sr.v.i, sr.datasize);
}

/*Ŀ�Ĳ�������������������Ҳ�����*/
void DOP_ASGN_LOP_ADD_ROP(Xop* d, Xop* l, Xop* r) {
	DOP_ASGN_LOP_ADD_SUB_ROP(d, l, r, 1);
}

/*Ŀ�Ĳ�������������������Ҳ�����*/
void DOP_ASGN_LOP_SUB_ROP(Xop* d, Xop* l, Xop* r) {
	DOP_ASGN_LOP_ADD_SUB_ROP(d, l, r, 0);
}

unsigned long unsigned_mul64_func_romaddr; //�޷���64λ�˷�������ڵ�ַ

/*�޷���64λ�˷���������*/
void unsigned_mul64_func_gen() {
	if (unsigned_mul64_func_romaddr == 0) {
		unsigned long label_0;
		unsigned char reg_1 = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_2 = REGISTER_FILE_OP_FUNC_CACHE + 1;
		unsigned char reg_3 = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_4 = REGISTER_FILE_OP_FUNC_CACHE + 3;
		unsigned char reg_5 = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_6 = REGISTER_FILE_OP_FUNC_CACHE + 5;
		unsigned char reg_7 = REGISTER_FILE_OP_FUNC_CACHE + 6;
		unsigned char reg_h = REGISTER_FILE_OP_FUNC_CACHE + 7;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		unsigned_mul64_func_romaddr = rom_cp >> 1;

		/* 0x0 byte0 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_1, ALU_MUL_H);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_MUL_L);

		/* 1x0 byte1 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_2, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_1);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF_O(reg_2);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x1 byte1 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_3, ALU_ADD_C);

		/* 2x0 byte2 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x1 byte2 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_4, ALU_ADD_C);

		/* 0x2 byte2 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x0 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_5, ALU_ADD_C);

		/* 2x1 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x2 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x3 byte3 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x0 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_6, ALU_ADD_C);

		/* 3x1 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x2 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x3 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x4 byte4 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);

		/* 5x0 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		_RF_ASGN_ALU(reg_7, ALU_ADD_C);

		/* 4x1 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x2 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x3 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x4 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x5 byte5 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x0 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 5x1 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x2 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x3 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x4 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x5 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x6 byte6 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_h, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_h);
		A_ASGN_ALU(ALU_ADD);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 7x0 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 6x1 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 5x2 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 4x3 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 3x4 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 2x5 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 1x6 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		RF_ASGN_ALU(ALU_ADD);

		/* 0x7 byte7 */
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_ADD);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*Ŀ�Ĳ�������������������Ҳ�����*/
void DOP_ASGN_LOP_MUL_ROP(Xop* d, Xop* l, Xop* r) {
	Xop sd = *d, sl = *l, sr = *r;

	if ((sl.datatype == Xop::XOP_I && sr.datatype == Xop::XOP_I) || (sl.datatype == Xop::XOP_U && sr.datatype == Xop::XOP_U)) {
		if (sl.datasize >= 1 && sl.datasize <= 4 && sr.datasize >= 1 && sr.datasize <= 4) {
			addr_convert(&sd, &sl, &sr);
			if (sl.datasize == 1 && sr.datasize == 1) {
				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 0);
				OP_ASGN_ALU(&sd, 0, ALU_MUL_L);
			}
			else if (sl.datasize == 2 && sr.datasize == 2) {
				unsigned char reg_1 = regalloc(1, 1);

				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 0);
				OP_ASGN_ALU(&sd, 0, ALU_MUL_L);
				_RF_ASGN_ALU_O(reg_1, ALU_MUL_H);
				A_ASGN_OP(&sl, 1);
				B_ASGN_OP(&sr, 0);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_1);
				RF_ASGN_ALU(ALU_ADD);
				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 1);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_1);
				OP_ASGN_ALU(&sd, 1, ALU_ADD);

				regfree(reg_1, 1);
			}
			else if (sl.datasize == 4 && sr.datasize == 4) {
				unsigned char reg_1 = regalloc(1, 1);
				unsigned char reg_2 = regalloc(1, 1);
				unsigned char reg_3 = regalloc(1, 1);
				unsigned char reg_h = regalloc(1, 1);

				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 0);
				OP_ASGN_ALU(&sd, 0, ALU_MUL_L);
				_RF_ASGN_ALU_O(reg_1, ALU_MUL_H);

				A_ASGN_OP(&sl, 1);
				B_ASGN_OP(&sr, 0);
				_RF_ASGN_ALU_O(reg_2, ALU_MUL_H);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_1);
				RF_ASGN_ALU(ALU_ADD);
				A_ASGN_ALU(ALU_ADD_C);
				B_ASGN__RF_O(reg_2);
				RF_ASGN_ALU(ALU_ADD);

				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 1);
				_RF_ASGN_ALU_O(reg_h, ALU_MUL_H);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_1);
				OP_ASGN_ALU(&sd, 1, ALU_ADD);
				A_ASGN_ALU(ALU_ADD_C);
				B_ASGN__RF_O(reg_h);
				A_ASGN_ALU(ALU_ADD);
				B_ASGN__RF_O(reg_2);
				RF_ASGN_ALU(ALU_ADD);
				_RF_ASGN_ALU_O(reg_3, ALU_ADD_C);

				A_ASGN_OP(&sl, 2);
				B_ASGN_OP(&sr, 0);
				_RF_ASGN_ALU_O(reg_h, ALU_MUL_H);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_2);
				RF_ASGN_ALU(ALU_ADD);
				A_ASGN_ALU(ALU_ADD_C);
				B_ASGN__RF_O(reg_h);
				A_ASGN_ALU(ALU_ADD);
				B_ASGN__RF_O(reg_3);
				RF_ASGN_ALU(ALU_ADD);

				A_ASGN_OP(&sl, 1);
				B_ASGN_OP(&sr, 1);
				_RF_ASGN_ALU_O(reg_h, ALU_MUL_H);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_2);
				RF_ASGN_ALU(ALU_ADD);
				A_ASGN_ALU(ALU_ADD_C);
				B_ASGN__RF_O(reg_h);
				A_ASGN_ALU(ALU_ADD);
				B_ASGN__RF_O(reg_3);
				RF_ASGN_ALU(ALU_ADD);

				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 2);
				_RF_ASGN_ALU_O(reg_h, ALU_MUL_H);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_2);
				OP_ASGN_ALU(&sd, 2, ALU_ADD);
				A_ASGN_ALU(ALU_ADD_C);
				B_ASGN__RF_O(reg_h);
				A_ASGN_ALU(ALU_ADD);
				B_ASGN__RF_O(reg_3);
				RF_ASGN_ALU(ALU_ADD);

				A_ASGN_OP(&sl, 3);
				B_ASGN_OP(&sr, 0);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_3);
				RF_ASGN_ALU(ALU_ADD);

				A_ASGN_OP(&sl, 2);
				B_ASGN_OP(&sr, 1);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_3);
				RF_ASGN_ALU(ALU_ADD);

				A_ASGN_OP(&sl, 1);
				B_ASGN_OP(&sr, 2);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_3);
				RF_ASGN_ALU(ALU_ADD);

				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 3);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF_O(reg_3);
				OP_ASGN_ALU(&sd, 3, ALU_ADD);

				regfree(reg_1, 1);
				regfree(reg_2, 1);
				regfree(reg_3, 1);
				regfree(reg_h, 1);
			}
			else
				error("���DOP_ASGN_LOP_MUL_ROP�������ɻ��������д���\n");
			if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
				DOP_ASGN_SOP(d, &sd);
				regfree(sd.v.i, sd.datasize);
			}
			if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sl.v.i, sl.datasize);
			if (sr.addrtype == Xop::XOP_REGISTER_FILE && r->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sr.v.i, sr.datasize);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			unsigned long cp[3];

			sl.addrtype = Xop::XOP_REGISTER_FILE;
			sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
			REGISTER_FILE_ASGN_OP(&sl, l);
			sr.addrtype = Xop::XOP_REGISTER_FILE;
			sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
			REGISTER_FILE_ASGN_OP(&sr, r);
			for (int i = 0; i < 3; ++i) {
				_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
				cp[i] = rom_cp - 1;
			}
			unsigned_mul64_func_gen();
			PC_ASGN_IMMNUM(unsigned_mul64_func_romaddr);
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (LOC_OFFSET_CONST_P_OR(sd.addrtype)) {
				sd.addrtype = Xop::XOP_REGISTER_FILE;
				sd.datatype = sl.datatype;
				sd.datasize = sl.datasize;
				sd.v.i = REGISTER_FILE_OP_FUNC_DOP;
				DOP_ASGN_SOP(d, &sd);
			}
			else if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
				if (sd.v.i != REGISTER_FILE_OP_FUNC_DOP) {
					for (int i = 0; i < sd.datasize; ++i) {
						A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
						_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
					}
				}
			}
			else
				error("���DOP_ASGN_LOP_MUL_ROP�������ɻ��������д���\n");
		}
		else
			error("���DOP_ASGN_LOP_MUL_ROP�������ɻ��������д���\n");
	}
	else if (sl.datatype == Xop::XOP_F && sr.datatype == Xop::XOP_F) {
		unsigned long cp[3];

		sl.addrtype = Xop::XOP_REGISTER_FILE;
		sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
		REGISTER_FILE_ASGN_OP(&sl, l);
		sr.addrtype = Xop::XOP_REGISTER_FILE;
		sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
		REGISTER_FILE_ASGN_OP(&sr, r);
		for (int i = 0; i < 3; ++i) {
			_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
			cp[i] = rom_cp - 1;
		}
		if (sl.datasize == 4 && sr.datasize == 4) {
			/*float*/
			float_mul_func_gen();
			PC_ASGN_IMMNUM(float_mul_func_romaddr);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			/*double*/
			double_mul_func_gen();
			PC_ASGN_IMMNUM(double_mul_func_romaddr);
		}
		else
			error("���DOP_ASGN_LOP_MUL_ROP�������ɻ��������д���\n");
		romdata[cp[0]] = rom_cp >> 1;
		romdata[cp[1]] = rom_cp >> 9;
		romdata[cp[2]] = rom_cp >> 17;
		if (LOC_OFFSET_CONST_P_OR(sd.addrtype)) {
			sd.addrtype = Xop::XOP_REGISTER_FILE;
			sd.datatype = sl.datatype;
			sd.datasize = sl.datasize;
			sd.v.i = REGISTER_FILE_OP_FUNC_DOP;
			DOP_ASGN_SOP(d, &sd);
		}
		else if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
			if (sd.v.i != REGISTER_FILE_OP_FUNC_DOP) {
				for (int i = 0; i < sd.datasize; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
				}
			}
		}
		else
			error("���DOP_ASGN_LOP_MUL_ROP�������ɻ��������д���\n");
	}
	else
		error("���DOP_ASGN_LOP_MUL_ROP�������ɻ��������д���\n");
}

unsigned long unsigned_div16_func_romaddr; //�޷���16λ����������ڵ�ַ
unsigned long signed_div16_func_romaddr; //�з���16λ����������ڵ�ַ
unsigned long unsigned_div32_func_romaddr; //�޷���32λ����������ڵ�ַ
unsigned long signed_div32_func_romaddr; //�з���32λ����������ڵ�ַ
unsigned long unsigned_div64_func_romaddr; //�޷���64λ����������ڵ�ַ
unsigned long signed_div64_func_romaddr; //�з���64λ����������ڵ�ַ
unsigned long unsigned_mod16_func_romaddr; //�޷���16λȡ�ຯ����ڵ�ַ
unsigned long signed_mod16_func_romaddr; //�з���16λȡ�ຯ����ڵ�ַ
unsigned long unsigned_mod32_func_romaddr; //�޷���32λȡ�ຯ����ڵ�ַ
unsigned long signed_mod32_func_romaddr; //�з���32λȡ�ຯ����ڵ�ַ
unsigned long unsigned_mod64_func_romaddr; //�޷���64λȡ�ຯ����ڵ�ַ
unsigned long signed_mod64_func_romaddr; //�з���64λȡ�ຯ����ڵ�ַ

/*�޷���16λ������������*/
void unsigned_div16_func_gen() {
	if (unsigned_div16_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_mod = REGISTER_FILE_OP_FUNC_CACHE + 3;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 5;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		unsigned_div16_func_romaddr = rom_cp >> 1;

		_RF_ASGN_IMMNUM(reg_mod + 1, 0);
		_RF_ASGN_IMMNUM(reg_mod, 0);
		_RF_ASGN_IMMNUM(reg_cp, 15);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(reg_mod);
		A_ASGN__RF(reg_mod + 1);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_mod, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(reg_mod);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		A_ASGN_ALU(ALU_SUB_C);
		B_ASGN__RF(reg_sub_c);
		A_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(reg_mod, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(reg_mod + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�޷���16λȡ�ຯ������*/
void unsigned_mod16_func_gen() {
	if (unsigned_mod16_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 3;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		unsigned_mod16_func_romaddr = rom_cp >> 1;

		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(reg_cp, 15);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		A_ASGN_ALU(ALU_SUB_C);
		B_ASGN__RF(reg_sub_c);
		A_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�з���16λ������������*/
void signed_div16_func_gen() {
	if (signed_div16_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_mod = REGISTER_FILE_OP_FUNC_CACHE + 3;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 5;
		unsigned char reg_0 = REGISTER_FILE_OP_FUNC_CACHE + 6;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		signed_div16_func_romaddr = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_0, ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN_ALU(ALU_A_NOT);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		A_ASGN_ALU(ALU_A_ADD_1_C);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN_ALU(ALU_A_NOT);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		A_ASGN_ALU(ALU_A_ADD_1_C);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 1, ALU_ADD);
		A_ASGN__RF(reg_0);
		RF_ASGN_ALU(ALU_A_NOT);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		_RF_ASGN_IMMNUM(reg_mod + 1, 0);
		_RF_ASGN_IMMNUM(reg_mod, 0);
		_RF_ASGN_IMMNUM(reg_cp, 15);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(reg_mod);
		A_ASGN__RF(reg_mod + 1);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_mod, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(reg_mod);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		A_ASGN_ALU(ALU_SUB_C);
		B_ASGN__RF(reg_sub_c);
		A_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(reg_mod, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(reg_mod + 1, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		A_ASGN__RF(reg_0);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN_ALU(ALU_A_NOT);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		A_ASGN_ALU(ALU_A_ADD_1_C);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�з���16λȡ�ຯ������*/
void signed_mod16_func_gen() {
	if (signed_mod16_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 2;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 3;
		unsigned char reg_0 = REGISTER_FILE_OP_FUNC_CACHE + 4;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		signed_mod16_func_romaddr = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(reg_0, ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN_ALU(ALU_A_NOT);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		A_ASGN_ALU(ALU_A_ADD_1_C);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN_ALU(ALU_A_NOT);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		A_ASGN_ALU(ALU_A_ADD_1_C);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_ROP + 1, ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(reg_cp, 15);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		A_ASGN_ALU(ALU_SUB_C);
		B_ASGN__RF(reg_sub_c);
		A_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		A_ASGN__RF(reg_0);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN_ALU(ALU_A_NOT);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		A_ASGN_ALU(ALU_A_ADD_1_C);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�޷���32λ������������*/
void unsigned_div32_func_gen() {
	if (unsigned_div32_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_mod = REGISTER_FILE_OP_FUNC_CACHE + 5;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 9;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		unsigned_div32_func_romaddr = rom_cp >> 1;
		
		_RF_ASGN_IMMNUM(reg_mod + 3, 0);
		_RF_ASGN_IMMNUM(reg_mod + 2, 0);
		_RF_ASGN_IMMNUM(reg_mod + 1, 0);
		_RF_ASGN_IMMNUM(reg_mod, 0);
		_RF_ASGN_IMMNUM(reg_cp, 31);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(reg_mod + 2);
		A_ASGN__RF(reg_mod + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_mod + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod);
		_RF_ASGN_ALU(reg_mod + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(reg_mod, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);
		
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		
		A_ASGN__RF(reg_mod);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(reg_mod, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(reg_mod + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(reg_mod + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(reg_mod + 3, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);
		

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�޷���64λ������������*/
void unsigned_div64_func_gen() {
	if (unsigned_div64_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 8;
		unsigned char reg_mod = REGISTER_FILE_OP_FUNC_CACHE + 9;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 17;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		unsigned_div64_func_romaddr = rom_cp >> 1;

		_RF_ASGN_IMMNUM(reg_mod + 7, 0);
		_RF_ASGN_IMMNUM(reg_mod + 6, 0);
		_RF_ASGN_IMMNUM(reg_mod + 5, 0);
		_RF_ASGN_IMMNUM(reg_mod + 4, 0);
		_RF_ASGN_IMMNUM(reg_mod + 3, 0);
		_RF_ASGN_IMMNUM(reg_mod + 2, 0);
		_RF_ASGN_IMMNUM(reg_mod + 1, 0);
		_RF_ASGN_IMMNUM(reg_mod, 0);
		_RF_ASGN_IMMNUM(reg_cp, 63);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(reg_mod + 6);
		A_ASGN__RF(reg_mod + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 5);
		_RF_ASGN_ALU(reg_mod + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 4);
		_RF_ASGN_ALU(reg_mod + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 3);
		_RF_ASGN_ALU(reg_mod + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 2);
		_RF_ASGN_ALU(reg_mod + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_mod + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod);
		_RF_ASGN_ALU(reg_mod + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(reg_mod, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 7, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(reg_mod);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 4);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_sub + 4, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 5);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_sub + 5, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 6);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_sub + 6, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 7);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(reg_sub + 7, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(reg_mod, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(reg_mod + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(reg_mod + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(reg_mod + 3, ALU_OUTA);
		A_ASGN__RF(reg_sub + 4);
		_RF_ASGN_ALU(reg_mod + 4, ALU_OUTA);
		A_ASGN__RF(reg_sub + 5);
		_RF_ASGN_ALU(reg_mod + 5, ALU_OUTA);
		A_ASGN__RF(reg_sub + 6);
		_RF_ASGN_ALU(reg_mod + 6, ALU_OUTA);
		A_ASGN__RF(reg_sub + 7);
		_RF_ASGN_ALU(reg_mod + 7, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�޷���32λȡ�ຯ������*/
void unsigned_mod32_func_gen() {
	if (unsigned_mod32_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 5;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		unsigned_mod32_func_romaddr = rom_cp >> 1;

		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(reg_cp, 31);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�޷���64λȡ�ຯ������*/
void unsigned_mod64_func_gen() {
	if (unsigned_mod64_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 8;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 9;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		unsigned_mod64_func_romaddr = rom_cp >> 1;

		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(reg_cp, 63);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 7, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_sub + 4, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_sub + 5, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_sub + 6, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(reg_sub + 7, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		A_ASGN__RF(reg_sub + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_OUTA);
		A_ASGN__RF(reg_sub + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_OUTA);
		A_ASGN__RF(reg_sub + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_OUTA);
		A_ASGN__RF(reg_sub + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�з���32λ������������*/
void signed_div32_func_gen() {
	if (signed_div32_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_mod = REGISTER_FILE_OP_FUNC_CACHE + 5;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 9;
		unsigned char reg_0 = REGISTER_FILE_OP_FUNC_CACHE + 10;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		signed_div32_func_romaddr = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(reg_0, ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_0);
		RF_ASGN_ALU(ALU_A_NOT);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		_RF_ASGN_IMMNUM(reg_mod + 3, 0);
		_RF_ASGN_IMMNUM(reg_mod + 2, 0);
		_RF_ASGN_IMMNUM(reg_mod + 1, 0);
		_RF_ASGN_IMMNUM(reg_mod, 0);
		_RF_ASGN_IMMNUM(reg_cp, 31);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(reg_mod + 2);
		A_ASGN__RF(reg_mod + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_mod + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod);
		_RF_ASGN_ALU(reg_mod + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(reg_mod, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(reg_mod);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(reg_mod, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(reg_mod + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(reg_mod + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(reg_mod + 3, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		A_ASGN__RF(reg_0);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�з���64λ������������*/
void signed_div64_func_gen() {
	if (signed_div64_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 8;
		unsigned char reg_mod = REGISTER_FILE_OP_FUNC_CACHE + 9;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 17;
		unsigned char reg_0 = REGISTER_FILE_OP_FUNC_CACHE + 18;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		signed_div64_func_romaddr = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(reg_0, ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_0);
		RF_ASGN_ALU(ALU_A_NOT);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		_RF_ASGN_IMMNUM(reg_mod + 7, 0);
		_RF_ASGN_IMMNUM(reg_mod + 6, 0);
		_RF_ASGN_IMMNUM(reg_mod + 5, 0);
		_RF_ASGN_IMMNUM(reg_mod + 4, 0);
		_RF_ASGN_IMMNUM(reg_mod + 3, 0);
		_RF_ASGN_IMMNUM(reg_mod + 2, 0);
		_RF_ASGN_IMMNUM(reg_mod + 1, 0);
		_RF_ASGN_IMMNUM(reg_mod, 0);
		_RF_ASGN_IMMNUM(reg_cp, 63);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(reg_mod + 6);
		A_ASGN__RF(reg_mod + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 5);
		_RF_ASGN_ALU(reg_mod + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 4);
		_RF_ASGN_ALU(reg_mod + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 3);
		_RF_ASGN_ALU(reg_mod + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 2);
		_RF_ASGN_ALU(reg_mod + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_mod + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(reg_mod);
		_RF_ASGN_ALU(reg_mod + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(reg_mod, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 7, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(reg_mod);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_mod + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 4);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_sub + 4, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 5);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_sub + 5, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 6);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_sub + 6, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(reg_mod + 7);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(reg_sub + 7, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(reg_mod, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(reg_mod + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(reg_mod + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(reg_mod + 3, ALU_OUTA);
		A_ASGN__RF(reg_sub + 4);
		_RF_ASGN_ALU(reg_mod + 4, ALU_OUTA);
		A_ASGN__RF(reg_sub + 5);
		_RF_ASGN_ALU(reg_mod + 5, ALU_OUTA);
		A_ASGN__RF(reg_sub + 6);
		_RF_ASGN_ALU(reg_mod + 6, ALU_OUTA);
		A_ASGN__RF(reg_sub + 7);
		_RF_ASGN_ALU(reg_mod + 7, ALU_OUTA);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		A_ASGN__RF(reg_0);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�з���32λȡ�ຯ������*/
void signed_mod32_func_gen() {
	if (signed_mod32_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 4;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 5;
		unsigned char reg_0 = REGISTER_FILE_OP_FUNC_CACHE + 6;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		signed_mod32_func_romaddr = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(reg_0, ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(reg_cp, 31);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		A_ASGN__RF(reg_0);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*�з���64λȡ�ຯ������*/
void signed_mod64_func_gen() {
	if (signed_mod64_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_sub = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_sub_c = REGISTER_FILE_OP_FUNC_CACHE + 8;
		unsigned char reg_cp = REGISTER_FILE_OP_FUNC_CACHE + 9;
		unsigned char reg_0 = REGISTER_FILE_OP_FUNC_CACHE + 10;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		signed_mod64_func_romaddr = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(reg_0, ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(reg_cp, 63);
		label_1 = rom_cp >> 1;

		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 7, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP);
		_RF_ASGN_ALU(reg_sub, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 1);
		_RF_ASGN_ALU(reg_sub + 1, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 2);
		_RF_ASGN_ALU(reg_sub + 2, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);

		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 3);
		_RF_ASGN_ALU(reg_sub + 3, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 4);
		_RF_ASGN_ALU(reg_sub + 4, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 5);
		_RF_ASGN_ALU(reg_sub + 5, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 6);
		_RF_ASGN_ALU(reg_sub + 6, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		_RF_ASGN_ALU(reg_sub_c, ALU_SUB_C);
		A_ASGN_ALU(ALU_SUB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_ROP + 7);
		_RF_ASGN_ALU(reg_sub + 7, ALU_SUB);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_sub_c);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		A_ASGN__RF(reg_sub);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_OUTA);
		A_ASGN__RF(reg_sub + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_OUTA);
		A_ASGN__RF(reg_sub + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_OUTA);
		A_ASGN__RF(reg_sub + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		A_ASGN__RF(reg_sub + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_OUTA);
		A_ASGN__RF(reg_sub + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_OUTA);
		A_ASGN__RF(reg_sub + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_OUTA);
		A_ASGN__RF(reg_sub + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		A_ASGN__RF(reg_cp);
		RF_ASGN_ALU(ALU_A_SUB_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_1);

		A_ASGN__RF(reg_0);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_OUTA, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*Ŀ�Ĳ�������������������Ҳ�����*/
void DOP_ASGN_LOP_DIV_ROP(Xop* d, Xop* l, Xop* r) {
	Xop sd = *d, sl = *l, sr = *r;

	if ((sl.datatype == Xop::XOP_I && sr.datatype == Xop::XOP_I) || (sl.datatype == Xop::XOP_U && sr.datatype == Xop::XOP_U)) {
		if (sl.datasize == 1 && sr.datasize == 1) {
			addr_convert(&sd, &sl, &sr);
			if (sl.datatype == Xop::XOP_U) {
				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 0);
				OP_ASGN_ALU(&sd, 0, ALU_DIV);
			}
			else {
				unsigned char reg_l = regalloc(1, 1);
				unsigned char reg_r = regalloc(1, 1);
				unsigned char reg_d = regalloc(1, 1);
				unsigned char reg_0 = regalloc(1, 1);

				A_ASGN_OP(&sl, 0);
				B_ASGN_ALU(ALU_OUTA);
				A_ASGN_ALU(ALU_ADD_C);
				_RF_ASGN_ALU(reg_l, ALU_OUTA);
				_RF_ASGN_ALU(reg_0, ALU_OUTA);
				B_ASGN_IMMNUM(0xff);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN_OP(&sl, 0);
				A_ASGN_ALU(ALU_XOR);
				B_ASGN__RF(reg_l);
				RF_ASGN_ALU(ALU_ADD);

				B_ASGN_OP(&sr, 0);
				A_ASGN_ALU(ALU_OUTA);
				B_ASGN_ALU(ALU_ADD_C);
				_RF_ASGN_ALU(reg_r, ALU_OUTB);
				A_ASGN__RF(reg_0);
				RF_ASGN_ALU(ALU_XOR);
				A_ASGN_IMMNUM(0xff);
				B_ASGN_ALU(ALU_MUL_L);
				A_ASGN_OP(&sr, 0);
				B_ASGN_ALU(ALU_XOR);
				A_ASGN__RF(reg_r);
				B_ASGN_ALU(ALU_ADD);

				A_ASGN__RF(reg_l);
				_RF_ASGN_ALU(reg_d, ALU_DIV);

				A_ASGN__RF(reg_0);
				B_ASGN_IMMNUM(0xff);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF(reg_d);
				A_ASGN_ALU(ALU_XOR);
				B_ASGN__RF(reg_0);
				OP_ASGN_ALU(&sd, 0, ALU_ADD);

				regfree(reg_l, 1);
				regfree(reg_r, 1);
				regfree(reg_d, 1);
				regfree(reg_0, 1);
			}
			if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
				DOP_ASGN_SOP(d, &sd);
				regfree(sd.v.i, sd.datasize);
			}
			if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sl.v.i, sl.datasize);
			if (sr.addrtype == Xop::XOP_REGISTER_FILE && r->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sr.v.i, sr.datasize);
		}
		else {
			unsigned long cp[3];

			sl.addrtype = Xop::XOP_REGISTER_FILE;
			sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
			REGISTER_FILE_ASGN_OP(&sl, l);
			sr.addrtype = Xop::XOP_REGISTER_FILE;
			sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
			REGISTER_FILE_ASGN_OP(&sr, r);
			for (int i = 0; i < 3; ++i) {
				_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
				cp[i] = rom_cp - 1;
			}
			if (sl.datasize == 2 && sr.datasize == 2) {
				if (sl.datatype == Xop::XOP_U) {
					unsigned_div16_func_gen();
					PC_ASGN_IMMNUM(unsigned_div16_func_romaddr);
				}
				else {
					signed_div16_func_gen();
					PC_ASGN_IMMNUM(signed_div16_func_romaddr);
				}
			}
			else if (sl.datasize == 4 && sr.datasize == 4) {
				if (sl.datatype == Xop::XOP_U) {
					unsigned_div32_func_gen();
					PC_ASGN_IMMNUM(unsigned_div32_func_romaddr);
				}
				else {
					signed_div32_func_gen();
					PC_ASGN_IMMNUM(signed_div32_func_romaddr);
				}
			}
			else if (sl.datasize == 8 && sr.datasize == 8) {
				if (sl.datatype == Xop::XOP_U) {
					unsigned_div64_func_gen();
					PC_ASGN_IMMNUM(unsigned_div64_func_romaddr);
				}
				else {
					signed_div64_func_gen();
					PC_ASGN_IMMNUM(signed_div64_func_romaddr);
				}
			}
			else
				error("���DOP_ASGN_LOP_DIV_ROP�������ɻ��������д���\n");
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (LOC_OFFSET_CONST_P_OR(sd.addrtype)) {
				sd.addrtype = Xop::XOP_REGISTER_FILE;
				sd.datatype = sl.datatype;
				sd.datasize = sl.datasize;
				sd.v.i = REGISTER_FILE_OP_FUNC_DOP;
				DOP_ASGN_SOP(d, &sd);
			}
			else if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
				if (sd.v.i != REGISTER_FILE_OP_FUNC_DOP) {
					for (int i = 0; i < sd.datasize; ++i) {
						A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
						_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
					}
				}
			}
			else
				error("���DOP_ASGN_LOP_DIV_ROP�������ɻ��������д���\n");
		}
	}
	else if (sl.datatype == Xop::XOP_F && sr.datatype == Xop::XOP_F) {
		unsigned long cp[3];

		sl.addrtype = Xop::XOP_REGISTER_FILE;
		sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
		REGISTER_FILE_ASGN_OP(&sl, l);
		sr.addrtype = Xop::XOP_REGISTER_FILE;
		sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
		REGISTER_FILE_ASGN_OP(&sr, r);
		for (int i = 0; i < 3; ++i) {
			_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
			cp[i] = rom_cp - 1;
		}
		if (sl.datasize == 4 && sr.datasize == 4) {
			/*float*/
			float_div_func_gen();
			PC_ASGN_IMMNUM(float_div_func_romaddr);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			/*double*/
			double_div_func_gen();
			PC_ASGN_IMMNUM(double_div_func_romaddr);
		}
		else
			error("���DOP_ASGN_LOP_DIV_ROP�������ɻ��������д���\n");
		romdata[cp[0]] = rom_cp >> 1;
		romdata[cp[1]] = rom_cp >> 9;
		romdata[cp[2]] = rom_cp >> 17;
		if (LOC_OFFSET_CONST_P_OR(sd.addrtype)) {
			sd.addrtype = Xop::XOP_REGISTER_FILE;
			sd.datatype = sl.datatype;
			sd.datasize = sl.datasize;
			sd.v.i = REGISTER_FILE_OP_FUNC_DOP;
			DOP_ASGN_SOP(d, &sd);
		}
		else if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
			if (sd.v.i != REGISTER_FILE_OP_FUNC_DOP) {
				for (int i = 0; i < sd.datasize; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
				}
			}
		}
		else
			error("���DOP_ASGN_LOP_DIV_ROP�������ɻ��������д���\n");
		return;
	}
	else
		error("���DOP_ASGN_LOP_DIV_ROP�������ɻ��������д���\n");
}

/*����������Ҳ�����,������Ŀ�Ĳ�����*/
void DOP_ASGN_LOP_MOD_ROP(Xop* d, Xop* l, Xop* r) {
	Xop sd = *d, sl = *l, sr = *r;

	if ((sl.datatype == Xop::XOP_I && sr.datatype == Xop::XOP_I) || (sl.datatype == Xop::XOP_U && sr.datatype == Xop::XOP_U)) {
		if (sl.datasize == 1 && sr.datasize == 1) {
			addr_convert(&sd, &sl, &sr);
			if (sl.datatype == Xop::XOP_U) {
				A_ASGN_OP(&sl, 0);
				B_ASGN_OP(&sr, 0);
				OP_ASGN_ALU(&sd, 0, ALU_MOD);
			}
			else {
				unsigned char reg_l = regalloc(1, 1);
				unsigned char reg_r = regalloc(1, 1);
				unsigned char reg_d = regalloc(1, 1);
				unsigned char reg_0 = regalloc(1, 1);

				A_ASGN_OP(&sl, 0);
				B_ASGN_ALU(ALU_OUTA);
				A_ASGN_ALU(ALU_ADD_C);
				_RF_ASGN_ALU(reg_l, ALU_OUTA);
				_RF_ASGN_ALU(reg_0, ALU_OUTA);
				B_ASGN_IMMNUM(0xff);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN_OP(&sl, 0);
				A_ASGN_ALU(ALU_XOR);
				B_ASGN__RF(reg_l);
				RF_ASGN_ALU(ALU_ADD);

				B_ASGN_OP(&sr, 0);
				A_ASGN_ALU(ALU_OUTA);
				B_ASGN_ALU(ALU_ADD_C);
				_RF_ASGN_ALU(reg_r, ALU_OUTB);
				A_ASGN_IMMNUM(0xff);
				B_ASGN_ALU(ALU_MUL_L);
				A_ASGN_OP(&sr, 0);
				B_ASGN_ALU(ALU_XOR);
				A_ASGN__RF(reg_r);
				B_ASGN_ALU(ALU_ADD);

				A_ASGN__RF(reg_l);
				_RF_ASGN_ALU(reg_d, ALU_MOD);

				A_ASGN__RF(reg_0);
				B_ASGN_IMMNUM(0xff);
				A_ASGN_ALU(ALU_MUL_L);
				B_ASGN__RF(reg_d);
				A_ASGN_ALU(ALU_XOR);
				B_ASGN__RF(reg_0);
				OP_ASGN_ALU(&sd, 0, ALU_ADD);

				regfree(reg_l, 1);
				regfree(reg_r, 1);
				regfree(reg_d, 1);
				regfree(reg_0, 1);
			}
			if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
				DOP_ASGN_SOP(d, &sd);
				regfree(sd.v.i, sd.datasize);
			}
			if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sl.v.i, sl.datasize);
			if (sr.addrtype == Xop::XOP_REGISTER_FILE && r->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sr.v.i, sr.datasize);
		}
		else {
			unsigned long cp[3];

			sl.addrtype = Xop::XOP_REGISTER_FILE;
			sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
			REGISTER_FILE_ASGN_OP(&sl, l);
			sr.addrtype = Xop::XOP_REGISTER_FILE;
			sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
			REGISTER_FILE_ASGN_OP(&sr, r);
			for (int i = 0; i < 3; ++i) {
				_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
				cp[i] = rom_cp - 1;
			}
			if (sl.datasize == 2 && sr.datasize == 2) {
				if (sl.datatype == Xop::XOP_U) {
					unsigned_mod16_func_gen();
					PC_ASGN_IMMNUM(unsigned_mod16_func_romaddr);
				}
				else {
					signed_mod16_func_gen();
					PC_ASGN_IMMNUM(signed_mod16_func_romaddr);
				}
			}
			else if (sl.datasize == 4 && sr.datasize == 4) {
				if (sl.datatype == Xop::XOP_U) {
					unsigned_mod32_func_gen();
					PC_ASGN_IMMNUM(unsigned_mod32_func_romaddr);
				}
				else {
					signed_mod32_func_gen();
					PC_ASGN_IMMNUM(signed_mod32_func_romaddr);
				}
			}
			else if (sl.datasize == 8 && sr.datasize == 8) {
				if (sl.datatype == Xop::XOP_U) {
					unsigned_mod64_func_gen();
					PC_ASGN_IMMNUM(unsigned_mod64_func_romaddr);
				}
				else {
					signed_mod64_func_gen();
					PC_ASGN_IMMNUM(signed_mod64_func_romaddr);
				}
			}
			else
				error("���DOP_ASGN_LOP_MOD_ROP�������ɻ��������д���\n");
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (LOC_OFFSET_CONST_P_OR(sd.addrtype)) {
				sd.addrtype = Xop::XOP_REGISTER_FILE;
				sd.datatype = sl.datatype;
				sd.datasize = sl.datasize;
				sd.v.i = REGISTER_FILE_OP_FUNC_DOP;
				DOP_ASGN_SOP(d, &sd);
			}
			else if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
				if (sd.v.i != REGISTER_FILE_OP_FUNC_DOP) {
					for (int i = 0; i < sd.datasize; ++i) {
						A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
						_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
					}
				}
			}
			else
				error("���DOP_ASGN_LOP_MOD_ROP�������ɻ��������д���\n");
		}
	}
	else
		error("���DOP_ASGN_LOP_MOD_ROP�������ɻ��������д���\n");
}

/*Ŀ�Ĳ�����������������롢������Ҳ�����*/
void DOP_ASGN_LOP_AND_OR_XOR_ROP(Xop* d, Xop* l, Xop* r, char control) {
	Xop sd = *d, sl = *l, sr = *r;
	unsigned char aluaddr;

	switch (control) {
	case 0: aluaddr = ALU_AND; break;
	case 1: aluaddr = ALU_OR; break;
	case 2: aluaddr = ALU_XOR; break;
	}
	if ((sl.datatype == Xop::XOP_I && sr.datatype == Xop::XOP_I) || (sl.datatype == Xop::XOP_U && sr.datatype == Xop::XOP_U)) {
		addr_convert(&sd, &sl, &sr);
		if (sl.datasize >= 1 && sr.datasize >= 1 && sl.datasize <= 8 && sr.datasize <= 8) {
			for (int i = 0; i < sl.datasize; ++i) {
				A_ASGN_OP(&sl, i);
				B_ASGN_OP(&sr, i);
				OP_ASGN_ALU(&sd, i, aluaddr);
			}
		}
		else if (sl.datasize == 4 && sr.datasize == 1 && sr.addrtype == Xop::XOP_CONST && aluaddr == ALU_AND) {
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, ALU_AND);
			A_ASGN_IMMNUM(0);
			OP_ASGN_ALU(&sd, 1, ALU_OUTA);
			OP_ASGN_ALU(&sd, 2, ALU_OUTA);
			OP_ASGN_ALU(&sd, 3, ALU_OUTA);
		}
		else if (sl.datasize == 8 && sr.datasize == 1 && sr.addrtype == Xop::XOP_CONST && aluaddr == ALU_AND) {
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			OP_ASGN_ALU(&sd, 0, ALU_AND);
			A_ASGN_IMMNUM(0);
			for(int i = 1; i < 8; ++i)
				OP_ASGN_ALU(&sd, i, ALU_OUTA);
		}
		else
			error("���DOP_ASGN_LOP_AND_OR_XOR_ROP�������ɻ��������д���\n");
	}
	else
		error("���DOP_ASGN_LOP_AND_OR_XOR_ROP�������ɻ��������д���\n");
	if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
		DOP_ASGN_SOP(d, &sd);
		regfree(sd.v.i, sd.datasize);
	}
	if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sl.v.i, sl.datasize);
	if (sr.addrtype == Xop::XOP_REGISTER_FILE && r->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sr.v.i, sr.datasize);
}

/*Ŀ�Ĳ�������������������Ҳ�����*/
void DOP_ASGN_LOP_AND_ROP(Xop* d, Xop* l, Xop* r) {
	DOP_ASGN_LOP_AND_OR_XOR_ROP(d, l, r, 0);
}

/*Ŀ�Ĳ�������������������Ҳ�����*/
void DOP_ASGN_LOP_OR_ROP(Xop* d, Xop* l, Xop* r) {
	DOP_ASGN_LOP_AND_OR_XOR_ROP(d, l, r, 1);
}

/*Ŀ�Ĳ��������������������Ҳ�����*/
void DOP_ASGN_LOP_XOR_ROP(Xop* d, Xop* l, Xop* r) {
	DOP_ASGN_LOP_AND_OR_XOR_ROP(d, l, r, 2);
}

/*Ŀ�Ĳ��������������������,�Ҳ�����Ϊ����λ��*/
void DOP_ASGN_LOP_LSH_ROP(Xop* d, Xop* l, Xop* r) {
	Xop sd = *d, sl = *l, sr = *r;

	if (((sl.datatype == Xop::XOP_I || sl.datatype == Xop::XOP_U) && sr.datatype == Xop::XOP_I)) {
		if (sr.addrtype == Xop::XOP_CONST && ((sr.v.i >= 0 && sr.v.i <= 8) || sr.v.i == 16 || sr.v.i == 24 || sr.v.i == 32 || sr.v.i == 40 || sr.v.i == 48 || sr.v.i == 56 || sr.v.i == 64)) {
			addr_convert(&sd, &sl, NULL);
			if (sr.v.i == 0) {
				if (sl.datasize >= 1 && sl.datasize <= 8) {
					for (int i = 0; i < sl.datasize; ++i) {
						A_ASGN_OP(&sl, i);
						OP_ASGN_ALU(&sd, i, ALU_OUTA);
					}
				}
				else
					error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
			}
			else if (sr.v.i == 1) {
				if (sl.datasize == 1) {
					A_ASGN_OP(&sl, 0);
					OP_ASGN_ALU(&sd, 0, ALU_A_0_LSH);
				}
				else if (sl.datasize == 2) {
					A_ASGN_OP(&sl, 1);
					B_ASGN_OP(&sl, 0);
					OP_ASGN_ALU(&sd, 0, ALU_B_0_LSH);
					OP_ASGN_ALU(&sd, 1, ALU_A_BH_LSH);
				}
				else if (sl.datasize == 4) {
					B_ASGN_OP(&sl, 2);
					A_ASGN_OP(&sl, 3);
					OP_ASGN_ALU(&sd, 3, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 1);
					OP_ASGN_ALU(&sd, 2, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 0);
					OP_ASGN_ALU(&sd, 0, ALU_B_0_LSH);
					OP_ASGN_ALU(&sd, 1, ALU_A_BH_LSH);
				}
				else if (sl.datasize == 8) {
					B_ASGN_OP(&sl, 6);
					A_ASGN_OP(&sl, 7);
					OP_ASGN_ALU(&sd, 7, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 5);
					OP_ASGN_ALU(&sd, 6, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 4);
					OP_ASGN_ALU(&sd, 5, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 3);
					OP_ASGN_ALU(&sd, 4, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 2);
					OP_ASGN_ALU(&sd, 3, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 1);
					OP_ASGN_ALU(&sd, 2, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN_OP(&sl, 0);
					OP_ASGN_ALU(&sd, 0, ALU_B_0_LSH);
					OP_ASGN_ALU(&sd, 1, ALU_A_BH_LSH);
				}
				else
					error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
			}
			else if (sr.v.i > 1 && sr.v.i < 8) {
				if (sl.datasize == 1) {
					A_ASGN_OP(&sl, 0);
					B_ASGN_IMMNUM(1 << sr.v.i);
					OP_ASGN_ALU(&sd, 0, ALU_MUL_L);
				}
				else if (sl.datasize == 2) {
					unsigned char reg_h0 = regalloc(1, 1);

					A_ASGN_IMMNUM(1 << sr.v.i);
					B_ASGN_OP(&sl, 0);
					_RF_ASGN_ALU_O(reg_h0, ALU_MUL_H);
					OP_ASGN_ALU(&sd, 0, ALU_MUL_L);
					B_ASGN_OP(&sl, 1);
					A_ASGN_ALU(ALU_MUL_L);
					B_ASGN__RF_O(reg_h0);
					OP_ASGN_ALU(&sd, 1, ALU_ADD);

					regfree(reg_h0, 1);
				}
				else if (sl.datasize == 4) {
					unsigned char reg_h0 = regalloc(1, 1);
					unsigned char reg_h1 = regalloc(1, 1);
					unsigned char reg_l1 = regalloc(1, 1);
					unsigned char reg_h2 = regalloc(1, 1);
					unsigned char reg_l2 = regalloc(1, 1);
					
					A_ASGN_IMMNUM(1 << sr.v.i);
					B_ASGN_OP(&sl, 0);
					_RF_ASGN_ALU_O(reg_h0, ALU_MUL_H);
					OP_ASGN_ALU(&sd, 0, ALU_MUL_L);
					B_ASGN_OP(&sl, 1);
					_RF_ASGN_ALU_O(reg_h1, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l1, ALU_MUL_L);
					B_ASGN_OP(&sl, 2);
					_RF_ASGN_ALU_O(reg_h2, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l2, ALU_MUL_L);
					B_ASGN_OP(&sl, 3);
					A_ASGN_ALU(ALU_MUL_L);
					B_ASGN__RF_O(reg_h2);
					OP_ASGN_ALU(&sd, 3, ALU_ADD);
					A_ASGN__RF_O(reg_l2);
					B_ASGN__RF_O(reg_h1);
					OP_ASGN_ALU(&sd, 2, ALU_ADD);
					A_ASGN__RF_O(reg_l1);
					B_ASGN__RF_O(reg_h0);
					OP_ASGN_ALU(&sd, 1, ALU_ADD);

					regfree(reg_h0, 1);
					regfree(reg_h1, 1);
					regfree(reg_l1, 1);
					regfree(reg_h2, 1);
					regfree(reg_l2, 1);
				}
				else if (sl.datasize == 8) {
					unsigned char reg_h0 = regalloc(1, 1);
					unsigned char reg_h1 = regalloc(1, 1);
					unsigned char reg_l1 = regalloc(1, 1);
					unsigned char reg_h2 = regalloc(1, 1);
					unsigned char reg_l2 = regalloc(1, 1);
					unsigned char reg_h3 = regalloc(1, 1);
					unsigned char reg_l3 = regalloc(1, 1);
					unsigned char reg_h4 = regalloc(1, 1);
					unsigned char reg_l4 = regalloc(1, 1);
					unsigned char reg_h5 = regalloc(1, 1);
					unsigned char reg_l5 = regalloc(1, 1);
					unsigned char reg_h6 = regalloc(1, 1);
					unsigned char reg_l6 = regalloc(1, 1);

					A_ASGN_IMMNUM(1 << sr.v.i);
					B_ASGN_OP(&sl, 0);
					_RF_ASGN_ALU_O(reg_h0, ALU_MUL_H);
					OP_ASGN_ALU(&sd, 0, ALU_MUL_L);
					B_ASGN_OP(&sl, 1);
					_RF_ASGN_ALU_O(reg_h1, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l1, ALU_MUL_L);
					B_ASGN_OP(&sl, 2);
					_RF_ASGN_ALU_O(reg_h2, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l2, ALU_MUL_L);
					B_ASGN_OP(&sl, 3);
					_RF_ASGN_ALU_O(reg_h3, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l3, ALU_MUL_L);
					B_ASGN_OP(&sl, 4);
					_RF_ASGN_ALU_O(reg_h4, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l4, ALU_MUL_L);
					B_ASGN_OP(&sl, 5);
					_RF_ASGN_ALU_O(reg_h5, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l5, ALU_MUL_L);
					B_ASGN_OP(&sl, 6);
					_RF_ASGN_ALU_O(reg_h6, ALU_MUL_H);
					_RF_ASGN_ALU_O(reg_l6, ALU_MUL_L);
					B_ASGN_OP(&sl, 7);
					A_ASGN_ALU(ALU_MUL_L);
					B_ASGN__RF_O(reg_h6);
					OP_ASGN_ALU(&sd, 7, ALU_ADD);
					A_ASGN__RF_O(reg_l6);
					B_ASGN__RF_O(reg_h5);
					OP_ASGN_ALU(&sd, 6, ALU_ADD);
					A_ASGN__RF_O(reg_l5);
					B_ASGN__RF_O(reg_h4);
					OP_ASGN_ALU(&sd, 5, ALU_ADD);
					A_ASGN__RF_O(reg_l4);
					B_ASGN__RF_O(reg_h3);
					OP_ASGN_ALU(&sd, 4, ALU_ADD);
					A_ASGN__RF_O(reg_l3);
					B_ASGN__RF_O(reg_h2);
					OP_ASGN_ALU(&sd, 3, ALU_ADD);
					A_ASGN__RF_O(reg_l2);
					B_ASGN__RF_O(reg_h1);
					OP_ASGN_ALU(&sd, 2, ALU_ADD);
					A_ASGN__RF_O(reg_l1);
					B_ASGN__RF_O(reg_h0);
					OP_ASGN_ALU(&sd, 1, ALU_ADD);

					regfree(reg_h0, 1);
					regfree(reg_h1, 1);
					regfree(reg_l1, 1);
					regfree(reg_h2, 1);
					regfree(reg_l2, 1);
					regfree(reg_h3, 1);
					regfree(reg_l3, 1);
					regfree(reg_h4, 1);
					regfree(reg_l4, 1);
					regfree(reg_h5, 1);
					regfree(reg_l5, 1);
					regfree(reg_h6, 1);
					regfree(reg_l6, 1);
				}
				else
					error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
			}
			else {
				if (sr.v.i >= sl.datasize * 8) {
					A_ASGN_IMMNUM(0);
					for (int i = 0; i < sl.datasize; ++i)
						OP_ASGN_ALU(&sd, i, ALU_OUTA);
				}
				else {
					int i;
					for (i = sl.datasize - 1; i - (sr.v.i / 8) >= 0; --i) {
						A_ASGN_OP(&sl, i - (sr.v.i / 8));
						OP_ASGN_ALU(&sd, i, ALU_OUTA);
					}
					A_ASGN_IMMNUM(0);
					for (; i >= 0; --i)
						OP_ASGN_ALU(&sd, i, ALU_OUTA);
				}
			}
			if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
				DOP_ASGN_SOP(d, &sd);
				regfree(sd.v.i, sd.datasize);
			}
			if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sl.v.i, sl.datasize);
		}
		else {
			char l_regfree = 0, r_regfree = 0;

			switch (sr.addrtype) {
			case Xop::XOP_LOC: case Xop::XOP_OFFSET: case Xop::XOP_CONST_P:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				r->datatype = Xop::XOP_X;
				DOP_ASGN_SOP_INDIR(&sr, r);
				r->datatype = sr.datatype;
				r_regfree = 1;
				break;
			case Xop::XOP_REGISTER_FILE:
				if (glowreg[sr.v.i].life > 1) {
					sr.v.i = regalloc(sr.datasize, 1);
					A_ASGN__RF_O(r->v.i);
					_RF_ASGN_ALU_O(sr.v.i, ALU_OUTA);
					r_regfree = 1;
				}
				break;
			case Xop::XOP_CONST:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				_RF_ASGN_IMMNUM_O(sr.v.i, r->v.i);
				r_regfree = 1;
				break;
			case Xop::XOP_REGISTER_IO0:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				_RF_ASGN_IO0(sr.v.i);
				r_regfree = 1;
				break;
			case Xop::XOP_REGISTER_IO1:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				_RF_ASGN_IO1(sr.v.i);
				r_regfree = 1;
				break;
			default:
				error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
			}
			switch (sl.addrtype) {
			case Xop::XOP_LOC: case Xop::XOP_OFFSET: case Xop::XOP_CONST_P:
				if (sd.addrtype == Xop::XOP_REGISTER_FILE)
					sl.v.i = sd.v.i;
				else {
					sl.v.i = regalloc(sl.datasize, 1);
					l_regfree = 1;
				}
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				l->datatype = Xop::XOP_X;
				DOP_ASGN_SOP_INDIR(&sl, l);
				l->datatype = sl.datatype;
				break;
			case Xop::XOP_REGISTER_FILE:
				if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
					if (glowreg[sl.v.i].life > 1) {
						for (int i = 0; i < sd.datasize; ++i) {
							A_ASGN__RF(sl.v.i + i);
							_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
						}
						sl.v.i = sd.v.i;
					}
					else {
						glowreg[sl.v.i].life += glowreg[sd.v.i].life;
						glowreg[sd.v.i].life = 1;
						regfree(sd.v.i, sd.datasize);
						d->v.i = sl.v.i;
					}
				}
				else if (glowreg[sl.v.i].life > 1) {
					sl.v.i = regalloc(sl.datasize, 1);
					for (int i = 0; i < sl.datasize; ++i) {
						A_ASGN__RF(l->v.i + i);
						_RF_ASGN_ALU(sl.v.i + i, ALU_OUTA);
					}
					l_regfree = 1;
				}
				break;
			case Xop::XOP_CONST:
				if (sd.addrtype == Xop::XOP_REGISTER_FILE)
					sl.v.i = sd.v.i;
				else {
					sl.v.i = regalloc(sl.datasize, 1);
					l_regfree = 1;
				}
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				for (int i = 0; i < sl.datasize; ++i)
					_RF_ASGN_IMMNUM_O(sl.v.i + i, l->v.i >> (i * 8));
				break;
			case Xop::XOP_REGISTER_IO0:
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				sl.v.i = regalloc(sl.datasize, 1);
				_RF_ASGN_IO0(sl.v.i);
				l_regfree = 1;
				break;
			case Xop::XOP_REGISTER_IO1:
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				sl.v.i = regalloc(sl.datasize, 1);
				_RF_ASGN_IO1(sl.v.i);
				l_regfree = 1;
				break;
			default:
				error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
			}
			if (sl.addrtype == Xop::XOP_REGISTER_FILE && sr.addrtype == Xop::XOP_REGISTER_FILE) {
				unsigned long label_0, label_1;

				if (sl.datasize == 1) {
					A_ASGN__RF_O(sr.v.i);
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					B_ASGN__RF(sl.v.i);
					RF_ASGN_ALU(ALU_B_0_LSH);
					A_ASGN_ALU(ALU_A_SUB_1);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else if (sl.datasize == 2) {
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					A_ASGN__RF(sl.v.i + 1);
					B_ASGN__RF(sl.v.i);
					RF_ASGN_ALU(ALU_B_0_LSH);
					_RF_ASGN_ALU(sl.v.i + 1, ALU_A_BH_LSH);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					A_ASGN__RF(sr.v.i);
					RF_ASGN_ALU(ALU_A_SUB_1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else if (sl.datasize == 4) {
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					B_ASGN__RF(sl.v.i + 2);
					A_ASGN__RF(sl.v.i + 3);
					RF_ASGN_ALU(ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i + 1);
					_RF_ASGN_ALU(sl.v.i + 2, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i);
					RF_ASGN_ALU(ALU_B_0_LSH);
					_RF_ASGN_ALU(sl.v.i + 1, ALU_A_BH_LSH);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					A_ASGN__RF(sr.v.i);
					RF_ASGN_ALU(ALU_A_SUB_1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else if (sl.datasize == 8) {
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					B_ASGN__RF(sl.v.i + 6);
					A_ASGN__RF(sl.v.i + 7);
					RF_ASGN_ALU(ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i + 5);
					_RF_ASGN_ALU(sl.v.i + 6, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i + 4);
					_RF_ASGN_ALU(sl.v.i + 5, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i + 3);
					_RF_ASGN_ALU(sl.v.i + 4, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i + 2);
					_RF_ASGN_ALU(sl.v.i + 3, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i + 1);
					_RF_ASGN_ALU(sl.v.i + 2, ALU_A_BH_LSH);
					A_ASGN_ALU(ALU_OUTB);
					B_ASGN__RF(sl.v.i);
					RF_ASGN_ALU(ALU_B_0_LSH);
					_RF_ASGN_ALU(sl.v.i + 1, ALU_A_BH_LSH);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					A_ASGN__RF(sr.v.i);
					RF_ASGN_ALU(ALU_A_SUB_1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else
					error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
				if (LOC_OFFSET_CONST_P_OR(sd.addrtype))
					DOP_ASGN_SOP(d, &sl);
			}
			else
				error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
			if (l_regfree != 0)
				regfree(sl.v.i, sl.datasize);
			if (r_regfree != 0)
				regfree(sr.v.i, sr.datasize);
		}
	}
	else
		error("���DOP_ASGN_LOP_LSH_ROP�������ɻ��������д���\n");
}

/*Ŀ�Ĳ��������������������,�Ҳ�����Ϊ����λ��*/
void DOP_ASGN_LOP_RSH_ROP(Xop* d, Xop* l, Xop* r) {
	Xop sd = *d, sl = *l, sr = *r;

	if (((sl.datatype == Xop::XOP_I || sl.datatype == Xop::XOP_U) && sr.datatype == Xop::XOP_I)) {
		if (sr.addrtype == Xop::XOP_CONST && ((sr.v.i >= 0 && sr.v.i <= 8) || sr.v.i == 16 || sr.v.i == 24 || sr.v.i == 32 || sr.v.i == 40 || sr.v.i == 48 || sr.v.i == 56 || sr.v.i == 64)) {
			addr_convert(&sd, &sl, NULL);
			if (sr.v.i == 0) {
				if (sl.datasize >= 1 && sl.datasize <= 8) {
					for (int i = 0; i < sl.datasize; ++i) {
						A_ASGN_OP(&sl, i);
						OP_ASGN_ALU(&sd, i, ALU_OUTA);
					}
				}
				else
					error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
			}
			else if (sr.v.i == 1) {
				if (sl.datasize == 1) {
					A_ASGN_OP(&sl, 0);
					if(sl.datatype == Xop::XOP_U)
						OP_ASGN_ALU(&sd, 0, ALU_A_0_RSH);
					else
						OP_ASGN_ALU(&sd, 0, ALU_A_AH_RSH);
				}
				else if (sl.datasize == 2) {
					A_ASGN_OP(&sl, 1);
					B_ASGN_OP(&sl, 0);
					OP_ASGN_ALU(&sd, 0, ALU_B_AL_RSH);
					if (sl.datatype == Xop::XOP_U)
						OP_ASGN_ALU(&sd, 1, ALU_A_0_RSH);
					else
						OP_ASGN_ALU(&sd, 1, ALU_A_AH_RSH);
				}
				else if (sl.datasize == 4) {
					A_ASGN_OP(&sl, 1);
					B_ASGN_OP(&sl, 0);
					OP_ASGN_ALU(&sd, 0, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 2);
					OP_ASGN_ALU(&sd, 1, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 3);
					if (sl.datatype == Xop::XOP_U)
						OP_ASGN_ALU(&sd, 3, ALU_A_0_RSH);
					else
						OP_ASGN_ALU(&sd, 3, ALU_A_AH_RSH);
					OP_ASGN_ALU(&sd, 2, ALU_B_AL_RSH);
				}
				else if (sl.datasize == 8) {
					A_ASGN_OP(&sl, 1);
					B_ASGN_OP(&sl, 0);
					OP_ASGN_ALU(&sd, 0, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 2);
					OP_ASGN_ALU(&sd, 1, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 3);
					OP_ASGN_ALU(&sd, 2, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 4);
					OP_ASGN_ALU(&sd, 3, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 5);
					OP_ASGN_ALU(&sd, 4, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 6);
					OP_ASGN_ALU(&sd, 5, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN_OP(&sl, 7);
					if (sl.datatype == Xop::XOP_U)
						OP_ASGN_ALU(&sd, 7, ALU_A_0_RSH);
					else
						OP_ASGN_ALU(&sd, 7, ALU_A_AH_RSH);
					OP_ASGN_ALU(&sd, 6, ALU_B_AL_RSH);
				}
				else
					error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
			}
			else if (sr.v.i > 1 && sr.v.i < 8) {
				char h = 0x80;
				for (int i = sr.v.i; i != 0; --i)
					h >>= 1;
				if (sl.datasize == 1) {
					if (sl.datatype == Xop::XOP_U) {
						A_ASGN_OP(&sl, 0);
						B_ASGN_IMMNUM(1 << (8 - sr.v.i));
						OP_ASGN_ALU(&sd, 0, ALU_MUL_H);
					}
					else {
						unsigned char reg_h = regalloc(1, 1);

						A_ASGN_OP(&sl, 0);
						B_ASGN_ALU(ALU_OUTA);
						A_ASGN_ALU(ALU_ADD_C);
						B_ASGN_IMMNUM(h);
						_RF_ASGN_ALU_O(reg_h, ALU_MUL_L);
						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 0);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_h);
						OP_ASGN_ALU(&sd, 0, ALU_OR);

						regfree(reg_h, 1);
					}
				}
				else if (sl.datasize == 2) {
					if (sl.datatype == Xop::XOP_U) {
						unsigned char reg_l0 = regalloc(1, 1);

						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 1);
						_RF_ASGN_ALU_O(reg_l0, ALU_MUL_L);
						OP_ASGN_ALU(&sd, 1, ALU_MUL_H);
						B_ASGN_OP(&sl, 0);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_l0);
						OP_ASGN_ALU(&sd, 0, ALU_ADD);

						regfree(reg_l0, 1);
					}
					else {
						unsigned char reg_h = regalloc(1, 1);
						unsigned char reg_l0 = regalloc(1, 1);

						A_ASGN_OP(&sl, 1);
						B_ASGN_ALU(ALU_OUTA);
						A_ASGN_ALU(ALU_ADD_C);
						B_ASGN_IMMNUM(h);
						_RF_ASGN_ALU_O(reg_h, ALU_MUL_L);
						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 1);
						_RF_ASGN_ALU_O(reg_l0, ALU_MUL_L);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_h);
						OP_ASGN_ALU(&sd, 1, ALU_OR);
						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 0);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_l0);
						OP_ASGN_ALU(&sd, 0, ALU_ADD);

						regfree(reg_h, 1);
						regfree(reg_l0, 1);
					}
				}
				else if (sl.datasize == 4) {
					if (sl.datatype == Xop::XOP_U) {
						unsigned char reg_h1 = regalloc(1, 1);
						unsigned char reg_l1 = regalloc(1, 1);
						unsigned char reg_h2 = regalloc(1, 1);
						unsigned char reg_l2 = regalloc(1, 1);
						unsigned char reg_l3 = regalloc(1, 1);

						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 3);
						_RF_ASGN_ALU_O(reg_l3, ALU_MUL_L);
						OP_ASGN_ALU(&sd, 3, ALU_MUL_H);
						B_ASGN_OP(&sl, 2);
						_RF_ASGN_ALU_O(reg_h2, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l2, ALU_MUL_L);
						B_ASGN_OP(&sl, 1);
						_RF_ASGN_ALU_O(reg_h1, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l1, ALU_MUL_L);
						B_ASGN_OP(&sl, 0);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_l1);
						OP_ASGN_ALU(&sd, 0, ALU_ADD);
						A_ASGN__RF_O(reg_h1);
						B_ASGN__RF_O(reg_l2);
						OP_ASGN_ALU(&sd, 1, ALU_ADD);
						A_ASGN__RF_O(reg_h2);
						B_ASGN__RF_O(reg_l3);
						OP_ASGN_ALU(&sd, 2, ALU_ADD);

						regfree(reg_h1, 1);
						regfree(reg_l1, 1);
						regfree(reg_h2, 1);
						regfree(reg_l2, 1);
						regfree(reg_l3, 1);
					}
					else {
						unsigned char reg_h = regalloc(1, 1);
						unsigned char reg_h1 = regalloc(1, 1);
						unsigned char reg_l1 = regalloc(1, 1);
						unsigned char reg_h2 = regalloc(1, 1);
						unsigned char reg_l2 = regalloc(1, 1);
						unsigned char reg_l3 = regalloc(1, 1);

						A_ASGN_OP(&sl, 3);
						B_ASGN_ALU(ALU_OUTA);
						A_ASGN_ALU(ALU_ADD_C);
						B_ASGN_IMMNUM(h);
						_RF_ASGN_ALU_O(reg_h, ALU_MUL_L);
						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 3);
						_RF_ASGN_ALU_O(reg_l3, ALU_MUL_L);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_h);
						OP_ASGN_ALU(&sd, 3, ALU_OR);
						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 2);
						_RF_ASGN_ALU_O(reg_h2, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l2, ALU_MUL_L);
						B_ASGN_OP(&sl, 1);
						_RF_ASGN_ALU_O(reg_h1, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l1, ALU_MUL_L);
						B_ASGN_OP(&sl, 0);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_l1);
						OP_ASGN_ALU(&sd, 0, ALU_ADD);
						A_ASGN__RF_O(reg_h1);
						B_ASGN__RF_O(reg_l2);
						OP_ASGN_ALU(&sd, 1, ALU_ADD);
						A_ASGN__RF_O(reg_h2);
						B_ASGN__RF_O(reg_l3);
						OP_ASGN_ALU(&sd, 2, ALU_ADD);

						regfree(reg_h, 1);
						regfree(reg_h1, 1);
						regfree(reg_l1, 1);
						regfree(reg_h2, 1);
						regfree(reg_l2, 1);
						regfree(reg_l3, 1);
					}
				}
				else if (sl.datasize == 8) {
					if (sl.datatype == Xop::XOP_U) {
						unsigned char reg_h1 = regalloc(1, 1);
						unsigned char reg_l1 = regalloc(1, 1);
						unsigned char reg_h2 = regalloc(1, 1);
						unsigned char reg_l2 = regalloc(1, 1);
						unsigned char reg_h3 = regalloc(1, 1);
						unsigned char reg_l3 = regalloc(1, 1);
						unsigned char reg_h4 = regalloc(1, 1);
						unsigned char reg_l4 = regalloc(1, 1);
						unsigned char reg_h5 = regalloc(1, 1);
						unsigned char reg_l5 = regalloc(1, 1);
						unsigned char reg_h6 = regalloc(1, 1);
						unsigned char reg_l6 = regalloc(1, 1);
						unsigned char reg_l7 = regalloc(1, 1);

						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 7);
						_RF_ASGN_ALU_O(reg_l7, ALU_MUL_L);
						OP_ASGN_ALU(&sd, 7, ALU_MUL_H);
						B_ASGN_OP(&sl, 6);
						_RF_ASGN_ALU_O(reg_h6, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l6, ALU_MUL_L);
						B_ASGN_OP(&sl, 5);
						_RF_ASGN_ALU_O(reg_h5, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l5, ALU_MUL_L);
						B_ASGN_OP(&sl, 4);
						_RF_ASGN_ALU_O(reg_h4, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l4, ALU_MUL_L);
						B_ASGN_OP(&sl, 3);
						_RF_ASGN_ALU_O(reg_h3, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l3, ALU_MUL_L);
						B_ASGN_OP(&sl, 2);
						_RF_ASGN_ALU_O(reg_h2, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l2, ALU_MUL_L);
						B_ASGN_OP(&sl, 1);
						_RF_ASGN_ALU_O(reg_h1, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l1, ALU_MUL_L);
						B_ASGN_OP(&sl, 0);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_l1);
						OP_ASGN_ALU(&sd, 0, ALU_ADD);
						A_ASGN__RF_O(reg_h1);
						B_ASGN__RF_O(reg_l2);
						OP_ASGN_ALU(&sd, 1, ALU_ADD);
						A_ASGN__RF_O(reg_h2);
						B_ASGN__RF_O(reg_l3);
						OP_ASGN_ALU(&sd, 2, ALU_ADD);
						A_ASGN__RF_O(reg_h3);
						B_ASGN__RF_O(reg_l4);
						OP_ASGN_ALU(&sd, 3, ALU_ADD);
						A_ASGN__RF_O(reg_h4);
						B_ASGN__RF_O(reg_l5);
						OP_ASGN_ALU(&sd, 4, ALU_ADD);
						A_ASGN__RF_O(reg_h5);
						B_ASGN__RF_O(reg_l6);
						OP_ASGN_ALU(&sd, 5, ALU_ADD);
						A_ASGN__RF_O(reg_h6);
						B_ASGN__RF_O(reg_l7);
						OP_ASGN_ALU(&sd, 6, ALU_ADD);

						regfree(reg_h1, 1);
						regfree(reg_l1, 1);
						regfree(reg_h2, 1);
						regfree(reg_l2, 1);
						regfree(reg_h3, 1);
						regfree(reg_l3, 1);
						regfree(reg_h4, 1);
						regfree(reg_l4, 1);
						regfree(reg_h5, 1);
						regfree(reg_l5, 1);
						regfree(reg_h6, 1);
						regfree(reg_l6, 1);
						regfree(reg_l7, 1);
					}
					else {
						unsigned char reg_h = regalloc(1, 1);
						unsigned char reg_h1 = regalloc(1, 1);
						unsigned char reg_l1 = regalloc(1, 1);
						unsigned char reg_h2 = regalloc(1, 1);
						unsigned char reg_l2 = regalloc(1, 1);
						unsigned char reg_h3 = regalloc(1, 1);
						unsigned char reg_l3 = regalloc(1, 1);
						unsigned char reg_h4 = regalloc(1, 1);
						unsigned char reg_l4 = regalloc(1, 1);
						unsigned char reg_h5 = regalloc(1, 1);
						unsigned char reg_l5 = regalloc(1, 1);
						unsigned char reg_h6 = regalloc(1, 1);
						unsigned char reg_l6 = regalloc(1, 1);
						unsigned char reg_l7 = regalloc(1, 1);

						A_ASGN_OP(&sl, 7);
						B_ASGN_ALU(ALU_OUTA);
						A_ASGN_ALU(ALU_ADD_C);
						B_ASGN_IMMNUM(h);
						_RF_ASGN_ALU_O(reg_h, ALU_MUL_L);
						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 7);
						_RF_ASGN_ALU_O(reg_l7, ALU_MUL_L);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_h);
						OP_ASGN_ALU(&sd, 7, ALU_OR);
						A_ASGN_IMMNUM(1 << (8 - sr.v.i));
						B_ASGN_OP(&sl, 6);
						_RF_ASGN_ALU_O(reg_h6, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l6, ALU_MUL_L);
						B_ASGN_OP(&sl, 5);
						_RF_ASGN_ALU_O(reg_h5, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l5, ALU_MUL_L);
						B_ASGN_OP(&sl, 4);
						_RF_ASGN_ALU_O(reg_h4, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l4, ALU_MUL_L);
						B_ASGN_OP(&sl, 3);
						_RF_ASGN_ALU_O(reg_h3, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l3, ALU_MUL_L);
						B_ASGN_OP(&sl, 2);
						_RF_ASGN_ALU_O(reg_h2, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l2, ALU_MUL_L);
						B_ASGN_OP(&sl, 1);
						_RF_ASGN_ALU_O(reg_h1, ALU_MUL_H);
						_RF_ASGN_ALU_O(reg_l1, ALU_MUL_L);
						B_ASGN_OP(&sl, 0);
						A_ASGN_ALU(ALU_MUL_H);
						B_ASGN__RF_O(reg_l1);
						OP_ASGN_ALU(&sd, 0, ALU_ADD);
						A_ASGN__RF_O(reg_h1);
						B_ASGN__RF_O(reg_l2);
						OP_ASGN_ALU(&sd, 1, ALU_ADD);
						A_ASGN__RF_O(reg_h2);
						B_ASGN__RF_O(reg_l3);
						OP_ASGN_ALU(&sd, 2, ALU_ADD);
						A_ASGN__RF_O(reg_h3);
						B_ASGN__RF_O(reg_l4);
						OP_ASGN_ALU(&sd, 3, ALU_ADD);
						A_ASGN__RF_O(reg_h4);
						B_ASGN__RF_O(reg_l5);
						OP_ASGN_ALU(&sd, 4, ALU_ADD);
						A_ASGN__RF_O(reg_h5);
						B_ASGN__RF_O(reg_l6);
						OP_ASGN_ALU(&sd, 5, ALU_ADD);
						A_ASGN__RF_O(reg_h6);
						B_ASGN__RF_O(reg_l7);
						OP_ASGN_ALU(&sd, 6, ALU_ADD);

						regfree(reg_h, 1);
						regfree(reg_h1, 1);
						regfree(reg_l1, 1);
						regfree(reg_h2, 1);
						regfree(reg_l2, 1);
						regfree(reg_h3, 1);
						regfree(reg_l3, 1);
						regfree(reg_h4, 1);
						regfree(reg_l4, 1);
						regfree(reg_h5, 1);
						regfree(reg_l5, 1);
						regfree(reg_h6, 1);
						regfree(reg_l6, 1);
						regfree(reg_l7, 1);
					}
				}
				else
					error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
			}
			else {
				if (sl.datatype == Xop::XOP_U) {
					if (sr.v.i >= sl.datasize * 8) {
						A_ASGN_IMMNUM(0);
						for (int i = 0; i < sl.datasize; ++i)
							OP_ASGN_ALU(&sd, i, ALU_OUTA);
					}
					else {
						int i;
						for (i = 0; i + (sr.v.i / 8) < sl.datasize; ++i) {
							A_ASGN_OP(&sl, i + (sr.v.i / 8));
							OP_ASGN_ALU(&sd, i, ALU_OUTA);
						}
						A_ASGN_IMMNUM(0);
						for (; i < sl.datasize; ++i)
							OP_ASGN_ALU(&sd, i, ALU_OUTA);
					}
				}
				else {
					if (sr.v.i >= sl.datasize * 8) {
						A_ASGN_OP(&sl, sl.datasize - 1);
						B_ASGN_ALU(ALU_OUTA);
						A_ASGN_ALU(ALU_ADD_C);
						B_ASGN_IMMNUM(0xff);
						for (int i = sl.datasize - 1; i >= 0; --i)
							OP_ASGN_ALU(&sd, i, ALU_MUL_L);
					}
					else {
						int i;
						for (i = 0; i + (sr.v.i / 8) < sl.datasize; ++i) {
							A_ASGN_OP(&sl, i + (sr.v.i / 8));
							OP_ASGN_ALU(&sd, i, ALU_OUTA);
						}
						B_ASGN_ALU(ALU_OUTA);
						A_ASGN_ALU(ALU_ADD_C);
						B_ASGN_IMMNUM(0xff);
						for (; i < sl.datasize; ++i)
							OP_ASGN_ALU(&sd, i, ALU_MUL_L);
					}
				}
			}
			if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
				DOP_ASGN_SOP(d, &sd);
				regfree(sd.v.i, sd.datasize);
			}
			if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(sl.v.i, sl.datasize);
		}
		else {
			char l_regfree = 0, r_regfree = 0;

			switch (sr.addrtype) {
			case Xop::XOP_LOC: case Xop::XOP_OFFSET: case Xop::XOP_CONST_P:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				r->datatype = Xop::XOP_X;
				DOP_ASGN_SOP_INDIR(&sr, r);
				r->datatype = sr.datatype;
				r_regfree = 1;
				break;
			case Xop::XOP_REGISTER_FILE:
				if (glowreg[sr.v.i].life > 1) {
					sr.v.i = regalloc(sr.datasize, 1);
					A_ASGN__RF_O(r->v.i);
					_RF_ASGN_ALU_O(sr.v.i, ALU_OUTA);
					r_regfree = 1;
				}
				break;
			case Xop::XOP_CONST:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				_RF_ASGN_IMMNUM_O(sr.v.i, r->v.i);
				r_regfree = 1;
				break;
			case Xop::XOP_REGISTER_IO0:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				_RF_ASGN_IO0(sr.v.i);
				r_regfree = 1;
				break;
			case Xop::XOP_REGISTER_IO1:
				sr.addrtype = Xop::XOP_REGISTER_FILE;
				sr.v.i = regalloc(sr.datasize, 1);
				_RF_ASGN_IO1(sr.v.i);
				r_regfree = 1;
				break;
			default:
				error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
			}
			switch (sl.addrtype) {
			case Xop::XOP_LOC: case Xop::XOP_OFFSET: case Xop::XOP_CONST_P:
				if (sd.addrtype == Xop::XOP_REGISTER_FILE)
					sl.v.i = sd.v.i;
				else {
					sl.v.i = regalloc(sl.datasize, 1);
					l_regfree = 1;
				}
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				l->datatype = Xop::XOP_X;
				DOP_ASGN_SOP_INDIR(&sl, l);
				l->datatype = sl.datatype;
				break;
			case Xop::XOP_REGISTER_FILE:
				if (sd.addrtype == Xop::XOP_REGISTER_FILE) {
					if (glowreg[sl.v.i].life > 1) {
						for (int i = 0; i < sd.datasize; ++i) {
							A_ASGN__RF(sl.v.i + i);
							_RF_ASGN_ALU(sd.v.i + i, ALU_OUTA);
						}
						sl.v.i = sd.v.i;
					}
					else {
						glowreg[sl.v.i].life += glowreg[sd.v.i].life;
						glowreg[sd.v.i].life = 1;
						regfree(sd.v.i, sd.datasize);
						d->v.i = sl.v.i;
					}
				}
				else if (glowreg[sl.v.i].life > 1) {
					sl.v.i = regalloc(sl.datasize, 1);
					for (int i = 0; i < sl.datasize; ++i) {
						A_ASGN__RF(l->v.i + i);
						_RF_ASGN_ALU(sl.v.i + i, ALU_OUTA);
					}
					l_regfree = 1;
				}
				break;
			case Xop::XOP_CONST:
				if (sd.addrtype == Xop::XOP_REGISTER_FILE)
					sl.v.i = sd.v.i;
				else {
					sl.v.i = regalloc(sl.datasize, 1);
					l_regfree = 1;
				}
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				for (int i = 0; i < sl.datasize; ++i)
					_RF_ASGN_IMMNUM_O(sl.v.i + i, l->v.i >> (i * 8));
				break;
			case Xop::XOP_REGISTER_IO0:
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				sl.v.i = regalloc(sl.datasize, 1);
				_RF_ASGN_IO0(sl.v.i);
				l_regfree = 1;
				break;
			case Xop::XOP_REGISTER_IO1:
				sl.addrtype = Xop::XOP_REGISTER_FILE;
				sl.v.i = regalloc(sl.datasize, 1);
				_RF_ASGN_IO1(sl.v.i);
				l_regfree = 1;
				break;
			default:
				error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
			}
			if (sl.addrtype == Xop::XOP_REGISTER_FILE && sr.addrtype == Xop::XOP_REGISTER_FILE) {
				unsigned long label_0, label_1;

				if (sl.datasize == 1) {
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					A_ASGN__RF(sl.v.i);
					if (sl.datatype == Xop::XOP_U)
						RF_ASGN_ALU(ALU_A_0_RSH);
					else
						RF_ASGN_ALU(ALU_A_AH_RSH);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					A_ASGN__RF(sr.v.i);
					RF_ASGN_ALU(ALU_A_SUB_1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else if (sl.datasize == 2) {
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					A_ASGN__RF(sl.v.i + 1);
					B_ASGN__RF(sl.v.i);
					RF_ASGN_ALU(ALU_B_AL_RSH);
					if (sl.datatype == Xop::XOP_U)
						_RF_ASGN_ALU(sl.v.i + 1, ALU_A_0_RSH);
					else
						_RF_ASGN_ALU(sl.v.i + 1, ALU_A_AH_RSH);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					A_ASGN__RF(sr.v.i);
					RF_ASGN_ALU(ALU_A_SUB_1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else if (sl.datasize == 4) {
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					A_ASGN__RF(sl.v.i + 1);
					B_ASGN__RF(sl.v.i);
					RF_ASGN_ALU(ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 2);
					_RF_ASGN_ALU(sl.v.i + 1, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 3);
					if (sl.datatype == Xop::XOP_U)
						RF_ASGN_ALU(ALU_A_0_RSH);
					else
						RF_ASGN_ALU(ALU_A_AH_RSH);
					_RF_ASGN_ALU(sl.v.i + 2, ALU_B_AL_RSH);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					A_ASGN__RF(sr.v.i);
					RF_ASGN_ALU(ALU_A_SUB_1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else if (sl.datasize == 8) {
					label_1 = rom_cp;
					PC_ASGN_IMMNUM(0);
					label_0 = rom_cp >> 1;
					A_ASGN__RF(sl.v.i + 1);
					B_ASGN__RF(sl.v.i);
					RF_ASGN_ALU(ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 2);
					_RF_ASGN_ALU(sl.v.i + 1, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 3);
					_RF_ASGN_ALU(sl.v.i + 2, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 4);
					_RF_ASGN_ALU(sl.v.i + 3, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 5);
					_RF_ASGN_ALU(sl.v.i + 4, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 6);
					_RF_ASGN_ALU(sl.v.i + 5, ALU_B_AL_RSH);
					B_ASGN_ALU(ALU_OUTA);
					A_ASGN__RF(sl.v.i + 7);
					if (sl.datatype == Xop::XOP_U)
						RF_ASGN_ALU(ALU_A_0_RSH);
					else
						RF_ASGN_ALU(ALU_A_AH_RSH);
					_RF_ASGN_ALU(sl.v.i + 6, ALU_B_AL_RSH);
					MODIFY_A2A1A0(label_1, rom_cp >> 1);
					A_ASGN__RF(sr.v.i);
					RF_ASGN_ALU(ALU_A_SUB_1);
					IFALU_PC_ASGN_IMMNUM(ALU_A_SUB_1_C, label_0);
				}
				else
					error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
				if (LOC_OFFSET_CONST_P_OR(sd.addrtype))
					DOP_ASGN_SOP(d, &sl);
			}
			else
				error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
			if (l_regfree != 0)
				regfree(sl.v.i, sl.datasize);
			if (r_regfree != 0)
				regfree(sr.v.i, sr.datasize);
		}
	}
	else
		error("���DOP_ASGN_LOP_RSH_ROP�������ɻ��������д���\n");
}

/*����������Ҳ������Ƚ�,���ڻ򲻵�����ת�������(controlΪ0ѡ�����ת��,��0ѡ�񲻵���ת��)*/
void LOP_EQ_NE_ROP(Xop* l, Xop* r, ADDRDATA label, char control) {
	Xop sl = *l, sr = *r;

	if ((sl.datatype == Xop::XOP_I && sr.datatype == Xop::XOP_I) || (sl.datatype == Xop::XOP_U && sr.datatype == Xop::XOP_U) || (sl.datatype == Xop::XOP_F && sr.datatype == Xop::XOP_F)) {
		addr_convert(NULL, &sl, &sr);
		if (sl.datasize == 1 && sr.datasize == 1) {
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			if(control == 0)
				A_ASGN_ALU(ALU_EQUAL_C);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		}
		else if (sl.datasize == 2 && sr.datasize == 2) {
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			_RF_ASGN_ALU_O(reg_c, ALU_EQUAL_C);
			A_ASGN_OP(&sl, 1);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_AND);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);

			regfree(reg_c, 1);
		}
		else if (sl.datasize == 4 && sr.datasize == 4) {
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			_RF_ASGN_ALU_O(reg_c, ALU_EQUAL_C);
			A_ASGN_OP(&sl, 1);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 2);
			B_ASGN_OP(&sr, 2);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 3);
			B_ASGN_OP(&sr, 3);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_AND);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);

			regfree(reg_c, 1);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			_RF_ASGN_ALU_O(reg_c, ALU_EQUAL_C);
			A_ASGN_OP(&sl, 1);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 2);
			B_ASGN_OP(&sr, 2);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 3);
			B_ASGN_OP(&sr, 3);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 4);
			B_ASGN_OP(&sr, 4);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 5);
			B_ASGN_OP(&sr, 5);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 6);
			B_ASGN_OP(&sr, 6);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			RF_ASGN_ALU(ALU_AND);
			A_ASGN_OP(&sl, 7);
			B_ASGN_OP(&sr, 7);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_AND);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);

			regfree(reg_c, 1);
		}
		else
			error("���LOP_EQ_NE_ROP�������ɻ��������д���\n");
	}
	/*
	else if (sl.datatype == Xop::XOP_F && sr.datatype == Xop::XOP_F) {
		unsigned long cp[3];

		sl.addrtype = Xop::XOP_REGISTER_FILE;
		sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
		REGISTER_FILE_ASGN_OP(&sl, l);
		sr.addrtype = Xop::XOP_REGISTER_FILE;
		sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
		REGISTER_FILE_ASGN_OP(&sr, r);
		for (int i = 0; i < 3; ++i) {
			_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
			cp[i] = rom_cp - 1;
		}
		if (sl.datasize == 4 && sr.datasize == 4) {
			//float
			float_sub_func_gen();
			PC_ASGN_IMMNUM(float_sub_func_romaddr);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			//double
			double_sub_func_gen();
			PC_ASGN_IMMNUM(double_sub_func_romaddr);
		}
		else
			error("���LOP_EQ_NE_ROP�������ɻ��������д���\n");
		romdata[cp[0]] = rom_cp >> 1;
		romdata[cp[1]] = rom_cp >> 9;
		romdata[cp[2]] = rom_cp >> 17;

		if (sl.datasize == 4) {
			A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
			B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
			A_ASGN_ALU(ALU_A_BH_LSH);
			B_ASGN_IMMNUM(0);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0) {
				A_ASGN_ALU(ALU_EQUAL_C);
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			}
			else
				IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		}
		else {
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
			B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
			A_ASGN_ALU(ALU_A_BH_LSH);
			B_ASGN_IMMNUM(0);
			_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
			A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
			B_ASGN_IMMNUM(0x70);
			A_ASGN_ALU(ALU_AND);
			B_ASGN_IMMNUM(0);
			A_ASGN_ALU(ALU_EQUAL_C);
			B_ASGN__RF(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_AND);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);

			regfree(reg_c, 1);
		}
		return;
	}
	*/
	else
		error("���LOP_EQ_NE_ROP�������ɻ��������д���\n");
	if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sl.v.i, sl.datasize);
	if (sr.addrtype == Xop::XOP_REGISTER_FILE && r->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sr.v.i, sr.datasize);
}

/*����������Ҳ������Ƚ�,������ת�������*/
void LOP_EQ_ROP(Xop* l, Xop* r, ADDRDATA label) {
	LOP_EQ_NE_ROP(l, r, label, 0);
}

/*����������Ҳ������Ƚ�,��������ת�������*/
void LOP_NE_ROP(Xop* l, Xop* r, ADDRDATA label) {
	LOP_EQ_NE_ROP(l, r, label, 1);
}

/*����������Ҳ������Ƚ�,���ڵ��ڻ�С����ת�������(controlΪ0ѡ��С��ת��,��0ѡ����ڵ���ת��)*/
void LOP_LT_GE_ROP(Xop* l, Xop* r, ADDRDATA label, char control) {
	Xop sl = *l, sr = *r;

	if (sl.datatype == Xop::XOP_U && sr.datatype == Xop::XOP_U) {
		addr_convert(NULL, &sl, &sr);
		if (sl.datasize == 1 && sr.datasize == 1) {
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			if (control == 0)
				A_ASGN_ALU(ALU_SUB_C);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);
		}
		else if (sl.datasize == 2 && sr.datasize == 2) {
			unsigned char reg_c = regalloc(1, 1);

			B_ASGN_OP(&sr, 0);
			A_ASGN_OP(&sl, 0);
			B_ASGN_ALU(ALU_SUB_C);
			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_ADD);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);

			regfree(reg_c, 1);
		}
		else if (sl.datasize == 4 && sr.datasize == 4) {
			unsigned char reg_c = regalloc(1, 1);

			B_ASGN_OP(&sr, 0);
			A_ASGN_OP(&sl, 0);
			B_ASGN_ALU(ALU_SUB_C);
			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 2);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 2);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 3);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 3);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_ADD);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);

			regfree(reg_c, 1);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			unsigned char reg_c = regalloc(1, 1);

			B_ASGN_OP(&sr, 0);
			A_ASGN_OP(&sl, 0);
			B_ASGN_ALU(ALU_SUB_C);
			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 2);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 2);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 3);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 3);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 4);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 4);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 5);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 5);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 6);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 6);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 7);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 7);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_ADD);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);

			regfree(reg_c, 1);
		}
		else
			error("���LOP_LT_GE_ROP�������ɻ��������д���\n");
	}
	else if(sl.datatype == Xop::XOP_I && sr.datatype == Xop::XOP_I) {
		addr_convert(NULL, &sl, &sr);
		if (sl.datasize == 1 && sr.datasize == 1) {
			unsigned char reg_0 = regalloc(1, 1);

			A_ASGN_IMMNUM(0x80);
			B_ASGN_OP(&sr, 0);
			_RF_ASGN_ALU_O(reg_0, ALU_XOR);
			B_ASGN_OP(&sl, 0);
			A_ASGN_ALU(ALU_XOR);
			B_ASGN__RF_O(reg_0);
			if (control == 0)
				A_ASGN_ALU(ALU_SUB_C);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_SUB_C, 0);

			regfree(reg_0, 1);
		}
		else if (sl.datasize == 2 && sr.datasize == 2) {
			unsigned char reg_0 = regalloc(1, 1);
			unsigned char reg_1 = regalloc(1, 1);
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sr, 1);
			B_ASGN_IMMNUM(0x80);
			_RF_ASGN_ALU_O(reg_1, ALU_XOR);
			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU_O(reg_0, ALU_XOR);
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			B_ASGN_ALU(ALU_SUB_C);
			A_ASGN__RF_O(reg_0);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN__RF_O(reg_1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);

			if (control == 0)
				A_ASGN_ALU(ALU_ADD);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);

			regfree(reg_0, 1);
			regfree(reg_1, 1);
			regfree(reg_c, 1);
		}
		else if (sl.datasize == 4 && sr.datasize == 4) {
			unsigned char reg_0 = regalloc(1, 1);
			unsigned char reg_1 = regalloc(1, 1);
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sr, 3);
			B_ASGN_IMMNUM(0x80);
			_RF_ASGN_ALU_O(reg_1, ALU_XOR);
			A_ASGN_OP(&sl, 3);
			_RF_ASGN_ALU_O(reg_0, ALU_XOR);
			A_ASGN_OP(&sl, 0);
			B_ASGN_OP(&sr, 0);
			B_ASGN_ALU(ALU_SUB_C);
			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 2);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 2);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN__RF(reg_0);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN__RF(reg_1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_ADD);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);

			regfree(reg_0, 1);
			regfree(reg_1, 1);
			regfree(reg_c, 1);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			unsigned char reg_0 = regalloc(1, 1);
			unsigned char reg_1 = regalloc(1, 1);
			unsigned char reg_c = regalloc(1, 1);

			A_ASGN_OP(&sr, 7);
			B_ASGN_IMMNUM(0x80);
			_RF_ASGN_ALU_O(reg_1, ALU_XOR);
			A_ASGN_OP(&sl, 7);
			_RF_ASGN_ALU_O(reg_0, ALU_XOR);
			B_ASGN_OP(&sr, 0);
			A_ASGN_OP(&sl, 0);
			B_ASGN_ALU(ALU_SUB_C);
			A_ASGN_OP(&sl, 1);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 2);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 2);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 3);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 3);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 4);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 4);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 5);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 5);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN_OP(&sl, 6);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN_OP(&sr, 6);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			B_ASGN_ALU(ALU_ADD);
			A_ASGN__RF(reg_0);
			_RF_ASGN_ALU(reg_c, ALU_SUB_C);
			A_ASGN_ALU(ALU_SUB);
			B_ASGN__RF(reg_1);
			A_ASGN_ALU(ALU_SUB_C);
			B_ASGN__RF_O(reg_c);
			if (control == 0)
				A_ASGN_ALU(ALU_ADD);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			if (control == 0)
				IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
			else
				IFALU_PC_ASGN_IMMNUM(ALU_ADD, 0);

			regfree(reg_0, 1);
			regfree(reg_1, 1);
			regfree(reg_c, 1);
		}
		else
			error("���LOP_LT_GE_ROP�������ɻ��������д���\n");
	}
	else if (sl.datatype == Xop::XOP_F && sr.datatype == Xop::XOP_F) {
		unsigned long cp[3];

		sl.addrtype = Xop::XOP_REGISTER_FILE;
		sl.v.i = REGISTER_FILE_OP_FUNC_LOP;
		REGISTER_FILE_ASGN_OP(&sl, l);
		sr.addrtype = Xop::XOP_REGISTER_FILE;
		sr.v.i = REGISTER_FILE_OP_FUNC_ROP;
		REGISTER_FILE_ASGN_OP(&sr, r);
		for (int i = 0; i < 3; ++i) {
			_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
			cp[i] = rom_cp - 1;
		}
		if (sl.datasize == 4 && sr.datasize == 4) {
			/*float*/
			float_sub_func_gen();
			PC_ASGN_IMMNUM(float_sub_func_romaddr);
		}
		else if (sl.datasize == 8 && sr.datasize == 8) {
			/*double*/
			double_sub_func_gen();
			PC_ASGN_IMMNUM(double_sub_func_romaddr);
		}
		else
			error("���LOP_LT_GE_ROP�������ɻ��������д���\n");
		romdata[cp[0]] = rom_cp >> 1;
		romdata[cp[1]] = rom_cp >> 9;
		romdata[cp[2]] = rom_cp >> 17;
		if (control == 0) {
			if (sl.datasize == 4)
				B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
			else
				B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
			A_ASGN_ALU(ALU_A_BH_LSH);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		}
		else {
			if (sl.datasize == 4)
				B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
			else
				B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
			insertaddr(label, rom_cp + 1, rom_cp + 3, rom_cp + 5, 0);
			IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		}
		return;
	}
	else
		error("���LOP_LT_GE_ROP�������ɻ��������д���\n");
	if (sl.addrtype == Xop::XOP_REGISTER_FILE && l->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sl.v.i, sl.datasize);
	if (sr.addrtype == Xop::XOP_REGISTER_FILE && r->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(sr.v.i, sr.datasize);
}

/*����������Ҳ������Ƚ�,���ڵ�����ת�������*/
void LOP_GE_ROP(Xop* l, Xop* r, ADDRDATA label) {
	LOP_LT_GE_ROP(l, r, label, 1);
}

/*����������Ҳ������Ƚ�,С�ڵ�����ת�������*/
void LOP_LE_ROP(Xop* l, Xop* r, ADDRDATA label) {
	LOP_LT_GE_ROP(r, l, label, 1);
}

/*����������Ҳ������Ƚ�,������ת�������*/
void LOP_GT_ROP(Xop* l, Xop* r, ADDRDATA label) {
	LOP_LT_GE_ROP(r, l, label, 0);
}

/*����������Ҳ������Ƚ�,С����ת�������*/
void LOP_LT_ROP(Xop* l, Xop* r, ADDRDATA label) {
	LOP_LT_GE_ROP(l, r, label, 0);
}

unsigned long float_cvfi_func_romaddr; //float_cvfi������ڵ�ַ
unsigned long float_cvif_func_romaddr; //float_cvif������ڵ�ַ
unsigned long double_cvfi_func_romaddr; //double_cvfi������ڵ�ַ
unsigned long double_cvif_func_romaddr; //double_cvif������ڵ�ַ
unsigned long float_to_double_func_romaddr; //floatתdouble������ڵ�ַ
unsigned long double_to_float_func_romaddr; //doubleתfloat������ڵ�ַ

/*float_cvfi��������*/
void float_cvfi_func_gen() {
	if (float_cvfi_func_romaddr == 0) {
		unsigned long label_0, label_1;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		float_cvfi_func_romaddr = rom_cp >> 1;

		/*��ȡָ����1,β����1.0*/
		A_ASGN_IMMNUM(0x80);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		RF_ASGN_ALU(ALU_OR);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_IMMNUM(0x7f);
		A_ASGN_ALU(ALU_XOR);
		_RF_ASGN_ALU(reg_lop_index, ALU_A_SUB_1);

		/*���ָ����1������,���Ϊ0*/
		A_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_NOT);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*������ƴ���31λ,���Ϊ-2147483648*/
		B_ASGN_IMMNUM(31);
		A_ASGN_ALU(ALU_ADD_C);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0x80);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*��ȡ����*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		label_1 = rom_cp >> 1;
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(reg_lop_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_ADD_1_C, label_1);

		/*��������Ǹ���,���ȡ����1*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*double_cvfi��������*/
void double_cvfi_func_gen() {
	if (double_cvfi_func_romaddr == 0) {
		unsigned long label_0, label_1;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		double_cvfi_func_romaddr = rom_cp >> 1;

		/*��ȡָ��*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_lop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		/*ָ����1*/
		A_ASGN__RF(reg_lop_index);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_SUB_1_C);
		A_ASGN__RF(reg_lop_index + 1);
		RF_ASGN_ALU(ALU_SUB);

		/*���ָ����1������,���Ϊ0*/
		A_ASGN_ALU(ALU_SUB);
		B_ASGN_ALU(ALU_A_NOT);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*������ƴ���63λ,���Ϊ-9223372036854775808*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(63);
		A_ASGN_ALU(ALU_ADD_C);
		B_ASGN__RF(reg_lop_index + 1);
		A_ASGN_ALU(ALU_ADD_C);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0x80);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*ָ����3*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(3);
		RF_ASGN_ALU(ALU_SUB);

		/*��ȡ����*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0);
		label_1 = rom_cp >> 1;
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(reg_lop_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_ADD_1_C, label_1);

		/*��������Ǹ���,���ȡ����1*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*float_cvif��������*/
void float_cvif_func_gen() {
	if (float_cvif_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_index = REGISTER_FILE_OP_FUNC_CACHE;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		float_cvif_func_romaddr = rom_cp >> 1;

		/*�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTB);

		/*����Ǹ���,ȡ����1*/
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*������Ǹ���,����-2147483648.0*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0xcf);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*���ƶ���1.0*/
		_RF_ASGN_IMMNUM(reg_index, -32);
		label_1 = rom_cp >> 1;
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_A_NOT);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		/*���λ��Ϊ1,����1λ*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(reg_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_ADD_1_C, label_1);
		/*long32Ϊ��,���Ϊ0*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ִ������*/
		B_ASGN_IMMNUM(0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		/*����û�н�λ,ָ����1*/
		A_ASGN__RF(reg_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*ָ��ת��Ϊԭ��ʽ*/
		A_ASGN__RF(reg_index);
		B_ASGN_IMMNUM(0x7f);
		RF_ASGN_ALU(ALU_XOR);

		/*װ��ָ���ͷ���*/
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_B_0_LSH);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_index);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*double_cvif��������*/
void double_cvif_func_gen() {
	if (double_cvif_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 1;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		double_cvif_func_romaddr = rom_cp >> 1;

		/*�������*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTB);

		/*����Ǹ���,ȡ����1*/
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_A_ADD_1);
		B_ASGN_ALU(ALU_A_ADD_1_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_NOT);
		RF_ASGN_ALU(ALU_ADD);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*������Ǹ���,����-9223372036854775808.0*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xe0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0xc3);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*���ƶ���1.0*/
		_RF_ASGN_IMMNUM(reg_index, -64);
		label_1 = rom_cp >> 1;
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN_ALU(ALU_A_NOT);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		/*���λ��Ϊ1,����1λ*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		RF_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 6, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 5, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 4, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 3, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 2, ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		RF_ASGN_ALU(ALU_B_0_LSH);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + 1, ALU_A_BH_LSH);
		A_ASGN__RF(reg_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		IFALU_PC_ASGN_IMMNUM(ALU_A_ADD_1_C, label_1);
		/*long32Ϊ��,���Ϊ0*/
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 7, 0);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);

		/*ִ������*/
		B_ASGN_IMMNUM(0x04);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_ADD);
		A_ASGN_ALU(ALU_ADD_C);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		/*����û�н�λ,ָ����1*/
		A_ASGN__RF(reg_index);
		RF_ASGN_ALU(ALU_A_ADD_1);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*����β��*/
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 3);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_MUL_H);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		A_ASGN_ALU(ALU_A_0_RSH);
		RF_ASGN_ALU(ALU_OR);

		/*����β����1.0*/
		A_ASGN_IMMNUM(0x0f);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_AND);

		/*ָ��ת��Ϊԭ��ʽ,��װ��ָ���ͷ���*/
		A_ASGN__RF(reg_index);
		B_ASGN_IMMNUM(0x10);
		_RF_ASGN_ALU(reg_c, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN_IMMNUM(0xf0);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_OR);
		A_ASGN_IMMNUM(0);
		B_ASGN__RF(reg_index);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_IMMNUM(0x70);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(reg_c);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x3f);
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_ALU(ALU_OUTA);
		RF_ASGN_ALU(ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*floatתdouble��������*/
void float_to_double_func_gen() {
	if (float_to_double_func_romaddr == 0) {
		unsigned long label_0, label_1;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		float_to_double_func_romaddr = rom_cp >> 1;

		/*����nan*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		B_ASGN_ALU(ALU_A_0_LSH);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf8);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*ָ������-128,����double�����*/
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_IMMNUM(0xff);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0xf0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*ָ������127,����doubleΪ0*/
		B_ASGN_IMMNUM(0);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 3, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 4, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 5, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 6, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*float����3λ����double*/
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 6, ALU_MUL_L);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 7, ALU_MUL_H);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 2);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 5, ALU_MUL_L);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 6);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 1);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 4, ALU_MUL_L);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 5);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x20);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_MUL_L);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 4);
		RF_ASGN_ALU(ALU_OR);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);

		/*װ�ط���*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 7);
		B_ASGN_ALU(ALU_A_BH_LSH);
		A_ASGN_ALU(ALU_OUTB);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_IMMNUM(0x8f);
		RF_ASGN_ALU(ALU_AND);

		/*����ָ��*/
		A_ASGN_IMMNUM(0x20);
		B_ASGN_ALU(ALU_MUL_H);
		A_ASGN_IMMNUM(0x01);
		B_ASGN_ALU(ALU_AND);
		A_ASGN_IMMNUM(0x70);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN_RF();
		B_ASGN_ALU(ALU_OR);
		A_ASGN_IMMNUM(0x38);
		RF_ASGN_ALU(ALU_XOR);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*doubleתfloat��������*/
void double_to_float_func_gen() {
	if (double_to_float_func_romaddr == 0) {
		unsigned long label_0, label_1, label_2;
		unsigned char reg_lop_index = REGISTER_FILE_OP_FUNC_CACHE;
		unsigned char reg_c = REGISTER_FILE_OP_FUNC_CACHE + 2;

		label_0 = rom_cp;
		PC_ASGN_IMMNUM(0);
		double_to_float_func_romaddr = rom_cp >> 1;

		/*��ȡָ��*/
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_B_0_LSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		A_ASGN_ALU(ALU_A_AH_RSH);
		B_ASGN_ALU(ALU_B_AL_RSH);
		_RF_ASGN_ALU(reg_lop_index + 1, ALU_A_AH_RSH);
		A_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_lop_index, ALU_XOR);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_IMMNUM(0x03);
		RF_ASGN_ALU(ALU_XOR);

		/*����nan*/
		B_ASGN_IMMNUM(0xff);
		_RF_ASGN_ALU(reg_c, ALU_EQUAL_C);
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x00);
		A_ASGN_ALU(ALU_EQUAL_C);
		B_ASGN__RF(reg_c);
		RF_ASGN_ALU(ALU_AND);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN_IMMNUM(0x20);
		A_ASGN_ALU(ALU_MUL_H);
		B_ASGN__RF(reg_c);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_AND, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0xc0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_OUTA);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*���С��-127,����float�����*/
		B_ASGN_IMMNUM(127);
		A_ASGN__RF(reg_lop_index);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_ALU(ALU_ADD);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_IMMNUM(0xfe);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*�������126,����floatΪ0*/
		B_ASGN_IMMNUM(127);
		A_ASGN__RF(reg_lop_index);
		B_ASGN_ALU(ALU_SUB_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_ALU(ALU_SUB);
		A_ASGN_ALU(ALU_A_BH_LSH);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		B_ASGN_IMMNUM(0x80);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_AND);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*β����1.0*/
		A_ASGN_IMMNUM(0x10);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		A_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x1f);
		RF_ASGN_ALU(ALU_AND);

		/*double����3λװ��float*/
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		RF_ASGN_ALU(ALU_MUL_L);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP, ALU_MUL_H);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 4);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 1, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 5);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 2, ALU_MUL_H);
		A_ASGN_ALU(ALU_MUL_L);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		RF_ASGN_ALU(ALU_OR);
		B_ASGN_IMMNUM(0x08);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 6);
		B_ASGN_ALU(ALU_MUL_L);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		RF_ASGN_ALU(ALU_OR);

		/*ִ������*/
		B_ASGN_IMMNUM(0x80);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 3);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 1);
		RF_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		RF_ASGN_ALU(ALU_ADD);
		label_1 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, 0);
		/*�����н�λ,ָ����1*/
		A_ASGN__RF(reg_lop_index);
		RF_ASGN_ALU(ALU_A_SUB_1);
		B_ASGN_ALU(ALU_A_SUB_1_C);
		A_ASGN__RF(reg_lop_index + 1);
		RF_ASGN_ALU(ALU_SUB);
		/*���С��-127,����float�����*/
		B_ASGN_IMMNUM(127);
		A_ASGN__RF(reg_lop_index);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(reg_lop_index + 1);
		B_ASGN_ALU(ALU_ADD);
		label_2 = rom_cp;
		IFALU_PC_ASGN_IMMNUM(ALU_A_BH_LSH, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 1, 0);
		_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_DOP + 2, 0x80);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN_IMMNUM(0xfe);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);
		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_2, rom_cp >> 1);
		MODIFY_A2A1A0(label_1, rom_cp >> 1);

		/*ָ��ת��Ϊԭ��ʽ*/
		A_ASGN__RF(reg_lop_index);
		B_ASGN_IMMNUM(0x7f);
		RF_ASGN_ALU(ALU_XOR);

		/*װ��ָ���ͷ���*/
		A_ASGN_ALU(ALU_XOR);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + 2);
		B_ASGN_ALU(ALU_B_0_LSH);
		RF_ASGN_ALU(ALU_B_AL_RSH);
		B_ASGN__RF(REGISTER_FILE_OP_FUNC_LOP + 7);
		A_ASGN_ALU(ALU_A_BH_LSH);
		B_ASGN__RF(reg_lop_index);
		_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_DOP + 3, ALU_B_AL_RSH);

		REGISTER_TO_A2A1A0(REGISTER_FILE_OP_FUNC_RET, 0);
		PC_ASGN_A2A1A0();
		MODIFY_A2A1A0(label_0, rom_cp >> 1);
	}
}

/*Դ�������Ӹ�����ת��,�����Ŀ�Ĳ�����(�Ĵ�����)*/
void DOP_ASGN_SOP_CVF(Xop* d, Xop* s) {
	Xop ss = *s;
	/*CVFI*/
	if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_I) {
		unsigned long cp[3];

		ss.addrtype = Xop::XOP_REGISTER_FILE;
		ss.v.i = REGISTER_FILE_OP_FUNC_LOP;
		REGISTER_FILE_ASGN_OP(&ss, s);
		for (int i = 0; i < 3; ++i) {
			_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
			cp[i] = rom_cp - 1;
		}
		/*float*/
		if (ss.datasize == 4) {
			/*char short long*/
			if (d->datasize <= 4) {
				float_cvfi_func_gen();
				PC_ASGN_IMMNUM(float_cvfi_func_romaddr);
				romdata[cp[0]] = rom_cp >> 1;
				romdata[cp[1]] = rom_cp >> 9;
				romdata[cp[2]] = rom_cp >> 17;
				if (d->v.i != REGISTER_FILE_OP_FUNC_DOP) {
					for (int i = 0; i < d->datasize; ++i) {
						A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
						_RF_ASGN_ALU(d->v.i + i, ALU_OUTA);
					}
				}
			}
			/*long long*/
			else if (d->datasize == 8) {
				float_to_double_func_gen();
				PC_ASGN_IMMNUM(float_to_double_func_romaddr);
				romdata[cp[0]] = rom_cp >> 1;
				romdata[cp[1]] = rom_cp >> 9;
				romdata[cp[2]] = rom_cp >> 17;
				for (int i = 0; i < 8; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + i, ALU_OUTA);
				}
				for (int i = 0; i < 3; ++i) {
					_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
					cp[i] = rom_cp - 1;
				}
				double_cvfi_func_gen();
				PC_ASGN_IMMNUM(double_cvfi_func_romaddr);
				romdata[cp[0]] = rom_cp >> 1;
				romdata[cp[1]] = rom_cp >> 9;
				romdata[cp[2]] = rom_cp >> 17;
				if (d->v.i != REGISTER_FILE_OP_FUNC_DOP) {
					for (int i = 0; i < d->datasize; ++i) {
						A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
						_RF_ASGN_ALU(d->v.i + i, ALU_OUTA);
					}
				}
			}
			else
				error("���DOP_ASGN_SOP_CVF�������ɻ��������д���\n");
		}
		/*double*/
		else {
			double_cvfi_func_gen();
			PC_ASGN_IMMNUM(double_cvfi_func_romaddr);
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (d->datasize <= 8) {
				if (d->v.i != REGISTER_FILE_OP_FUNC_DOP) {
					for (int i = 0; i < d->datasize; ++i) {
						A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
						_RF_ASGN_ALU(d->v.i + i, ALU_OUTA);
					}
				}
			}
			else
				error("���DOP_ASGN_SOP_CVF�������ɻ��������д���\n");
		}
	}
	else if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_F) {
		unsigned long cp[3];

		ss.addrtype = Xop::XOP_REGISTER_FILE;
		ss.v.i = REGISTER_FILE_OP_FUNC_LOP;
		REGISTER_FILE_ASGN_OP(&ss, s);
		for (int i = 0; i < 3; ++i) {
			_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
			cp[i] = rom_cp - 1;
		}
		/*float to double*/
		if (ss.datasize == 4 && d->datasize == 8) {
			float_to_double_func_gen();
			PC_ASGN_IMMNUM(float_to_double_func_romaddr);
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (d->v.i != REGISTER_FILE_OP_FUNC_DOP) {
				for (int i = 0; i < d->datasize; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(d->v.i + i, ALU_OUTA);
				}
			}
		}
		/*double to float*/
		else if (ss.datasize == 8 && d->datasize == 4) {
			double_to_float_func_gen();
			PC_ASGN_IMMNUM(double_to_float_func_romaddr);
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (d->v.i != REGISTER_FILE_OP_FUNC_DOP) {
				for (int i = 0; i < d->datasize; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(d->v.i + i, ALU_OUTA);
				}
			}
		}
		else
			error("���DOP_ASGN_SOP_CVF�������ɻ��������д���\n");
	}
	else
		error("���DOP_ASGN_SOP_CVF�������ɻ��������д���\n");
}

/*Դ��������ָ����ת��,�����Ŀ�Ĳ�����(�Ĵ�����)*/
void DOP_ASGN_SOP_CVP(Xop* d, Xop* s) {
	Xop sd = *d, ss = *s;

	//CVPU
	if (sd.addrtype == Xop::XOP_REGISTER_FILE && sd.datatype == Xop::XOP_U) {
		if (sd.datasize == 4) {
			if (LOC_OFFSET_CONST_P_OR(ss.addrtype)) {
				if (ss.datatype == Xop::XOP_X) {
					LOC_OFFSET_CONST_P_TO_REGISTER_FILE(&sd, &ss);
					_RF_ASGN_IMMNUM(sd.v.i + 3, 0);
				}
				else if (ss.datatype == Xop::XOP_P) {
					ss.datatype = Xop::XOP_X;
					sd.datasize = 3;
					DOP_ASGN_SOP_INDIR(&sd, &ss);
					_RF_ASGN_IMMNUM(sd.v.i + 3, 0);
				}
				else
					error("���DOP_ASGN_SOP_CVP�������ɻ��������д���\n");
			}
			else if(ss.addrtype == Xop::XOP_REGISTER_FILE && ss.datatype == Xop::XOP_P){
				for (int i = 0; i < 3; ++i) {
					A_ASGN__RF_O(ss.v.i + i);
					_RF_ASGN_ALU_O(sd.v.i + i, ALU_OUTA);
				}
				_RF_ASGN_IMMNUM(sd.v.i + 3, 0);
			}
			else
				error("���DOP_ASGN_SOP_CVP�������ɻ��������д���\n");
		}
		else
			error("���DOP_ASGN_SOP_CVP�������ɻ��������д���\n");
	}
	else
		error("���DOP_ASGN_SOP_CVP�������ɻ��������д���\n");
}

/*Դ�������ӷ�������ת��,�����Ŀ�Ĳ�����*/
void DOP_ASGN_SOP_CVI(Xop* d, Xop* s) {
	/*CVII*/
	if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_I) {
		if (s->datasize == 1) {
			if (d->datasize == 2) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				_RF_ASGN_ALU(d->v.i + 1, ALU_MUL_L);
			}
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for(int i = 1; i < 4; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 1; i < 8; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else if (s->datasize == 2) {
			if (d->datasize == 1)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i + 1);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				_RF_ASGN_ALU(d->v.i + 2, ALU_MUL_L);
				_RF_ASGN_ALU(d->v.i + 3, ALU_MUL_L);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i + 1);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 2; i < 8; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else if (s->datasize == 4) {
			if (d->datasize == 1 || d->datasize == 2)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i + 3);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 4; i < 8; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else if (s->datasize == 8) {
			if (d->datasize >= 1 && d->datasize <= 4)
				REGISTER_FILE_ASGN_OP(d, s);
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else
			error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
	}
	/*CVIU*/
	else if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_U) {
		if (s->datasize == 1) {
			if (d->datasize == 1)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 2) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				_RF_ASGN_ALU(d->v.i + 1, ALU_MUL_L);
			}
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 1; i < 4; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 1; i < 8; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else if (s->datasize == 2) {
			if (d->datasize == 1 || d->datasize == 2)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i + 1);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				_RF_ASGN_ALU(d->v.i + 2, ALU_MUL_L);
				_RF_ASGN_ALU(d->v.i + 3, ALU_MUL_L);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i + 1);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 2; i < 8; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else if (s->datasize == 4) {
			if (d->datasize >= 1 && d->datasize <= 4)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(d->v.i + 3);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 4; i < 8; ++i)
					_RF_ASGN_ALU(d->v.i + i, ALU_MUL_L);
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else if (s->datasize == 8) {
			if (d->datasize >= 1 && d->datasize <= 8)
				REGISTER_FILE_ASGN_OP(d, s);
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
		}
		else
			error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
	}
	/*CVIF*/
	else if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_F) {
		Xop ss = *s;
		unsigned long cp[3];
		/*float*/
		if (d->datasize == 4) {
			ss.addrtype = Xop::XOP_REGISTER_FILE;
			ss.v.i = REGISTER_FILE_OP_FUNC_LOP;
			REGISTER_FILE_ASGN_OP(&ss, s);
			/*char*/
			if (ss.datasize == 1) {
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(REGISTER_FILE_OP_FUNC_LOP);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 1; i < 4; ++i)
					_RF_ASGN_ALU(ss.v.i + i, ALU_MUL_L);
			}
			/*short*/
			else if (ss.datasize == 2) {
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(REGISTER_FILE_OP_FUNC_LOP + 1);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 2; i < 4; ++i)
					_RF_ASGN_ALU(ss.v.i + i, ALU_MUL_L);
			}
			/*long*/
			else if (ss.datasize == 4) {
			}
			/*long long*/
			else if (ss.datasize == 8) {
				for (int i = 0; i < 3; ++i) {
					_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
					cp[i] = rom_cp - 1;
				}
				double_cvif_func_gen();
				PC_ASGN_IMMNUM(double_cvif_func_romaddr);
				romdata[cp[0]] = rom_cp >> 1;
				romdata[cp[1]] = rom_cp >> 9;
				romdata[cp[2]] = rom_cp >> 17;
				for (int i = 0; i < 8; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(REGISTER_FILE_OP_FUNC_LOP + i, ALU_OUTA);
				}
				for (int i = 0; i < 3; ++i) {
					_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
					cp[i] = rom_cp - 1;
				}
				double_to_float_func_gen();
				PC_ASGN_IMMNUM(double_to_float_func_romaddr);
				goto label_0;
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
			for (int i = 0; i < 3; ++i) {
				_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
				cp[i] = rom_cp - 1;
			}
			float_cvif_func_gen();
			PC_ASGN_IMMNUM(float_cvif_func_romaddr);
			label_0:
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (d->v.i != REGISTER_FILE_OP_FUNC_DOP) {
				for (int i = 0; i < d->datasize; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(d->v.i + i, ALU_OUTA);
				}
			}
		}
		/*double*/
		else {
			ss.addrtype = Xop::XOP_REGISTER_FILE;
			ss.v.i = REGISTER_FILE_OP_FUNC_LOP;
			REGISTER_FILE_ASGN_OP(&ss, s);
			/*char*/
			if (ss.datasize == 1) {
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(REGISTER_FILE_OP_FUNC_LOP);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 1; i < 8; ++i)
					_RF_ASGN_ALU(ss.v.i + i, ALU_MUL_L);
			}
			/*short*/
			else if (ss.datasize == 2) {
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(REGISTER_FILE_OP_FUNC_LOP + 1);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 2; i < 8; ++i)
					_RF_ASGN_ALU(ss.v.i + i, ALU_MUL_L);
			}
			/*long*/
			else if (ss.datasize == 4) {
				A_ASGN_IMMNUM(0);
				B_ASGN__RF_O(REGISTER_FILE_OP_FUNC_LOP + 3);
				A_ASGN_ALU(ALU_A_BH_LSH);
				B_ASGN_IMMNUM(0xff);
				for (int i = 4; i < 8; ++i)
					_RF_ASGN_ALU(ss.v.i + i, ALU_MUL_L);
			}
			/*long long*/
			else if (ss.datasize == 8) {
			}
			else
				error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
			for (int i = 0; i < 3; ++i) {
				_RF_ASGN_IMMNUM(REGISTER_FILE_OP_FUNC_RET + i, 0);
				cp[i] = rom_cp - 1;
			}
			double_cvif_func_gen();
			PC_ASGN_IMMNUM(double_cvif_func_romaddr);
			romdata[cp[0]] = rom_cp >> 1;
			romdata[cp[1]] = rom_cp >> 9;
			romdata[cp[2]] = rom_cp >> 17;
			if (d->v.i != REGISTER_FILE_OP_FUNC_DOP) {
				for (int i = 0; i < d->datasize; ++i) {
					A_ASGN__RF(REGISTER_FILE_OP_FUNC_DOP + i);
					_RF_ASGN_ALU(d->v.i + i, ALU_OUTA);
				}
			}
		}
	}
	else
		error("���DOP_ASGN_SOP_CVI�������ɻ��������д���\n");
}

/*Դ���������޷�������ת��,�����Ŀ�Ĳ�����(�Ĵ�����)*/
void DOP_ASGN_SOP_CVU(Xop* d, Xop* s) {
	/*CVUI*/
	if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_I) {
		if (s->datasize == 1) {
			if (d->datasize == 1)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 2) {
				REGISTER_FILE_ASGN_OP(d, s);
				_RF_ASGN_IMMNUM(d->v.i + 1, 0);
			}
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 1; i < 4; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 1; i < 8; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else if (s->datasize == 2) {
			if (d->datasize == 1 || d->datasize == 2)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				_RF_ASGN_IMMNUM(d->v.i + 2, 0);
				_RF_ASGN_IMMNUM(d->v.i + 3, 0);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 2; i < 8; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else if (s->datasize == 4) {
			if (d->datasize >= 1 && d->datasize <= 4)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 4; i < 8; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else if (s->datasize == 8) {
			if (d->datasize >= 1 && d->datasize <= 8)
				REGISTER_FILE_ASGN_OP(d, s);
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else
			error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
	}
	/*CVUU*/
	else if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_U) {
		if (s->datasize == 1) {
			if (d->datasize == 2) {
				REGISTER_FILE_ASGN_OP(d, s);
				_RF_ASGN_IMMNUM(d->v.i + 1, 0);
			}
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 1; i < 4; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 1; i < 8; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else if (s->datasize == 2) {
			if (d->datasize == 1)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 4) {
				REGISTER_FILE_ASGN_OP(d, s);
				_RF_ASGN_IMMNUM(d->v.i + 2, 0);
				_RF_ASGN_IMMNUM(d->v.i + 3, 0);
			}
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 2; i < 8; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else if (s->datasize == 4) {
			if (d->datasize == 1 || d->datasize == 2)
				REGISTER_FILE_ASGN_OP(d, s);
			else if (d->datasize == 8) {
				REGISTER_FILE_ASGN_OP(d, s);
				for (int i = 4; i < 8; ++i)
					_RF_ASGN_IMMNUM(d->v.i + i, 0);
			}
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else if (s->datasize == 8) {
			if (d->datasize >= 1 && d->datasize <= 4)
				REGISTER_FILE_ASGN_OP(d, s);
			else
				error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
		}
		else
			error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
	}
	/*CVUP*/
	else if (d->addrtype == Xop::XOP_REGISTER_FILE && d->datatype == Xop::XOP_P && d->datasize == 3) {
		if (s->datasize == 1) {
			REGISTER_FILE_ASGN_OP(d, s);
			_RF_ASGN_IMMNUM(d->v.i + 1, 0);
			_RF_ASGN_IMMNUM(d->v.i + 2, 0);
		}
		else if (s->datasize == 2) {
			REGISTER_FILE_ASGN_OP(d, s);
			_RF_ASGN_IMMNUM(d->v.i + 2, 0);
		}
		else if (s->datasize == 4 || s->datasize == 8)
			REGISTER_FILE_ASGN_OP(d, s);
		else
			error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
	}
	else
		error("���DOP_ASGN_SOP_CVU�������ɻ��������д���\n");
}

/*Դ������ȡ��,�����Ŀ�Ĳ�����*/
void DOP_ASGN_SOP_BCOM(Xop* d, Xop* s) {
	Xop sd = *d, ss = *s;

	if (ss.datatype == Xop::XOP_I || ss.datatype == Xop::XOP_U) {
		if (ss.datasize >= 1 && ss.datasize <= 8) {
			addr_convert(&sd, &ss, NULL);
			for (int i = 0; i < ss.datasize; ++i) {
				A_ASGN_OP(&ss, i);
				OP_ASGN_ALU(&sd, i, ALU_A_NOT);
			}
			if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
				DOP_ASGN_SOP(d, &sd);
				regfree(sd.v.i, sd.datasize);
			}
			if (ss.addrtype == Xop::XOP_REGISTER_FILE && s->addrtype != Xop::XOP_REGISTER_FILE)
				regfree(ss.v.i, ss.datasize);
		}
		else
			error("���DOP_ASGN_SOP_BCOM�������ɻ��������д���\n");
	}
	else
		error("���DOP_ASGN_SOP_BCOM�������ɻ��������д���\n");
	
}

/*Դ���������и�������,�����Ŀ�Ĳ�����*/
void DOP_ASGN_SOP_NEG(Xop* d, Xop* s) {
	Xop sd = *d, ss = *s;

	if (ss.datatype == Xop::XOP_I) {
		addr_convert(&sd, &ss, NULL);
		if (ss.datasize == 1) {
			A_ASGN_OP(&ss, 0);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 0, ALU_A_ADD_1);
		}
		else if (ss.datasize == 2) {
			A_ASGN_OP(&ss, 1);
			B_ASGN_ALU(ALU_A_NOT);
			A_ASGN_OP(&ss, 0);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 0, ALU_A_ADD_1);
			A_ASGN_ALU(ALU_A_ADD_1_C);
			OP_ASGN_ALU(&sd, 1, ALU_ADD);
		}
		else if (ss.datasize == 4) {
			A_ASGN_OP(&ss, 1);
			B_ASGN_ALU(ALU_A_NOT);
			A_ASGN_OP(&ss, 0);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 0, ALU_A_ADD_1);
			A_ASGN_ALU(ALU_A_ADD_1_C);
			OP_ASGN_ALU(&sd, 1, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 2);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 2, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 3);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 3, ALU_ADD);
		}
		else if (ss.datasize == 8) {
			A_ASGN_OP(&ss, 1);
			B_ASGN_ALU(ALU_A_NOT);
			A_ASGN_OP(&ss, 0);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 0, ALU_A_ADD_1);
			A_ASGN_ALU(ALU_A_ADD_1_C);
			OP_ASGN_ALU(&sd, 1, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 2);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 2, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 3);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 3, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 4);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 4, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 5);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 5, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 6);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 6, ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN_OP(&ss, 7);
			A_ASGN_ALU(ALU_A_NOT);
			OP_ASGN_ALU(&sd, 7, ALU_ADD);
		}
		else
			error("���DOP_ASGN_SOP_NEG�������ɻ��������д���\n");
	}
	else if (ss.datatype == Xop::XOP_F) {
		addr_convert(&sd, &ss, NULL);
		if (ss.datasize == 4 || ss.datasize == 8) {
			for (int i = 0; i < ss.datasize - 1; ++i) {
				A_ASGN_OP(&ss, i);
				OP_ASGN_ALU(&sd, i, ALU_OUTA);
			}
			A_ASGN_OP(&ss, ss.datasize - 1);
			B_ASGN_IMMNUM(0x80);
			OP_ASGN_ALU(&sd, ss.datasize - 1, ALU_XOR);
		}
		else
			error("���DOP_ASGN_SOP_NEG�������ɻ��������д���\n");
	}
	else
		error("���DOP_ASGN_SOP_NEG�������ɻ��������д���\n");
	if (sd.addrtype == Xop::XOP_REGISTER_FILE && d->addrtype != Xop::XOP_REGISTER_FILE) {
		DOP_ASGN_SOP(d, &sd);
		regfree(sd.v.i, sd.datasize);
	}
	if (ss.addrtype == Xop::XOP_REGISTER_FILE && s->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(ss.v.i, ss.datasize);
}

#define ARG_RET_ADDR_SKIP 3 //���ص�ַռ�ÿռ�
#define ARG_RET_PAGES_SKIP 1 //����ҳ��ƫ��ռ�ÿռ�
#define ARG_RET_ADDR_OFFSET 0 //���ص�ַ����ջҳƫ��
#define ARG_RET_PAGES_OFFSET 3 //����ҳƫ������ջҳƫ��
unsigned char arg_sp_reg; //����Ŀ�Ķ�ջҳ�ļĴ����ѵĵ�ַ
unsigned long arg_offset; //����ƫ�Ƶ�ַ(ûƫ����û����)(ȫ�ֳ�ʼ��)
unsigned long arg_pages_romaddr; //����Ŀ�Ķ�ջҳ��ҳƫ������ROM��ַ(ҳƫ�ƴ�CALL�޸�)
unsigned long func_sp_alloc_base; //��̬����ջ��ַ
unsigned long func_sp_alloc_offset; //��̬����ջƫ��

/*�Ĵ�����װ����A2��A1�Ĵ���*/
void REGISTER_FILE_TO_A2A1(unsigned char regaddr, long offset) {
	if ((offset & 0xffffff00) == 0) {
		A2_ASGN__RF_O(regaddr + 1);
		A1_ASGN__RF_O(regaddr);
	}
	else {
		A_ASGN__RF_O(regaddr);
		B_ASGN_IMMNUM(offset >> 8);
		A1_ASGN_ALU(ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(regaddr + 1);
		A2_ASGN_ALU(ALU_ADD);
	}
}

/*����*/
void SOP_ARG(Xop* s) {
	Xop ss = *s;
	unsigned long cp[3];

	if (arg_offset == 0) {
		/*���㴫��Ŀ�Ķ�ջҳ,�����arg_sp_regָ��ļĴ�����*/
		arg_sp_reg = regalloc(2, 1);
		A_ASGN__RF_O(REGISTER_FILE_SP);
		B_ASGN_IMMNUM(0);
		arg_pages_romaddr = rom_cp - 1;
		_RF_ASGN_ALU(arg_sp_reg, ALU_ADD);
		B_ASGN_ALU(ALU_ADD_C);
		A_ASGN__RF(REGISTER_FILE_SP + 1);
		_RF_ASGN_ALU(arg_sp_reg + 1, ALU_ADD);
		arg_offset += ARG_RET_ADDR_SKIP + ARG_RET_PAGES_SKIP;
	}
	if (LOC_OFFSET_CONST_P_OR(ss.addrtype) && ss.datatype != Xop::XOP_X) {
		ss.addrtype = Xop::XOP_REGISTER_FILE;
		ss.v.i = regalloc(ss.datasize, 1);
		s->datatype = Xop::XOP_X;
		DOP_ASGN_SOP_INDIR(&ss, s);
		s->datatype = ss.datatype;
	}
	for (int x = 0; x < ss.datasize; ++x) {
		if (x == 0)
			REGISTER_FILE_TO_A2A1(arg_sp_reg, arg_offset);
		else if ((arg_offset + x & 255) == 0)
			REGISTER_FILE_TO_A2A1(arg_sp_reg, arg_offset + x);
		A0_ASGN_IMMNUM(arg_offset + x);
		switch (ss.addrtype) {
		case Xop::XOP_LOC:
			RAM_ASGN_IMMNUM(0);
			cp[x] = rom_cp - 1;
			break;
		case Xop::XOP_OFFSET:
			if (x == 0) {
				RAM_ASGN_IMMNUM(ss.v.i);
			}
			else if (x == 1) {
				if ((ss.v.i & 0xffffff00) == 0)
					RAM_ASGN__RF(REGISTER_FILE_SP);
				else {
					A_ASGN__RF(REGISTER_FILE_SP);
					B_ASGN_IMMNUM(ss.v.i >> 8);
					RAM_ASGN_ALU(ALU_ADD);
					B_ASGN_ALU(ALU_ADD_C);
				}
			}
			else if (x == 2) {
				if ((ss.v.i & 0xffffff00) == 0)
					RAM_ASGN__RF(REGISTER_FILE_SP + 1);
				else {
					A_ASGN__RF(REGISTER_FILE_SP + 1);
					RAM_ASGN_ALU(ALU_ADD);
				}
			}
			break;
		case Xop::XOP_CONST_P:
			RAM_ASGN_IMMNUM(ss.v.u >> (x * 8));
			break;
		case Xop::XOP_REGISTER_FILE:
			RAM_ASGN__RF(ss.v.i + x);
			break;
		case Xop::XOP_CONST:
			if (ss.datatype == Xop::XOP_I)
				RAM_ASGN_IMMNUM(ss.v.i >> (x * 8));
			else if (ss.datatype == Xop::XOP_U)
				RAM_ASGN_IMMNUM(ss.v.u >> (x * 8));
			else if (ss.datatype == Xop::XOP_F) {
				if (ss.datasize == 4) {
					float f = ss.v.d;
					RAM_ASGN_IMMNUM(*((unsigned long*)&f) >> (x * 8));
				}
				else {
					double d = ss.v.d;
					unsigned long* p = (unsigned long*)&d;
					if (x < 4)
						RAM_ASGN_IMMNUM(p[swap] >> (x * 8));
					else
						RAM_ASGN_IMMNUM(p[1 - swap] >> ((x - 4) * 8));
				}
			}
			break;
		case Xop::XOP_REGISTER_IO0:
			RAM_ASGN_IO0();
			break;
		case Xop::XOP_REGISTER_IO1:
			RAM_ASGN_IO1();
			break;
		default: error("���SOP_ARG�������ɻ��������д���\n");
		}
	}
	if(ss.datasize != 3)
		arg_offset += ss.datasize;
	else
		arg_offset += 4;
	if (arg_offset > 65536)
		error("ջ�ռ����,���ݲ�������,ջ���ݴ�СΪ%d�ֽ�,�����趨ֵ65536�ֽ�\n", arg_offset);
	if (ss.addrtype == Xop::XOP_LOC)
		insertaddr(ss.entry, cp[2], cp[1], cp[0], ss.v.i);
	else if (ss.addrtype == Xop::XOP_REGISTER_FILE && s->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(ss.v.i, ss.datasize);
}

/*����*/
void SOP_RET(Xop* s) {
	Xop ss = *s;
	unsigned long cp[3];

	if (LOC_OFFSET_CONST_P_OR(ss.addrtype) && ss.datatype != Xop::XOP_X) {
		ss.addrtype = Xop::XOP_REGISTER_FILE;
		ss.v.i = REGISTER_FILE_RET_VALUE;
		s->datatype = Xop::XOP_X;
		DOP_ASGN_SOP_INDIR(&ss, s);
		s->datatype = ss.datatype;
		return;
	}
	for (int x = 0; x < ss.datasize; ++x) {
		switch (ss.addrtype) {
		case Xop::XOP_LOC:
			_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE + x, 0);
			cp[x] = rom_cp - 1;
			break;
		case Xop::XOP_OFFSET:
			if (x == 0) {
				_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE, ss.v.i);
			}
			else if (x == 1) {
				A_ASGN__RF(REGISTER_FILE_SP);
				if ((ss.v.i & 0xffffff00) == 0)
					_RF_ASGN_ALU(REGISTER_FILE_RET_VALUE + 1, ALU_OUTA);
				else {
					B_ASGN_IMMNUM(ss.v.i >> 8);
					_RF_ASGN_ALU(REGISTER_FILE_RET_VALUE + 1, ALU_ADD);
					B_ASGN_ALU(ALU_ADD_C);
				}
			}
			else if (x == 2) {
				A_ASGN__RF(REGISTER_FILE_SP + 1);
				if ((ss.v.i & 0xffffff00) == 0)
					_RF_ASGN_ALU(REGISTER_FILE_RET_VALUE + 2, ALU_OUTA);
				else
					_RF_ASGN_ALU(REGISTER_FILE_RET_VALUE + 2, ALU_ADD);
			}
			break;
		case Xop::XOP_CONST_P:
			_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE + x, ss.v.u >> (x * 8));
			break;
		case Xop::XOP_REGISTER_FILE:
			A_ASGN__RF(ss.v.i + x);
			_RF_ASGN_ALU(REGISTER_FILE_RET_VALUE + x, ALU_OUTA);
			break;
		case Xop::XOP_CONST:
			if (ss.datatype == Xop::XOP_I)
				_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE + x, ss.v.i >> (x * 8));
			else if (ss.datatype == Xop::XOP_U)
				_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE + x, ss.v.u >> (x * 8));
			else if (ss.datatype == Xop::XOP_F) {
				if (ss.datasize == 4) {
					float f = ss.v.d;
					_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE + x, *((unsigned long*)&f) >> (x * 8));
				}
				else {
					double d = ss.v.d;
					unsigned long* p = (unsigned long*)&d;
					if (x < 4)
						_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE + x, p[swap] >> (x * 8));
					else
						_RF_ASGN_IMMNUM(REGISTER_FILE_RET_VALUE + x, p[1 - swap] >> ((x - 4) * 8));
				}
			}
			break;
		case Xop::XOP_REGISTER_IO0:
			_RF_ASGN_IO0(REGISTER_FILE_RET_VALUE);
			break;
		case Xop::XOP_REGISTER_IO1:
			_RF_ASGN_IO1(REGISTER_FILE_RET_VALUE);
			break;
		default: error("���SOP_RET�������ɻ��������д���\n");
		}
	}
	if (ss.addrtype == Xop::XOP_LOC)
		insertaddr(ss.entry, cp[2], cp[1], cp[0], ss.v.i);
	//else if (ss.addrtype == Xop::XOP_REGISTER_FILE && s->addrtype != Xop::XOP_REGISTER_FILE)
		//regfree(ss.v.i, ss.datasize);
}

/*��ת*/
void SOP_JUMP(Xop* s) {
	if (s->datatype == Xop::XOP_X || (s->addrtype == Xop::XOP_REGISTER_FILE && s->datatype == Xop::XOP_P)) {
		switch (s->addrtype) {
		case Xop::XOP_LOC:
			insertaddr(s->entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, s->v.i);
			PC_ASGN_IMMNUM(0);
			return;
		case Xop::XOP_CONST_P: PC_ASGN_IMMNUM(s->v.u); return;
		case Xop::XOP_REGISTER_FILE:
			REGISTER_TO_A2A1A0(s->v.i, 0);
			PC_ASGN_A2A1A0();
			return;
		}
	}
	error("���SOP_JUMP�������ɻ��������д���\n");
}

/*����*/
void SOP_CALL(Xop* s) {
	Xop ss = *s;
	unsigned long cp[3];
	unsigned char sp_offset = (func_sp_alloc_offset >> 8) + ((func_sp_alloc_offset & 0xff) != 0);

	if (func_sp_alloc_offset > 65280)
		error("ջ�ռ����,�������ô���,ջ���ݴ�СΪ%d�ֽ�,�����趨ֵ65280�ֽ�\n", func_sp_alloc_offset);
	if (LOC_OFFSET_CONST_P_OR(ss.addrtype) && ss.datatype == Xop::XOP_P) {
		ss.addrtype = Xop::XOP_REGISTER_FILE;
		ss.v.i = regalloc(ss.datasize, 1);
		s->datatype = Xop::XOP_X;
		DOP_ASGN_SOP_INDIR(&ss, s);
		s->datatype = ss.datatype;
	}
	if (((ss.addrtype == Xop::XOP_LOC || ss.addrtype == Xop::XOP_CONST_P) && ss.datatype == Xop::XOP_X) || (ss.addrtype == Xop::XOP_REGISTER_FILE && ss.datatype == Xop::XOP_P)) {
		/*ջҳָ�뷭ҳ*/
		if (arg_offset == 0) {
			A_ASGN__RF_O(REGISTER_FILE_SP);
			B_ASGN_IMMNUM(sp_offset);
			A1_ASGN_ALU(ALU_ADD);
			RF_ASGN_ALU(ALU_ADD);
			B_ASGN_ALU(ALU_ADD_C);
			A_ASGN__RF(REGISTER_FILE_SP + 1);
			A2_ASGN_ALU(ALU_ADD);
			RF_ASGN_ALU(ALU_ADD);
		}
		else {
			romdata[arg_pages_romaddr] = sp_offset;
			A_ASGN__RF_O(arg_sp_reg);
			A1_ASGN_ALU(ALU_OUTA);
			_RF_ASGN_ALU(REGISTER_FILE_SP, ALU_OUTA);
			A_ASGN__RF(arg_sp_reg + 1);
			A2_ASGN_ALU(ALU_OUTA);
			_RF_ASGN_ALU(REGISTER_FILE_SP + 1, ALU_OUTA);
			regfree(arg_sp_reg, 2);
			arg_offset = 0;
		}
		/*���ݷ��ص�ַ*/
		for (int i = 0; i < 3; ++i) {
			A0_ASGN_IMMNUM(ARG_RET_ADDR_OFFSET + i);
			RAM_ASGN_IMMNUM(0);
			cp[i] = rom_cp - 1;
		}
		/*���ݷ���ҳƫ��*/
		A0_ASGN_IMMNUM(ARG_RET_PAGES_OFFSET);
		RAM_ASGN_IMMNUM(sp_offset);
		/*ת������������*/
		switch (ss.addrtype) {
		case Xop::XOP_LOC:
			insertaddr(ss.entry, rom_cp + 1, rom_cp + 3, rom_cp + 5, ss.v.i);
			PC_ASGN_IMMNUM(0);
			break;
		case Xop::XOP_CONST_P:
			PC_ASGN_IMMNUM(ss.v.u);
			break;
		case Xop::XOP_REGISTER_FILE:
			REGISTER_TO_A2A1A0(ss.v.i, 0);
			PC_ASGN_A2A1A0();
			break;
		}
		/*���ص�ַ�ض����ڴ˴�*/
		romdata[cp[0]] = rom_cp >> 1;
		romdata[cp[1]] = rom_cp >> 9;
		romdata[cp[2]] = rom_cp >> 17;
		reset_cpu_o();
	}
	else
		error("���SOP_CALL�������ɻ��������д���\n");
	if (ss.addrtype == Xop::XOP_REGISTER_FILE && s->addrtype != Xop::XOP_REGISTER_FILE)
		regfree(ss.v.i, ss.datasize);
}

/*���ɺ�������ָ��*/
void FUNCTION_RET() {
	SP_TO_A2A1(0);
	A0_ASGN_IMMNUM(ARG_RET_PAGES_OFFSET);
	A_ASGN__RF(REGISTER_FILE_SP);
	B_ASGN_RAM();
	RF_ASGN_ALU(ALU_SUB);
	B_ASGN_ALU(ALU_SUB_C);
	A_ASGN__RF(REGISTER_FILE_SP + 1);
	RF_ASGN_ALU(ALU_SUB);
	A0_ASGN_IMMNUM(ARG_RET_ADDR_OFFSET + 2);
	A_ASGN_RAM();
	A0_ASGN_IMMNUM(ARG_RET_ADDR_OFFSET + 1);
	B_ASGN_RAM();
	A0_ASGN_IMMNUM(ARG_RET_ADDR_OFFSET);
	A0_ASGN_RAM();
	A1_ASGN_ALU(ALU_OUTB);
	A2_ASGN_ALU(ALU_OUTA);
	PC_ASGN_A2A1A0();
}

/****************************************LCC��������˽ӿ�****************************************/

/*���ݶ�֪ͨ*/
static void I(_segment)(int n) {
	switch (n) {
	case CODE:
		if (cseg != CODE) {
			romentry = rom_cp;
			PC_ASGN_IMMNUM(0);
			cseg = n;
		}
		break;
	case DATA: case LIT:
		if (cseg == CODE)
			MODIFY_A2A1A0(romentry, rom_cp >> 1);
		cseg = n;
	case BSS: break;
	}
}

/*ƫ�Ƶ�ַ֪ͨ*/
static void I(_address)(Symbol q, Symbol p, long n) {
	q->x.name = p->x.name;
	q->x.offset = p->x.offset + n;
}

/*�����ַ֪ͨ*/
static void I(_defaddress)(Symbol p) {
	unsigned long a[3];

	for (int i = 0; i < 3; ++i) {
		_RAM_ASGN_IMMNUM_O(ramallocaddr++, 0);
		a[i] = rom_cp - 1;
	}
	ramallocaddr++;
	insertaddr(newaddrdata(p->x.name), a[2], a[1], a[0], p->x.offset);
}

/*����֪ͨ*/
static void I(_defconst)(int suffix, int size, Value v) {
	for (int i = 0; i < size; ++i) {
		switch (suffix) {
		case _I: _RAM_ASGN_IMMNUM_O(ramallocaddr++, v.i >> (i * 8)); break;
		case U: _RAM_ASGN_IMMNUM_O(ramallocaddr++, v.u >> (i * 8)); break;
		case P: _RAM_ASGN_IMMNUM_O(ramallocaddr++, (unsigned long)v.p >> (i * 8)); break;
		case F:
			if (size == 4) {
				float f = v.d;
				_RAM_ASGN_IMMNUM_O(ramallocaddr++, *(unsigned long*)&f >> (i * 8));
			}
			else {
				double d = v.d;
				unsigned long* p = (unsigned long*)&d;
				if (i < 4)
					_RAM_ASGN_IMMNUM_O(ramallocaddr++, p[swap] >> (i * 8));
				else
					_RAM_ASGN_IMMNUM_O(ramallocaddr++, p[1 - swap] >> ((i - 4) * 8));
			}
			break;
		}
	}
	return;
}
/*�ַ���֪ͨ*/
static void I(_defstring)(int len, char* str) {
	char* s;

	for (s = str; s < str + len; s++)
		_RAM_ASGN_IMMNUM_O(ramallocaddr++, *s);
}
/*����֪ͨ*/
static void I(_defsymbol)(Symbol p) {
	if (p->scope == CONSTANTS)
		switch (optype(ttob(p->type))) {
		case _I: p->x.name = stringf("%D", p->u.c.v.i); break;
		case U: p->x.name = stringf("%U", p->u.c.v.u); break;
		case P: p->x.name = stringf("%U", p->u.c.v.p); break;
		case F: p->x.name = stringf("%f", p->u.c.v.d); break;
		default: assert(0);
		}
	else if (p->scope >= LOCAL && p->sclass == STATIC)
		p->x.name = stringf("$%d", genlabel(1));
	else if (p->scope == LABELS || p->generated)
		p->x.name = stringf("$%s", p->name);
	else if (p->scope == GLOBAL && p->sclass == STATIC)
		p->x.name = stringf("$%s", p->name);
	else
		p->x.name = p->name;
}

/*���������,�ж������򷵻�1*/
static char loc_dumptree_binary(Node p) {
	if (p != NULL && p->glowop.addrtype == Xop::XOP_VOID) {
		if (p->kids[0] != NULL && p->kids[1] != NULL)
			return 1;
		return loc_dumptree_binary(p->kids[0]) | loc_dumptree_binary(p->kids[1]);
	}
	return 0;
}

/*Ϊ�ڵ�Xop�½��Ĵ���*/
void node_xop_new_register(Node p) {
	p->glowop.addrtype = Xop::XOP_REGISTER_FILE;
	p->glowop.datatype = (Xop::dt)optype(p->op);
	if (optype(p->op) == P)
		p->glowop.datasize = 3;
	else
		p->glowop.datasize = opsize(p->op);
	p->glowop.v.i = regalloc(p->glowop.datasize, p->count);
}

/*���ʽ�ӿ�*/
static void glowop_dumptree(Node p, Node pf) {
	static Node Up_call_node;

	if (p->glowop.addrtype != Xop::XOP_VOID)
		return;
	switch (specific(p->op)) {
	case ASGN + B:
		if (p->kids[0] == 0 || p->kids[1] == 0 || p->syms[0] == 0) {
			error("���loc_dumptree����ASGN+B����\n");
			return;
		}
		glowop_dumptree(p->kids[0], p);
		glowop_dumptree(p->kids[1], p);
		DOP_ASGN_SOP_B(&p->kids[0]->glowop, &p->kids[1]->glowop, p->syms[0]->u.c.v.u);
		if (p->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
		if (p->kids[1]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[1]->glowop.v.i, p->kids[1]->glowop.datasize);
		return;
	case RET + V:
		if (p->kids[0] != 0 || p->kids[1] != 0) {
			error("���loc_dumptree����RET+V����\n");
			return;
		}
	}
	switch (generic(p->op)) {
	case ADDRG: case ADDRF: case ADDRL:
		if (p->kids[0] != 0 || p->kids[1] != 0 || p->syms[0] == 0 || p->syms[0]->x.name == 0)
			return;
		p->glowop.datatype = Xop::XOP_X;
		p->glowop.datasize = 3;
		if (generic(p->op) == ADDRG) {
			if (strcmp(p->syms[0]->x.name, "REGISTER_IO0") == 0)
				p->glowop.addrtype = Xop::XOP_REGISTER_IO0;
			else if (strcmp(p->syms[0]->x.name, "REGISTER_IO1") == 0)
				p->glowop.addrtype = Xop::XOP_REGISTER_IO1;
			else {
				p->glowop.entry = newaddrdata(p->syms[0]->x.name);
				if (p->glowop.entry->base == 0xffffffff) {
					p->glowop.addrtype = Xop::XOP_LOC;
				}
				else {
					p->glowop.addrtype = Xop::XOP_CONST_P;
					p->glowop.v.u = p->glowop.entry->base + p->syms[0]->x.offset;
					return;
				}
			}
		}
		else
			p->glowop.addrtype = Xop::XOP_OFFSET;
		p->glowop.v.i = p->syms[0]->x.offset;
		return;
	case INDIR:
		if (p->kids[0] == 0 || p->kids[1] != 0) {
			error("���loc_dumptree����INDIR����\n");
			return;
		}
		glowop_dumptree(p->kids[0], p);
		switch (p->kids[0]->glowop.addrtype) {
		case Xop::XOP_LOC: case Xop::XOP_OFFSET: case Xop::XOP_CONST_P: {
			if (p->count > 1 || (optype(p->op) == P && generic(pf->op) == INDIR)) {
				node_xop_new_register(p);
				DOP_ASGN_SOP_INDIR(&p->glowop, &p->kids[0]->glowop);
			}
			else {
				p->glowop = p->kids[0]->glowop;
				p->glowop.datatype = (Xop::dt)optype(p->op);
				if (optype(p->op) != P && optype(p->op) != B)
					p->glowop.datasize = opsize(p->op);
			}
			return;
		}
		case Xop::XOP_REGISTER_FILE:
			if (optype(p->op) == B) {
				p->glowop = p->kids[0]->glowop;
				p->glowop.datatype = Xop::XOP_B;
				glowreg[p->glowop.v.i].life += p->count - 1;
			}
			else {
				node_xop_new_register(p);
				DOP_ASGN_SOP_INDIR(&p->glowop, &p->kids[0]->glowop);
				regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
			}
			return;
		case Xop::XOP_REGISTER_IO0: case Xop::XOP_REGISTER_IO1:
			p->glowop.addrtype = p->kids[0]->glowop.addrtype;
			p->glowop.datatype = (Xop::dt)optype(p->op);
			p->glowop.datasize = opsize(p->op);
			return;
		default:
			error("���loc_dumptree����INDIR���ʹ���\n");
			return;
		}
	case CNST:
		if (p->kids[0] != 0 || p->kids[1] != 0 || p->syms[0] == 0 || p->syms[0]->x.name == 0) {
			error("���loc_dumptree����CNST����\n");
			return;
		}
		if (optype(p->op) == P) {
			p->glowop.addrtype = Xop::XOP_CONST_P;
			p->glowop.datatype = Xop::XOP_X;
			p->glowop.datasize = 3;
			p->glowop.v.u = (unsigned long)p->syms[0]->u.c.v.p;
		}
		else {
			p->glowop.addrtype = Xop::XOP_CONST;
			p->glowop.datatype = (Xop::dt)optype(p->op);
			p->glowop.datasize = opsize(p->op);
			p->glowop.v = p->syms[0]->u.c.v;
		}
		return;
	case LABEL:
		if (p->kids[0] != 0 || p->kids[1] != 0 || p->syms[0] == 0 || p->syms[0]->x.name == 0) {
			error("���loc_dumptree����LABEL����\n");
			return;
		}
		newaddrdata(p->syms[0]->x.name)->base = rom_cp >> 1;
		reset_cpu_o();
		return;
	case CVF: case CVI: case CVP: case CVU:
		if (p->kids[0] == 0 || p->kids[1] != 0) {
			error("���loc_dumptree����CVF CVI CVP CVU����\n");
			return;
		}
		glowop_dumptree(p->kids[0], p);
		if (generic(p->op) == CVU && (optype(p->op) == U || optype(p->op) == _I) && opsize(p->kids[0]->op) >= 1 && opsize(p->kids[0]->op) <= 8 && generic(pf->op) == ADD && optype(pf->op) == P && p->count == 1) {
			p->glowop = p->kids[0]->glowop;
			return;
		}
		node_xop_new_register(p);
		switch (generic(p->op)) {
		case CVF: DOP_ASGN_SOP_CVF(&p->glowop, &p->kids[0]->glowop); break;
		case CVI: DOP_ASGN_SOP_CVI(&p->glowop, &p->kids[0]->glowop); break;
		case CVP: DOP_ASGN_SOP_CVP(&p->glowop, &p->kids[0]->glowop); break;
		case CVU: DOP_ASGN_SOP_CVU(&p->glowop, &p->kids[0]->glowop); break;
		}
		if (p->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
		return;
	case ARG: case RET: case JUMP:
		if (p->kids[0] == 0 || p->kids[1] != 0) {
			error("���loc_dumptree����ARG RET JUMP����\n");
			return;
		}
		glowop_dumptree(p->kids[0], p);
		switch (generic(p->op)) {
		case ARG: SOP_ARG(&p->kids[0]->glowop); break;
		case RET: SOP_RET(&p->kids[0]->glowop); break;
		case JUMP: SOP_JUMP(&p->kids[0]->glowop); break;
		}
		if (p->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
		return;
	case CALL:
		if (p->kids[0] == 0 || p->kids[1] != 0 || optype(p->op) == B) {
			error("���loc_dumptree����CALL����\n");
			return;
		}
		glowop_dumptree(p->kids[0], p);
		if (glowreg[REGISTER_FILE_RET_VALUE].life > 0) {
			Xop sop;
			sop = Up_call_node->glowop;
			Up_call_node->glowop.addrtype = Xop::XOP_OFFSET;
			Up_call_node->glowop.datatype = Xop::XOP_X;
			Up_call_node->glowop.v.i = func_sp_alloc_offset;
			func_sp_alloc_offset += sop.datasize;
			if (func_sp_alloc_offset > maxoffset)
				maxoffset = func_sp_alloc_offset;
			DOP_ASGN_SOP(&Up_call_node->glowop, &sop);
			Up_call_node->glowop.datatype = sop.datatype;
			glowreg[REGISTER_FILE_RET_VALUE].life = 0;
		}
		for (short i = REG_START; i < REG_SIZE; ++i) {
			if ((p->kids[0]->glowop.addrtype != Xop::XOP_REGISTER_FILE || i < p->kids[0]->glowop.v.i || i > p->kids[0]->glowop.v.i + 2) &&
				(arg_offset == 0 || i < arg_sp_reg || i > arg_sp_reg + 1) &&
				glowreg[i].state == Reg::REG_BUSY) {
				Xop dop, sop;
				sop.addrtype = Xop::XOP_REGISTER_FILE;
				sop.datatype = Xop::XOP_U;
				sop.datasize = 1;
				sop.v.i = i;
				dop.addrtype = Xop::XOP_OFFSET;
				dop.datatype = Xop::XOP_X;
				dop.v.i = func_sp_alloc_offset;
				func_sp_alloc_offset += 1;
				if (func_sp_alloc_offset > maxoffset)
					maxoffset = func_sp_alloc_offset;
				DOP_ASGN_SOP(&dop, &sop);
			}
		}
		SOP_CALL(&p->kids[0]->glowop);
		for (short i = REG_SIZE; i >= REG_START; --i) {
			if ((p->kids[0]->glowop.addrtype != Xop::XOP_REGISTER_FILE || i < p->kids[0]->glowop.v.i || i > p->kids[0]->glowop.v.i + 2) && glowreg[i].state == Reg::REG_BUSY) {
				Xop dop, sop;
				sop.addrtype = Xop::XOP_OFFSET;
				sop.datatype = Xop::XOP_X;
				sop.v.i = --func_sp_alloc_offset;
				dop.addrtype = Xop::XOP_REGISTER_FILE;
				dop.datatype = Xop::XOP_U;
				dop.datasize = 1;
				dop.v.i = i;
				DOP_ASGN_SOP_INDIR(&dop, &sop);
			}
		}
		if (optype(p->op) != V && p->count > 0) {
			p->glowop.addrtype = Xop::XOP_REGISTER_FILE;
			p->glowop.datatype = (Xop::dt)optype(p->op);
			if (optype(p->op) == P)
				p->glowop.datasize = 3;
			else
				p->glowop.datasize = opsize(p->op);
			p->glowop.v.i = REGISTER_FILE_RET_VALUE;
			glowreg[REGISTER_FILE_RET_VALUE].life = p->count;
			Up_call_node = p;
		}
		if (p->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
		return;
	case ASGN:
		if (p->kids[0] == 0 || p->kids[1] == 0) {
			error("���loc_dumptree����ASGN����\n");
			return;
		}
		glowop_dumptree(p->kids[0], p);
		glowop_dumptree(p->kids[1], p);
		if (p->kids[1]->glowop.asgnskip == 0) {
			DOP_ASGN_SOP(&p->kids[0]->glowop, &p->kids[1]->glowop);
			if (p->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
				regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
			if (p->kids[1]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
				regfree(p->kids[1]->glowop.v.i, p->kids[1]->glowop.datasize);
		}
		return;
	case BOR: case BAND: case BXOR: case RSH: case LSH: case ADD: case SUB: case DIV: case MUL: case MOD: case BCOM: case NEG:
		if (generic(p->op) == BCOM || generic(p->op) == NEG) {
			if (p->kids[0] == 0 || p->kids[1] != 0) {
				error("���loc_dumptree����BCOM NEG����\n");
				return;
			}
			glowop_dumptree(p->kids[0], p);
		}
		else {
			if (p->kids[0] == 0 || p->kids[1] == 0) {
				error("���loc_dumptree����BOR BAND BXOR RSH LSH ADD SUB DIV MUL MOD����\n");
				return;
			}
			if (loc_dumptree_binary(p->kids[0]) != 0) {
				glowop_dumptree(p->kids[0], p);
				glowop_dumptree(p->kids[1], p);
			}
			else {
				glowop_dumptree(p->kids[1], p);
				glowop_dumptree(p->kids[0], p);
			}
		}
		if (opsize(p->op) == 1 && p->count == 1 && ((generic(p->op) != LSH && generic(p->op) != RSH) || (p->kids[1]->glowop.addrtype == Xop::XOP_CONST && p->kids[1]->glowop.v.i >= 0 && p->kids[1]->glowop.v.i <= 8))) {
			switch (generic(pf->op)) {
			case DIV: case MOD: case GE: case LT:
				if (optype(p->op) != U)
					break;
			case BOR: case BAND: case BXOR: case RSH: case LSH: case ADD: case SUB: case MUL: case EQ: case NE:
				if (pf->kids[0] == p) {
					if (generic(pf->op) == LSH) {
						if (generic(pf->kids[1]->op) == CNST && pf->kids[1]->syms[0]->u.c.v.i >= 0 && pf->kids[1]->syms[0]->u.c.v.i <= 8) {
							p->glowop.addrtype = Xop::XOP_REGISTER_A;
							p->glowop.datatype = (Xop::dt)optype(p->op);
							p->glowop.datasize = opsize(p->op);
						}
					}
					else if (generic(pf->op) == RSH) {
						if (generic(pf->kids[1]->op) == CNST) {
							if (optype(p->op) == U) {
								if (pf->kids[1]->syms[0]->u.c.v.i >= 0 && pf->kids[1]->syms[0]->u.c.v.i <= 8) {
									p->glowop.addrtype = Xop::XOP_REGISTER_A;
									p->glowop.datatype = (Xop::dt)optype(p->op);
									p->glowop.datasize = opsize(p->op);
								}
							}
							else {
								if (pf->kids[1]->syms[0]->u.c.v.i == 1 || pf->kids[1]->syms[0]->u.c.v.i == 8) {
									p->glowop.addrtype = Xop::XOP_REGISTER_A;
									p->glowop.datatype = (Xop::dt)optype(p->op);
									p->glowop.datasize = opsize(p->op);
								}
							}
						}
					}
					else {
						if (generic(pf->kids[1]->op) == CNST || pf->kids[1]->glowop.addrtype == Xop::XOP_REGISTER_FILE) {
							p->glowop.addrtype = Xop::XOP_REGISTER_A;
							p->glowop.datatype = (Xop::dt)optype(p->op);
							p->glowop.datasize = opsize(p->op);
						}
						else if (generic(pf->kids[1]->op) == INDIR) {
							if (generic(pf->kids[1]->kids[0]->op) == ADDRG) {
								p->glowop.addrtype = Xop::XOP_REGISTER_A;
								p->glowop.datatype = (Xop::dt)optype(p->op);
								p->glowop.datasize = opsize(p->op);
							}
							else if ((generic(pf->kids[1]->kids[0]->op) == ADDRL || generic(pf->kids[1]->kids[0]->op) == ADDRF) && (pf->kids[1]->kids[0]->syms[0]->x.offset & 0xffffff00) == 0) {
								p->glowop.addrtype = Xop::XOP_REGISTER_A;
								p->glowop.datatype = (Xop::dt)optype(p->op);
								p->glowop.datasize = opsize(p->op);
							}
						}
					}
				}
				else {
					if (generic(pf->op) != RSH && generic(pf->op) != LSH) {
						if (generic(pf->kids[0]->op) == CNST || pf->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE) {
							p->glowop.addrtype = Xop::XOP_REGISTER_B;
							p->glowop.datatype = (Xop::dt)optype(p->op);
							p->glowop.datasize = opsize(p->op);
						}
						else if (generic(pf->kids[0]->op) == INDIR) {
							if (generic(pf->kids[0]->kids[0]->op) == ADDRG) {
								p->glowop.addrtype = Xop::XOP_REGISTER_B;
								p->glowop.datatype = (Xop::dt)optype(p->op);
								p->glowop.datasize = opsize(p->op);
							}
							else if ((generic(pf->kids[0]->kids[0]->op) == ADDRL || generic(pf->kids[0]->kids[0]->op) == ADDRF) && (pf->kids[0]->kids[0]->syms[0]->x.offset & 0xffffff00) == 0) {
								p->glowop.addrtype = Xop::XOP_REGISTER_B;
								p->glowop.datatype = (Xop::dt)optype(p->op);
								p->glowop.datasize = opsize(p->op);
							}
						}
					}
				}
				break;
			case BCOM: case NEG:
				p->glowop.addrtype = Xop::XOP_REGISTER_A;
				p->glowop.datatype = (Xop::dt)optype(p->op);
				p->glowop.datasize = opsize(p->op);
				break;
			}
		}
		if (p->glowop.addrtype == Xop::XOP_VOID) {
			if (generic(pf->op) == ASGN && pf->kids[1] == p && p->count == 1 && pf->kids[0]->glowop.datatype == Xop::XOP_X &&
				(pf->kids[0]->glowop.addrtype == Xop::XOP_LOC || pf->kids[0]->glowop.addrtype == Xop::XOP_OFFSET || pf->kids[0]->glowop.addrtype == Xop::XOP_CONST_P)) {
				p->glowop = pf->kids[0]->glowop;
				p->glowop.asgnskip = 1;
			}
			else
				node_xop_new_register(p);
		}
		switch (generic(p->op)) {
		case BOR: DOP_ASGN_LOP_OR_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case BAND: DOP_ASGN_LOP_AND_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case BXOR: DOP_ASGN_LOP_XOR_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case RSH: DOP_ASGN_LOP_RSH_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case LSH: DOP_ASGN_LOP_LSH_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case ADD: DOP_ASGN_LOP_ADD_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case SUB: DOP_ASGN_LOP_SUB_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case DIV: DOP_ASGN_LOP_DIV_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case MUL: DOP_ASGN_LOP_MUL_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case MOD: DOP_ASGN_LOP_MOD_ROP(&p->glowop, &p->kids[0]->glowop, &p->kids[1]->glowop); break;
		case BCOM: DOP_ASGN_SOP_BCOM(&p->glowop, &p->kids[0]->glowop); break;
		case NEG: DOP_ASGN_SOP_NEG(&p->glowop, &p->kids[0]->glowop); break;
		}
		if (p->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
		if (generic(p->op) != BCOM && generic(p->op) != NEG) {
			if (p->kids[1]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
				regfree(p->kids[1]->glowop.v.i, p->kids[1]->glowop.datasize);
		}
		return;
	case EQ: case NE: case GT: case GE: case LE: case LT:
		if (p->kids[0] == 0 || p->kids[1] == 0 || p->syms[0] == 0 || p->syms[0]->x.name == 0) {
			error("���loc_dumptree����EQ NE GT GE LE LT����\n");
			return;
		}
		glowop_dumptree(p->kids[0], p);
		glowop_dumptree(p->kids[1], p);
		ADDRDATA label = newaddrdata(p->syms[0]->x.name);
		switch (generic(p->op)) {
		case EQ: LOP_EQ_ROP(&p->kids[0]->glowop, &p->kids[1]->glowop, label); break;
		case NE: LOP_NE_ROP(&p->kids[0]->glowop, &p->kids[1]->glowop, label); break;
		case GT: LOP_GT_ROP(&p->kids[0]->glowop, &p->kids[1]->glowop, label); break;
		case GE: LOP_GE_ROP(&p->kids[0]->glowop, &p->kids[1]->glowop, label); break;
		case LE: LOP_LE_ROP(&p->kids[0]->glowop, &p->kids[1]->glowop, label); break;
		case LT: LOP_LT_ROP(&p->kids[0]->glowop, &p->kids[1]->glowop, label); break;
		}
		if (p->kids[0]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[0]->glowop.v.i, p->kids[0]->glowop.datasize);
		if (p->kids[1]->glowop.addrtype == Xop::XOP_REGISTER_FILE)
			regfree(p->kids[1]->glowop.v.i, p->kids[1]->glowop.datasize);
		return;
	}
	assert(0);
}

static void I(_emit)(Node p) {
	for (; p; p = p->link)
		glowop_dumptree(p, NULL);
	func_sp_alloc_offset = func_sp_alloc_base;
}

/*�������֪ͨ*/
static void I(_export)(Symbol p) {
}

/*֪ͨ����*/
static void I(_function)(Symbol f, Symbol caller[], Symbol callee[], int ncalls) {
	int i;

	(*IR->_segment)(CODE);
	offset = ARG_RET_ADDR_SKIP + ARG_RET_PAGES_SKIP;
	for (i = 0; caller[i] && callee[i]; i++) {
		offset = roundup(offset, caller[i]->type->align);
		caller[i]->x.name = callee[i]->x.name = stringf("%d", offset);
		caller[i]->x.offset = callee[i]->x.offset = offset;
		offset += caller[i]->type->size;
	}
	if (variadic(f->type))
		offset += VA_ARG_BUF_SIZE;
	maxoffset = offset;
	maxargoffset = argoffset = 0;
	gencode(caller, callee);
	func_sp_alloc_base = func_sp_alloc_offset = maxoffset;
	ADDRDATA q = newaddrdata(f->x.name);
	q->base = rom_cp >> 1;
	reset_cpu_o();
	emitcode();
	if(maxoffset > 65536)
		error("����ջ�ռ��������,��СΪ%d�ֽ�,�����趨ֵ65536�ֽ�\n", maxoffset);
	FUNCTION_RET();
}

static void gen02(Node p) {
	assert(p);
	if (generic(p->op) == ARG) {
		assert(p->syms[0]);
		argoffset += (p->syms[0]->u.c.v.i < 4 ? 4 : p->syms[0]->u.c.v.i);
	}
	else if (generic(p->op) == CALL) {
		maxargoffset = (argoffset > maxargoffset ? argoffset : maxargoffset);
		argoffset = 0;
	}
}

static void gen01(Node p) {
	if (p) {
		gen01(p->kids[0]);
		gen01(p->kids[1]);
		gen02(p);
	}
}

static Node I(_gen)(Node p) {
	Node q;

	assert(p);
	for (q = p; q; q = q->link)
		gen01(q);
	return p;
}

/*ȫ�ַ���֪ͨ*/
static void I(_global)(Symbol p) {
 	newaddrdata(p->x.name)->base = ramallocaddr;
}

/*��������֪ͨ*/
static void I(_import)(Symbol p) {
}

/*�ֲ����������ַ����(����������)*/
static void I(_local)(Symbol p) {

	offset = roundup(offset, p->type->align);
	p->x.name = stringf("%d", offset);
	p->x.offset = offset;
	offset += p->type->size;
}

static void I(_progbeg)(int argc, char* argv[]) {
	union {
		char c;
		int i;
	} u;
	u.i = 0;
	u.c = 1;
	swap = ((int)(u.i == 1)) != IR->little_endian;
}

static void I(_progend)(void) {}

/*�ռ�֪ͨ*/
static void I(_space)(int n) {
	ramallocaddr += n;
}

static void I(_stabline)(Coordinate* cp) {
	static char* prevfile;
	static int prevline;

	if (cp->file && (prevfile == NULL || strcmp(prevfile, cp->file) != 0)) {
		print("file \"%s\"\n", prevfile = cp->file);
		prevline = 0;
	}
	if (cp->y != prevline)
		print("line %d\n", prevline = cp->y);
	fflush(stdout);

}

#define l__blockbeg blockbeg
#define l__blockend blockend

_Interface glowIR = {
	1, 1, 0,	/* char */
	2, 1, 0,	/* short */
	4, 1, 0,	/* int */
	4, 1, 0,	/* long */
	8, 1, 0,	/* long long */
	4, 1, 0,	/* float */
	8, 1, 0,	/* double */
	8, 1, 0,	/* long double */
	4, 1, 0,	/* T* */
	0, 1, 0,	/* struct */
	1,		/* little_endian */
	0,		/* mulops_calls */
	0,		/* wants_callb */
	0,		/* wants_argb */
	1,		/* left_to_right */
	1,		/* wants_dag */
	0,		/* unsigned_char */
	I(_address),
	I(_blockbeg),
	I(_blockend),
	I(_defaddress),
	I(_defconst),
	I(_defstring),
	I(_defsymbol),
	I(_emit),
	I(_export),
	I(_function),
	I(_gen),
	I(_global),
	I(_import),
	I(_local),
	I(_progbeg),
	I(_progend),
	I(_segment),
	I(_space),
	0,		/* I(stabblock) */
	0,		/* I(stabend) */
	0,		/* I(stabfend) */
	0,		/* I(stabinit) */
	I(_stabline),
	0,		/* I(stabsym) */
	0,		/* I(stabtype) */
};

/****************************************��ʼ��CPU��ALU���ջҳָ��****************************************/

/*��ʼ��CPU����*/
void glow_cpu_init() {
	unsigned long label_0, label_1, label_2, label_3, label_4;

#define REG_ALU_A 0
#define REG_ALU_B 1
#define REG_ALU_OUT_0 2
#define REG_ALU_OUT_1 3
#define REG_0 4
#define REG_1 5
#define REG_2 6
#define REG_3 7

	/******************���ֳ�ʼ��ALU_A_ADD_1��,BΪ1ʱ,A��ֵ��1�����*******************/
	RA_ASGN_IMMNUM(0);
	B_ASGN_IMMNUM(0);
	for (short i = 0; i < 256; ++i) {
		A_ASGN_IMMNUM(i);
		RF_ASGN_IMMNUM(i + 1);
		ALU_ASGN_RF(ALU_A_ADD_1);
	}
	/***************���ֳ�ʼ��ALU_EQUAL_C��,BΪ0ʱ,A��Ϊ0���0,AΪ0���1***************/
	for (short i = 0; i < 256; ++i) {
		A_ASGN_IMMNUM(i);
		RF_ASGN_IMMNUM(i == 0 ? 1 : 0);
		ALU_ASGN_RF(ALU_EQUAL_C);
	}
	/*************************������ʼ��ALU_ADD���ALU_ADD_C��**************************/

	/*��ʼ������ֵ*/
	_RF_ASGN_IMMNUM(REG_ALU_A, 0);
	_RF_ASGN_IMMNUM(REG_ALU_B, 0);
	_RF_ASGN_IMMNUM(REG_ALU_OUT_0, 0);
	_RF_ASGN_IMMNUM(REG_0, -1);
	label_2 = rom_cp >> 1;
	_RF_ASGN_IMMNUM(REG_ALU_OUT_1, 0);
	label_1 = rom_cp >> 1;
	/*A��B������д��ALU*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_ADD, REG_ALU_OUT_0);
	/*���д��ALU���Ϊ0, REG_0��ֵ��1��д��REG_ALU_OUT_1*/
	A_ASGN__RF(REG_ALU_OUT_0);
	B_ASGN_IMMNUM(0);
	label_0 = rom_cp;
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
	A_ASGN__RF(REG_0);
	_RF_ASGN_ALU(REG_ALU_OUT_1, ALU_A_ADD_1);
	MODIFY_A2A1A0(label_0, rom_cp >> 1);
	/*A��B�Ľ�λд��ALU*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_ADD_C, REG_ALU_OUT_1);
	/*REG_ALU_B��REG_ALU_OUT_0����*/
	B_ASGN_IMMNUM(0);
	A_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_A_ADD_1);
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_1*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_1);
	/*REG_ALU_A����,��������REG_ALU_OUT_0*/
	_RF_ASGN_IMMNUM(REG_0, 0);
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_2*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_2);

	/***********������ʼ��ALU_A_ADD_1��ALU_A_ADD_1_C��ALU_A_0_LSH��ALU_A_BH_LSH��ALU_B_0_LSH��ALU_OUTA��ALU_OUTB��************/

	label_0 = rom_cp >> 1;
	/*REG_ALU_A��1���ALU������ݸ��¸�Ŀ��*/
	B_ASGN_IMMNUM(1);
	A_ASGN__RF(REG_ALU_A);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_ADD);
	_RF_ASGN_ALU(REG_ALU_OUT_1, ALU_ADD_C);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_A_ADD_1, REG_ALU_OUT_0);
	ALU_ASGN__RF(ALU_A_ADD_1_C, REG_ALU_OUT_1);
	/*REG_ALU_A��0����1λ������ݸ��¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN_RF();
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_ADD);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_A_0_LSH, REG_ALU_OUT_0);
	/*REG_ALU_B��0����1λ������ݸ��¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_B);
	_RF_ASGN_ALU(REG_0, ALU_ADD_C);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_ADD);
	A_ASGN__RF(REG_ALU_A);
	ALU_ASGN__RF(ALU_B_0_LSH, REG_ALU_OUT_0);
	/*REG_ALU_A��B���λ����1λ������ݸ��¸�Ŀ��*/
	A_ASGN_ALU(ALU_A_0_LSH);
	B_ASGN__RF(REG_0);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_ADD);
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_A_BH_LSH, REG_ALU_OUT_0);
	/*REG_ALU_A��REG_ALU_B���ݸ��¸�Ŀ��*/
	ALU_ASGN__RF(ALU_OUTA, REG_ALU_A);
	ALU_ASGN__RF(ALU_OUTB, REG_ALU_B);
	/*REG_ALU_B����*/
	B_ASGN_IMMNUM(0);
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/*******************************������ʼ��ALU_A_NOT��********************************/

	label_0 = rom_cp >> 1;
	/*��ʼ������ֵ*/
	_RF_ASGN_IMMNUM(REG_0, -8);
	A_ASGN__RF(REG_ALU_A);
	_RF_ASGN_ALU(REG_1, ALU_OUTA);
	label_1 = rom_cp >> 1;
	/*REG_ALU_OUT_0����1λ*/
	A_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_A_0_LSH);
	/*���REG_1���λ��Ϊ1,REG_ALU_OUT_0��1*/
	A_ASGN__RF(REG_1);
	B_ASGN_RF();
	A_ASGN_ALU(ALU_ADD_C);
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_EQUAL_C);
	B_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_ADD);
	/*REG_1����1λ*/
	A_ASGN__RF(REG_1);
	RF_ASGN_ALU(ALU_A_0_LSH);
	/*REG_0����*/
	A_ASGN__RF(REG_0);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_0��Ϊ0��ת����label_1*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_1);
	label_2 = rom_cp >> 1;
	/*REG_ALU_Aȡ��������ݸ��¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_A_NOT, REG_ALU_OUT_0);
	/*REG_ALU_B����*/
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_2*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_2);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/*************************������ʼ��ALU_SUB���ALU_SUB_C��**************************/

	label_0 = rom_cp >> 1;
	/*REG_ALU_A������REG_ALU_B���,�������ٷ�����¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	A_ASGN_ALU(ALU_A_NOT);
	_RF_ASGN_ALU(REG_ALU_OUT_1, ALU_ADD_C);
	A_ASGN_ALU(ALU_ADD);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_A_NOT);
	A_ASGN__RF(REG_ALU_A);
	ALU_ASGN__RF(ALU_SUB, REG_ALU_OUT_0);
	ALU_ASGN__RF(ALU_SUB_C, REG_ALU_OUT_1);
	/*REG_ALU_B����*/
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_0*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/*********************������ʼ��ALU_A_SUB_1��ALU_A_SUB_1_C��ALU_EQUAL_C��**********************/

	label_0 = rom_cp >> 1;
	/*REG_ALU_A��1���ALU������ݸ��¸�Ŀ��*/
	B_ASGN_IMMNUM(1);
	A_ASGN__RF(REG_ALU_A);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_SUB);
	_RF_ASGN_ALU(REG_ALU_OUT_1, ALU_SUB_C);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_A_SUB_1, REG_ALU_OUT_0);
	ALU_ASGN__RF(ALU_A_SUB_1_C, REG_ALU_OUT_1);
	/*REG_ALU_A��REG_ALU_B��ͬ�����0x01��Ŀ��,����д��Ŀ�����0x00*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	A_ASGN_ALU(ALU_SUB);
	B_ASGN_IMMNUM(0);
	label_1 = rom_cp;
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, 0);
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	_RF_ASGN_IMMNUM(REG_ALU_OUT_0, 0x01);
	ALU_ASGN_RF(ALU_EQUAL_C);
	label_2 = rom_cp;
	PC_ASGN_IMMNUM(0);
	MODIFY_A2A1A0(label_1, rom_cp >> 1);
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	_RF_ASGN_IMMNUM(REG_ALU_OUT_0, 0x00);
	ALU_ASGN_RF(ALU_EQUAL_C);
	MODIFY_A2A1A0(label_2, rom_cp >> 1);
	/*REG_ALU_B����*/
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_0*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/*******************************������ʼ��ALU_AND��ALU_OR��ALU_XOR��********************************/

	label_0 = rom_cp >> 1;
	/*��ʼ������ֵ*/
	_RF_ASGN_IMMNUM(REG_0, -8);
	A_ASGN__RF(REG_ALU_A);
	_RF_ASGN_ALU(REG_1, ALU_OUTA);
	A_ASGN__RF(REG_ALU_B);
	_RF_ASGN_ALU(REG_2, ALU_OUTA);
	label_1 = rom_cp >> 1;
	/*REG_ALU_OUT_0��REG_ALU_OUT_1����1λ*/
	A_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_A_0_LSH);
	A_ASGN__RF(REG_ALU_OUT_1);
	RF_ASGN_ALU(ALU_A_0_LSH);
	/*���REG_1��REG_2���λ����1,REG_ALU_OUT_0��1*/
	A_ASGN__RF(REG_1);
	B_ASGN_RF();
	A_ASGN_ALU(ALU_ADD_C);
	B_ASGN_IMMNUM(0);
	_RF_ASGN_ALU(REG_3, ALU_EQUAL_C);
	A_ASGN__RF(REG_2);
	B_ASGN_RF();
	A_ASGN_ALU(ALU_ADD_C);
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_EQUAL_C);
	B_ASGN__RF(REG_3);
	A_ASGN_ALU(ALU_ADD);
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_EQUAL_C);
	B_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_ADD);
	/*���REG_1��REG_2���λ��ͬ,REG_ALU_OUT_1��1*/
	A_ASGN__RF(REG_1);
	B_ASGN_RF();
	_RF_ASGN_ALU(REG_3, ALU_ADD_C);
	A_ASGN__RF(REG_2);
	B_ASGN_RF();
	A_ASGN_ALU(ALU_ADD_C);
	B_ASGN__RF(REG_3);
	A_ASGN_ALU(ALU_SUB);
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_EQUAL_C);
	B_ASGN__RF(REG_ALU_OUT_1);
	RF_ASGN_ALU(ALU_ADD);
	/*REG_1��REG_2����1λ*/
	A_ASGN__RF(REG_1);
	RF_ASGN_ALU(ALU_A_0_LSH);
	A_ASGN__RF(REG_2);
	RF_ASGN_ALU(ALU_A_0_LSH);
	/*REG_0����*/
	A_ASGN__RF(REG_0);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_0��Ϊ0��ת����label_1*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_1);
	/*REG_ALU_A��REG_ALU_B���������ݸ��¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_AND, REG_ALU_OUT_0);
	/*REG_ALU_A��REG_ALU_B����������ȡ�����¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_A_NOT);
	A_ASGN__RF(REG_ALU_B);
	B_ASGN_ALU(ALU_A_NOT);
	A_ASGN__RF(REG_ALU_A);
	A_ASGN_ALU(ALU_A_NOT);
	ALU_ASGN__RF(ALU_OR, REG_ALU_OUT_0);
	/*REG_ALU_A��REG_ALU_Bͬ��������ȡ�����¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_OUT_1);
	RF_ASGN_ALU(ALU_A_NOT);
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_XOR, REG_ALU_OUT_1);
	/*REG_ALU_B����*/
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_0*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/********************************������ʼ��ALU_MUL_L��ALU_MUL_H��ALU_DIV��ALU_MOD��*********************************/

	label_0 = rom_cp >> 1;
	/*--------------����˷�--------------*/
	/*��ʼ������ֵ*/
	_RF_ASGN_IMMNUM(REG_0, -8);
	A_ASGN__RF(REG_ALU_A);
	_RF_ASGN_ALU(REG_1, ALU_OUTA);
	_RF_ASGN_IMMNUM(REG_ALU_OUT_1, 0);
	_RF_ASGN_IMMNUM(REG_ALU_OUT_0, 0);
	label_1 = rom_cp >> 1;
	/*REG_ALU_OUT_1��REG_ALU_OUT_0���λ��ͬ����1λ*/
	A_ASGN__RF(REG_ALU_OUT_1);
	B_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_B_0_LSH);
	_RF_ASGN_ALU(REG_ALU_OUT_1, ALU_A_BH_LSH);
	/*���REG_1���λΪ1,��REG_ALU_B��ֵ����REG_ALU_OUT_1��REG_ALU_OUT_0��ɵ�16λ����*/
	A_ASGN__RF(REG_1);
	B_ASGN_RF();
	label_2 = rom_cp;
	IFALU_PC_ASGN_IMMNUM(ALU_ADD_C, 0);
	A_ASGN__RF(REG_ALU_B);
	B_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_ADD);
	B_ASGN_ALU(ALU_ADD_C);
	A_ASGN__RF(REG_ALU_OUT_1);
	RF_ASGN_ALU(ALU_ADD);
	MODIFY_A2A1A0(label_2, rom_cp >> 1);
	/*REG_1����1λ*/
	A_ASGN__RF(REG_1);
	RF_ASGN_ALU(ALU_A_0_LSH);
	/*REG_0����*/
	A_ASGN__RF(REG_0);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_0��Ϊ0��ת����label_1*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_1);
	/*REG_ALU_A��REG_ALU_B��˺�����ݸ��¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_MUL_H, REG_ALU_OUT_1);
	ALU_ASGN__RF(ALU_MUL_L, REG_ALU_OUT_0);
	/*--------------�������--------------*/
	/*��ʼ������ֵ*/
	_RF_ASGN_IMMNUM(REG_0, -8);
	A_ASGN__RF(REG_ALU_A);
	_RF_ASGN_ALU(REG_1, ALU_OUTA);
	_RF_ASGN_IMMNUM(REG_ALU_OUT_1, 0);
	label_1 = rom_cp >> 1;
	/*REG_ALU_OUT_0����1λ*/
	A_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_A_0_LSH);
	/*REG_ALU_OUT_1��REG_1���λ��ͬ����1λ*/
	A_ASGN__RF(REG_ALU_OUT_1);
	B_ASGN__RF(REG_1);
	RF_ASGN_ALU(ALU_B_0_LSH);
	_RF_ASGN_ALU(REG_ALU_OUT_1, ALU_A_BH_LSH);
	/*���REG_ALU_OUT_1��REG_ALU_B����,REG_ALU_OUT_1��ȥREG_ALU_B����REG_ALU_OUT_0��1*/
	A_ASGN_ALU(ALU_A_BH_LSH);
	B_ASGN__RF(REG_ALU_B);
	A_ASGN_ALU(ALU_SUB_C);
	label_2 = rom_cp;
	IFALU_PC_ASGN_IMMNUM(ALU_A_NOT, 0);
	A_ASGN__RF(REG_ALU_OUT_1);
	RF_ASGN_ALU(ALU_SUB);
	A_ASGN__RF(REG_ALU_OUT_0);
	RF_ASGN_ALU(ALU_A_ADD_1);
	MODIFY_A2A1A0(label_2, rom_cp >> 1);
	/*REG_0����*/
	A_ASGN__RF(REG_0);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_0��Ϊ0��ת����label_1*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_1);
	/*REG_ALU_A����REG_ALU_B������ݸ��¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_DIV, REG_ALU_OUT_0);
	ALU_ASGN__RF(ALU_MOD, REG_ALU_OUT_1);
	/*--------------�������--------------*/
	/*REG_ALU_B����*/
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_0*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/*****************************������ʼ��ALU_A_0_RSH���ALU_A_AH_RSH��******************************/

	label_0 = rom_cp >> 1;
	/*REG_ALU_A��0����1λ������ݸ��¸�Ŀ��*/
	A_ASGN__RF(REG_ALU_A);
	B_ASGN_IMMNUM(2);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_DIV);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_A_0_RSH, REG_ALU_OUT_0);
	/*REG_ALU_A�����λ����1λ������ݸ��¸�Ŀ��*/
	B_ASGN_IMMNUM(0x80);
	A_ASGN_ALU(ALU_AND);
	B_ASGN_RF();
	RF_ASGN_ALU(ALU_ADD);
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_A_AH_RSH, REG_ALU_OUT_0);
	/*REG_ALU_B����*/
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_2*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/********************************������ʼ��ALU_B_AL_RSH��*********************************/

	label_0 = rom_cp >> 1;
	/*REG_ALU_B��REG_ALU_A���λ����1λ������ݸ��¸�Ŀ��*/
	B_ASGN_IMMNUM(128);
	A_ASGN__RF(REG_ALU_A);
	B_ASGN_ALU(ALU_MUL_L);
	A_ASGN__RF(REG_ALU_B);
	A_ASGN_ALU(ALU_A_0_RSH);
	_RF_ASGN_ALU(REG_ALU_OUT_0, ALU_ADD);
	A_ASGN__RF(REG_ALU_A);
	B_ASGN__RF(REG_ALU_B);
	ALU_ASGN__RF(ALU_B_AL_RSH, REG_ALU_OUT_0);
	/*REG_ALU_B����*/
	A_ASGN__RF(REG_ALU_B);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_B��Ϊ0��ת����label_0*/
	B_ASGN_IMMNUM(0);
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);
	/*REG_ALU_A����*/
	A_ASGN__RF(REG_ALU_A);
	RF_ASGN_ALU(ALU_A_ADD_1);
	/*���REG_ALU_A��Ϊ0��ת����label_0*/
	A_ASGN_ALU(ALU_A_ADD_1);
	IFALU_PC_ASGN_IMMNUM(ALU_EQUAL_C, label_0);

	/********************************��ʼ��ջҳָ��ֵ*********************************/

	_RF_ASGN_IMMNUM(REGISTER_FILE_SP, 0);
	sp0_init_romaddr = rom_cp - 1;
	_RF_ASGN_IMMNUM(REGISTER_FILE_SP + 1, 0);
	sp1_init_romaddr = rom_cp - 1;
}

/****************************************glowȫ�ֳ�ʼ��****************************************/

/*glowȫ�ֳ�ʼ��*/
void glow_global_init() {
	optimize = 1; //��ʼ���Ż�ѡ��
	glow_mem_alloc_init(); //��ʼ��CPU�ڴ�ʹ�ü����Ȳ���
	glow_string_init(); //��ʼ���ַ�������
	glow_regalloc_init(); //��ʼ���Ĵ����ѹ���
	ADDRDATA_ENTRY = NULL; //ȫ�ֵ�ַ�������
	arg_offset = 0; //����ƫ�Ƶ�ַ
	cseg = 0; //�μ�¼
	glow_cpu_init(); //��ʼ��CPU����
	unsigned_mul64_func_romaddr = 0; //�޷���64λ�˷�������ڵ�ַ
	unsigned_div16_func_romaddr = 0; //�޷���16λ����������ڵ�ַ
	signed_div16_func_romaddr = 0; //�з���16λ����������ڵ�ַ
	unsigned_div32_func_romaddr = 0; //�޷���32λ����������ڵ�ַ
	signed_div32_func_romaddr = 0; //�з���32λ����������ڵ�ַ
	unsigned_div64_func_romaddr = 0; //�޷���64λ����������ڵ�ַ
	signed_div64_func_romaddr = 0; //�з���64λ����������ڵ�ַ
	unsigned_mod16_func_romaddr = 0; //�޷���16λȡ�ຯ����ڵ�ַ
	signed_mod16_func_romaddr = 0; //�з���16λȡ�ຯ����ڵ�ַ
	unsigned_mod32_func_romaddr = 0; //�޷���32λȡ�ຯ����ڵ�ַ
	signed_mod32_func_romaddr = 0; //�з���32λȡ�ຯ����ڵ�ַ
	unsigned_mod64_func_romaddr = 0; //�޷���64λȡ�ຯ����ڵ�ַ
	signed_mod64_func_romaddr = 0; //�з���64λȡ�ຯ����ڵ�ַ
	float_add_func_romaddr = 0; //float�ӷ�������ڵ�ַ
	float_sub_func_romaddr = 0; //float����������ڵ�ַ
	float_mul_func_romaddr = 0; //float�˷�������ڵ�ַ
	float_div_func_romaddr = 0; //float����������ڵ�ַ
	float_cvfi_func_romaddr = 0; //float_cvfi������ڵ�ַ
	float_cvif_func_romaddr = 0; //float_cvif������ڵ�ַ
	double_add_func_romaddr = 0; //double�ӷ�������ڵ�ַ
	double_sub_func_romaddr = 0; //double����������ڵ�ַ
	double_mul_func_romaddr = 0; //double�˷�������ڵ�ַ
	double_div_func_romaddr = 0; //double����������ڵ�ַ
	double_cvfi_func_romaddr = 0; //double_cvfi������ڵ�ַ
	double_cvif_func_romaddr = 0; //double_cvif������ڵ�ַ
	float_to_double_func_romaddr = 0; //floatתdouble������ڵ�ַ
	double_to_float_func_romaddr = 0; //doubleתfloat������ڵ�ַ
}

/****************************************ROM�������CPUָ��****************************************/

#define UP_IS_RF_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x00) NOP() //�����һ��ָ��Ŀ�Ĳ�������RF�����ɿղ���ָ��
#define UP_IS_A_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x01) NOP() //�����һ��ָ��Ŀ�Ĳ�������A�Ĵ��������ɿղ���ָ��
#define UP_IS_A0_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x02) NOP() //�����һ��ָ��Ŀ�Ĳ�������A0�Ĵ��������ɿղ���ָ��
#define UP_IS_A1_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x03) NOP() //�����һ��ָ��Ŀ�Ĳ�������A1�Ĵ��������ɿղ���ָ��
#define UP_IS_A2_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x04) NOP() //�����һ��ָ��Ŀ�Ĳ�������A2�Ĵ��������ɿղ���ָ��
#define UP_IS_RA_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x05) NOP() //�����һ��ָ��Ŀ�Ĳ�������RA�Ĵ��������ɿղ���ָ��
#define UP_IS_B_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x06) NOP() //�����һ��ָ��Ŀ�Ĳ�������B�Ĵ��������ɿղ���ָ��
#define UP_IS_RAM_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x08) NOP() //�����һ��ָ��Ŀ�Ĳ�������RAM�����ɿղ���ָ��
#define UP_IS_IO0_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x0a) NOP() //�����һ��ָ��Ŀ�Ĳ�������IO0�����ɿղ���ָ��
#define UP_IS_IO1_GEN_NOP if (rom_cp > 1 && (romdata[rom_cp - 2] & 0x0f) == 0x0b) NOP() //�����һ��ָ��Ŀ�Ĳ�������IO1�����ɿղ���ָ��

/*ROM���ָ��*/
void ROM_ADD_INS(unsigned char h, unsigned char l) {
	if (rom_cp < ROM_SIZE) {
		romdata[rom_cp] = h;
		romdata[rom_cp + 1] = l;
		rom_cp_max = rom_cp += 2;
	}
	else
		rom_cp_max += 2;
}

/*************������ΪԴ����ָ��*************/

/*RF����������*/
void RF_ASGN_IMMNUM(unsigned char num) {
	//UP_IS_RA_GEN_NOP;
	UP_IS_RF_GEN_NOP;
	ROM_ADD_INS(0x00, num);
	if (((cpu.a2 & 0xffffff00) == CPU_O::REG_F && (cpu.a2 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a2 = CPU_O::REG_X;
	if (((cpu.a1 & 0xffffff00) == CPU_O::REG_F && (cpu.a1 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a1 = CPU_O::REG_X;
	if (((cpu.a0 & 0xffffff00) == CPU_O::REG_F && (cpu.a0 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a0 = CPU_O::REG_X;
}

/*A����������*/
void A_ASGN_IMMNUM(unsigned char num) {
	UP_IS_A_GEN_NOP;
	ROM_ADD_INS(0x01, num);
}

/*A0����������*/
void A0_ASGN_IMMNUM(unsigned char num) {
	UP_IS_A0_GEN_NOP;
	ROM_ADD_INS(0x02, num);
	cpu.a0 = num;
}

/*A1����������*/
void A1_ASGN_IMMNUM(unsigned char num) {
	UP_IS_A1_GEN_NOP;
	ROM_ADD_INS(0x03, num);
	cpu.a1 = num;
}

/*A2����������*/
void A2_ASGN_IMMNUM(unsigned char num) {
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x04, num);
	cpu.a2 = num;
}

/*RA����������*/
void RA_ASGN_IMMNUM(unsigned char num) {
	UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x05, num);
	cpu.ra = num;
}

/*B����������*/
void B_ASGN_IMMNUM(unsigned char num) {
	UP_IS_B_GEN_NOP;
	ROM_ADD_INS(0x06, num);
}

/*RAM����������*/
void RAM_ASGN_IMMNUM(unsigned char num) {
	UP_IS_RAM_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x08, num);
}

/*IO0����������*/
void IO0_ASGN_IMMNUM(unsigned char num) {
	UP_IS_IO0_GEN_NOP;
	ROM_ADD_INS(0x0a, num);
}

/*IO1����������*/
void IO1_ASGN_IMMNUM(unsigned char num) {
	UP_IS_IO1_GEN_NOP;
	ROM_ADD_INS(0x0b, num);
}

/*************ALUΪԴ����ָ��*************/

/*RF����ALU*/
void RF_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_A_GEN_NOP;
	UP_IS_B_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	UP_IS_RF_GEN_NOP;
	ROM_ADD_INS(0x10, aluaddr);
	if (((cpu.a2 & 0xffffff00) == CPU_O::REG_F && (cpu.a2 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a2 = CPU_O::REG_X;
	if (((cpu.a1 & 0xffffff00) == CPU_O::REG_F && (cpu.a1 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a1 = CPU_O::REG_X;
	if (((cpu.a0 & 0xffffff00) == CPU_O::REG_F && (cpu.a0 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a0 = CPU_O::REG_X;
}

/*A����ALU*/
void A_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_A_GEN_NOP;
	ROM_ADD_INS(0x11, aluaddr);
}

/*A0����ALU*/
void A0_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_A0_GEN_NOP;
	ROM_ADD_INS(0x12, aluaddr);
	cpu.a0 = CPU_O::REG_X;
}

/*A1����ALU*/
void A1_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_A1_GEN_NOP;
	ROM_ADD_INS(0x13, aluaddr);
	cpu.a1 = CPU_O::REG_X;
}

/*A2����ALU*/
void A2_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x14, aluaddr);
	cpu.a2 = CPU_O::REG_X;
}

/*RA����ALU*/
void RA_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x15, aluaddr);
	cpu.ra = CPU_O::REG_X;
}

/*B����ALU*/
void B_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_B_GEN_NOP;
	ROM_ADD_INS(0x16, aluaddr);
}

/*RAM����ALU*/
void RAM_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_A_GEN_NOP;
	UP_IS_B_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x18, aluaddr);
}

/*IO0����ALU*/
void IO0_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_IO0_GEN_NOP;
	ROM_ADD_INS(0x1a, aluaddr);
}

/*IO1����ALU*/
void IO1_ASGN_ALU(unsigned char aluaddr) {
	UP_IS_IO1_GEN_NOP;
	ROM_ADD_INS(0x1b, aluaddr);
}

/**************RFΪԴ����ָ��**************/

/*A����RF*/
void A_ASGN_RF() {
	UP_IS_A_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x21, 0xff);
}

/*A0����RF*/
void A0_ASGN_RF() {
	UP_IS_A0_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x22, 0xff);
	if (cpu.ra != CPU_O::REG_X)
		cpu.a0 = CPU_O::REG_F + cpu.ra;
	else
		cpu.a0 = CPU_O::REG_X;
}

/*A1����RF*/
void A1_ASGN_RF() {
	UP_IS_A1_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x23, 0xff);
	if (cpu.ra != CPU_O::REG_X)
		cpu.a1 = CPU_O::REG_F + cpu.ra;
	else
		cpu.a1 = CPU_O::REG_X;
}

/*A2����RF*/
void A2_ASGN_RF() {
	UP_IS_A2_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x24, 0xff);
	if (cpu.ra != CPU_O::REG_X)
		cpu.a2 = CPU_O::REG_F + cpu.ra;
	else
		cpu.a2 = CPU_O::REG_X;
}

/*RA����RF*/
void RA_ASGN_RF() {
	UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x25, 0xff);
	cpu.ra = CPU_O::REG_X;
}

/*B����RF*/
void B_ASGN_RF() {
	UP_IS_B_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x26, 0xff);
}

/*RAM����RF*/
void RAM_ASGN_RF() {
	//UP_IS_RA_GEN_NOP;
	UP_IS_RAM_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x28, 0xff);
}

/*ALU����RF*/
void ALU_ASGN_RF(unsigned char aluaddr) {
	UP_IS_A_GEN_NOP;
	UP_IS_B_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x29, aluaddr);
	//ROM_ADD_INS(0xff, aluaddr);
}

/*IO0����RF*/
void IO0_ASGN_RF() {
	UP_IS_IO0_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x2a, 0xff);
}

/*IO1����RF*/
void IO1_ASGN_RF() {
	UP_IS_IO1_GEN_NOP;
	//UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x2b, 0xff);
}

/***************RAMΪԴ����ָ��***************/

/*RF����RAM*/
void RF_ASGN_RAM(void) {
	//UP_IS_RA_GEN_NOP;
	UP_IS_RF_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x30, 0xff);
	if (((cpu.a2 & 0xffffff00) == CPU_O::REG_F && (cpu.a2 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a2 = CPU_O::REG_X;
	if (((cpu.a1 & 0xffffff00) == CPU_O::REG_F && (cpu.a1 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a1 = CPU_O::REG_X;
	if (((cpu.a0 & 0xffffff00) == CPU_O::REG_F && (cpu.a0 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a0 = CPU_O::REG_X;
}

/*A����RAM*/
void A_ASGN_RAM(void) {
	UP_IS_A_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x31, 0xff);
}

/*A0����RAM*/
void A0_ASGN_RAM(void) {
	UP_IS_A0_GEN_NOP;
	UP_IS_A1_GEN_NOP;
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x32, 0xff);
	cpu.a0 = CPU_O::REG_X;
}

/*A1����RAM*/
void A1_ASGN_RAM(void) {
	UP_IS_A0_GEN_NOP;
	UP_IS_A1_GEN_NOP;
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x33, 0xff);
	cpu.a1 = CPU_O::REG_X;
}

/*A2����RAM*/
void A2_ASGN_RAM(void) {
	UP_IS_A0_GEN_NOP;
	UP_IS_A1_GEN_NOP;
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x34, 0xff);
	cpu.a2 = CPU_O::REG_X;
}

/*RA����RAM*/
void RA_ASGN_RAM(void) {
	UP_IS_RA_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x35, 0xff);
	cpu.ra = CPU_O::REG_X;
}

/*B����RAM*/
void B_ASGN_RAM(void) {
	UP_IS_B_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x36, 0xff);
}

/*ALU����RAM*/
void ALU_ASGN_RAM(unsigned char aluaddr) {
	UP_IS_A_GEN_NOP;
	UP_IS_B_GEN_NOP;
	UP_IS_A0_GEN_NOP;
	UP_IS_A1_GEN_NOP;
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x39, aluaddr);
	//ROM_ADD_INS(0xff, aluaddr);
}

/*IO0����RAM*/
void IO0_ASGN_RAM(void) {
	UP_IS_IO0_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x3a, 0xff);
}

/*IO1����RAM*/
void IO1_ASGN_RAM(void) {
	UP_IS_IO1_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x3b, 0xff);
}

/***************IO0ΪԴ����ָ��***************/

/*RF����IO0*/
void RF_ASGN_IO0(void) {
	//UP_IS_RA_GEN_NOP;
	UP_IS_RF_GEN_NOP;
	ROM_ADD_INS(0x40, 0xff);
	if (((cpu.a2 & 0xffffff00) == CPU_O::REG_F && (cpu.a2 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a2 = CPU_O::REG_X;
	if (((cpu.a1 & 0xffffff00) == CPU_O::REG_F && (cpu.a1 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a1 = CPU_O::REG_X;
	if (((cpu.a0 & 0xffffff00) == CPU_O::REG_F && (cpu.a0 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a0 = CPU_O::REG_X;
}

/*A����IO0*/
void A_ASGN_IO0(void) {
	UP_IS_A_GEN_NOP;
	ROM_ADD_INS(0x41, 0xff);
}

/*A0����IO0*/
void A0_ASGN_IO0(void) {
	UP_IS_A0_GEN_NOP;
	ROM_ADD_INS(0x42, 0xff);
	cpu.a0 = CPU_O::REG_X;
}

/*A1����IO0*/
void A1_ASGN_IO0(void) {
	UP_IS_A1_GEN_NOP;
	ROM_ADD_INS(0x43, 0xff);
	cpu.a1 = CPU_O::REG_X;
}

/*A2����IO0*/
void A2_ASGN_IO0(void) {
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x44, 0xff);
	cpu.a2 = CPU_O::REG_X;
}

/*RA����IO0*/
void RA_ASGN_IO0(void) {
	UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x45, 0xff);
	cpu.ra = CPU_O::REG_X;
}

/*B����IO0*/
void B_ASGN_IO0(void) {
	UP_IS_B_GEN_NOP;
	ROM_ADD_INS(0x46, 0xff);
}

/*RAM����IO0*/
void RAM_ASGN_IO0(void) {
	UP_IS_RAM_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x48, 0xff);
}

/*ALU����IO0*/
void ALU_ASGN_IO0(unsigned char aluaddr) {
	UP_IS_A_GEN_NOP;
	UP_IS_B_GEN_NOP;
	ROM_ADD_INS(0x49, aluaddr);
	//ROM_ADD_INS(0xff, aluaddr);
}

/*IO0����IO0*/
void IO0_ASGN_IO0(void) {
	UP_IS_IO0_GEN_NOP;
	ROM_ADD_INS(0x4a, 0xff);
}

/*IO1����IO0*/
void IO1_ASGN_IO0(void) {
	UP_IS_IO1_GEN_NOP;
	ROM_ADD_INS(0x4b, 0xff);
}

/***************IO1ΪԴ����ָ��***************/

/*RF����IO1*/
void RF_ASGN_IO1(void) {
	//UP_IS_RA_GEN_NOP;
	UP_IS_RF_GEN_NOP;
	ROM_ADD_INS(0x50, 0xff);
	if (((cpu.a2 & 0xffffff00) == CPU_O::REG_F && (cpu.a2 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a2 = CPU_O::REG_X;
	if (((cpu.a1 & 0xffffff00) == CPU_O::REG_F && (cpu.a1 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a1 = CPU_O::REG_X;
	if (((cpu.a0 & 0xffffff00) == CPU_O::REG_F && (cpu.a0 & 255) == cpu.ra) || cpu.ra == CPU_O::REG_X)
		cpu.a0 = CPU_O::REG_X;
}

/*A����IO1*/
void A_ASGN_IO1(void) {
	UP_IS_A_GEN_NOP;
	ROM_ADD_INS(0x51, 0xff);
}

/*A0����IO1*/
void A0_ASGN_IO1(void) {
	UP_IS_A0_GEN_NOP;
	ROM_ADD_INS(0x52, 0xff);
	cpu.a0 = CPU_O::REG_X;
}

/*A1����IO1*/
void A1_ASGN_IO1(void) {
	UP_IS_A1_GEN_NOP;
	ROM_ADD_INS(0x53, 0xff);
	cpu.a1 = CPU_O::REG_X;
}

/*A2����IO1*/
void A2_ASGN_IO1(void) {
	UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x54, 0xff);
	cpu.a2 = CPU_O::REG_X;
}

/*RA����IO1*/
void RA_ASGN_IO1(void) {
	UP_IS_RA_GEN_NOP;
	ROM_ADD_INS(0x55, 0xff);
	cpu.ra = CPU_O::REG_X;
}

/*B����IO1*/
void B_ASGN_IO1(void) {
	UP_IS_B_GEN_NOP;
	ROM_ADD_INS(0x56, 0xff);
}

/*RAM����IO1*/
void RAM_ASGN_IO1(void) {
	UP_IS_RAM_GEN_NOP;
	//UP_IS_A0_GEN_NOP;
	//UP_IS_A1_GEN_NOP;
	//UP_IS_A2_GEN_NOP;
	ROM_ADD_INS(0x58, 0xff);
}

/*ALU����IO1*/
void ALU_ASGN_IO1(unsigned char aluaddr) {
	UP_IS_A_GEN_NOP;
	UP_IS_B_GEN_NOP;
	ROM_ADD_INS(0x59, aluaddr);
	//ROM_ADD_INS(0xff, aluaddr);
}

/*IO0����IO1*/
void IO0_ASGN_IO1(void) {
	UP_IS_IO0_GEN_NOP;
	ROM_ADD_INS(0x5a, 0xff);
}

/*IO1����IO1*/
void IO1_ASGN_IO1(void) {
	UP_IS_IO1_GEN_NOP;
	ROM_ADD_INS(0x5b, 0xff);
}

/***************����ת��ָ��***************/

/*PC����A2A1A0 (��������ת)*/
void PC_ASGN_A2A1A0(void) {
	ROM_ADD_INS(0x07, 0xfe);
}

/*�ж�ALU���,����PC�Ƿ����A2A1A0 (������ת),Ϊ0��ת*/
void IFALU_PC_ASGN_A2A1A0(unsigned char aluaddr) {
	//ROM_ADD_INS(0x1f, aluaddr);
	ROM_ADD_INS(0x17, aluaddr);
}

/*�ж�RF���,����PC�Ƿ����A2A1A0 (������ת),Ϊ0��ת*/
void IFRF_PC_ASGN_A2A1A0(void) {
	//ROM_ADD_INS(0x2f, 0xff);
	ROM_ADD_INS(0x27, 0xff);
}

/*�ղ���*/
void NOP() {
	ROM_ADD_INS(0xff, 0xff);
}

/*A2A1A0����������*/
void A2A1A0_ASGN_IMMNUM(unsigned long addr) {
	A2_ASGN_IMMNUM(addr >> 16);
	A1_ASGN_IMMNUM(addr >> 8);
	A0_ASGN_IMMNUM(addr);
}

/*A2A1A0����������,���Ż�*/
void A2A1A0_ASGN_IMMNUM_O(unsigned long addr) {
	if (optimize == 0 || ((addr >> 16) & 0xff) != cpu.a2)
		A2_ASGN_IMMNUM(addr >> 16);
	if (optimize == 0 || ((addr >> 8) & 0xff) != cpu.a1)
		A1_ASGN_IMMNUM(addr >> 8);
	if (optimize == 0 || (addr & 0xff) != cpu.a0)
		A0_ASGN_IMMNUM(addr);
}

/*PC����������(��������ת)*/
void PC_ASGN_IMMNUM(unsigned long a2a1a0_addr) {
	A2A1A0_ASGN_IMMNUM(a2a1a0_addr);
	PC_ASGN_A2A1A0();
	reset_cpu_o();
}

/*�ж�ALU���,����PC�Ƿ���������� (������ת),Ϊ0��ת*/
void IFALU_PC_ASGN_IMMNUM(unsigned char aluaddr, unsigned long a2a1a0_addr) {
	A2A1A0_ASGN_IMMNUM(a2a1a0_addr);
	IFALU_PC_ASGN_A2A1A0(aluaddr);
	reset_cpu_o();
}

/*�ж�RF���,����PC�Ƿ���������� (������ת),Ϊ0��ת*/
void IFRF_PC_ASGN_IMMNUM(unsigned long a2a1a0_addr) {
	A2A1A0_ASGN_IMMNUM(a2a1a0_addr);
	IFRF_PC_ASGN_A2A1A0();
	reset_cpu_o();
}

/*�޸�A2A1A0*/
void MODIFY_A2A1A0(unsigned long romaddr, unsigned long addr) {
	romdata[romaddr + 1] = addr >> 16;
	romdata[romaddr + 3] = addr >> 8;
	romdata[romaddr + 5] = addr;
	reset_cpu_o();
}

/***************RFΪԴ����ָ��(��RF��ַ)***************/

/*A����RF*/
void A_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	A_ASGN_RF();
}

/*A0����RF*/
void A0_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	A0_ASGN_RF();
}

/*A1����RF*/
void A1_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	A1_ASGN_RF();
}

/*A2����RF*/
void A2_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	A2_ASGN_RF();
}

/*RA����RF*/
void RA_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	RA_ASGN_RF();
}

/*B����RF*/
void B_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	B_ASGN_RF();
}

/*RAM����RF*/
void RAM_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	RAM_ASGN_RF();
}

/*ALU����RF*/
void ALU_ASGN__RF(unsigned char aluaddr, unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	ALU_ASGN_RF(aluaddr);
}

/*IO0����RF*/
void IO0_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	IO0_ASGN_RF();
}

/*IO1����RF*/
void IO1_ASGN__RF(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	IO1_ASGN_RF();
}

/****************RFΪĿ�Ĵ���ָ��(��RF��ַ)****************/

/*RF����������*/
void _RF_ASGN_IMMNUM(unsigned char ra, unsigned char num) {
	RA_ASGN_IMMNUM(ra);
	RF_ASGN_IMMNUM(num);
}

/*RF����ALU*/
void _RF_ASGN_ALU(unsigned char ra, unsigned char aluaddr) {
	RA_ASGN_IMMNUM(ra);
	RF_ASGN_ALU(aluaddr);
}

/*RF����RAM*/
void _RF_ASGN_RAM(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	RF_ASGN_RAM();
}

/*RF����IO0*/
void _RF_ASGN_IO0(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	RF_ASGN_IO0();
}

/*RF����IO1*/
void _RF_ASGN_IO1(unsigned char ra) {
	RA_ASGN_IMMNUM(ra);
	RF_ASGN_IO1();
}

/****************RAMΪԴ����ָ��(��RAM��ַ)****************/

/*RF����RAM*/
void RF_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	RF_ASGN_RAM();
}

/*A����RAM*/
void A_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	A_ASGN_RAM();
}

/*A0����RAM*/
void A0_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	A0_ASGN_RAM();
}

/*A1����RAM*/
void A1_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	A1_ASGN_RAM();
}

/*A2����RAM*/
void A2_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	A2_ASGN_RAM();
}

/*RA����RAM*/
void RA_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	RA_ASGN_RAM();
}

/*B����RAM*/
void B_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	B_ASGN_RAM();
}

/*ALU����RAM*/
void ALU_ASGN__RAM(unsigned char aluaddr, unsigned long ramaddr) {
	A2A1A0_ASGN_IMMNUM(ramaddr);
	ALU_ASGN_RAM(aluaddr);
}

/*IO0����RAM*/
void IO0_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	IO0_ASGN_RAM();
}

/*IO1����RAM*/
void IO1_ASGN__RAM(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	IO1_ASGN_RAM();
}

/****************RAMΪĿ�Ĵ���ָ��(��RAM��ַ)****************/

/*RAM����������*/
void _RAM_ASGN_IMMNUM(unsigned long addr, unsigned char num) {
	A2A1A0_ASGN_IMMNUM(addr);
	RAM_ASGN_IMMNUM(num);
}

/*RAM����ALU*/
void _RAM_ASGN_ALU(unsigned long ramaddr, unsigned char aluaddr) {
	A2A1A0_ASGN_IMMNUM(ramaddr);
	RAM_ASGN_ALU(aluaddr);
}

/*RAM����RF*/
void _RAM_ASGN_RF(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	RAM_ASGN_RF();
}

/*RAM����IO0*/
void _RAM_ASGN_IO0(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	RAM_ASGN_IO0();
}

/*RAM����IO1*/
void _RAM_ASGN_IO1(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM(addr);
	RAM_ASGN_IO1();
}

/****************RAM��RF����ָ��(��RAM��RF��ַ)****************/

/*RAM����RF*/
void _RAM_ASGN__RF(unsigned long ramaddr, unsigned char ra) {
	A2A1A0_ASGN_IMMNUM(ramaddr);
	RAM_ASGN__RF(ra);
}

/*RF����RAM*/
void _RF_ASGN__RAM(unsigned char ra, unsigned long ramaddr) {
	RA_ASGN_IMMNUM(ra);
	A2A1A0_ASGN_IMMNUM(ramaddr);
	RF_ASGN_RAM();
}

/****************A0ΪĿ�Ĵ���ָ��,���Ż�****************/

void A0_ASGN_IMMNUM_O(unsigned char num) {
	if (optimize == 0 || num != cpu.a0)
		A0_ASGN_IMMNUM(num);
}

/****************RFΪԴ����ָ��(��RF��ַ),���Ż�****************/

/*A����RF*/
void A_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	A_ASGN_RF();
}

/*A0����RF*/
void A0_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || cpu.a0 != CPU_O::REG_F + ra) {
		if (optimize == 0 || ra != cpu.ra)
			RA_ASGN_IMMNUM(ra);
		A0_ASGN_RF();
	}
}

/*A1����RF*/
void A1_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || cpu.a1 != CPU_O::REG_F + ra) {
		if (optimize == 0 || ra != cpu.ra)
			RA_ASGN_IMMNUM(ra);
		A1_ASGN_RF();
	}
}

/*A2����RF*/
void A2_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || cpu.a2 != CPU_O::REG_F + ra) {
		if (optimize == 0 || ra != cpu.ra)
			RA_ASGN_IMMNUM(ra);
		A2_ASGN_RF();
	}
}

/*RA����RF*/
void RA_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RA_ASGN_RF();
}

/*B����RF*/
void B_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	B_ASGN_RF();
}

/*RAM����RF*/
void RAM_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RAM_ASGN_RF();
}

/*ALU����RF*/
void ALU_ASGN__RF_O(unsigned char aluaddr, unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	ALU_ASGN_RF(aluaddr);
}

/*IO0����RF*/
void IO0_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	IO0_ASGN_RF();
}

/*IO1����RF*/
void IO1_ASGN__RF_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	IO1_ASGN_RF();
}

/****************RFΪĿ�Ĵ���ָ��(��RF��ַ),���Ż�****************/

/*RF����������*/
void _RF_ASGN_IMMNUM_O(unsigned char ra, unsigned char num) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RF_ASGN_IMMNUM(num);
}

/*RF����ALU*/
void _RF_ASGN_ALU_O(unsigned char ra, unsigned char aluaddr) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RF_ASGN_ALU(aluaddr);
}

/*RF����RAM*/
void _RF_ASGN_RAM_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RF_ASGN_RAM();
}

/*RF����IO0*/
void _RF_ASGN_IO0_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RF_ASGN_IO0();
}

/*RF����IO1*/
void _RF_ASGN_IO1_O(unsigned char ra) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RF_ASGN_IO1();
}

/****************RAMΪԴ����ָ��(��RAM��ַ),���Ż�****************/

/*RF����RAM*/
void RF_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	RF_ASGN_RAM();
}

/*A����RAM*/
void A_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	A_ASGN_RAM();
}

/*A0����RAM*/
void A0_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	A0_ASGN_RAM();
}

/*A1����RAM*/
void A1_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	A1_ASGN_RAM();
}

/*A2����RAM*/
void A2_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	A2_ASGN_RAM();
}

/*RA����RAM*/
void RA_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	RA_ASGN_RAM();
}

/*B����RAM*/
void B_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	B_ASGN_RAM();
}

/*ALU����RAM*/
void ALU_ASGN__RAM_O(unsigned char aluaddr, unsigned long ramaddr) {
	A2A1A0_ASGN_IMMNUM_O(ramaddr);
	ALU_ASGN_RAM(aluaddr);
}

/*IO0����RAM*/
void IO0_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	IO0_ASGN_RAM();
}

/*IO1����RAM*/
void IO1_ASGN__RAM_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	IO1_ASGN_RAM();
}

/****************RAMΪĿ�Ĵ���ָ��(��RAM��ַ),���Ż�****************/

/*RAM����������*/
void _RAM_ASGN_IMMNUM_O(unsigned long addr, unsigned char num) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	RAM_ASGN_IMMNUM(num);
}

/*RAM����ALU*/
void _RAM_ASGN_ALU_O(unsigned long ramaddr, unsigned char aluaddr) {
	A2A1A0_ASGN_IMMNUM_O(ramaddr);
	RAM_ASGN_ALU(aluaddr);
}

/*RAM����RF*/
void _RAM_ASGN_RF_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	RAM_ASGN_RF();
}

/*RAM����IO0*/
void _RAM_ASGN_IO0_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	RAM_ASGN_IO0();
}

/*RAM����IO1*/
void _RAM_ASGN_IO1_O(unsigned long addr) {
	A2A1A0_ASGN_IMMNUM_O(addr);
	RAM_ASGN_IO1();
}

/****************RAM��RF����ָ��(��RAM��RF��ַ),���Ż�****************/

/*RAM����RF*/
void _RAM_ASGN__RF_O(unsigned long ramaddr, unsigned char ra) {
	A2A1A0_ASGN_IMMNUM_O(ramaddr);
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	RAM_ASGN_RF();
}

/*RF����RAM*/
void _RF_ASGN__RAM_O(unsigned char ra, unsigned long ramaddr) {
	if (optimize == 0 || ra != cpu.ra)
		RA_ASGN_IMMNUM(ra);
	A2A1A0_ASGN_IMMNUM_O(ramaddr);
	RF_ASGN_RAM();
}
