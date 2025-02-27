#include "c.h"
#include <stdio.h> //C��׼��

static char rcsid[] = "$Id$";

#define equalp(x) v.x == p->sym.u.c.v.x


struct entry {
	struct symbol sym;
	struct entry* link;
};
/*���ű�*/
struct table {
	int level; //���ű�������
	Table previous; //ָ���ϸ����ű�
	struct entry *buckets[256]; //��ǰ��������Ź�ϣ�������ָ��
	Symbol all; //��ǰ��������ϸ������������������
};
#define HASHSIZE NELEMS(((Table)0)->buckets) //HASHSIZE = 256
static struct table
cns = { CONSTANTS },
ext = { GLOBAL },
ids = { GLOBAL },
tys = { GLOBAL };
Table constants = &cns;  //�������ű�
Table externals = &ext;  //extern���ű�
Table identifiers = &ids;  //ָ���ڲ�ķ��ű�
Table globals = &ids;  //�ļ���������ű�
Table types = &tys;  //���ͱ�Ƿ��ű�
Table labels;  //�ڲ���ŷ��ű�
int level = GLOBAL; //��ǰ������
static int tempid;
List loci, symbols;

static int label;

void sym_init(void)
{
	int i;

	cns = { CONSTANTS };
	cns.previous = 0;
	cns.all = 0;
	for (i = 0; i < 256; ++i) cns.buckets[i] = 0;

	ext = { GLOBAL };
	ext.previous = 0;
	ext.all = 0;
	for (i = 0; i < 256; ++i) ext.buckets[i] = 0;

	ids = { GLOBAL };
	ids.previous = 0;
	ids.all = 0;
	for (i = 0; i < 256; ++i) ids.buckets[i] = 0;

	tys = { GLOBAL };
	tys.previous = 0;
	tys.all = 0;
	for (i = 0; i < 256; ++i) tys.buckets[i] = 0;

	constants = &cns;
	externals = &ext;
	identifiers = &ids;
	globals = &ids;
	types = &tys;
	labels = 0;
	level = GLOBAL;
	int tempid;
	loci = 0;
	symbols = 0;

	label = 1;
}

/*����һ��table,��������ָ��,arenaΪ������*/
Table newtable(int arena) {
	Table _new;
	//NEW0(_new, arena);
	//memset(_new = (Table)allocate(sizeof * _new, arena), 0, sizeof * _new);
	_new = (Table)allocate(sizeof * _new, arena);
	int i = sizeof * _new;
	memset(_new, 0, i);
	return _new;
}

/*����һ��table,����tpָ���table,��������ָ��,levelΪ�µ�������*/
Table table(Table tp, int level) {
	Table _new = newtable(FUNC);
	_new->previous = tp;
	_new->level = level;
	if (tp)
		_new->all = tp->all;
	return _new;
}

/*��ָ���������е����з���ִ�и�������*/
void foreach(Table tp, int lev, void (*apply)(Symbol, void*), void* cl) {
	assert(tp);
	while (tp && tp->level > lev) //tp���ڲ�ͬ����lev
		tp = tp->previous;
	if (tp && tp->level == lev) {
		Symbol p;
		Coordinate sav;
		sav = src;
		for (p = tp->all; p && p->scope == lev; p = p->up) { //�ò�ķ��Ŷ�����(*apply)(p, cl)
			src = p->src; //src���������(*apply)(p, cl)
			(*apply)(p, cl);
		}
		src = sav;
	}
}

/*����һ���µ�������*/
void enterscope(void) {
	if (++level == LOCAL)
		tempid = 0;  //����ֲ�����������ü�������
}

/*�˳���ǰ������*/
void exitscope(void) {
	rmtypes(level);
	if (types->level == level)
		types = types->previous;
	if (identifiers->level == level) {
		if (Aflag >= 2) {
			int n = 0;
			Symbol p;
			for (p = identifiers->all; p && p->scope == level; p = p->up)
				if (++n > 127) {
					warning("more than 127 identifiers declared in a block\n");
					break;
				}
		}
		identifiers = identifiers->previous;
	}
	assert(level >= GLOBAL);
	--level;
}

