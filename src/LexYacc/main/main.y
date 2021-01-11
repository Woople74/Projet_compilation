%{
	#include <stdlib.h>
	#include <stdio.h>
	#include <string.h>
	#include <time.h>
	#include "pile.h"

	#define FICTEMP "tmp/intermediaire.txt"

	int yylex();
	extern int yylineno;
	extern int NIS;
	extern int cmp_reg;
	extern int taille;
	int taille_prog, tmp, val[500], cmptVal, taille_decl, indice;
	pile p, p2; 
%}

%code requires { 
	#include "tableLex.h"
	#include "tablereg.h"
	#include "tabledecl.h"
	#include "tableTypes.h"
	#include "arbreAbstrait.h"
}

%code {
	arbre arbreAbstrait = NULL;
	void yyerror (char const *str) {
		fprintf(stderr,"Erreur de syntaxe en ligne %d\n%s\n", yylineno, str);
		arbreAbstrait = aa_vide();
	}
}

%union {
	arbre t_arbre;
	int t_int;
}

%define parse.error verbose
%locations
/** Symboles terminaux **/
    /* Structure du programme */
%token PROG "program"
%token DEBUT "begin"
%token FIN "end"
    /* Déclarations */
%token TYPE "type"
%token VAR "variable"
%token STRUCT "struct"
%token FSTRUCT "finstruct"
%token PROCEDURE "proc"
%token FONCTION "funct"
%token TABLEAU "tab"
%token DE "of"
    /* Noms de types de données */
%token T_INT "int"
%token T_FLOAT "float"
%token T_BOOL "bool"
%token T_CHAR "char"
%token T_STRING "string"
    /* Types de données */
%token <t_int> INT "entier"
%token <t_int> FLOAT "réel"
%token <t_int> BOOL "booléen"
%token <t_int> STRING "chaîne de caractères"
%token <t_int> CHAR "caractère"
    /* Opérateurs arithmétique */
%token PLUS "+"
%token MOINS "-"
%token MULT "*"
%token DIV "/"
%token MOD "%"
%token EXP "^"
    /* Opérateurs relationnel */
%token INF "<"
%token SUP ">"
%token INFE "<="
%token SUPE ">="
%token EGAL "="
%token DIF "!="
    /* Opérateurs logique */
%token OR "|"
%token AND "&"
%token NOT "!"
    /* Opérateurs daffectation */
%token OPAFF "<-"
    /* Ponctuations */
%token PO "("
%token PF ")"
%token CO "["
%token CF "]"
%token POINT "."
%token VIRG ","
%token PV ";"
%token POINTPOINT ".."
%token GUILLEMET "\""
%token APOSTROPHE "'" 
%token DEUX_POINTS ":"
    /* Structures conditionnelles */
%token SI "if"
%token ALORS "then"
%token SINON "else"
%token TANTQUE "while"
%token FAIRE "do"
%token POUR "for"
    /* Entrées & sorties */
%token RETOURNE "return"
%token AFFICHER "print"
    /* Identifiants */
%token <t_int> IDF "identifiant"
	/* Misc */
%token INNATENDU "expression"

/** Symboles non-terminaux des instructions **/
	/* Structure du programme */
%type <t_arbre> corps liste_instructions suite_liste_inst instruction
	/* Affectations */
%type <t_arbre> affectation variable idf_variable liste_indices
	/* Expression */
%type <t_arbre> expression constante 
%type <t_arbre> expr_pm expr_md expr_exp expr_base constante_maths
%type <t_arbre> expr_comp
%type <t_arbre> expr_bool_and expr_bool_or expr_bool_not expr_bool_base
	/* Appels de fonctions & procédures */
%type <t_arbre> appel_fonction suite_args 
	/* Structures conditionnelles */
%type <t_arbre> condition expr_cond tantque pour instruction_pour
	/* Entrées & sorties */
%type <t_arbre> resultat_retourne afficher
	/* Déclarations */
%type <t_int> type_simple nom_type 
%type <t_int> declaration_fonction un_param 
%type <t_int> declaration_variable 
%type <t_int> suite_declaration_type declaration_type 

%%
programme : PROG {
	tr_ajout_nis(cmp_reg, NIS);
	p = pile_vide();
	p2 = pile_vide();
	/* taille=1+NIS; */
	}
        	IDF corps {
	arbreAbstrait = $4;
	tr_ajout_taille(0, taille);
	}
		  | PROG {
	tr_ajout_nis(cmp_reg, NIS);
	p = pile_vide();
	p2 = pile_vide();
	/* taille=1+NIS; */
	} 
		    corps { 
	arbreAbstrait = $3; 
	tr_ajout_taille(0, taille);
	}
		  ;

