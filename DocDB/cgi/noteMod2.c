/****************************************************************************
    mcnoteMod2.c

    Take a specified Note number (for the form generated by 
       mcnoteModForm2), and get that record from the mcnotes DB.
    Call mcnoteModForm1 with the result.

    Mov. 1995:  Initial routine 
    Dec. 1995:  Revise to account for 3 date_req fields
*****************************************************************************/

#include <stdio.h>
#include <sys/types.h>
#include <fcntl.h>
#include <stdlib.h>
#include <ctype.h>
#include "notes.h"


main(int argc, char *argv[]) {

    /* From routine post-query.c */
    entry entries[MAX_ENTRIES];
    register int x,m=0;
    int cl,
	off,
	length;

    /* Declarations added by GC */
    MYSQL *db_sock;
    int i, indx, j;
    int num_search, num_recs;
    char new_lab[7];
    char buf[2048];
    char *field1;
    char srchfld[12];
    char srchstr[MAX_LEN], srchstr2[MAX_LEN + 50], srchstrci[5 * MAX_LEN];
    MYSQL_RES *result;
    MYSQL_ROW   cur;
    MYSQL_FIELD *curField;


    /* Set up for html output */
    printf("Content-type: text/html%c%c",10,10);

    /* Make sure we're looking at POST method form results */
    if(strcmp(getenv("REQUEST_METHOD"),"POST")) {
        printf("This script should be referenced with a METHOD of POST.\n");
        printf("If you don't understand this, see this ");
	printf("<A HREF=\"%s\">forms overview</A>.\n", FORM_INFO_URL);
        exit(1);
    }
    if(strcmp(getenv("CONTENT_TYPE"),"application/x-www-form-urlencoded")) {
        printf("This script can only be used to decode form results. \n");
        exit(1);
    }

    /* Decode form results into individual fields and values */
    cl = atoi(getenv("CONTENT_LENGTH"));
    for(x=0;cl && (!feof(stdin));x++) {
        m=x;
        entries[x].val = fmakeword(stdin,'&',&cl);
        plustospace(entries[x].val);
        unescape_url(entries[x].val);
        entries[x].name = makeword(entries[x].val,'=');
    }


    /*-------------------------------------------------------*/
    /* mSQL-specific part */
    /*-------------------------------------------------------*/

    /* Get search field(s) and value(s) from form input */

    /* First make sure user has entered a Note number */
    if (strcmp(entries[0].name, "number")) {
	printf ("Sorry, I was expecting to get a number.");
	return;
    }
    /* ... and make sure that it is a number */
    for (i = 0; i < strlen(entries[0].val); i++) {
	if (!isdigit(entries[0].val[i])) {
	    printf("Error: Note number <STRONG>%s</STRONG>", entries[0].val); 
	    printf(" has non-numeric characters<P>");
	    return;
	}
    }

    /* Make up the query string to send to mSQL */
    /* #define SELECT_NUM "select * from %s where %s=%d" */
    sprintf(buf, SELECT_NUM, TABLE, SEL_FIELD, atoi(entries[0].val));

    /* Now do the mSQL query */

    db_sock = mysql_init(NULL);
    if (db_sock == NULL) {
	printf ("mysql_init() failed<BR>");
	return;
    }

    if(mysql_real_connect(db_sock,DBSERVER,USERNAME,PWORD,DB,0,NULL,0) == NULL) {
	printf ("error in connecting: %s<BR>",mysql_error(db_sock));
	return;
    }

    mysql_query(db_sock, buf);
    result = mysql_store_result(db_sock);

    if (result) {
	/* Put the result into a form for editing */
	noteModForm1(result);
    }
    else {
	printf("Error: could not find revised entry.<BR>");
	exit(-1);
    }

    /* Free memory used for query result, and disconnect socket */
    mysql_free_result(result);
    mysql_close(db_sock);

    return;
}


/********** routines included from NCSA file util.c ********************/

char *makeword(char *line, char stop) {
    int x = 0,y;
    char *word = (char *) malloc(sizeof(char) * (strlen(line) + 1));

    for(x=0;((line[x]) && (line[x] != stop));x++)
        word[x] = line[x];

    word[x] = '\0';
    if(line[x]) ++x;
    y=0;

    while(line[y++] = line[x++]);
    return word;
}

char *fmakeword(FILE *f, char stop, int *cl) {
    int wsize;
    char *word;
    int ll;

    wsize = 102400;
    ll=0;
    word = (char *) malloc(sizeof(char) * (wsize + 1));

    while(1) {
        word[ll] = (char)fgetc(f);
        if(ll==wsize) {
            word[ll+1] = '\0';
            wsize+=102400;
            word = (char *)realloc(word,sizeof(char)*(wsize+1));
        }
        --(*cl);
        if((word[ll] == stop) || (feof(f)) || (!(*cl))) {
            if(word[ll] != stop) ll++;
            word[ll] = '\0';
	    word = (char *) realloc(word, ll+1);
            return word;
        }
        ++ll;
    }
}

char x2c(char *what) {
    register char digit;

    digit = (what[0] >= 'A' ? ((what[0] & 0xdf) - 'A')+10 : (what[0] - '0'));
    digit *= 16;
    digit += (what[1] >= 'A' ? ((what[1] & 0xdf) - 'A')+10 : (what[1] - '0'));
    return(digit);
}

void unescape_url(char *url) {
    register int x,y;

    for(x=0,y=0;url[y];++x,++y) {
        if((url[x] = url[y]) == '%') {
            url[x] = x2c(&url[y+1]);
            y+=2;
        }
    }
    url[x] = '\0';
}

void plustospace(char *str) {
    register int x;

    for(x=0;str[x];x++) if(str[x] == '+') str[x] = ' ';
}