/*����һ������,������һ���÷��ŵ�Symbol, nameΪ��������,tppΪ���ڷ��ű�,levelΪ��ǰ��,arenaΪ������*/
Symbol install(const char* name, Table* tpp, int level, int arena) {
	Table tp = *tpp;
	struct entry* p;
	unsigned h = (unsigned long)name & (HASHSIZE - 1);

	assert(level == 0 || level >= tp->level);
	if (level > 0 && tp->level < level)  //С��level�����½�һ��table
		tp = *tpp = table(tp, level);
	//NEW0(p, arena);
	memset(p = (entry*)allocate(sizeof * p, arena), 0, sizeof * p);
	p->sym.name = (char*)name;
	p->sym.scope = level;
	p->sym.up = tp->all;
	tp->all = &p->sym;
	p->link = tp->buckets[h];
	tp->buckets[h] = p;
	return &p->sym;
}

/*��srcָ��ķ��ű����һ����Ϊname�ķ��ų����Ž�dstָ��ķ��ű�,�����ظ÷��ŵ�ָ��*/
Symbol relocate(const char* name, Table src, Table dst) {
	struct entry *p, ** q;
	Symbol* r;
	unsigned h = (unsigned long)name & (HASHSIZE - 1);

	for (q = &src->buckets[h]; *q; q = &(*q)->link)  //��srcָ��ķ��Ź�ϣ����������Ϊname�ķ���
		if (name == (*q)->sym.name)
			break;
	assert(*q);
	/*
	 Remove the entry from src's hash chain
	  and from its list of all symbols.
	*/

	p = *q;
	*q = (*q)->link;  //�ӹ�ϣ��������
	for (r = &src->all; *r && *r != &p->sym; r = &(*r)->up)  //��symbol��������
		;
	assert(*r == &p->sym);
	*r = p->sym.up;

	/*
	 Insert the entry into dst's hash chain
	  and into its list of all symbols.
	  Return the symbol-table entry.
	*/
	p->link = dst->buckets[h];
	dst->buckets[h] = p;
	p->sym.up = dst->all;
	dst->all = &p->sym;
	return &p->sym;
}

/*�ڱ��в���һ������,������һ���÷��ŵ�Symbol, nameΪ��������,tpΪ���ڷ��ű�*/
Symbol lookup(const char* name, Table tp) {
	struct entry* p;
	unsigned h = (unsigned long)name & (HASHSIZE - 1);

	assert(tp);
	do
		for (p = tp->buckets[h]; p; p = p->link)
			if (name == p->sym.name)
				return &p->sym;
	while ((tp = tp->previous) != NULL);
	return NULL;
}

/*����һ���ۼӼ��������*/
int genlabel(int n) {
	//static int label = 1;

	label += n;
	return label - n;
}

/*labels�����һ�����,���û���ҵ����½�һ��ͬʱ֪ͨ������,�����ظ÷��ŵ�ָ��,labΪ�����*/
Symbol findlabel(int lab) {
	struct entry* p;
	unsigned h = lab & (HASHSIZE - 1);

	for (p = labels->buckets[h]; p; p = p->link)
		if (lab == p->sym.u.l.label)
			return &p->sym;
	//NEW0(p, FUNC);
	memset(p = (entry*)allocate(sizeof * p, FUNC), 0, sizeof * p);
	p->sym.name = stringd(lab);
	p->sym.scope = LABELS;
	p->sym.up = labels->all;
	labels->all = &p->sym;
	p->link = labels->buckets[h];
	labels->buckets[h] = p;
	p->sym.generated = 1;  //��־Ϊ��������������ɵ��ַ���
	p->sym.u.l.label = lab;  //��������
	(*IR->_defsymbol)(&p->sym);
	return &p->sym;
}

