#include "c.h"

static char rcsid[] = "$Id$";

#define SWSIZE 512

#define den(i,j) ((j-buckets[i]+1.0)/(v[j]-v[buckets[i]]+1))

struct code codehead = { code::Start };
Code codelist = &codehead;
float density = 0.5;
Table stmtlabs;

static int foldcond(Tree e1, Tree e2);
static void caselabel(Swtch, long long, int); //修改支持64位,2022.2.27
//static void caselabel(Swtch, long, int);
static void cmp(int, Symbol, long long, int); //修改支持64位,2022.2.27
//static void cmp(int, Symbol, long, int);
static Tree conditional(int);
static void dostmt(int, Swtch, int);
static int equal(Symbol, Symbol);
static void forstmt(int, Swtch, int);
static void ifstmt(int, int, Swtch, int);
static Symbol localaddr(Tree);
static void stmtlabel(void);
static void swstmt(int, int, int);
static void whilestmt(int, Swtch, int);

void stmt_init(void)
{
	codehead = { code::Start };
	codelist = &codehead;
	density = 0.5;
	stmtlabs = 0;
}

Code code(int kind) {
	Code cp;

	if (!reachable(kind))
		warning("unreachable code\n");

	//NEW(cp, FUNC);
	cp = (Code)allocate(sizeof * cp, FUNC);
	cp->kind = (code::code_enum)kind;
/*
	switch (kind)
	{
	case code::Blockbeg:cp->kind = code::Blockbeg; break;
	case code::Blockend:cp->kind = code::Blockend; break;
	case code::Local:cp->kind = code::Local; break;
	case code::Address:cp->kind = code::Address; break;
	case code::Defpoint:cp->kind = code::Defpoint; break;
	case code::Label:cp->kind = code::Label; break;
	case code::Start:cp->kind = code::Start; break;
	case code::Gen:cp->kind = code::Gen; break;
	case code::Jump:cp->kind = code::Jump; break;
	case code::Switch:cp->kind = code::Switch; break;
	}
*/

	cp->prev = codelist;
	cp->next = NULL;
	codelist->next = cp;
	codelist = cp;
	return cp;
}
int reachable(int kind) {
	if (kind > code::Start) {
		Code cp;
		for (cp = codelist; cp->kind < code::Label; )
			cp = cp->prev;
		if (cp->kind == code::Jump || cp->kind == code::Switch)
			return 0;
	}
	return 1;
}
void addlocal(Symbol p) {
	if (!p->defined) {
		code(code::Local)->u.var = p;
		p->defined = 1;
		p->scope = level;
	}
}
void definept(Coordinate* p) {
	Code cp = code(code::Defpoint);

	cp->u.point.src = p ? *p : src;
	cp->u.point.point = npoints;
	if (ncalled > 0) {
		int n = findcount(cp->u.point.src.file,
			cp->u.point.src.x, cp->u.point.src.y);
		if (n > 0)
			refinc = (float)n / ncalled;
	}
	if (glevel > 2)	locus(identifiers, &cp->u.point.src);
	if (events.points && reachable(code::Gen))
	{
		Tree e = NULL;
		apply(events.points, &cp->u.point.src, &e);
		if (e)
			listnodes(e, 0, 0);
	}
}
void statement(int loop, Swtch swp, int lev) {
	float ref = refinc;

	if (Aflag >= 2 && lev == 15)
		warning("more than 15 levels of nested statements\n");
	switch (t) {
	case IF:       ifstmt(genlabel(2), loop, swp, lev + 1);
		break;
	case WHILE:    whilestmt(genlabel(3), swp, lev + 1); break;
	case DO:       dostmt(genlabel(3), swp, lev + 1); expect(';');
		break;

	case FOR:      forstmt(genlabel(4), swp, lev + 1);
		break;
	case BREAK:    walk(NULL, 0, 0);
		definept(NULL);
		if (swp && swp->lab > loop)
			branch(swp->lab + 1);
		else if (loop)
			branch(loop + 2);
		else
			error("illegal break statement\n");
		t = gettok(); expect(';');
		break;

	case CONTINUE: walk(NULL, 0, 0);
		definept(NULL);
		if (loop)
			branch(loop + 1);
		else
			error("illegal continue statement\n");
		t = gettok(); expect(';');
		break;

	case SWITCH:   swstmt(loop, genlabel(2), lev + 1);
		break;
	case CASE: {
		int lab = genlabel(1);
		if (swp == NULL)
			error("illegal case label\n");
		definelab(lab);
		while (t == CASE) {
			static char stop[] = { IF, ID, 0 };
			Tree p;
			t = gettok();
			p = _constexpr(0);
			if (generic(p->op) == CNST && isint(p->type)) {
				if (swp) {
					needconst++;
					p = cast(p, swp->sym->type);
					if (p->type->op == _UNSIGNED)
						p->u.v.i = extend(p->u.v.u, p->type);
					needconst--;
					caselabel(swp, p->u.v.i, lab);
				}
			}
			else
				error("case label must be a constant integer expression\n");

			test(':', stop);
		}
		statement(loop, swp, lev);
	} break;
	case DEFAULT:  if (swp == NULL)
		error("illegal default label\n");
				else if (swp->deflab)
		error("extra default label\n");
				else {
		swp->deflab = findlabel(swp->lab);
		definelab(swp->deflab->u.l.label);
	}
				t = gettok();
				expect(':');
				statement(loop, swp, lev); break;
	case RETURN: {
		Type rty = freturn(cfunc->type);
		t = gettok();
		definept(NULL);
		if (t != ';')
			if (rty == voidtype) {
				error("extraneous return value\n");
				expr(0);
				retcode(NULL);
			}
			else
				retcode(expr(0));
		else {
			if (rty != voidtype) {
				warning("missing return value\n");
				retcode(cnsttree(inttype, 0L));
			}
			else
				retcode(NULL);
		}
		branch(cfunc->u.f.label);
	} expect(';');
	break;

	case '{':      compound(loop, swp, lev + 1); break;
	case ';':      definept(NULL); t = gettok(); break;
	case GOTO:     walk(NULL, 0, 0);
		definept(NULL);
		t = gettok();
		if (t == ID) {
			Symbol p = lookup(token, stmtlabs);
			if (p == NULL) {
				p = install(token, &stmtlabs, 0, FUNC);
				p->scope = LABELS;
				p->u.l.label = genlabel(1);
				p->src = src;
			}
			use(p, src);
			branch(p->u.l.label);
			t = gettok();
		}
		else
			error("missing label in goto\n"); expect(';');
		break;

	case ID:       if (getchr() == ':') {
		stmtlabel();
		statement(loop, swp, lev);
		break;
	}
	default:       definept(NULL);
		if (kind[t] != ID) {
			error("unrecognized statement\n");
			t = gettok();
		}
		else {
			Tree e = expr0(0); //表达式处理入口
			listnodes(e, 0, 0); //转换为DAG
			if (nodecount == 0 || nodecount > 200)
				walk(NULL, 0, 0);
			else if (glevel) walk(NULL, 0, 0);
			deallocate(STMT);
		} expect(';');
		break;

	}
	if (kind[t] != IF && kind[t] != ID
		&& t != '}' && t != EOI) {
		static char stop[] = { IF, ID, '}', 0 };
		error("illegal statement termination\n");
		skipto(0, stop);
	}
	refinc = ref;
}

