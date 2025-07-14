@echo off
chcp 932 >nul

REM ========================================
REM Git AutoCRLF�������{�L���b�V���N���A�c�[��
REM ========================================

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"
set "REPO_LIST_FILE=%SCRIPT_DIR%conf\repositories.txt"
set "LOG_DIR=%SCRIPT_DIR%log"
set "BACKUP_DIR=%SCRIPT_DIR%backup"

REM PowerShell���g�p���Ĉ��S�ȓ��t����������𐶐�
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "DATETIME_STR=%%i"
set "LOG_FILE=%LOG_DIR%\git-autocrlf-disable-cache-clear_%DATETIME_STR%.log"

REM ���O�t�@�C���̐�΃p�X���ipushd��ł����������삷��悤�Ɂj
for %%i in ("%LOG_FILE%") do set "LOG_FILE_ABS=%%~fi"

REM �����ݒ�̌���
call :ValidateSetup || goto :SetupError
setlocal enabledelayedexpansion

echo ========================================
echo Git AutoCRLF �������{�L���b�V���N���A �c�[��
echo ========================================
echo.
echo ���s���[�h��I�����Ă�������:
echo 1. AutoCRLF�������{�L���b�V���N���A���s�i���|�W�g���S�̃o�b�N�A�b�v�t���j
echo 2. ���|�W�g�����m�F
echo 3. �X�^�b�V���ꗗ�\��  
echo 4. git-autocrlf-disable�֘A�X�^�b�V������
echo 5. �I��
echo.
set /p "MODE=�I�����Ă������� (1-5): "

if "%MODE%"=="1" goto :MainProcess
if "%MODE%"=="2" goto :CheckRepositories
if "%MODE%"=="3" goto :ListStashes
if "%MODE%"=="4" goto :RestoreStashes
if "%MODE%"=="5" goto :Exit

echo �����ȑI���ł��B
pause
endlocal
exit /b 1

:SetupError
echo.
echo ========================================
echo �Z�b�g�A�b�v�G���[
echo ========================================
echo �����ݒ�ɖ�肪����܂��B�ȉ����m�F���Ă��������F
echo.
echo �� ���̃c�[�����񋟂���Ώ��@�F
echo   1. setup.bat �����s���ď����ݒ���������Ă�������
echo   2. conf\config.txt �� BASE_DIR �𐳂����ݒ肵�Ă�������
echo   3. conf\repositories.txt �Ƀ��|�W�g������񋓂��Ă�������
echo.
echo �� ��ʓI�ȃg���u���V���[�e�B���O�F
echo   - �t�@�C���p�X�ɃX�y�[�X����ꕶ�����܂܂�Ă��Ȃ����m�F
echo   - �f�B�X�N�̋󂫗e�ʂ��\���ɂ��邩�m�F
echo   - �E�C���X�΍�\�t�g�ɂ��u���b�N���Ȃ����m�F
echo.
pause
exit /b 1

:Exit
echo �c�[�����I�����܂��B
endlocal
exit /b 0

:MainProcess
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

REM ���O�f�B���N�g���ƃo�b�N�A�b�v�f�B���N�g���̍쐬
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM ���O�t�@�C��������
echo [%date% %time%] Git AutoCRLF �������{�L���b�V���N���A�����J�n�i2�t�F�[�Y���s�E���|�W�g���S�̃o�b�N�A�b�v�t���j > "%LOG_FILE_ABS%"

echo �x�[�X�f�B���N�g��: %BASE_DIR%
echo ���O�t�@�C��: %LOG_FILE%
echo.

REM �O���[�o��autocrlf�ݒ�̊m�F�ƕύX
echo �O���[�o��autocrlf�ݒ�̊m�F��...
for /f "tokens=*" %%a in ('git config --global core.autocrlf 2^>nul') do set "GLOBAL_AUTOCRLF=%%a"
if not defined GLOBAL_AUTOCRLF set "GLOBAL_AUTOCRLF=���ݒ�"
echo   ���݂̃O���[�o���ݒ�: %GLOBAL_AUTOCRLF%

echo   ���s: git config --global core.autocrlf false
git config --global core.autocrlf false
if not errorlevel 1 (
    echo   �O���[�o��autocrlf�ݒ��false�ɕύX���܂���
    echo [%date% %time%] �O���[�o��autocrlf�ݒ��false�ɕύX >> "%LOG_FILE_ABS%"
) else (
    echo �x��: �O���[�o��autocrlf�ݒ�̕ύX�Ɏ��s���܂���
    echo [%date% %time%] �x��: �O���[�o��autocrlf�ݒ�ύX���s >> "%LOG_FILE_ABS%"
)
echo.

REM ���|�W�g�����X�g�̕\��
echo �Ώۃ��|�W�g��:
echo ----------------------------------------
type "%REPO_LIST_FILE%"
echo ----------------------------------------
echo.

echo.
echo ========================================
echo �d�v�Ȓ��ӎ���
echo ========================================
echo �o�b�`���s���͑Ώۃ��|�W�g����Eclipse���̊֘A�c�[����
echo �g�p���Ȃ��ł��������B
echo.
echo - Git������s���c�[���iEclipse�AIntelliJ�ASourceTree���j����Ă�������
echo - �Ώۃf�B���N�g�����̃t�@�C���𒼐ڕҏW���Ȃ��ł�������
echo - �o�b�N�A�b�v�ƃ��Z�b�g��������������܂ł��҂���������
echo ========================================
echo.

set /p "CONFIRM=��L�𗝉����ď��������s���܂����H (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo �������L�����Z�����܂����B
    pause
    endlocal
    exit /b 0
)

echo.
echo ========================================
echo �t�F�[�Y1: �S���|�W�g���̃o�b�N�A�b�v���s
echo ========================================
echo.

set "BACKUP_SUCCESS_COUNT=0"
set "BACKUP_ERROR_COUNT=0"

REM �S���|�W�g���̃o�b�N�A�b�v���ŏ��Ɏ��s
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    REM �R�����g�s��empty�s���X�L�b�v
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :BackupRepository "!REPO_NAME!"
        )
    )
)

echo.
echo ========================================
echo �o�b�N�A�b�v����
echo ========================================
echo ����: %BACKUP_SUCCESS_COUNT% ���|�W�g��
echo �G���[: %BACKUP_ERROR_COUNT% ���|�W�g��

if %BACKUP_ERROR_COUNT% gtr 0 (
    echo.
    echo �G���[: �o�b�N�A�b�v�Ɏ��s�������|�W�g�������邽�߁A
    echo �ύX�����𒆎~���܂��B
    echo ���O�t�@�C��: %LOG_FILE%
    echo.
    pause
    endlocal
    exit /b 1
)

echo.
echo ========================================
echo �t�F�[�Y2: AutoCRLF�ݒ�ύX�E�L���b�V���N���A���s
echo ========================================
echo.

set "SUCCESS_COUNT=0"
set "ERROR_COUNT=0"

REM �S�o�b�N�A�b�v�����������ꍇ�̂ݕύX���������s
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    REM �R�����g�s��empty�s���X�L�b�v
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :ProcessRepository "!REPO_NAME!"
        )
    )
)

echo.
echo ========================================
echo ��������
echo ========================================
echo �o�b�N�A�b�v����: %BACKUP_SUCCESS_COUNT% ���|�W�g��
echo �ύX��������: %SUCCESS_COUNT% ���|�W�g��
echo �ύX�����G���[: %ERROR_COUNT% ���|�W�g��
echo ���O�t�@�C��: %LOG_FILE%
echo.

pause
endlocal
exit /b 0

REM ========================================
REM �o�b�N�A�b�v��p�����֐�
REM ========================================
:BackupRepository
setlocal enabledelayedexpansion
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo �o�b�N�A�b�v��: %REPO_NAME%
echo ----------------------------------------

REM ���O�o��
echo [%date% %time%] �o�b�N�A�b�v�J�n: %REPO_NAME% >> "%LOG_FILE_ABS%"

REM ���|�W�g���f�B���N�g���̊m�F
if not exist "%REPO_PATH%" (
    echo �G���[: ���|�W�g���f�B���N�g����������܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: �f�B���N�g���s���� %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a BACKUP_ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM .git�f�B���N�g���̊m�F
if not exist "%REPO_PATH%\.git" (
    echo �G���[: Git���|�W�g���ł͂���܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: Git���|�W�g���ł͂Ȃ� %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a BACKUP_ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM ���|�W�g���S�̂̃o�b�N�A�b�v�쐬
REM PowerShell���g�p���ăo�b�N�A�b�v�p�^�C���X�^���v����
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "BACKUP_TIMESTAMP=%%i"
set "REPO_BACKUP_DIR=%BACKUP_DIR%\%REPO_NAME%_full_%BACKUP_TIMESTAMP%"

call :CreateFullRepositoryBackup "%REPO_PATH%" "%REPO_BACKUP_DIR%" || (
    echo �G���[: ���|�W�g���S�̂̃o�b�N�A�b�v�Ɏ��s���܂���
    echo [%date% %time%] �G���[: �S�̃o�b�N�A�b�v���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    set /a BACKUP_ERROR_COUNT+=1
    endlocal
    goto :eof
)

echo ����: %REPO_NAME% �̃o�b�N�A�b�v���������܂���
echo [%date% %time%] �o�b�N�A�b�v����: %REPO_NAME% >> "%LOG_FILE_ABS%"
set /a BACKUP_SUCCESS_COUNT+=1

endlocal
goto :eof

REM ========================================
REM ���|�W�g�������֐�
REM ========================================
:ProcessRepository
setlocal enabledelayedexpansion
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo ������: %REPO_NAME%
echo ----------------------------------------

REM ���O�o��
echo [%date% %time%] �����J�n: %REPO_NAME% >> "%LOG_FILE_ABS%"

REM ���|�W�g���f�B���N�g���̊m�F
if not exist "%REPO_PATH%" (
    echo �G���[: ���|�W�g���f�B���N�g����������܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: �f�B���N�g���s���� %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM .git�f�B���N�g���̊m�F
if not exist "%REPO_PATH%\.git" (
    echo �G���[: Git���|�W�g���ł͂���܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: Git���|�W�g���ł͂Ȃ� %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM �h���C�u���ׂ��\�������邽�߁A�f�B���N�g���ړ�
pushd "%REPO_PATH%" || (
    echo �G���[: �f�B���N�g���Ɉړ��ł��܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: �f�B���N�g���ړ����s %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM ���݂̃X�e�[�^�X�m�F
echo 1. �X�e�[�^�X�m�F��...
call :CheckGitStatus || (
    echo �G���[: Git��Ԋm�F�Ɏ��s���܂���
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

REM �ύX������ꍇ�̃X�^�b�V��
echo 2. �ύX�m�F�E�X�^�b�V����...
call :HandleChanges || (
    echo �G���[: �ύX�����Ɏ��s���܂���
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

REM ���݂�autocrlf�ݒ�m�F
echo 3. ���݂�autocrlf�ݒ�m�F��...
echo   ���s: git config core.autocrlf
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "CURRENT_AUTOCRLF=%%a"
if not defined CURRENT_AUTOCRLF set "CURRENT_AUTOCRLF=���ݒ�"
echo   ���݂̐ݒ�: %CURRENT_AUTOCRLF%
echo [%date% %time%] ���݂�autocrlf�ݒ�: %CURRENT_AUTOCRLF% %REPO_NAME% >> "%LOG_FILE_ABS%"

REM autocrlf=false �ɐݒ�
echo 4. autocrlf=false �ɐݒ蒆...
call :SetAutocrlfFalse || (
    echo �G���[: autocrlf�ݒ�ύX�Ɏ��s���܂���
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

REM Git�L���b�V�����N���A���ă��[�L���O�f�B���N�g����HEAD�ŏ㏑��
echo 5. Git�L���b�V���ꊇ�N���A�EHEAD���Z�b�g��...
call :ResetToHead || (
    echo �G���[: �L���b�V���N���A�EHEAD���Z�b�g�Ɏ��s���܂���
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

popd

echo 6. ����: %REPO_NAME%
echo [%date% %time%] ��������: %REPO_NAME% >> "%LOG_FILE_ABS%"
set /a SUCCESS_COUNT+=1

endlocal
goto :eof

REM ========================================
REM ���|�W�g�����m�F�@�\
REM ========================================
:CheckRepositories
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo ���|�W�g�����m�F
echo ========================================
echo �x�[�X�f�B���N�g��: %BASE_DIR%

REM �O���[�o��autocrlf�ݒ�̕\��
for /f "tokens=*" %%a in ('git config --global core.autocrlf 2^>nul') do set "GLOBAL_AUTOCRLF=%%a"
if not defined GLOBAL_AUTOCRLF set "GLOBAL_AUTOCRLF=���ݒ�"
echo �O���[�o��autocrlf�ݒ�: %GLOBAL_AUTOCRLF%
echo.

set "TOTAL_COUNT=0"
set "VALID_COUNT=0"
set "CHECK_ERROR_COUNT=0"

for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            set /a TOTAL_COUNT+=1
            call :CheckRepository "!REPO_NAME!"
        )
    )
)

echo.
echo ========================================
echo �W�v����
echo ========================================
echo ����: %TOTAL_COUNT% ���|�W�g��
echo �L��: %VALID_COUNT% ���|�W�g��
echo �G���[: %CHECK_ERROR_COUNT% ���|�W�g��
echo.
pause
endlocal
exit /b 0

:CheckRepository
setlocal enabledelayedexpansion
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo %REPO_NAME%
echo ----------------------------------------

if not exist "%REPO_PATH%" (
    echo   ���: �f�B���N�g�������݂��܂���
    echo   �p�X: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    endlocal
    goto :eof
)

if not exist "%REPO_PATH%\.git" (
    echo   ���: Git���|�W�g���ł͂���܂���
    echo   �p�X: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    endlocal
    goto :eof
)

pushd "%REPO_PATH%" || (
    endlocal
    goto :eof
)

REM ���݂̃u�����`
for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%b"
if not defined CURRENT_BRANCH set "CURRENT_BRANCH=�s��"

REM autocrlf�ݒ�
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "AUTOCRLF=%%a"
if not defined AUTOCRLF set "AUTOCRLF=���ݒ�"

REM �ύX��
git diff --quiet 2>nul
if not errorlevel 1 (
    set "HAS_CHANGES=�Ȃ�"
) else (
    set "HAS_CHANGES=����"
)

REM �X�^�b�V����
for /f "tokens=*" %%s in ('git stash list 2^>nul ^| find /c /v ""') do set "STASH_COUNT=%%s"
if not defined STASH_COUNT set "STASH_COUNT=0"

REM git-autocrlf-disable�֘A�X�^�b�V����
for /f "tokens=*" %%t in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-disable" ^| find /c /v ""') do set "DISABLE_STASH_COUNT=%%t"
if not defined DISABLE_STASH_COUNT set "DISABLE_STASH_COUNT=0"

popd

echo   ���: ����
echo   �p�X: %REPO_PATH%
echo   �u�����`: %CURRENT_BRANCH%
echo   autocrlf: %AUTOCRLF%
echo   ���ۑ��ύX: %HAS_CHANGES%
echo   �X�^�b�V����: %STASH_COUNT% (disable�֘A: %DISABLE_STASH_COUNT%)

set /a VALID_COUNT+=1

popd
endlocal
goto :eof

REM ========================================
REM �X�^�b�V���ꗗ�\���@�\
REM ========================================
:ListStashes
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo �X�^�b�V���ꗗ
echo ========================================
echo �x�[�X�f�B���N�g��: %BASE_DIR%
echo.

for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :ShowRepositoryStashes "!REPO_NAME!"
        )
    )
)

pause
endlocal
exit /b 0

:ShowRepositoryStashes
setlocal enabledelayedexpansion
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

if not exist "%REPO_PATH%\.git" (
    endlocal
    goto :eof
)

echo ----------------------------------------
echo %REPO_NAME%
echo ----------------------------------------

pushd "%REPO_PATH%" || (
    endlocal
    goto :eof
)

git stash list 2>nul | findstr /C:"git-autocrlf-disable" >nul
if not errorlevel 1 (
    git stash list 2>nul
) else (
    git stash list 2>nul | find /c /v "" > temp_count.txt
    set /p STASH_COUNT=<temp_count.txt
    del temp_count.txt
    if !STASH_COUNT! gtr 0 (
        echo �X�^�b�V����: !STASH_COUNT! �igit-autocrlf-disable�֘A�Ȃ��j
        git stash list 2>nul
    ) else (
        echo �X�^�b�V���Ȃ�
    )
)

popd
endlocal
goto :eof

REM ========================================
REM git-autocrlf-disable�֘A�X�^�b�V�������@�\
REM ========================================
:RestoreStashes
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo git-autocrlf-disable�֘A�X�^�b�V������
echo ========================================
echo �x�[�X�f�B���N�g��: %BASE_DIR%
echo.
echo ����: ���̑���ɂ��Agit-autocrlf-disable�ō쐬���ꂽ
echo �X�^�b�V������������܂��B���݂̕ύX�͎�����\��������܂��B
echo.
set /p "RESTORE_CONFIRM=���s���܂����H (Y/N): "
if /i not "%RESTORE_CONFIRM%"=="Y" (
    echo �L�����Z�����܂����B
    pause
    endlocal
    exit /b 0
)

for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :RestoreRepositoryStash "!REPO_NAME!"
        )
    )
)

pause
endlocal
exit /b 0

:RestoreRepositoryStash
setlocal enabledelayedexpansion
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

if not exist "%REPO_PATH%\.git" (
    endlocal
    goto :eof
)

echo ----------------------------------------
echo %REPO_NAME%
echo ----------------------------------------

pushd "%REPO_PATH%" || (
    endlocal
    goto :eof
)

REM git-autocrlf-disable�֘A�̃X�^�b�V��������
for /f "tokens=1,* delims=:" %%a in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-disable"') do (
    set "STASH_REF=%%a"
    set "STASH_MSG=%%b"
    echo �X�^�b�V������: !STASH_REF! -!STASH_MSG!
    git stash pop "!STASH_REF!" 2>nul
    if not errorlevel 1 (
        echo ����: �X�^�b�V���𕜌����܂���
    ) else (
        echo �G���[: �X�^�b�V�������Ɏ��s���܂���
    )
    goto :RestoreRepositoryStashEnd
)

echo git-autocrlf-disable�֘A�̃X�^�b�V����������܂���

:RestoreRepositoryStashEnd
popd
endlocal
goto :eof

REM ========================================
REM �ݒ�ƃG���[�n���h�����O�֐�
REM ========================================

:ValidateSetup
setlocal
REM �f�B���N�g���쐬
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM ��{�t�@�C���̑��݊m�F
if not exist "%CONFIG_FILE%" (
    echo �G���[: �ݒ�t�@�C�� %CONFIG_FILE% ��������܂���B
    endlocal
    exit /b 1
)

if not exist "%REPO_LIST_FILE%" (
    echo �G���[: ���|�W�g�����X�g�t�@�C�� %REPO_LIST_FILE% ��������܂���B
    endlocal
    exit /b 1
)

endlocal
exit /b 0

:LoadConfig
setlocal
REM �ݒ�ǂݍ���
echo �ݒ�t�@�C���ǂݍ��ݒ�: %CONFIG_FILE%
if not exist "%CONFIG_FILE%" (
    echo �G���[: �ݒ�t�@�C�������݂��܂���: %CONFIG_FILE%
    endlocal
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    if "%%a"=="BASE_DIR" (
        set "BASE_DIR=%%b"
        echo �ǂݍ���: BASE_DIR=%%b
    )
    if "%%a"=="SEVENZIP_PATH" (
        set "SEVENZIP_PATH=%%b"
        echo �ǂݍ���: SEVENZIP_PATH=%%b
    )
)
endlocal & set "BASE_DIR=%BASE_DIR%" & set "SEVENZIP_PATH=%SEVENZIP_PATH%"
exit /b 0

:ValidateConfig
setlocal
REM BASE_DIR�ݒ�m�F
if not defined BASE_DIR (
    echo �G���[: BASE_DIR ���ݒ肳��Ă��܂���B
    endlocal
    exit /b 1
)

REM BASE_DIR�̑��݊m�F
if not exist "%BASE_DIR%" (
    echo �G���[: BASE_DIR �Ŏw�肳�ꂽ�f�B���N�g�������݂��܂���: %BASE_DIR%
    endlocal
    exit /b 1
)

REM 7z.exe�̕K�{�m�F�i7z.exe���K�{�ɂȂ����̂Ōx���ɕύX�j
if defined SEVENZIP_PATH (
    if not exist "%SEVENZIP_PATH%" (
        echo �G���[: �w�肳�ꂽ7z.exe��������܂���: %SEVENZIP_PATH%
        echo ���̐V�o�[�W�����ł�7z.exe�͕K�{�ł��B
        endlocal
        exit /b 1
    )
) else (
    echo �G���[: SEVENZIP_PATH���ݒ肳��Ă��܂���B
    echo ���̐V�o�[�W�����ł�7z.exe�͕K�{�ł��B
    endlocal
    exit /b 1
)

endlocal
exit /b 0

:CreateBackup
setlocal enabledelayedexpansion
set "SOURCE_PATH=%~1"
set "BACKUP_PATH=%~2"

REM 7z.exe�g�p���K�{
if not defined SEVENZIP_PATH (
    echo �G���[: 7z.exe���ݒ肳��Ă��܂���
    endlocal
    exit /b 1
)

echo   ���s: "%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5
"%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 2>&1
if not errorlevel 1 (
    echo   7z���k�o�b�N�A�b�v����: %BACKUP_PATH%.7z
    echo [%date% %time%] 7z���k�o�b�N�A�b�v����: %BACKUP_PATH%.7z >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 0
) else (
    echo �G���[: 7z���k�Ɏ��s���܂����i�I���R�[�h: %ERRORLEVEL%�j
    echo [%date% %time%] �G���[: 7z���k���s�i�I���R�[�h: %ERRORLEVEL%�j %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:CreateFullRepositoryBackup
setlocal enabledelayedexpansion
set "SOURCE_PATH=%~1"
set "BACKUP_PATH=%~2"

REM 7z.exe�g�p���K�{
if not defined SEVENZIP_PATH (
    echo �G���[: 7z.exe���ݒ肳��Ă��܂���
    endlocal
    exit /b 1
)

echo   ���s: "%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5
"%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 2>&1
if not errorlevel 1 (
    echo   ���|�W�g���S�̂�7z���k�o�b�N�A�b�v����: %BACKUP_PATH%.7z
    echo [%date% %time%] ���|�W�g���S�̂�7z���k�o�b�N�A�b�v����: %BACKUP_PATH%.7z >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 0
) else (
    echo �G���[: ���|�W�g���S�̂�7z���k�Ɏ��s���܂����i�I���R�[�h: %ERRORLEVEL%�j
    echo [%date% %time%] �G���[: ���|�W�g���S�̂�7z���k���s�i�I���R�[�h: %ERRORLEVEL%�j %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:CheckGitStatus
setlocal
echo   ���s: git status --porcelain
git status --porcelain >nul 2>&1
if not errorlevel 1 (
    endlocal
    exit /b 0
) else (
    echo �G���[: git status �����s���܂���
    echo [%date% %time%] �G���[: git status���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:HandleChanges
setlocal enabledelayedexpansion
echo   ���s: git diff --quiet
git diff --quiet 2>nul
if not errorlevel 1 (
    echo �ύX�Ȃ��i�X�^�b�V���s�v�j
    endlocal
    exit /b 0
) else (
    echo �ύX�����o���܂����B�X�^�b�V�����쐬���܂�...
    REM PowerShell���g�p���ăX�^�b�V�����b�Z�[�W�p�̈��S�ȓ��t�����𐶐�
    for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"') do set "STASH_DATETIME=%%i"
    echo   ���s: git stash push -m "git-autocrlf-disable: !STASH_DATETIME!"
    git stash push -m "git-autocrlf-disable: !STASH_DATETIME!" >> "%LOG_FILE_ABS%" 2>&1
    if not errorlevel 1 (
        echo [%date% %time%] �X�^�b�V���쐬���� %REPO_NAME% >> "%LOG_FILE_ABS%"
        endlocal
        exit /b 0
    ) else (
        echo �G���[: �X�^�b�V���̍쐬�Ɏ��s���܂���
        echo [%date% %time%] �G���[: �X�^�b�V���쐬���s %REPO_NAME% >> "%LOG_FILE_ABS%"
        endlocal
        exit /b 1
    )
)

:SetAutocrlfFalse
setlocal
echo   ���s: git config core.autocrlf false
git config core.autocrlf false >> "%LOG_FILE_ABS%" 2>&1
if not errorlevel 1 (
    endlocal
    exit /b 0
) else (
    echo �G���[: autocrlf�ݒ�̕ύX�Ɏ��s���܂���
    echo [%date% %time%] �G���[: autocrlf�ݒ�ύX���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:ResetToHead
setlocal
echo   ���s: git rm --cached -r .
git rm --cached -r . >> "%LOG_FILE_ABS%" 2>&1
echo   ���s: git reset --hard HEAD
git reset --hard HEAD >> "%LOG_FILE_ABS%" 2>&1
if not errorlevel 1 (
    REM ���[�L���O�f�B���N�g�����N���[���A�b�v
    echo   ���s: git clean -fd
    git clean -fd >> "%LOG_FILE_ABS%" 2>&1

    echo   ����: Git�L���b�V���N���A�E���[�L���O�f�B���N�g����HEAD�̏�Ԃɕ������܂���
    echo [%date% %time%] �L���b�V���N���A�EHEAD���Z�b�g�E�N���[���A�b�v���� %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 0
) else (
    echo �G���[: �L���b�V���N���A�EHEAD���Z�b�g�Ɏ��s���܂���
    echo [%date% %time%] �G���[: �L���b�V���N���A�EHEAD���Z�b�g���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

REM ========================================
REM �G���[�n���h�����O�p���x��
REM ========================================

:ConfigError
echo.
echo ========================================
echo �ݒ�G���[
echo ========================================
echo.
echo �� ���̃c�[�����񋟂���Ώ��@�F
echo   1. conf\config.txt �� BASE_DIR �𐳂����ݒ肵�Ă�������
echo   2. �w�肵���f�B���N�g�������݂��邱�Ƃ��m�F���Ă�������
echo   3. setup.bat ���Ď��s���Đݒ�t�@�C������蒼���Ă�������
echo.
echo �� ��ʓI�ȃg���u���V���[�e�B���O�F
echo   - �p�X����2�o�C�g��������ꕶ�����܂܂�Ă��Ȃ����m�F
echo   - �l�b�g���[�N�h���C�u������ă��[�J���h���C�u���g�p
echo   - ���[�U�[�����ŃA�N�Z�X�\�ȃf�B���N�g�����ǂ����m�F
echo.
pause
endlocal
exit /b 1