/*constants���в�������ty��ֵv�ĳ�������,���û���ҵ����½�һ��ͬʱ֪ͨ������,�����ظ÷��ŵ�ָ��,*/
Symbol constant(Type ty, Value v) {
	struct entry* p;
	unsigned h = v.u & (HASHSIZE - 1);
	static union { int x; char endian; } little = { 1 };

	ty = unqual(ty);  //���ty->op >= _CONST����ty->type,���򷵻�ty,��ȥ�������е�const��volatile
	for (p = constants->buckets[h]; p; p = p->link)
		if (eqtype(ty, p->sym.type, 1)) //tyָ��ĵ�ַ��p->sym.type�ĵ�ַһ��?
			switch (ty->op) {  //��ty->op��ʲô����ѡ��Ƚϵ�����
			case _INT:      if (equalp(i)) return &p->sym; break;  //i��long
			case _UNSIGNED: if (equalp(u)) return &p->sym; break;  //u��unsigned long
			case _FLOAT:
				if (v.d == 0.0) {
					float z1 = v.d, z2 = p->sym.u.c.v.d;
					char* b1 = (char*)&z1, * b2 = (char*)&z2;
					if (z1 == z2
						&& (!little.endian && b1[0] == b2[0]
							|| little.endian && b1[sizeof(z1) - 1] == b2[sizeof(z2) - 1]))
						return &p->sym;
				}
				else if (equalp(d)) //d��long double
					return &p->sym;
				break;
			case _FUNCTION: if (equalp(g)) return &p->sym; break;  //g��void (*g)(void)
			case _ARRAY:
			case _POINTER:  if (equalp(p)) return &p->sym; break;  //p��void*
			default: assert(0);
			}
	//NEW0(p, PERM);
	memset(p = (entry*)allocate(sizeof * p, PERM), 0, sizeof* p);
	p->sym.name = vtoa(ty, v);
	p->sym.scope = CONSTANTS;
	p->sym.type = ty;
	p->sym.sclass = STATIC;
	p->sym.u.c.v = v;
	p->link = constants->buckets[h];
	p->sym.up = constants->all;
	constants->all = &p->sym;
	constants->buckets[h] = p;
	if (ty->u.sym && !ty->u.sym->addressed)
		(*IR->_defsymbol)(&p->sym);
	p->sym.defined = 1; //֪ͨ����֮��defined��־��1
	return &p->sym;
}

/*intconst��װ�˽�����֪ͨ���ͳ����Ĺ���*/
Symbol intconst(int n) {
	Value v;

	v.i = n;
	return constant(inttype, v);
}

/*����һ�����Žṹ����ʼ��(�����ľֲ�����),sclsΪ���ŵ���չ�洢����,tyΪ����,levΪ���ڲ�,���ΪGLOBAL��֪ͨ������,��󷵻ظ÷��ŵ�ָ��*/
Symbol genident(int scls, Type ty, int lev) {
	Symbol p;

	//NEW0(p, lev >= LOCAL ? FUNC : PERM);
	memset(p = (Symbol)allocate(sizeof * p, lev >= LOCAL ? FUNC : PERM), 0, sizeof * p);
	p->name = stringd(genlabel(1));
	p->scope = lev;
	p->sclass = scls;
	p->type = ty;
	p->generated = 1;  //��־Ϊ��������������ɵ��ַ���
	if (lev == GLOBAL)
		(*IR->_defsymbol)(p);
	return p;
}

/*����һ�����Žṹ����ʼ��(��������ʱ����),sclsΪ���ŵ���չ�洢����,tyΪ����,��󷵻ظ÷��ŵ�ָ��*/
Symbol temporary(int scls, Type ty) {
	Symbol p;

	//NEW0(p, FUNC);
	memset(p = (Symbol)allocate(sizeof *p, FUNC), 0, sizeof *p);
	p->name = stringd(++tempid);
	p->scope = level < LOCAL ? LOCAL : level;
	p->sclass = scls;
	p->type = ty;
	p->temporary = 1;  //�ú����ı�־
	p->generated = 1;  //��־Ϊ��������������ɵ��ַ���
	return p;
}