corps : liste_declarations liste_instructions { $$ = $2; }
      ;



/*** DÉCLARATIONS ***/

liste_declarations : liste_decl_types liste_decl_vars liste_decl_proc_fct
                   ;

liste_decl_types : 
                 | liste_decl_types declaration_type PV
                 ;

liste_decl_vars : 
                | liste_decl_vars declaration_variable PV
                ;

liste_decl_proc_fct : 
                    | liste_decl_proc_fct declaration_proc_fct PV
                    ;

declaration_proc_fct : declaration_procedure 
                     | declaration_fonction
                     ;

	/** Déclaration de types **/


declaration_type : TYPE IDF DEUX_POINTS suite_declaration_type 
	{if($4 == TYPE_T){
		taille_decl = 0;
		for(int i=0; i<tt_tabNbDimensions(tmp); i++) taille_decl += tt_tabDimBornSup(tmp, i) - tt_tabDimBornInf(tmp, i) * tt_tabTypeElem(tmp);
	}else{
		taille_decl = 0;
		for(int i=0; i<tt_structNbChamps(tmp); i++){
			decl d = td_getlastdecl(tl_getLex(tt_structNumLexChamp(tmp, i)));
			if(d.NATURE == TYPE_S || d.NATURE == TYPE_T){
				taille_decl += d.exec;
			}else{/*C'est forcement une variable*/
				taille_decl += td_getlastdecl(tl_getLex(d.index)).exec;
			}
		}
	}
	td_ajout($4, tl_getLex($2), cmp_reg, tmp, taille_decl);
	}
                 ; 

suite_declaration_type : STRUCT { cmptVal = 0; } liste_champs FSTRUCT { $$ = TYPE_S; tmp = tt_ajoutStruct(cmptVal/3, val); }
                       | TABLEAU dimension DE nom_type {$$ = TYPE_T; tmp = tt_ajoutTab($4, cmptVal/2, val); }
                       ; 

		/* Déclaration de structures */
		
liste_champs : un_champ PV
             | liste_champs un_champ PV
             ;

un_champ : IDF DEUX_POINTS nom_type { val[cmptVal++] = $3; val[cmptVal++] = $1; val[cmptVal++] = td_getdecl($3).exec;  }
         ;

		/* Déclaration de tableaux */

dimension : CO { cmptVal = 0; } liste_dimensions CF
          ;

liste_dimensions : une_dimension
                 | liste_dimensions VIRG une_dimension
                 ;

une_dimension : INT POINTPOINT INT { val[cmptVal++] = $1; val[cmptVal++] = $3; }
              ;


	/** Déclaration de variables **/


declaration_variable : VAR IDF DEUX_POINTS nom_type 
					{	indice = td_getdecl($2).index;
						printf("idf : %d \n", $2);
						printf("indice : %d \n", td_getdecl($2).index);
						if (indice < 4) taille += 1;
						else {
							taille = taille + (td_getdecl(indice).exec);
							/* td_ajout(VARI, tl_getLex($2), cmp_reg, $4, td_getdecl($4).exec); */ 
							/*taille=taille+(td_getlastdecl(char* nom)($2).exec); */ 
						}
					}
                     ;


	/** Déclaration de procédures **/


declaration_procedure : PROCEDURE {
	cmp_reg++; 
	NIS++ ;
	p = empiler(p, taille);
	p2 = empiler(p2, cmp_reg);
	taille=1+NIS; 
	tr_ajout_nis(cmp_reg, NIS); 
	}
						IDF listeparametres 
						liste_decl_types 
                        liste_decl_vars {
	tr_ajout_taille(cmp_reg, taille); 
	}
                        liste_decl_proc_fct
                        liste_instructions 
						{
	tr_ajout_arbre(sommet_pile(p2), $9);
	NIS-- ;
	taille = sommet_pile(p);
	p = depiler(p);
	p2 = depiler(p2);
	tmp = tt_ajoutProcedure (cmptVal/2, val);
	td_ajout(PROC, tl_getLex($3), cmp_reg, tmp, NIS);
	}
                      ;

listeparametres : { cmptVal = 0; }
			    | PO { cmptVal = 0; } listeparam PF
			    ;

listeparam : un_param
           | listeparam PV un_param
           ;

un_param : IDF DEUX_POINTS type_simple {
	taille++; 
	val[cmptVal++] = $1;
	val[cmptVal++] = $3; 
	td_ajout(PARAM, tl_getLex($1), cmp_reg, $3, td_getdecl($3).exec);}
         ;


	/** Déclaration de fonctions **/


