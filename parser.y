%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
extern FILE *yyin;

#define MAX_SYMBOLS 2048
enum { TYPE_INT = 1, TYPE_BOOL = 2, TYPE_ERROR = -1 };
typedef struct { char *name; int type; } Symbol;
static Symbol symbols[MAX_SYMBOLS];
static int symbol_count = 0;
static int semantic_error = 0;
static int syntax_error = 0;
static int temp_count = 0;
static int flow_depth = 0; /* TAC is suppressed inside if/else/while */
static FILE *tac_out = NULL;

static char *copystr(const char *s) {
    size_t n = strlen(s) + 1; char *p = malloc(n);
    if (!p) { perror("malloc"); exit(EXIT_FAILURE); }
    memcpy(p, s, n); return p;
}
static int lookup(const char *name) {
    for (int i = 0; i < symbol_count; i++)
        if (strcmp(symbols[i].name, name) == 0) return i;
    return -1;
}
static void declare_symbol(const char *name, int type) {
    if (lookup(name) >= 0) {
        fprintf(stderr, "Semantic Error (line %d): duplicate declaration of '%s'\n", yylineno, name);
        semantic_error = 1; return;
    }
    if (symbol_count >= MAX_SYMBOLS) {
        fprintf(stderr, "Semantic Error: symbol table capacity exceeded\n"); semantic_error = 1; return;
    }
    symbols[symbol_count].name = copystr(name);
    symbols[symbol_count++].type = type;
}
static int identifier_type(const char *name) {
    int i = lookup(name);
    if (i < 0) {
        fprintf(stderr, "Semantic Error (line %d): undeclared variable '%s'\n", yylineno, name);
        semantic_error = 1; return TYPE_ERROR;
    }
    return symbols[i].type;
}
static char *new_temp(void) {
    char buf[40]; snprintf(buf, sizeof(buf), "t%d", ++temp_count); return copystr(buf);
}
static void emit_binary(char **out, const char *left, const char *op, const char *right) {
    /* Allocate a numbered temporary only when an instruction is emitted. */
    if (tac_out && flow_depth == 0) {
        *out = new_temp();
        fprintf(tac_out, "%s = %s %s %s\n", *out, left, op, right);
    } else {
        /* Expressions in flow-control statements are checked, not emitted. */
        *out = copystr("<suppressed>");
    }
}
static void free_symbols(void) {
    for (int i = 0; i < symbol_count; i++) { free(symbols[i].name); symbols[i].name = NULL; }
    symbol_count = 0;
}
%}

%union {
    char *str;
    int type;
    struct { char *place; int type; } expr;
}

%token BCSMAIN IF ELSE WHILE
%token INT BOOL
%token <str> ID NUM
%token PLUS MUL ASSIGN
%token LT GT LE GE EQ NE
%token LBRACE RBRACE LPAREN RPAREN SEMICOLON INVALID
%type <type> type
%type <expr> aexpr term factor expr
%type <str> relop
%start program
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
program : BCSMAIN LBRACE decllist stmtlist RBRACE ;
decllist : decl | decllist decl ;
decl : type ID SEMICOLON { declare_symbol($2, $1); free($2); } ;
type : INT { $$ = TYPE_INT; } | BOOL { $$ = TYPE_BOOL; } ;
stmtlist : stmt | stmtlist SEMICOLON stmt ;

stmt
    : ID ASSIGN aexpr {
          int lhs_type = identifier_type($1);
          if ($3.type != TYPE_ERROR && lhs_type != TYPE_ERROR && lhs_type != $3.type) {
              fprintf(stderr, "Semantic Error (line %d): type mismatch assigning expression to '%s'\n", yylineno, $1);
              semantic_error = 1;
          }
          if (flow_depth == 0 && tac_out && lhs_type != TYPE_ERROR && $3.type != TYPE_ERROR && lhs_type == $3.type)
              fprintf(tac_out, "%s = %s\n", $1, $3.place);
          free($1); free($3.place);
      }
    | IF LPAREN { flow_depth++; } expr RPAREN {
          if ($4.type != TYPE_BOOL && $4.type != TYPE_ERROR) {
              fprintf(stderr, "Semantic Error (line %d): if condition must be bool (use a relational expression)\n", yylineno);
              semantic_error = 1;
          }
          free($4.place);
      } LBRACE stmtlist RBRACE ELSE LBRACE stmtlist RBRACE { flow_depth--; }
    | WHILE LPAREN { flow_depth++; } expr RPAREN {
          if ($4.type != TYPE_BOOL && $4.type != TYPE_ERROR) {
              fprintf(stderr, "Semantic Error (line %d): while condition must be bool (use a relational expression)\n", yylineno);
              semantic_error = 1;
          }
          free($4.place);
      } LBRACE stmtlist RBRACE { flow_depth--; }
    ;

