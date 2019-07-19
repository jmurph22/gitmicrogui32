include \masm32\include\masm32rt.inc

create_dialog PROTO :DWORD,:DWORD
DlgProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
system PROTO C, :PTR BYTE

.data
	ErrFileBase db "Could not write file: ",0

.data?
	hWnd       dd ?
	hInstance  dd ?
	hEdit      dd ?
	PathBuffer db MAX_PATH dup(?)
	CommitFile db MAX_PATH dup(?)
	cmd1       db MAX_PATH dup(?)
	cmd2       db MAX_PATH dup(?)
	ErrFile    db MAX_PATH dup(?)
.code
; --------------------------------------------------------------------------------------------------

start:
	call main
	invoke ExitProcess,eax

; --------------------------------------------------------------------------------------------------

StreamOutProc proc hFile:DWORD,pBuffer:DWORD, NumBytes:DWORD, pBytesWritten:DWORD
	invoke WriteFile,hFile,pBuffer,NumBytes,pBytesWritten,0
	xor eax,1
	ret
StreamOutProc endp

; --------------------------------------------------------------------------------------------------

main proc
	; Variables for some sort of dialog stuff.
	LOCAL rvl   :DWORD
	LOCAL arr[4]:DWORD
	LOCAL parr  :DWORD
	LOCAL icce:INITCOMMONCONTROLSEX

	; Buffers for processing command line arguments.
	LOCAL CmdBuffer[MAX_PATH]:BYTE

	;Get the application folder, and copy it to the path buffer.
	invoke GetAppPath,ADDR PathBuffer
	
	;See if we have 1 argument, and copy it to the command buffer.
	invoke GetCL,1,ADDR CmdBuffer
	
	; If we have no argument 
	.if eax == 1
		;Convert the path from relative to the full path.
		invoke GetFullPathName, ADDR CmdBuffer, sizeof MAX_PATH, ADDR PathBuffer,0
	.endif

	;Create string with git path and text file location
	strcat ADDR CommitFile,ADDR PathBuffer,"\.git\commit.txt"

	mov hInstance, rv(GetModuleHandle,NULL)
	mov icce.dwSize, SIZEOF INITCOMMONCONTROLSEX
	xor eax, eax
	mov icce.dwICC, eax
	invoke InitCommonControlsEx,ADDR icce

	fn LoadLibrary,"RICHED32.DLL"

	lea eax, arr
	mov parr, eax
	push esi
	mov esi, parr
	mov [esi],   rv(LoadIcon,hInstance,5)
	sas [esi+4], "git Micro GUI"
	pop esi

	mov rvl, rv(create_dialog,hInstance,parr)
	CallModalDialog hInstance,0,create_dialog,NULL

	ret

main endp

; --------------------------------------------------------------------------------------------------

create_dialog proc iinstance:DWORD,extra:DWORD

	Dialog "git Micro GUI", \               ; caption
	       "MS Sans Serif",8, \             ; font,pointsize
	        WS_OVERLAPPED or \              ; styles for
	        WS_SYSMENU or DS_CENTER, \      ; dialog window
	        3, \                            ; number of controls
	        50,50,380,245, \                ; x y co-ordinates
	        1024                            ; memory buffer size

	editstyle = WS_VISIBLE or WS_CHILDWINDOW or WS_BORDER or \
		    ES_MULTILINE or WS_VSCROLL or WS_HSCROLL or \
		    ES_AUTOHSCROLL or ES_AUTOVSCROLL or ES_NOHIDESEL or ES_WANTRETURN

	DlgRichEdit editstyle,1,1,300,225,99
	DlgButton "Commit",WS_TABSTOP,315,10,50,13,100
	DlgButton "Exit",WS_TABSTOP,315,25,50,13,IDCANCEL

	CallModalDialog iinstance,0,DlgProc,extra

	ret

create_dialog endp

; --------------------------------------------------------------------------------------------------

DlgProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD 
	LOCAL editstream:EDITSTREAM
	LOCAL hFile:DWORD
	Switch uMsg
		Case WM_INITDIALOG
	
		push esi
		mov esi, lParam
		invoke SendMessage,hWin,WM_SETICON,1,[esi]
		invoke SetWindowText,hWin,[esi+4]
		pop esi
	
		mov hEdit, rv(GetDlgItem,hWin,99)
		invoke SendMessage,hEdit,EM_EXLIMITTEXT,0,1000000000
	
		fn SendMessage,hEdit,WM_SETFONT,rv(GetStockObject,ANSI_FIXED_FONT),TRUE
	
		m2m hWnd, hWin
		mov eax, 1
		ret
	Case WM_COMMAND

	Switch wParam
		Case 100
			;Clear variables for safety.
			mov cmd1,0
			mov cmd2,0
			mov ErrFile,0

			;Set cmd1 to "cd <path> && git add -A"
			strcat ADDR cmd1,"cd ", ADDR PathBuffer," && git add -A"
			invoke system, ADDR cmd1

			;Create file based on the CommitFile name
			invoke CreateFile,ADDR CommitFile,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
			
			;If the function was improperly handled.
			.if eax == INVALID_HANDLE_VALUE
				strcat ADDR ErrFile,ADDR ErrFileBase, ADDR CommitFile
				invoke MessageBox,NULL,ADDR ErrFile,0,MB_OK

			;If it worked correctly.
			.else
				mov hFile,eax
				mov editstream.dwCookie,eax
				mov editstream.pfnCallback,offset StreamOutProc
				invoke SendMessage,hEdit,EM_STREAMOUT,SF_TEXT,addr editstream
				invoke CloseHandle,hFile

				;Set cmd2 to "cd <path> git commit -F .git/commit.txt && push origin master"
				strcat ADDR cmd2,"cd ", ADDR PathBuffer," && git commit -F ",ADDR CommitFile," && git push origin master"
				invoke system, ADDR cmd2
			.endif

		Case IDCANCEL
			invoke EndDialog,hWin,1
			EndSw
		Case WM_CLOSE
			invoke EndDialog,hWin,0
			EndSw
	return 0
DlgProc endp

; --------------------------------------------------------------------------------------------------

end start