declaration_fonction : FONCTION { 	
	cmp_reg++; 
	NIS++;
	p = empiler(p, taille);
	p2 = empiler(p2, cmp_reg);
	taille=1+NIS;
	tr_ajout_nis(cmp_reg, NIS); 
	}
					   IDF listeparametres 
					   RETOURNE type_simple 
					   liste_decl_types 
					   liste_decl_vars {	
	tr_ajout_taille(cmp_reg, taille); 
	}
                       liste_decl_proc_fct liste_instructions {	
	tr_ajout_arbre(sommet_pile(p2), $11);
	NIS--; 
	taille = sommet_pile(p);
	p = depiler(p); 
	p2 = depiler(p2);
	tmp = tt_ajoutFonction($6, cmptVal/2, val);
	td_ajout(FUNCT, tl_getLex($3), cmp_reg, tmp, NIS);
	}
                     ;


	/** Déclarations de noms et types de variables **/


nom_type : type_simple
         | IDF
         ;

type_simple : T_INT { $$ = 0; }
			| T_FLOAT { $$ = 1; }
			| T_BOOL { $$ = 2; }
			| T_CHAR { $$ = 3; }
			| T_STRING CO INT CF { $$ = -1; }
            ;



/*** INSTRUCTIONS ***/



liste_instructions : DEBUT suite_liste_inst FIN { $$ = aa_concatPereFils(aa_creerNoeud(A_LISTE, -1), $2); }
				   ; 

suite_liste_inst : { $$ = NULL; }
		 		 | instruction suite_liste_inst { $$ = aa_concatPereFrere($1, aa_concatPereFils(aa_creerNoeud(A_LISTE, -1), $2)); }
		 		 ;

instruction : affectation PV
			| appel_fonction PV
			| condition 
			| tantque
			| pour
			| RETOURNE resultat_retourne PV
				{ $$ = aa_concatPereFils(aa_creerNoeud(A_RETOURNER, -1), $2); }
			| afficher PV
	    	;


	/** Affectations **/


affectation : variable OPAFF expression 
				{ $$ = aa_concatPereFils(aa_creerNoeud(A_OPAFF, -1), aa_concatPereFrere($1, $3)); }
	    	;

variable : idf_variable POINT variable { $$ = aa_concatPereFils(aa_creerNoeud(A_CHAMP, -1), aa_concatPereFrere($1, $3)); }
		 | idf_variable
	 	 ;

idf_variable : idf_variable CO liste_indices CF { if ($1->fils != aa_vide() && $1->fils->id == A_LISTE_INDICES) {
													  arbre tmp = $1->fils;
													  while (tmp->frere != aa_vide()) tmp = tmp->frere;
												      aa_concatPereFrere(tmp, aa_concatPereFils(aa_creerNoeud(A_LISTE_INDICES, -1), $3)); 
												  } else $$ = aa_concatPereFils($1, aa_concatPereFils(aa_creerNoeud(A_LISTE_INDICES, -1), $3)); 
												}
			 | IDF { $$ = aa_creerNoeud(A_IDF, $1); }
			 ;

liste_indices : expr_pm VIRG liste_indices { $$ = aa_concatPereFrere($1, aa_concatPereFils(aa_creerNoeud(A_LISTE_INDICES, -1), $3)); }
              | expr_pm
              ;


	/** Expressions **/


expression : expr_pm
		   | expr_bool_or
		   | constante
		   ;

constante : STRING { $$ = aa_creerNoeud(A_CSTE_CHAINE, $1); }
		  | CHAR { $$ = aa_creerNoeud(A_CSTE_CAR, $1); }
		  ;

		/* Expressions arithmétiques */

expr_pm : expr_pm PLUS expr_md { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_PLUS, -1), aa_concatPereFrere($1, $3)); }
		| expr_pm MOINS expr_md { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_MOINS, -1), aa_concatPereFrere($1, $3)); }
		| expr_md
		;

expr_md : expr_md MULT expr_exp { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_MULT, -1), aa_concatPereFrere($1, $3)); }
		| expr_md DIV expr_exp { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_DIV, -1), aa_concatPereFrere($1, $3)); }
		| expr_md MOD expr_exp { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_MODUL, -1), aa_concatPereFrere($1, $3)); }
		| expr_exp
		;

expr_exp : expr_exp EXP expr_base { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_EXP, -1), aa_concatPereFrere($1, $3)); }
		 | MOINS expr_base { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_MOINS, -1), $2); }
		 | expr_base
		 ;

expr_base : constante_maths
		  | variable
	  	  | PO expr_pm PF { $$ = $2; }
		  | appel_fonction
	  	  ;

constante_maths : INT { $$ = aa_creerNoeud(A_CSTE_ENT, $1); }
		        | FLOAT { $$ = aa_creerNoeud(A_CSTE_REELE, $1); }
			    ;

		/* Expressions relationnels */

