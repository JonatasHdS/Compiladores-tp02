%option noyywrap
 /*
  *  The scanner definition for COOL.
  */

 /*
  *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
  *  output, so headers and global definitions are placed here to be visible
  * to the code in the file.  Don't remove anything that was here initially
  */
%{

#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <stdint.h> // chamada a biblioteca stdint

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */


int string_const_tam;
char string_const[MAX_STR_CONST];
bool string_contain_null_char;

%}

 /*
  * Define names for regular expressions here.
  */

%option noyywrap
%x LINHA_DE_COMENTARIO BLOCO_DE_COMENTARIO STRING


NUMERO          [0-9]
ALFANUMERICO    [a-zA-Z0-9_]
TYPEID          [A-Z]{ALFANUMERICO}*
OBJECTID        [a-z]{ALFANUMERICO}*
DARROW		=>
ASSIGN		<-
LE		<=

%%

 /*
  *  Números e identificadores
  */

{NUMERO}+                               {
        cool_yylval.symbol = inttable.add_string(yytext);
        return (INT_CONST);
}

{TYPEID}        {
        cool_yylval.symbol = idtable.add_string(yytext);
        return (TYPEID);
}

{OBJECTID}      {
        cool_yylval.symbol = idtable.add_string(yytext);
        return (OBJECTID);
}


\n				{ curr_lineno++; }
[ \t\r\v\f]+	{}
 
 /*
  *  Nested comments
  */

"--"			{ BEGIN LINHA_DE_COMENTARIO; }
"(\*"			{ BEGIN BLOCO_DE_COMENTARIO; }
"\*)"			{
	strcpy(cool_yylval.error_msg, "Unmatched *)");
	return (ERROR);
}

<LINHA_DE_COMENTARIO>\n		{ BEGIN 0; curr_lineno++; }
<BLOCO_DE_COMENTARIO>\n		{ curr_lineno++; }
<BLOCO_DE_COMENTARIO>"\*)"	{ BEGIN 0; }
<BLOCO_DE_COMENTARIO><<EOF>>	{ 
	strcpy(cool_yylval.error_msg, "EOF in comment");
	BEGIN 0; return (ERROR);
}

<LINHA_DE_COMENTARIO>.			{}
<BLOCO_DE_COMENTARIO>.		{}

 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return (ASSIGN); }
{LE}			{ return (LE); }

 /*
  *  operadores gerais.
  */

"{"			{ return '{'; }
"}"			{ return '}'; }
"("			{ return '('; }
")"			{ return ')'; }
"~"			{ return '~'; }
","			{ return ','; }
";"			{ return ';'; }
":"			{ return ':'; }
"+"			{ return '+'; }
"-"			{ return '-'; }
"*"			{ return '*'; }
"/"			{ return '/'; }
"%"			{ return '%'; }
"."			{ return '.'; }
"<"			{ return '<'; }
"="			{ return '='; }
"@"			{ return '@'; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:CLASS)		{ return (CLASS); }
(?i:ELSE)		{ return (ELSE); }
(?i:FI)			{ return (FI); }
(?i:IF)			{ return (IF); }
(?i:IN)			{ return (IN); }
(?i:INHERITS)	{ return (INHERITS); }
(?i:LET)		{ return (LET); }
(?i:LOOP)		{ return (LOOP); }
(?i:POOL)		{ return (POOL); }
(?i:THEN)		{ return (THEN); }
(?i:WHILE)		{ return (WHILE); }
(?i:CASE)		{ return (CASE); }
(?i:ESAC)		{ return (ESAC); }
(?i:OF)			{ return (OF); }
(?i:NEW)		{ return (NEW); }
(?i:LE)			{ return (LE); }
(?i:NOT)		{ return (NOT); }
(?i:ISVOID)		{ return (ISVOID); }

t[rR][uU][eE]		{ 
	cool_yylval.boolean = 1;
	return (BOOL_CONST);
}

f[aA][lL][sS][eE]	{ 
	cool_yylval.boolean = 0;
	return (BOOL_CONST);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"	{
	memset(string_const, 0, sizeof string_const);
	string_const_tam = 0; string_contain_null_char = false;
	BEGIN STRING;
}

<STRING><<EOF>>	{
	strcpy(cool_yylval.error_msg, "EOF in string constant");
	BEGIN 0; return (ERROR);
}

<STRING>\\.		{
	if (string_const_tam >= MAX_STR_CONST) {
		strcpy(cool_yylval.error_msg, "String constant too long");
		BEGIN 0; return (ERROR);
	} 
	switch(yytext[1]) {
		case '\"': string_const[string_const_tam++] = '\"'; break;
		case '\\': string_const[string_const_tam++] = '\\'; break;
		case 'b' : string_const[string_const_tam++] = '\b'; break;
		case 'f' : string_const[string_const_tam++] = '\f'; break;
		case 'n' : string_const[string_const_tam++] = '\n'; break;
		case 't' : string_const[string_const_tam++] = '\t'; break;
		case '0' : string_const[string_const_tam++] = 0; 
			   string_contain_null_char = true; break;
		default  : string_const[string_const_tam++] = yytext[1];
	}
}

<STRING>\\\n	{ curr_lineno++; }
<STRING>\n		{
	curr_lineno++;
	strcpy(cool_yylval.error_msg, "Unterminated string constant");
	BEGIN 0; return (ERROR);
}

<STRING>\"		{ 
	if (string_const_tam > 1 && string_contain_null_char) {
		strcpy(cool_yylval.error_msg, "String contains null character");
		BEGIN 0; return (ERROR);
	}
	cool_yylval.symbol = stringtable.add_string(string_const);
	BEGIN 0; return (STR_CONST);
}

<STRING>.		{ 
	if (string_const_tam >= MAX_STR_CONST) {
		strcpy(cool_yylval.error_msg, "String constant too long");
		BEGIN 0; return (ERROR);
	} 
	string_const[string_const_tam++] = yytext[0]; 
}


 /*
  *  Trata outros erros
  */

.	{
	strcpy(cool_yylval.error_msg, yytext); 
	return (ERROR); 
}

%%