/*newtemp��������ʹ��,����һ�����Žṹ����ʼ��(��������ʱ����),ͬʱ֪ͨ������,��󷵻ظ÷��ŵ�ָ��*/
Symbol newtemp(int sclass, int tc, int size) {
	Symbol p = temporary(sclass, btot(tc, size));  //btot���ú�׺ӳ��Ϊ��Ӧ����

	(*IR->_local)(p);
	p->defined = 1;  //֪ͨ����֮��defined��־��1
	return p;
}

Symbol allsymbols(Table tp) {
	return tp->all;
}

void locus(Table tp, Coordinate* cp) {
	loci = append(cp, loci);
	symbols = append(allsymbols(tp), symbols);
}

/*��Symbolָ��ͷ��Ŷ�λsrc,���ӷ��ŵ�ʹ�����uses*/
void use(Symbol p, Coordinate src) {
	Coordinate* cp;

	//NEW(cp, PERM);
	cp = (Coordinate*) allocate(sizeof * cp, PERM);
	*cp = src;
	p->uses = append(cp, p->uses);
}

/* findtype - find type ty in identifiers */
/*identifiers����������ty�ķ���,���ظ÷��ŵ�ָ��,����(p->sym.sclass == TYPEDEF)*/
Symbol findtype(Type ty) {
	Table tp = identifiers;
	int i;
	struct entry* p;

	assert(tp);
	do
		for (i = 0; i < HASHSIZE; i++)
			for (p = tp->buckets[i]; p; p = p->link)
				if (p->sym.type == ty && p->sym.sclass == TYPEDEF)
					return &p->sym;
	while ((tp = tp->previous) != NULL);
	return NULL;
}

/* mkstr - make a string constant */
/*mkstr - �����ַ�������,���ظ�symbolָ��*/
Symbol mkstr(char* str) {
	Value v;
	Symbol p;

	v.p = str;
	p = constant(array(chartype, strlen((char*)v.p) + 1, 0), v);
	if (p->u.c.loc == NULL)
		p->u.c.loc = genident(STATIC, p->type, GLOBAL);
	return p;
}

/* mksymbol - make a symbol for name, install in &globals if sclass==EXTERN */
/* mksymbol - Ϊ��������һ�����ţ����sclass==EXTERN����װ��globals��,ͬʱ֪ͨ������,sclassΪ��չ�洢����,nameΪ����,tyΪ����,���ظ�symbolָ�� */
Symbol mksymbol(int sclass, const char* name, Type ty) {
	Symbol p;

	if (sclass == EXTERN)
		p = install(string(name), &globals, GLOBAL, PERM);
	else {
		//NEW0(p, PERM);
		memset(p = (Symbol) allocate(sizeof *p, PERM), 0, sizeof *p);
		p->name = string(name);
		p->scope = GLOBAL;
	}
	p->sclass = sclass;
	p->type = ty;
	(*IR->_defsymbol)(p);
	p->defined = 1;  //֪ͨ����֮��defined��־��1
	return p;
}

/* vtoa - return string for the constant v of type ty */
/*������ty��ֵv������Ӧ���ַ���*/
char* vtoa(Type ty, Value v) {
	ty = unqual(ty);
	switch (ty->op) {
	case _INT:      return stringd(v.i);
	case _UNSIGNED: return stringf((v.u & ~0x7FFF) ? "0x%X" : "%U", v.u);
	case _FLOAT:    return stringf("%g", (double)v.d);
	case _ARRAY:
		if (ty->type == chartype || ty->type == signedchar
			|| ty->type == unsignedchar)
			return (char*)v.p;
		return stringf("%p", v.p);
	case _POINTER:  return stringf("%p", v.p);
	case _FUNCTION: return stringf("%p", v.g);
	}
	assert(0); return NULL;
}