expr_comp : expr_pm INF expr_pm { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_INF, -1), aa_concatPereFrere($1, $3)); }
		  | expr_pm SUP expr_pm { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_SUP, -1), aa_concatPereFrere($1, $3)); }
		  | expr_pm INFE expr_pm { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_INFE, -1), aa_concatPereFrere($1, $3)); }
		  | expr_pm SUPE expr_pm { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_SUPE, -1), aa_concatPereFrere($1, $3)); }
		  | expr_pm EGAL expr_pm { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_EGAL, -1), aa_concatPereFrere($1, $3)); }
		  | expr_pm DIF expr_pm { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_DIFF, -1), aa_concatPereFrere($1, $3)); }
		  ;

		/* Expressions logiques */

expr_bool_or : expr_bool_or OR expr_bool_and { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_OU, -1), aa_concatPereFrere($1, $3)); }
		     | expr_bool_and
		     ;

expr_bool_and : expr_bool_and AND expr_bool_not { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_ET, -1), aa_concatPereFrere($1, $3)); }
			  | expr_bool_not
			  ;

expr_bool_not : NOT expr_bool_base { $$ = aa_concatPereFils(aa_creerNoeud(A_OP_NON, -1), $2); }
			  | expr_bool_base
			  ;

expr_bool_base : PO expr_bool_or PF { $$ = $2; }
			   | expr_comp
			   | BOOL { $$ = aa_creerNoeud(A_CSTE_BOOL, $1); }
			   ;


	/** Appels de fonctions & procédures **/


appel_fonction : IDF PO suite_args PF 
			{ $$ = aa_concatPereFils(aa_creerNoeud(A_APPEL_FONC, $1), aa_concatPereFils(aa_creerNoeud(A_LISTEPARAMS, -1), $3)); }
		 ;

suite_args : { $$ = NULL; }
		   | expression { $$ = aa_concatPereFrere($1, aa_creerNoeud(A_LISTEPARAMS, -1)); }
		   | expression VIRG suite_args { $$ = aa_concatPereFrere($1, aa_concatPereFils(aa_creerNoeud(A_LISTEPARAMS, -1), $3)); }
		   ;


	/** Structures conditionnelles **/


condition : SI expr_cond ALORS liste_instructions { $$ = aa_concatPereFils(aa_creerNoeud(A_IF_THEN_ELSE, -1), aa_concatPereFrere($2, $4)); }
		  | SI expr_cond ALORS liste_instructions SINON liste_instructions
		  		{ $$ = aa_concatPereFils(aa_creerNoeud(A_IF_THEN_ELSE, -1), aa_concatPereFrere($2, aa_concatPereFrere($4, $6))); }
		  ;

expr_cond : expr_bool_or
		  | variable
		  ;


tantque : TANTQUE expr_cond FAIRE liste_instructions { $$ = aa_concatPereFils(aa_creerNoeud(A_WHILE, -1), aa_concatPereFrere($2, $4)); }
		| FAIRE liste_instructions TANTQUE expr_cond { $$ = aa_concatPereFils(aa_creerNoeud(A_DO_WHILE, -1), aa_concatPereFrere($4, $2)); }
		;


pour : POUR expression PV expr_cond PV instruction_pour FAIRE liste_instructions
		{ $$ = aa_concatPereFils(aa_creerNoeud(A_FOR, -1), aa_concatPereFrere($2, aa_concatPereFrere($4, aa_concatPereFrere($6, $8)))); }
	 ;

instruction_pour: affectation
				| appel_fonction
				;

	/** Entrées & sorties **/


resultat_retourne : { $$ = NULL; }
				  | expression
				  ;

afficher : AFFICHER PO expression PF { $$ = aa_concatPereFils(aa_creerNoeud(A_AFFICHER, -1), $3); }
		 ;

%%

int main(int argc, char *argv[]) {
	FILE *f;
	
	if (argc > 1 && (strcmp(argv[1], "-debug") == 0 ||
					 strcmp(argv[1], "-d") == 0))
		yydebug = 1;

	tl_init();
	tr_init();
	td_init();
	tt_init();

	/* On vide le fichier avant de l'ouvrir en append */
	f = fopen(FICTEMP, "w");
	fclose(f);
	f = fopen(FICTEMP, "a");

	yyparse();

	tl_ecrireFichier(f);
	tr_ecrireFichier(f);
	tt_ecrireFichier(f);


	td_afficher();
	tr_affiche();
	//tr_afficherArbres();

	tl_detruire();
	fclose(f);

	liberer_pile(p);
	liberer_pile(p2);

	exit(EXIT_SUCCESS);
}