static void ifstmt(int lab, int loop, Swtch swp, int lev) {
	t = gettok();
	expect('(');
	definept(NULL);
	walk(conditional(')'), 0, lab);
	refinc /= 2.0;
	statement(loop, swp, lev);
	if (t == ELSE) {
		branch(lab + 1);
		t = gettok();
		definelab(lab);
		statement(loop, swp, lev);
		if (findlabel(lab + 1)->ref)
			definelab(lab + 1);
	}
	else
		definelab(lab);
}
static Tree conditional(int tok) {
	Tree p = expr(tok);

	if (Aflag > 1 && isfunc(p->type))
		warning("%s used in a conditional expression\n",
			funcname(p));
	return cond(p);
}
static void stmtlabel(void) {
	Symbol p = lookup(token, stmtlabs);

	if (p == NULL) {
		p = install(token, &stmtlabs, 0, FUNC);
		p->scope = LABELS;
		p->u.l.label = genlabel(1);
		p->src = src;
	}
	if (p->defined)
		error("redefinition of label `%s' previously defined at %w\n", p->name, &p->src);

	p->defined = 1;
	definelab(p->u.l.label);
	t = gettok();
	expect(':');
}
static void forstmt(int lab, Swtch swp, int lev) {
	int once = 0;
	Tree e1 = NULL, e2 = NULL, e3 = NULL;
	Coordinate pt2, pt3;

	t = gettok();
	expect('(');
	definept(NULL);
	if (kind[t] == ID)
		e1 = texpr(expr0, ';', FUNC);
	else
		expect(';');
	walk(e1, 0, 0);
	pt2 = src;
	refinc *= 10.0;
	if (kind[t] == ID)
		e2 = texpr(conditional, ';', FUNC);
	else
		expect(';');
	pt3 = src;
	if (kind[t] == ID)
		e3 = texpr(expr0, ')', FUNC);
	else {
		static char stop[] = { IF, ID, '}', 0 };
		test(')', stop);
	}
	if (e2) {
		once = foldcond(e1, e2);
		if (!once)
			branch(lab + 3);
	}
	definelab(lab);
	statement(lab, swp, lev);
	definelab(lab + 1);
	definept(&pt3);
	if (e3)
		walk(e3, 0, 0);
	if (e2) {
		if (!once)
			definelab(lab + 3);
		definept(&pt2);
		walk(e2, lab, 0);
	}
	else {
		definept(&pt2);
		branch(lab);
	}
	if (findlabel(lab + 2)->ref)
		definelab(lab + 2);
}
static void swstmt(int loop, int lab, int lev) {
	Tree e;
	struct swtch sw;
	Code head, tail;

	t = gettok();
	expect('(');
	definept(NULL);
	e = expr(')');
	if (!isint(e->type)) {
		error("illegal type `%t' in switch expression\n",
			e->type);
		e = retype(e, inttype);
	}
	e = cast(e, promote(e->type));
	if (generic(e->op) == INDIR && isaddrop(e->kids[0]->op)
		&& e->kids[0]->u.sym->type == e->type
		&& !isvolatile(e->kids[0]->u.sym->type)) {
		sw.sym = e->kids[0]->u.sym;
		walk(NULL, 0, 0);
	}
	else {
		sw.sym = genident(REGISTER, e->type, level);
		addlocal(sw.sym);
		walk(asgn(sw.sym, e), 0, 0);
	}
	head = code(code::Switch);
	sw.lab = lab;
	sw.deflab = NULL;
	sw.ncases = 0;
	sw.size = SWSIZE;
	//sw.values = (long*)newarray(SWSIZE, sizeof * sw.values, FUNC);
	sw.values = (long long*)newarray(SWSIZE, sizeof * sw.values, FUNC); //修改支持64位,2022.2.27
	sw.labels = (Symbol*)newarray(SWSIZE, sizeof * sw.labels, FUNC);
	refinc /= 10.0;
	statement(loop, &sw, lev);
	if (sw.deflab == NULL) {
		sw.deflab = findlabel(lab);
		definelab(lab);
		if (sw.ncases == 0)
			warning("switch statement with no cases\n");
	}
	if (findlabel(lab + 1)->ref)
		definelab(lab + 1);
	tail = codelist;
	codelist = head->prev;
	codelist->next = head->prev = NULL;
	if (sw.ncases > 0)
		swgen(&sw);
	branch(lab);
	head->next->prev = codelist;
	codelist->next = head->next;
	codelist = tail;
}
//static void caselabel(Swtch swp, long val, int lab) {
static void caselabel(Swtch swp, long long val, int lab) { //修改支持64位,2022.2.27
	int k;

	if (swp->ncases >= swp->size)
	{
		//long* vals = swp->values;
		long long* vals = swp->values; //修改支持64位,2022.2.27
		Symbol* labs = swp->labels;
		swp->size *= 2;
		//swp->values = (long*)newarray(swp->size, sizeof * swp->values, FUNC);
		swp->values = (long long*)newarray(swp->size, sizeof * swp->values, FUNC); //修改支持64位,2022.2.27
		swp->labels = (Symbol*)newarray(swp->size, sizeof * swp->labels, FUNC);
		for (k = 0; k < swp->ncases; k++) {
			swp->values[k] = vals[k];
			swp->labels[k] = labs[k];
		}
	}
	k = swp->ncases;
	for (; k > 0 && swp->values[k - 1] >= val; k--) {
		swp->values[k] = swp->values[k - 1];
		swp->labels[k] = swp->labels[k - 1];
	}
	if (k < swp->ncases && swp->values[k] == val)
		error("duplicate case label `%d'\n", val);
	swp->values[k] = val;
	swp->labels[k] = findlabel(lab);
	++swp->ncases;
	if (Aflag >= 2 && swp->ncases == 258)
		warning("more than 257 cases in a switch\n");
}
void swgen(Swtch swp) {
	int* buckets, k, n;
	//long* v = swp->values;
	long long* v = swp->values; //修改支持64位,2022.2.27

	buckets = (int*)newarray(swp->ncases + 1,
		sizeof * buckets, FUNC);
	for (n = k = 0; k < swp->ncases; k++, n++) {
		buckets[n] = k;
		while (n > 0 && den(n - 1, k) >= density)
			n--;
	}
	buckets[n] = swp->ncases;
	swcode(swp, buckets, 0, n - 1);
}
void swcode(Swtch swp, int b[], int lb, int ub) {
	int hilab, lolab, l, u, k = (lb + ub) / 2;
	//long* v = swp->values;
	long long* v = swp->values; //修改支持64位,2022.2.27

	if (k > lb && k < ub) {
		lolab = genlabel(1);
		hilab = genlabel(1);
	}
	else if (k > lb) {
		lolab = genlabel(1);
		hilab = swp->deflab->u.l.label;
	}
	else if (k < ub) {
		lolab = swp->deflab->u.l.label;
		hilab = genlabel(1);
	}
	else
		lolab = hilab = swp->deflab->u.l.label;
	l = b[k];
	u = b[k + 1] - 1;
	if (u - l + 1 <= 3)
	{
		int i;
		for (i = l; i <= u; i++)
			cmp(EQ, swp->sym, v[i], swp->labels[i]->u.l.label);
		if (k > lb && k < ub)
			cmp(GT, swp->sym, v[u], hilab);
		else if (k > lb)
			cmp(GT, swp->sym, v[u], hilab);
		else if (k < ub)
			cmp(LT, swp->sym, v[l], lolab);
		else
			assert(lolab == hilab),
			branch(lolab);
		walk(NULL, 0, 0);
	}
	else {
		Tree e;
		Type ty = signedint(swp->sym->type);
		Symbol table = genident(STATIC,
			array(voidptype, u - l + 1, 0), GLOBAL);
		(*IR->_defsymbol)(table);
		cmp(LT, swp->sym, v[l], lolab);
		cmp(GT, swp->sym, v[u], hilab);
		e = (*optree['-'])(SUB, cast(idtree(swp->sym), ty), cnsttree(ty, v[l]));
		if (e->type->size < signedptr->size)
			e = cast(e, longtype);
		walk(tree(JUMP, voidtype,
			rvalue((*optree['+'])(ADD, pointer(idtree(table)), e)), NULL),
			0, 0);
		code(code::Switch);
		codelist->u.swtch.table = table;
		codelist->u.swtch.sym = swp->sym;
		codelist->u.swtch.deflab = swp->deflab;
		codelist->u.swtch.size = u - l + 1;
		codelist->u.swtch.values = &v[l];
		codelist->u.swtch.labels = &swp->labels[l];
		if (v[u] - v[l] + 1 >= 10000)
			warning("switch generates a huge table\n");
	}
	if (k > lb) {
		assert(lolab != swp->deflab->u.l.label);
		definelab(lolab);
		swcode(swp, b, lb, k - 1);
	}
	if (k < ub) {
		assert(hilab != swp->deflab->u.l.label);
		definelab(hilab);
		swcode(swp, b, k + 1, ub);
	}
}
/*修改支持64位,2022.2.27*/
static void cmp(int op, Symbol p, long long n, int lab) {
	Type ty = signedint(p->type);

	listnodes(eqtree(op,
		cast(idtree(p), ty),
		cnsttree(ty, n)),
		lab, 0);
}
/*
static void cmp(int op, Symbol p, long n, int lab) {
	Type ty = signedint(p->type);

	listnodes(eqtree(op,
		cast(idtree(p), ty),
		cnsttree(ty, n)),
		lab, 0);
}
*/
void retcode(Tree p) {
	Type ty;

	if (p == NULL) {
		if (events.returns)
			apply(events.returns, cfunc, NULL);
		return;
	}
	p = pointer(p);
	ty = assign(freturn(cfunc->type), p);
	if (ty == NULL) {
		error("illegal return type; found `%t' expected `%t'\n",
			p->type, freturn(cfunc->type));
		return;
	}
	p = cast(p, ty);
	if (retv)
	{
		if (iscallb(p))
			p = tree(RIGHT, p->type,
				tree(CALL + B, p->type,
					p->kids[0]->kids[0], idtree(retv)),
				rvalue(idtree(retv)));
		else {
			Type ty = retv->type->type;
			assert(isstruct(ty));
			if (ty->u.sym->u.s.cfields) {
				ty->u.sym->u.s.cfields = 0;
				p = asgntree(ASGN, rvalue(idtree(retv)), p);
				ty->u.sym->u.s.cfields = 1;
			}
			else
				p = asgntree(ASGN, rvalue(idtree(retv)), p);
		}
		walk(p, 0, 0);
		if (events.returns)
			apply(events.returns, cfunc, rvalue(idtree(retv)));
		return;
	}
	if (events.returns)
	{
		Symbol t1 = genident(AUTO, p->type, level);
		addlocal(t1);
		walk(asgn(t1, p), 0, 0);
		apply(events.returns, cfunc, idtree(t1));
		p = idtree(t1);
	}
	if (!isfloat(p->type))
		p = cast(p, promote(p->type));
	if (isptr(p->type))
	{
		Symbol q = localaddr(p);
		if (q && (q->computed || q->generated))
			warning("pointer to a %s is an illegal return value\n",
				q->scope == PARAM ? "parameter" : "local");
		else if (q)
			warning("pointer to %s `%s' is an illegal return value\n",
				q->scope == PARAM ? "parameter" : "local", q->name);
	}
	walk(tree(mkop(RET, p->type), p->type, p, NULL), 0, 0);
}
void definelab(int lab) {
	Code cp;
	Symbol p = findlabel(lab);

	assert(lab);
	walk(NULL, 0, 0);
	code(code::Label)->u.forest = newnode(LABEL + V, NULL, NULL, p);
	for (cp = codelist->prev; cp->kind <= code::Label; )
		cp = cp->prev;
	while (cp->kind == code::Jump
		&& cp->u.forest->kids[0]
		&& specific(cp->u.forest->kids[0]->op) == ADDRG + P
		&& cp->u.forest->kids[0]->syms[0] == p) {
		assert(cp->u.forest->kids[0]->syms[0]->u.l.label == lab);
		p->ref--;
		assert(cp->next);
		assert(cp->prev);
		cp->prev->next = cp->next;
		cp->next->prev = cp->prev;
		cp = cp->prev;
		while (cp->kind <= code::Label)
			cp = cp->prev;
	}
}
Node jump(int lab) {
	Symbol p = findlabel(lab);

	p->ref++;
	return newnode(JUMP + V, newnode(ADDRG + ttob(voidptype), NULL, NULL, p),
		NULL, NULL);
}
void branch(int lab) {
	Code cp;
	Symbol p = findlabel(lab);

	assert(lab);
	walk(NULL, 0, 0);
	code(code::Label)->u.forest = jump(lab);
	for (cp = codelist->prev; cp->kind < code::Label; )
		cp = cp->prev;
	while (cp->kind == code::Label
		&& cp->u.forest->op == LABEL + V
		&& !equal(cp->u.forest->syms[0], p)) {
		equatelab(cp->u.forest->syms[0], p);
		assert(cp->next);
		assert(cp->prev);
		cp->prev->next = cp->next;
		cp->next->prev = cp->prev;
		cp = cp->prev;
		while (cp->kind < code::Label)
			cp = cp->prev;
	}
	if (cp->kind == code::Jump || cp->kind == code::Switch) {
		p->ref--;
		codelist->prev->next = NULL;
		codelist = codelist->prev;
	}
	else {
		codelist->kind = code::Jump;
		if (cp->kind == code::Label
			&& cp->u.forest->op == LABEL + V
			&& equal(cp->u.forest->syms[0], p))
			warning("source code specifies an infinite loop\n");
	}
}
void equatelab(Symbol old, Symbol _new) {
	assert(old->u.l.equatedto == NULL);
	old->u.l.equatedto = _new;
	_new->ref++;
}
static int equal(Symbol lprime, Symbol dst) {
	assert(dst && lprime);
	for (; dst; dst = dst->u.l.equatedto)
		if (lprime == dst)
			return 1;
	return 0;
}
/* dostmt - do statement while ( expression ) */
static void dostmt(int lab, Swtch swp, int lev) {
	refinc *= 10.0;
	t = gettok();
	definelab(lab);
	statement(lab, swp, lev);
	definelab(lab + 1);
	expect(WHILE);
	expect('(');
	definept(NULL);
	walk(conditional(')'), lab, 0);
	if (findlabel(lab + 2)->ref)
		definelab(lab + 2);
}

