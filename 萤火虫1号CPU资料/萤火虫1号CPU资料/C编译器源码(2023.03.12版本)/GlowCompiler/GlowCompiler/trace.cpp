#include "c.h"

static char rcsid[] = "$Id$";

static char* fmt, * fp, * fmtend;	/* format string, current & limit pointer */
static Tree args;		/* printf arguments */
static Symbol frameno;		/* local holding frame number */

static Symbol null;

void trace_init(void)
{
	fmt = 0;
	fp = 0;
	fmtend = 0;
	args = 0;
	frameno = 0;
	null = 0;
}

/* appendstr - append str to the evolving format string, expanding it if necessary */
static void appendstr(char* str) {
	do
		if (fp == fmtend)
			if (fp) {
				char* s = (char*)allocate(2 * (fmtend - fmt), FUNC);
				strncpy(s, fmt, fmtend - fmt);
				fp = s + (fmtend - fmt);
				fmtend = s + 2 * (fmtend - fmt);
				fmt = s;
			}
			else {
				fp = fmt = (char*)allocate(80, FUNC);
				fmtend = fmt + 80;
			}
	while ((*fp++ = *str++) != 0);
	fp--;
}

/* tracevalue - append format and argument to print the value of e */
static void tracevalue(Tree e, int lev) {
	Type ty = unqual(e->type);

	switch (ty->op) {
	case _INT:
		if (ty == chartype || ty == signedchar)
			appendstr("'\\x%02x'");
		else if (ty == longtype)
			appendstr("0x%ld");
		else
			appendstr("0x%d");
		break;
	case _UNSIGNED:
		if (ty == chartype || ty == unsignedchar)
			appendstr("'\\x%02x'");
		else if (ty == unsignedlong)
			appendstr("0x%lx");
		else
			appendstr("0x%x");
		break;
	case _FLOAT:
		if (ty == longdouble)
			appendstr("%Lg");
		else
			appendstr("%g");
		break;
	case _POINTER:
		if (unqual(ty->type) == chartype
			|| unqual(ty->type) == signedchar
			|| unqual(ty->type) == unsignedchar) {
			//static Symbol null;
			if (null == NULL)
				null = mkstr("(null)");
			tracevalue(cast(e, unsignedtype), lev + 1);
			appendstr(" \"%.30s\"");
			e = condtree(e, e, pointer(idtree(null->u.c.loc)));
		}
		else {
			appendstr("("); appendstr(typestring(ty, "")); appendstr(")0x%x");
		}
		break;
	case _STRUCT: {
		Field q;
		appendstr("("); appendstr(typestring(ty, "")); appendstr("){");
		for (q = ty->u.sym->u.s.flist; q; q = q->link) {
			appendstr(q->name); appendstr("=");
			tracevalue(field(addrof(e), q->name), lev + 1);
			if (q->link)
				appendstr(",");
		}
		appendstr("}");
		return;
	}
	case _UNION:
		appendstr("("); appendstr(typestring(ty, "")); appendstr("){...}");
		return;
	case _ARRAY:
		if (lev && ty->type->size > 0) {
			int i;
			e = pointer(e);
			appendstr("{");
			for (i = 0; i < ty->size / ty->type->size; i++) {
				Tree p = (*optree['+'])(ADD, e, consttree(i, inttype));
				if (isptr(p->type) && isarray(p->type->type))
					p = retype(p, p->type->type);
				else
					p = rvalue(p);
				if (i)
					appendstr(",");
				tracevalue(p, lev + 1);
			}
			appendstr("}");
		}
		else
			appendstr(typestring(ty, ""));
		return;
	default:
		assert(0);
	}
	e = cast(e, promote(ty));
	args = tree(mkop(ARG, e->type), e->type, e, args);
}

/* tracefinis - complete & generate the trace call to print */
static void tracefinis(Symbol printer) {
	Tree* ap;
	Symbol p;

	*fp = 0;

	p = mkstr(string(fmt));
	for (ap = &args; *ap; ap = &(*ap)->kids[1])
		;
	*ap = tree(ARG + P, charptype, pointer(idtree(p->u.c.loc)), 0);
	walk(calltree(pointer(idtree(printer)), freturn(printer->type), args, NULL), 0, 0);
	args = 0;
	fp = fmtend = 0;
}

/* tracecall - generate code to trace entry to f */
static void tracecall(Symbol printer, Symbol f, void* ignore) {
	int i;
	Symbol counter = genident(STATIC, inttype, GLOBAL);

	defglobal(counter, BSS);
	(*IR->_space)(counter->type->size);
	frameno = genident(AUTO, inttype, level);
	addlocal(frameno);
	appendstr(f->name); appendstr("#");
	tracevalue(asgn(frameno, incr(INCR, idtree(counter), consttree(1, inttype))), 0);
	appendstr("(");
	for (i = 0; f->u.f.callee[i]; i++) {
		if (i)
			appendstr(",");
		appendstr(f->u.f.callee[i]->name); appendstr("=");
		tracevalue(idtree(f->u.f.callee[i]), 0);
	}
	if (variadic(f->type))
		appendstr(",...");
	appendstr(") called\n");
	tracefinis(printer);
}

/* tracereturn - generate code to trace return e */
static void tracereturn(Symbol printer, Symbol f, Tree e) {
	appendstr(f->name); appendstr("#");
	tracevalue(idtree(frameno), 0);
	appendstr(" returned");
	if (freturn(f->type) != voidtype && e) {
		appendstr(" ");
		tracevalue(e, 0);
	}
	appendstr("\n");
	tracefinis(printer);
}

/* traceInit - initialize for tracing */
void traceInit(char* arg) {
	if (strncmp(arg, "-t", 2) == 0 && strchr(arg, '=') == NULL) {
		Symbol printer = mksymbol(EXTERN, arg[2] ? &arg[2] : "printf",
			ftype(inttype, ptr(qual(_CONST, chartype)), voidtype, NULL));
		printer->defined = 0;
		attach((Apply)tracecall, printer, &events.entry);
		attach((Apply)tracereturn, printer, &events.returns);
	}
}
