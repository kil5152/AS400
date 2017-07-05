/******************************************************************************/
/*  FTP from One iSeries to Another iSeries                                   */
/*                                                                            */
/******************************************************************************/

             PGM        

             DCL        VAR(&FROMPGMLIB)  TYPE(*CHAR) LEN(10)

             DCL        VAR(&RTNLIB)     TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNMBR)     TYPE(*CHAR) LEN(10)
             DCL        VAR(&SRCTYPE)    TYPE(*CHAR) LEN(10)
             DCL        VAR(&TEXT)       TYPE(*CHAR) LEN(50)
             DCL        VAR(&FTPCMD)     TYPE(*CHAR) LEN(512)

             DCL        VAR(&QUOTE)      TYPE(*CHAR) LEN(2)

             DCL        VAR(&MBRNAM)     TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILENAM)    TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIBRARYNAM) TYPE(*CHAR) LEN(10)

             DCLF       FILE(MBRLISTP)

             CHGVAR     VAR(&QUOTE)  VALUE('''''')
			 CHGVAR     VAR(&FROMPGMLIB)  VALUE('TESTLIB')

             CALLSUBR   SUBR(FTPSRCMBRS)


/******************************************************************************/
/*                              SUBROUTINES                                   */
/******************************************************************************/

  /*   *******************************************************************    */
  /*                      FTP ALL SRC FILES                                   */
  /*   *******************************************************************    */

             SUBR       SUBR(FTPSRCMBRS)

                /* AN INPUT FILE OF FTP COMMANDS                 */
                /* FTPDTA FIELD MUST BE CHAR INSTEAD OF VARCHAR  */
                RUNSQL     SQL('DECLARE GLOBAL TEMPORARY TABLE +
                             SESSION.FTPFILP (FTPDTA CHAR(512)) WITH +
                             REPLACE ON COMMIT PRESERVE ROWS NOT LOGGED') +
                             COMMIT(*NONE) NAMING(*SQL)

                /* AN OUTPUT FILE OF FTP MESSAGES                */
                /* FTPDTA FIELD MUST BE CHAR INSTEAD OF VARCHAR  */
                RUNSQL     SQL('DECLARE GLOBAL TEMPORARY TABLE +
                             SESSION.FTPOUT  (FTPDTA CHAR(512)) WITH +
                             REPLACE ON COMMIT PRESERVE ROWS NOT LOGGED') +
                             COMMIT(*NONE) NAMING(*SQL)

                /* FTP COMMAND - USER NAME & PASSWORD         */
                CHGVAR     VAR(&FTPCMD) VALUE('USERNAME PASSWORD')
                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                /* FTP COMMAND - BINARY                       */
                CHGVAR     VAR(&FTPCMD) VALUE('BINARY')
                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                /* FTP COMMAND - NAMEFMT 1                    */
                CHGVAR     VAR(&FTPCMD) VALUE('NAMEFMT 1')
                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                /* FTP COMMAND - CHANGE THE DIRECTORY         */
                /*  E.G. CD /QSYS.LIB/XXXXXX.LIB              */
                CHGVAR     VAR(&FTPCMD) VALUE('CD /QSYS.LIB/' *TCAT +
                             &FROMPGMLIB *TCAT '.LIB')

                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                /* FTP COMMAND - CHANGE THE LOCAL DIRECTORY   */
                /*  E.G. LCD /QSYS.LIB/XXXXXX.LIB             */
                CHGVAR     VAR(&FTPCMD) VALUE('LCD /QSYS.LIB/' *TCAT +
                             &FROMPGMLIB *TCAT '.LIB')

                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                /* LIST OF MEMBERS                                         */							 
                OVRDBF     FILE(MBRLISTP) TOFILE(QTEMP/MBRLISTP) +
                             LVLCHK(*NO) SHARE(*YES)

                OPNQRYF    FILE((MBRLISTP)) QRYSLT('FILENAME *NE " " +
                             *AND MEMBERNAME *NE " " ') KEYFLD((FILENAME) +
                             (MEMBERNAME)) UNIQUEKEY(*ALL)

                /*     READ ALL LF/PF FILES                                */
                /*     READ ALL PRTF FILES                                 */
                /*     READ ALL SRVPGM & MOD                               */
                /*     READ ALL RPGLE                                      */
                /*     READ ALL CLP                                        */
 READ:          RCVF

                MONMSG     MSGID(CPF0864)  EXEC(GOTO CMDLBL(EOF))

                /* SET THE SOURCE MEMBER NAME                              */
                CHGVAR     VAR(&MBRNAM) VALUE(&MEMBERNAME)
                CHGVAR     VAR(&FILENAM) VALUE(&FILENAME)
                CHGVAR     VAR(&LIBRARYNAM) VALUE(&FROMPGMLIB)

                /* FTP COMMAND - PUT THE FILE ON THE REMOTE SYSTEM           */
                /*  E.G. PUT /QSYS.LIB/XXXXXX.LIB/QCLSRC.FILE/SOURCENAME.MBR */
                CHGVAR     VAR(&FTPCMD) VALUE('PUT /QSYS.LIB/' *TCAT +
                             &LIBRARYNAM *TCAT '.LIB/' *TCAT &FILENAM +
                             *TCAT '.FILE/' *TCAT &MBRNAM *TCAT '.MBR')

                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                /* GET THE SOURCE MEMBER DESCRIPTION                        */
                RTVMBRD    FILE(&LIBRARYNAM/&FILENAM) MBR(&MBRNAM *SAME) +
                             RTNLIB(&RTNLIB) RTNMBR(&RTNMBR) +
                             SRCTYPE(&SRCTYPE) TEXT(&TEXT)

                /*  CHGPFM - CHANGE THE ATTRIBUTES OF THE MEMBER             */
                /*            SOURCE TYPE & TEXT                             */
                /*   QUOTE RCMD CHGPFM FILE(XXX/QCLSRC) MBR(XXXXXX)          */
                /*                 SRCTYPE(XXX) TEXT('XXX  XXXXXX')          */
                CHGVAR     VAR(&FTPCMD) VALUE('QUOTE RCMD CHGPFM FILE(' +
                             *TCAT &RTNLIB *TCAT '/' *TCAT &FILENAM *TCAT +
                             ') MBR(' *TCAT &RTNMBR *TCAT ') SRCTYPE(' +
                             *TCAT &SRCTYPE *TCAT ') TEXT(' *TCAT &QUOTE +
                             *TCAT &TEXT *TCAT &QUOTE *TCAT ')')

                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                /* READ NEXT RECORD                                         */
                GOTO       READ

 EOF:           CLOF       OPNID(MBRLISTP)
                DLTOVR     FILE(MBRLISTP)

                /* USE CLOSE TO RESET THE FILE POINTER                        */
                /* ONCE EOF HAS BEEN ENCOUNTERED YOU CANNOT RESET THE         */
                /*  FILE POINTER USING POSDBF. CLOF DOES NOT ALLOW TO RESET   */
                /*  THE FILE POINTER                                          */
                CLOSE

                /* FTP COMMAND - END FTP SESSION                            */
                CHGVAR     VAR(&FTPCMD) VALUE( 'QUIT')
                RUNSQL     SQL('INSERT INTO QTEMP/FTPFILP VALUES('''|| +
                             &FTPCMD || ''')') COMMIT(*NONE)

                OVRDBF     FILE(INPUT) TOFILE(QTEMP/FTPFILP) MBR(*FIRST)
                OVRDBF     FILE(OUTPUT) TOFILE(QTEMP/FTPOUT) MBR(*FIRST)

                FTP        RMTSYS('SYSTEM_NAME')

                RUNSQL     SQL('DROP TABLE QTEMP/FTPFILP') COMMIT(*NONE)

                DLTOVR     FILE(INPUT OUTPUT)

                OVRPRTF    FILE(QSYSPRT) PAGESIZE(*N 132) SPOOL(*YES) +
                             FORMTYPE(DONT_PRINT) HOLD(*YES) +
                             SPLFNAME(FTPOUT)

                /* COPY OUTPUT FILE OF FTP MESSAGES TO A SPOOL FILE */
                CPYF       FROMFILE(QTEMP/FTPOUT) TOFILE(QSYSPRT)

                RUNSQL     SQL('DROP TABLE QTEMP/FTPOUT') COMMIT(*NONE)

             ENDSUBR

             ENDPGM 