/* foldcond - check if initial test in for(e1;e2;e3) S is necessary */
static int foldcond(Tree e1, Tree e2) {
	int op = generic(e2->op);
	Symbol v;

	if (e1 == 0 || e2 == 0)
		return 0;
	if (generic(e1->op) == ASGN && isaddrop(e1->kids[0]->op)
		&& generic(e1->kids[1]->op) == CNST) {
		v = e1->kids[0]->u.sym;
		e1 = e1->kids[1];
	}
	else
		return 0;
	if ((op == LE || op == LT || op == EQ || op == NE || op == GT || op == GE)
		&& generic(e2->kids[0]->op) == INDIR
		&& e2->kids[0]->kids[0]->u.sym == v
		&& e2->kids[1]->op == e1->op) {
		e1 = simplify(op, e2->type, e1, e2->kids[1]);
		if (e1->op == CNST + _I)
			return e1->u.v.i;
	}
	return 0;
}

/* localaddr - returns q if p yields the address of local/parameter q; otherwise returns 0 */
static Symbol localaddr(Tree p) {
	if (p == NULL)
		return NULL;
	switch (generic(p->op)) {
	case INDIR: case CALL: case ARG:
		return NULL;
	case ADDRL: case ADDRF:
		return p->u.sym;
	case RIGHT: case ASGN:
		if (p->kids[1])
			return localaddr(p->kids[1]);
		return localaddr(p->kids[0]);
	case COND: {
		Symbol q;
		assert(p->kids[1] && p->kids[1]->op == RIGHT);
		if ((q = localaddr(p->kids[1]->kids[0])) != NULL)
			return q;
		return localaddr(p->kids[1]->kids[1]);
	}
	default: {
		Symbol q;
		if (p->kids[0] && (q = localaddr(p->kids[0])) != NULL)
			return q;
		return localaddr(p->kids[1]);
	}
	}
}

/* whilestmt - while ( expression ) statement */
static void whilestmt(int lab, Swtch swp, int lev) {
	Coordinate pt;
	Tree e;

	refinc *= 10.0;
	t = gettok();
	expect('(');
	walk(NULL, 0, 0);
	pt = src;
	e = texpr(conditional, ')', FUNC);
	branch(lab + 1);
	definelab(lab);
	statement(lab, swp, lev);
	definelab(lab + 1);
	definept(&pt);
	walk(e, lab, 0);
	if (findlabel(lab + 2)->ref)
		definelab(lab + 2);
}
