NAME SCORE_SYSTEM
DATASEG SEGMENT PARA
    W_HD DW 01H
    REC_LEN EQU 33
    BUF DB 0
        DB 0
        DB 33 DUP('$')
    BUF2 DB REC_LEN + 1 DUP('%')
    BUF2_LEN DW 0
    ROW LABEL BYTE
        XH DB 5 DUP('$')
        XM DB 16 DUP('$') ;END WITH $
        SX DB 4 DUP('$')
        YW DB 4 DUP('$')
        WY DB 4 DUP('$')
        EDF DB '|'
    XH_KEYWORD DB 5 DUP('#')
    FULL_PATH LABEL BYTE
        PATH DB 'D:\CHENGJI\2009\'
        FILENAME DB 10H DUP(00H)
    PROMPT_FILENAME_LABEL DB 12H DUP(' '), 'Please enter a file name to store the data.', 0AH, 12H DUP(' '), 'Filename: $'
    PROMPT_STUDENT_ID_LABEL DB 12H DUP(' '), 'Please enter the ID to work.', 0AH, 12H DUP(' '), 'Student ID: $'
    ERROR_LABEL DB 'Encounter an IO error. Error Code: $'
    SUCC_LABEL DB 'File has been created. $'
    SUCC_APPEND_LABEL DB 'Record has been appended into file. $'
    SUCC_MODIFY_LABEL DB 'Record has been modified. $'
    SUCC_DELETE_LABEL DB 'Record has been deleted. $'
    SUCC_SAVE_LABEL DB 'File has been closed. Now you can turn off the computer safely. $'
    UNKNOWN_LABEL DB 'An unknown choice is given. $'
    NOT_CREATE_LABEL DB 'Your should create a file before this operation. $'
    SID_LENGTH_INCORRECT_LABEL DB 'Student ID should be four digits. $'
    NOT_FOUND_LABEL DB 'Record is not found. $'
    MENU DB 30 DUP(' '), 0C9H, 17 DUP(0CDH), 0BBH, 0AH
         DB 30 DUP(' '), 0BAH, '1. APPEND A ROW  ', 0BAH, 0AH
         DB 30 DUP(' '), 0BAH, '2. DISPLAY A ROW ', 0BAH, 0AH
         DB 30 DUP(' '), 0BAH, '3. MODIFY A ROW  ', 0BAH, 0AH
         DB 30 DUP(' '), 0BAH, '4. DELETE A ROW  ', 0BAH, 0AH
         DB 30 DUP(' '), 0BAH, '5. CREATE FILE   ', 0BAH, 0AH
         DB 30 DUP(' '), 0BAH, '6. RETURN TO DOS ', 0BAH, 0AH
         DB 30 DUP(' '), 0C8H, 17 DUP(0CDH), 0BCH, 0AH
         DB 12H DUP(' '), 'Please enter your choice.', 0AH, 12H DUP(' '), 'CHOICE: $' 
     XH_LABEL DB 12H DUP(' '), 'STUDENT ID: $'
     XM_LABEL DB 12H DUP(' '), 'FULL  NAME: $'
     SX_LABEL DB 12H DUP(' '), 'MATH SCORE: $'
     YW_LABEL DB 12H DUP(' '), 'NATVE LANG: $'
     WY_LABEL DB 12H DUP(' '), 'FRGN  LANG: $'
DATASEG ENDS
STACK SEGMENT PARA STACK
    STA DB 100 DUP('/')
    TOP EQU SIZE STA
