NAME SCORE_SYSTEM
DATASEG SEGMENT PARA
    BUF DB 0
        DB 0
        DB 16 DUP('$')
    ROW LABEL BYTE
        XH DB 4 DUP ('#')
        XM DB 16 DUP ('$') ;END WITH $
        SX DB 4 DUP ('$')
        YW DB 4 DUP ('$')
        WY DB 4 DUP ('$')
    W_HD DW 01H
    FULL_PATH LABEL BYTE
        PATH DB 'D:\CHENGJI\2009\'
        FILENAME DB 10H DUP (00H)
    ROMPT_FILENAME_LABEL DB 12H DUP(' '), 'Please enter a file name to store the data.', 0AH, 12H DUP(' '), 'Filename: $'
    ROMPT_STUDENT_ID_LABEL DB 12H DUP(' '), 'Please enter the ID to work.', 0AH, 12H DUP(' '), 'Student ID: $'
    ERROR_LABEL DB 'Encounter an IO error. Error Code: $'
    SUCC_LABEL DB 'File has been created. $'
    SUCC_APPEND_LABEL DB 'Record has been appended into file. $'
    SUCC_MODIFY_LABEL DB 'Record has been modified. $'
    SUCC_DELETE_LABEL DB 'Record has been deleted. $'
    UNKNOWN_LABEL DB 'An unknown choice is given. $'
    NOT_CREATE_LABEL DB 'Your should create a file before this operation. $'
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
            MSG UNKNOWN_LABEL, 0CH
    JMP NEXT_WELCOME_PROMPT
    BREAK_WELCOME_PROMPT:
    ;CLOSE THE FILE
    MOV AH, 3EH
    MOV BX, W_HD
    INT 21H
    
    MOV AH, 4CH
    INT 21H
    
    CHECK_SUCC MACRO SUCC_LB
        LOCAL NOT_CREATE_ERROR, APPEND_ERROR, ENDIF_APPEND_ERROR
        CMP W_HD, 01H
        JNE NOT_CREATE_ERROR
            MSG NOT_CREATE_LABEL, 0CH
            CALL CLEAR_WORKING_AREA
            JMP ENDIF_APPEND_ERROR
        NOT_CREATE_ERROR:
        JC APPEND_ERROR
            MOV W_HD, AX
            MSG SUCC_LB, 0AH
            JMP ENDIF_APPEND_ERROR
        APPEND_ERROR:
            MSG ERROR_LABEL, 0CH
            MOV BX, AX
            CALL PRINT_HEXIMAL
            CALL CLEAR_WORKING_AREA
        ENDIF_APPEND_ERROR:
    ENDM
    
    APPEND_SCREEN PROC FAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        CALL PROMPT_RECORD
        MOV AH, 40H
        MOV BX, W_HD
        MOV CX, 32
        MOV DX, OFFSET ROW
        INT 21H
        CHECK_SUCC SUCC_APPEND_LABEL
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    APPEND_SCREEN ENDP
    CREATE_SCREEN PROC FAR
        ; @DSPTN CREATE AND GET HANDLE BY A GIVEN FILENAME
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        CALL CLEAR_WORKING_AREA
        CALL PROMPT_FILENAME
        MOV AH, 3CH
        MOV CX, 00H
        MOV DX, OFFSET FULL_PATH
        INT 21H
        JC CREATE_ERROR
            MOV W_HD, AX
            MSG SUCC_LABEL, 0AH
            JMP ENDIF_CREATE_ERROR
        CREATE_ERROR:
            MSG ERROR_LABEL, 0CH
            MOV BX, AX
            CALL PRINT_HEXIMAL
            CALL CLEAR_WORKING_AREA
        ENDIF_CREATE_ERROR:
        POP DX
        POP CX
        POP BX
        POP AX
        RET
        PROMPT_FILENAME PROC NEAR
            ; @DSPTN PUT FILENAME RIGHT AFTER PATH
            MOV AH, 09H
            MOV DX, OFFSET ROMPT_FILENAME_LABEL
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
    WELCOME_SCREEN PROC FAR
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
    
    PRINT_NEWLINE PROC FAR
        PUSH AX
        PUSH DX
        MOV AH, 02H
        MOV DL, 0AH
        INT 21H
        POP DX
        POP AX
        RET
    PRINT_NEWLINE ENDP
    PRINT_HEXIMAL PROC FAR
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
    PRINT_MESSAGE PROC FAR
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
    CLEAR_WORKING_AREA PROC FAR
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
    
    PROMPT_RECORD PROC FAR
        CALL CLEAR_WORKING_AREA
        PROMPT_FIELD MACRO DST, DST_LABEL, LM
            MOV AH, 09H
            MOV DX, OFFSET DST_LABEL
            INT 21H
            MOV DI, OFFSET DST
            MOV CL, LM + 1
            CALL PROMPT_SAVE_STRING
        ENDM
        PROMPT_FIELD XH, XH_LABEL, 4
        PROMPT_FIELD XM, XM_LABEL, 15
        PROMPT_FIELD SX, SX_LABEL, 3
        PROMPT_FIELD YW, YW_LABEL, 3
        PROMPT_FIELD WY, WY_LABEL, 3
        
        RET
        PROMPT_SAVE_STRING PROC NEAR
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
            REP MOVSB
            POP CX
            POP SI
            
            POP DX
            POP BX
            POP AX
            RET
        PROMPT_SAVE_STRING ENDP
    PROMPT_RECORD ENDP
    
CODESEG ENDS
    END START





