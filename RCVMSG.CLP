/******************************************************************************/
/*  CL Program Example Using the RCVMSG Command                               */
/*                                                                            */
/******************************************************************************/

             PGM        

             DCL        VAR(&LOWKEY)     TYPE(*CHAR) LEN(4)
             DCL        VAR(&HIKEY)      TYPE(*CHAR) LEN(4)
             DCL        VAR(&MSGKEY)     TYPE(*CHAR) LEN(4)
             DCL        VAR(&MSG)        TYPE(*CHAR) LEN(256)
             DCL        VAR(&X)          TYPE(*INT)               
			     
             /* CREATE QTEMP/MSGOUTP TABLE */
             RUNSQL     SQL('DECLARE GLOBAL TEMPORARY TABLE +
                          SESSION.MSGOUTP (MESSAGE CHAR(256)) WITH REPLACE +
                          ON COMMIT PRESERVE ROWS NOT LOGGED') +
                        COMMIT(*NONE) NAMING(*SQL)

             /*---------------------------------------------------------------*/
             /* OBTAIN STARTING MESSAGE REFERENCE KEY                         */
             /*---------------------------------------------------------------*/
             SNDPGMMSG  MSG('MSGBEGIN') TOPGMQ(*SAME) KEYVAR(&LOWKEY)
             RMVMSG     MSGKEY(&LOWKEY)

        
			
			 /* Insert any command(s) or program call(s) you want              */
			 /*   to handle messages for here                                  */
			
			
	

             /*---------------------------------------------------------------*/
             /* OBTAIN ENDING MESSAGE REFERENCE KEY                           */
             /*---------------------------------------------------------------*/
             SNDPGMMSG  MSG('MSGEND') TOPGMQ(*SAME) KEYVAR(&HIKEY)
             RMVMSG     MSGKEY(&HIKEY)

             /*---------------------------------------------------------------*/
             /* LOOP TO RECEIVE MESSAGES ON INACTIVE INVOCATION               */
             /*---------------------------------------------------------------*/
             CHGVAR     %BIN(&MSGKEY 1 4)  (%BIN(&LOWKEY 1 4) + 1)
 LOOP:
             RCVMSG     PGMQ(*SAME (*)) MSGKEY(&MSGKEY) RMV(*NO) MSG(&MSG)

             MONMSG     CPF2410 EXEC(DO) /* HANDLE MSGKEY NOT FOUND */

                RCVMSG     MSGTYPE(*EXCP) RMV(*YES) /* REMOVE UNWANTED EXCPT */

                GOTO       SKIP
             ENDDO

             /*  SCAN THE MESSAGE AND REPLACE APOSTROPHE WITH A SPACE */
             DOFOR &X 1 256
                IF (%SST(&MSG &X 1) *EQ '''') THEN(DO)
                   CHGVAR VAR(%SST(&MSG &X 1)) VALUE(' ')
                ENDDO
             ENDDO

             /* INSERT EACH MESSAGE INTO QTEMP/MSGOUTP           */
             RUNSQL     SQL('INSERT INTO QTEMP/MSGOUTP VALUES(''' || +
                              &MSG || ''')') COMMIT(*NONE)

 SKIP:
             CHGVAR     %BIN(&MSGKEY 1 4)  (%BIN(&MSGKEY 1 4) + 1)
             IF         (&MSGKEY *LT &HIKEY) GOTO LOOP


             OVRPRTF    FILE(QSYSPRT) PAGESIZE(*N 132) SPOOL(*YES) +
                          FORMTYPE(DONT_PRINT) HOLD(*YES) SPLFNAME(JOBLOGOUT)

             /* COPY OUTPUT FILE OF FTP MESSAGES TO A SPOOL FILE */
             CPYF       FROMFILE(QTEMP/MSGOUTP) TOFILE(QSYSPRT)

             RUNSQL     SQL('DROP TABLE QTEMP/MSGOUTP') COMMIT(*NONE)

             ENDPGM 
