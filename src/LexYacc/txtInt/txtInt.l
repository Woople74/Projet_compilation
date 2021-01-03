%{
#include "txtInt.tab.h"
#include <string.h>
%}

%option yylineno
%option nounput
%option noinput
%option noyywrap

%%
','                     { return (VIRGULE); }
(-?[0]|[1-9][0-9]*)     { yylval.t_entier = atoi(yytext); return (ENTIER); }
[a-zA-Z][a-zA-Z0-9]*    { yylval.t_chaine = strdup(yytext); return (TEXTE); }
\"((\\\")|[^(\")])*\"   { yylval.t_chaine = strdup(yytext); return (CHAINE); }
"---"                   { return (SEPARATEUR); }
[[:blank:]\r\n]
%%