expr
    : aexpr relop aexpr {
          if ($1.type == TYPE_ERROR || $3.type == TYPE_ERROR) $$.type = TYPE_ERROR;
          else if (strcmp($2, "==") == 0 || strcmp($2, "!=") == 0) {
              if ($1.type != $3.type) {
                  fprintf(stderr, "Semantic Error (line %d): operands of '%s' must have matching types\n", yylineno, $2);
                  semantic_error = 1; $$.type = TYPE_ERROR;
              } else $$.type = TYPE_BOOL;
          } else {
              if ($1.type != TYPE_INT || $3.type != TYPE_INT) {
                  fprintf(stderr, "Semantic Error (line %d): relational operator '%s' requires int operands\n", yylineno, $2);
                  semantic_error = 1; $$.type = TYPE_ERROR;
              } else $$.type = TYPE_BOOL;
          }
          if (tac_out && flow_depth == 0 && $$.type != TYPE_ERROR) {
              $$.place = new_temp();
              fprintf(tac_out, "%s = %s %s %s\n", $$.place, $1.place, $2, $3.place);
          } else {
              /* Do not consume temporary numbers for suppressed/invalid TAC. */
              $$.place = copystr("<suppressed>");
          }
          free($1.place); free($2); free($3.place);
      }
    | aexpr { $$ = $1; }
    ;
relop : LT { $$ = copystr("<"); } | GT { $$ = copystr(">"); }
       | LE { $$ = copystr("<="); } | GE { $$ = copystr(">="); }
       | EQ { $$ = copystr("=="); } | NE { $$ = copystr("!="); } ;

aexpr
    : aexpr PLUS term {
          if ($1.type != TYPE_INT || $3.type != TYPE_INT) {
              fprintf(stderr, "Semantic Error (line %d): '+' requires int operands\n", yylineno);
              semantic_error = 1; $$.type = TYPE_ERROR; $$.place = copystr("<error>");
          } else { emit_binary(&$$.place, $1.place, "+", $3.place); $$.type = TYPE_INT; }
          free($1.place); free($3.place);
      }
    | term { $$ = $1; }
    ;
term
    : term MUL factor {
          if ($1.type != TYPE_INT || $3.type != TYPE_INT) {
              fprintf(stderr, "Semantic Error (line %d): '*' requires int operands\n", yylineno);
              semantic_error = 1; $$.type = TYPE_ERROR; $$.place = copystr("<error>");
          } else { emit_binary(&$$.place, $1.place, "*", $3.place); $$.type = TYPE_INT; }
          free($1.place); free($3.place);
      }
    | factor { $$ = $1; }
    ;
factor
    : ID { $$.place = $1; $$.type = identifier_type($1); }
    | NUM { $$.place = $1; $$.type = TYPE_INT; }
    | LPAREN aexpr RPAREN { $$ = $2; }
    ;
%%

void yyerror(const char *s) {
    (void)s;
    if (!syntax_error) fprintf(stderr, "Syntax Error (line %d)\n", yylineno);
    syntax_error = 1;
}
int main(int argc, char **argv) {
    if (argc != 3) { fprintf(stderr, "Usage: %s <input.bcs> <output.txt>\n", argv[0]); return 2; }
    yyin = fopen(argv[1], "r");
    if (!yyin) { perror(argv[1]); return 2; }
    tac_out = fopen(argv[2], "w");
    if (!tac_out) { perror(argv[2]); fclose(yyin); return 2; }
    int parse_result = yyparse();
    fclose(yyin); fclose(tac_out); tac_out = NULL;
    if (parse_result != 0 || syntax_error || semantic_error) {
        remove(argv[2]);
        if (parse_result == 0 && !syntax_error && semantic_error)
            fprintf(stderr, "Compilation failed: semantic errors found; TAC output removed.\n");
        free_symbols(); return 1;
    }
    printf("Semantic analysis successful. TAC written to %s\n", argv[2]);
    free_symbols(); return 0;
}
