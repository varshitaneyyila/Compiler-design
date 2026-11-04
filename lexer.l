%option noyywrap yylineno

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

static char *duptext(const char *s)
{
    size_t n = strlen(s) + 1;
    char *p = malloc(n);

    if (!p) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }

    memcpy(p, s, n);
    return p;
}
%}

%%

"BcsMain"                  { return BCSMAIN; }

"int"                      { return INT; }
"bool"                     { return BOOL; }

"if"                       { return IF; }
"else"                     { return ELSE; }
"while"                    { return WHILE; }

"<="                       { return LE; }
">="                       { return GE; }
"=="                       { return EQ; }
"!="                       { return NE; }
"<"                        { return LT; }
">"                        { return GT; }

"="                        { return ASSIGN; }
"+"                        { return PLUS; }
"*"                        { return MUL; }

"{"                        { return LBRACE; }
"}"                        { return RBRACE; }
"("                        { return LPAREN; }
")"                        { return RPAREN; }
";"                        { return SEMICOLON; }

[0-9]+                     {
                               yylval.str = duptext(yytext);
                               return NUM;
                           }

[a-zA-Z][a-zA-Z0-9]*       {
                               yylval.str = duptext(yytext);
                               return ID;
                           }

[ \t\r\n]+                 { /* Ignore whitespace */ }

.                          {
                               fprintf(stderr,
                                   "Lexical Error (line %d): invalid character '%s'\n",
                                   yylineno, yytext);
                               return INVALID;
                           }

%%