STACK ENDS
CODESEG SEGMENT PARA
    ASSUME DS: DATASEG, SS: STACK, ES: DATASEG
    START:
    MOV AX, DATASEG
    MOV DS, AX
    MOV ES, AX
    MSG MACRO LB, COLOR
        MOV BH, COLOR
        MOV DX, OFFSET LB
        CALL PRINT_MESSAGE
    ENDM
    NEXT_WELCOME_PROMPT:
        CALL WELCOME_SCREEN
        MOV AH, 01H
        INT 21H
        CMP AL, '6'
            JNE SKIP_C6
            JMP BREAK_WELCOME_PROMPT
        SKIP_C6:
        CMP AL, '5'
            JNE SKIP_C5
            CALL CREATE_SCREEN
            JMP NEXT_WELCOME_PROMPT
        SKIP_C5:
        CMP AL, '1'
            JNE SKIP_C1
            CALL APPEND_SCREEN
            JMP NEXT_WELCOME_PROMPT
        SKIP_C1:
        CMP AL, '2'
            JNE SKIP_C2
            CALL DISPLAY_SCREEN
            JMP NEXT_WELCOME_PROMPT
        SKIP_C2:
        CMP AL, '3'
            JNE SKIP_C3
            CALL MODIFY_SCREEN
            JMP NEXT_WELCOME_PROMPT
        SKIP_C3:
            MSG UNKNOWN_LABEL, 0CH
    JMP NEXT_WELCOME_PROMPT
    BREAK_WELCOME_PROMPT:
    ;CLOSE THE FILE
    MOV AH, 3EH
    MOV BX, W_HD
    INT 21H
    MSG SUCC_SAVE_LABEL, 0AH
    CALL CLEAR_WORKING_AREA
    
    MOV AH, 4CH
    INT 21H
    
    CHECK_HD_OPEN MACRO NOT_OPEN_JMP
        LOCAL NOT_CREATE_ERROR
        PUSHF
        CMP W_HD, 01H
        JNE NOT_CREATE_ERROR
            MSG NOT_CREATE_LABEL, 0CH
            CALL CLEAR_WORKING_AREA
            POPF
            JMP NOT_OPEN_JMP
        NOT_CREATE_ERROR:
        POPF
    ENDM
    CHECK_SUCC MACRO SUCC_LB
        LOCAL IO_ERROR, ENDIF_IO_ERROR
        JC IO_ERROR
            MSG SUCC_LB, 0AH
            JMP ENDIF_IO_ERROR
        IO_ERROR:
            MSG ERROR_LABEL, 0CH
            MOV BX, AX
            CALL PRINT_HEXIMAL
            CALL CLEAR_WORKING_AREA
        ENDIF_IO_ERROR:
    ENDM
    PROMPT_FIELD MACRO DST, DST_LABEL, LM
        MOV AH, 09H
        MOV DX, OFFSET DST_LABEL
        INT 21H
        MOV DI, OFFSET DST
        MOV CL, LM + 1
        CALL PROMPT_SAVE_STRING
    ENDM
    SHOW_FIELD MACRO SRC, SRC_LABEL
        MOV AH, 09H
        MOV DX, OFFSET SRC_LABEL
        INT 21H
        MOV DX, OFFSET SRC
        INT 21H
        CALL PRINT_NEWLINE
    ENDM
    LENG_CHK MACRO RESTART_LB
        LOCAL ENDIF_LENGTH_CHECK
        CMP BUF[1], 4
        JE ENDIF_LENGTH_CHECK
            MSG SID_LENGTH_INCORRECT_LABEL, 0CH
            JMP RESTART_LB
        ENDIF_LENGTH_CHECK:
    ENDM
    
    APPEND_SCREEN PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        CHECK_HD_OPEN BREAK_APPEND_SCREEN
        ;MOVE TO THE END OF THE FILE
        MOV AH, 42H
        MOV AL, 02H
        MOV BX, W_HD
        MOV CX, 00H
        MOV DX, 00H
        INT 21H
        CALL PROMPT_RECORD
        ;TODO: CHK_DUPLICATE
        MOV AH, 40H
        MOV BX, W_HD
        MOV CX, REC_LEN
        MOV DX, OFFSET ROW
        INT 21H
        CHECK_SUCC SUCC_APPEND_LABEL
        BREAK_APPEND_SCREEN:
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    APPEND_SCREEN ENDP
    DISPLAY_SCREEN PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        RESTART_DISPLAY_SCREEN:
        CALL CLEAR_WORKING_AREA
        CHECK_HD_OPEN BREAK_DISPLAY_SCREEN
        
        PROMPT_FIELD XH_KEYWORD, PROMPT_STUDENT_ID_LABEL, 4
        LENG_CHK RESTART_DISPLAY_SCREEN
        CALL SEARCH_BY_ID
        JC DS_NOT_FOUND
            ;LOAD MATCHED ROW
            MOV AH, 3FH
            MOV BX, W_HD
            MOV CX, REC_LEN
            MOV DX, OFFSET ROW
            INT 21H
            CALL SHOW_RECORD
            JMP BREAK_DISPLAY_SCREEN
        DS_NOT_FOUND:
            MSG NOT_FOUND_LABEL, 0CH
        
        BREAK_DISPLAY_SCREEN:
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    DISPLAY_SCREEN ENDP
    MODIFY_SCREEN PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        RESTART_MODIFY_SCREEN:
        CALL CLEAR_WORKING_AREA
        CHECK_HD_OPEN BREAK_MODIFY_SCREEN
        
        PROMPT_FIELD XH_KEYWORD, PROMPT_STUDENT_ID_LABEL, 4
        LENG_CHK RESTART_MODIFY_SCREEN
        CALL SEARCH_BY_ID
        JC DS_NOT_FOUND
            ;GET SID
            MOV CX, 5
            MOV SI, OFFSET XH_KEYWORD
            MOV DI, OFFSET XH
            CLD
            REP MOVSB
            ;PROMPT DETAIL
            CALL PROMPT_REVISE_RECORD
            MOV AH, 40H
            MOV BX, W_HD
            MOV CX, REC_LEN
            MOV DX, OFFSET ROW
            INT 21H
            CHECK_SUCC SUCC_MODIFY_LABEL
            JMP BREAK_MODIFY_SCREEN
        DS_NOT_FOUND:
            MSG NOT_FOUND_LABEL, 0CH
        
        BREAK_MODIFY_SCREEN:
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    MODIFY_SCREEN ENDP
    CREATE_SCREEN PROC
        ; @DSPTN CREATE AND GET HANDLE BY A GIVEN FILENAME
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        CALL CLEAR_WORKING_AREA
        CALL PROMPT_FILENAME
        ;TODO: CLOSE LAST
        MOV AH, 3CH
        MOV CX, 00H
        MOV DX, OFFSET FULL_PATH
        INT 21H
        JC SKIP_SAVE_HANDLE
            MOV W_HD, AX
        SKIP_SAVE_HANDLE:
        CHECK_SUCC SUCC_LABEL
        POP DX
        POP CX
        POP BX
        POP AX
        RET
        PROMPT_FILENAME PROC
            ; @DSPTN PUT FILENAME RIGHT AFTER PATH
            MOV AH, 09H
            MOV DX, OFFSET PROMPT_FILENAME_LABEL
            INT 21H
            MOV AH, 0AH
            MOV DX, OFFSET BUF
            MOV BUF[0], 10H
            INT 21H
            CALL PRINT_NEWLINE
            
            MOV BH, 0
            MOV BL, BUF[1]
            MOV BUF[BX + 2], 00H
            ;MOV DATA
            PUSH SI
            PUSH DI
            MOV CX, 10H
            MOV SI, OFFSET BUF + 2
            MOV DI, OFFSET FILENAME
            REP MOVSB
            POP DI
            POP SI
            RET
        PROMPT_FILENAME ENDP
    CREATE_SCREEN ENDP
    WELCOME_SCREEN PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        CALL CLEAR_WORKING_AREA
        ;MOVE CURSOR TO MENU FORMAT
        MOV AH, 02H
        MOV BH, 00H
        MOV DH, 05H
        MOV DL, 00H
        INT 10H
        MOV DX, OFFSET MENU
        MOV AH, 09H
        INT 21H
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    WELCOME_SCREEN ENDP
    
    PRINT_NEWLINE PROC
        PUSH AX
        PUSH DX
        MOV AH, 02H
        MOV DL, 0AH
        INT 21H
        POP DX
        POP AX
        RET
    PRINT_NEWLINE ENDP
    PRINT_HEXIMAL PROC
        ;@PARAM BX: NUMBER TO PRINT
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        MOV CH, 0
        NEXT_PARSE_HEXIMAL:
            MOV DX, BX
            AND DL, 0FH
            CMP DL, 09H
            JA NOT_NUMERIC
                OR DL, 30H
                JMP ENDIF_NUMERIC
            NOT_NUMERIC:
                ADD DL, 37H
            ENDIF_NUMERIC:
            PUSH DX
            INC CH
            MOV CL, 4
            SHR BX, CL
        JNZ NEXT_PARSE_HEXIMAL
        MOV CL, CH
        MOV CH, 0
        MOV AH, 02H
        NEXT_PRINT_HEXIMAL:
            POP DX
            INT 21H
        LOOP NEXT_PRINT_HEXIMAL
        BREAK_PARSE_HEXIMAL:
        MOV DL, 'H'
        INT 21H
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    PRINT_HEXIMAL ENDP
    PRINT_MESSAGE PROC
        ; @PARAMS DX: LABEL OFFSET, BH: COLOR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        ;CLEAR MESSAGE AREA
        MOV AX, 0600H
        MOV CX, 1800H
        MOV DX, 184FH
        INT 10H
        ;MOVE TO MESSAGE AREA
        MOV AH, 02H
        MOV BH, 00H
        MOV DH, 18H
        MOV DL, 00H
        INT 10H
        ;PRINT MESSAGE
        MOV AH, 09H
        POP DX
        INT 21H
        POP CX
        POP BX
        POP AX
        RET
    PRINT_MESSAGE ENDP
    CLEAR_WORKING_AREA PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        ;CLEAR WORKING AREA
        MOV AX, 0600H
        MOV BH, 07H
        MOV CX, 0000H
        MOV DX, 174FH
        INT 10H
        ;MOVE BACK TO WORKING AREA
        MOV AH, 02H
        MOV BH, 00H
        MOV DH, 0AH
        MOV DL, 00H
        INT 10H
        
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    CLEAR_WORKING_AREA ENDP
    
    PROMPT_RECORD PROC
        RESTART_PROMPT_RECORD:
        CALL CLEAR_WORKING_AREA
        PROMPT_FIELD XH, XH_LABEL, 4
        LENG_CHK RESTART_PROMPT_RECORD
        PROMPT_FIELD XM, XM_LABEL, 15
        PROMPT_FIELD SX, SX_LABEL, 3
        PROMPT_FIELD YW, YW_LABEL, 3
        PROMPT_FIELD WY, WY_LABEL, 3
        
        RET
        PROMPT_SAVE_STRING PROC
            ; @PARAMS DI: ENTRY TO STORE, CL: LENGTH LIMITATION
            PUSH AX
            PUSH BX
            PUSH DX
            
            MOV AH, 0AH
            MOV DX, OFFSET BUF
            MOV BUF[0], CL
            INT 21H
            CALL PRINT_NEWLINE
            
            MOV BH, 0
            MOV BL, BUF[1]
            MOV BUF[BX + 2], '$'
            ;MOV DATA
            PUSH SI
            PUSH CX
            MOV CH, 0
            MOV SI, OFFSET BUF + 2
            CLD
            REP MOVSB
            POP CX
            POP SI
            
            POP DX
            POP BX
            POP AX
            RET
        PROMPT_SAVE_STRING ENDP
    PROMPT_RECORD ENDP
    PROMPT_REVISE_RECORD PROC
        CALL CLEAR_WORKING_AREA
        SHOW_FIELD XH, XH_LABEL
        PROMPT_FIELD XM, XM_LABEL, 15
        PROMPT_FIELD SX, SX_LABEL, 3
        PROMPT_FIELD YW, YW_LABEL, 3
        PROMPT_FIELD WY, WY_LABEL, 3
        RET
    PROMPT_REVISE_RECORD ENDP
    SHOW_RECORD PROC
        CALL CLEAR_WORKING_AREA
        SHOW_FIELD XH, XH_LABEL
        SHOW_FIELD XM, XM_LABEL
        SHOW_FIELD SX, SX_LABEL
        SHOW_FIELD YW, YW_LABEL
        SHOW_FIELD WY, WY_LABEL
        ;PRESS ANY KEY TO CONTINUE
        MOV AH, 01H
        INT 21H
        RET
    SHOW_RECORD ENDP
    SEARCH_BY_ID PROC ;CONTRUCTING
        ; @PARAMS XH_KEYWORD
        ; @RETURN CF: 0 - NOT FOUND
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSH DI
        ;MOVE TO THE BEGINNING OF THE FILE
        MOV AH, 42H
        MOV AL, 00H
        MOV BX, W_HD
        MOV CX, 00H
        MOV DX, 00H
        INT 21H
        
        ;SEARCH THE ROWS
        MOV BX, W_HD
        MOV DX, OFFSET BUF2
        STC
        NEXT_ROW_CHECK:
            MOV AH, 3FH
            MOV CX, REC_LEN
            INT 21H
            MOV BUF2_LEN, AX
            
            ;CMP SID
            MOV CX, 4
            MOV SI, OFFSET XH_KEYWORD
            MOV DI, OFFSET BUF2
            CLD
            REPE CMPSB
            JNZ ENDIF_CMP_SID
                MOV AH, 42H
                MOV AL, 01H
                MOV BX, W_HD
                MOV CX, 0FFFFH
                MOV DX, -REC_LEN
                INT 21H
                CLC
                JMP BREAK_ROW_CHECK
            ENDIF_CMP_SID:
            
            CMP BUF2_LEN, REC_LEN
        JE NEXT_ROW_CHECK
        BREAK_ROW_CHECK:
        POP DI
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    SEARCH_BY_ID ENDP
CODESEG ENDS
    END START













