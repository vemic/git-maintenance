@echo off
chcp 932 >nul

rem ========================================
rem Git AutoCRLF�������{�L���b�V���N���A�c�[��
rem ========================================

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"
set "REPO_LIST_FILE=%SCRIPT_DIR%conf\repositories.txt"
set "LOG_DIR=%SCRIPT_DIR%log"
set "BACKUP_DIR=%SCRIPT_DIR%backup"

rem PowerShell���g�p���Ĉ��S�ȓ��t����������𐶐�
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "DATETIME_STR=%%i"
set "LOG_FILE=%LOG_DIR%\git-autocrlf-disable-cache-clear_%DATETIME_STR%.log"

rem ���O�t�@�C���̐�΃p�X���ipushd��ł����������삷��悤�Ɂj
for %%i in ("%LOG_FILE%") do set "LOG_FILE_ABS=%%~fi"

rem ���ˑ����`�F�b�N
call :CheckEnvironment || goto :EnvironmentError

rem �����ݒ�̌���
call :ValidateSetup || goto :SetupError
setlocal enabledelayedexpansion

:MainMenu
echo ========================================
echo Git AutoCRLF �������{�L���b�V���N���A �c�[��
echo ========================================
echo.
echo ���s���[�h��I�����Ă�������:
echo 1. AutoCRLF�������{�L���b�V���N���A���s
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

echo �����ȑI���ł��B�ē��͂��Ă��������B
goto :MainMenu

:EnvironmentError
echo.
echo ========================================
echo ���G���[
echo ========================================
echo ���̃c�[���͈ȉ��̊����K�v�ł��F
echo.
echo �� �K�{���F
echo   - Windows OS (CP932/Shift_JIS�Ή�)
echo   - PowerShell (���t���������p)
echo   - 7-Zip (7z.exe) - �o�b�N�A�b�v��p
echo.
echo �� ���o���ꂽ���F
echo   - PowerShell�܂���7z.exe��������܂���
echo   - conf\config.txt�Ő�����7z.exe�p�X��ݒ肵�Ă�������
echo.
echo �� ���ӎ����F
echo   - xcopy�o�b�N�A�b�v�͈��S���̊ϓ_����p�~����܂���
echo   - 7z.exe�����p�ł��Ȃ��ꍇ�͏����𒆎~���܂�
echo.
pause
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
exit /b 0

:MainProcess
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

rem ���O�f�B���N�g���ƃo�b�N�A�b�v�f�B���N�g���̍쐬
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

rem ���O�t�@�C��������
echo [%date% %time%] Git AutoCRLF �������{�L���b�V���N���A�����J�n > "%LOG_FILE_ABS%"

echo �x�[�X�f�B���N�g��: %BASE_DIR%
echo ���O�t�@�C��: %LOG_FILE%
echo.

rem �O���[�o��autocrlf�ݒ�̊m�F�ƕύX
echo �O���[�o��autocrlf�ݒ�̊m�F��...
for /f "tokens=*" %%a in ('git config --global core.autocrlf 2^>nul') do set "GLOBAL_AUTOCRLF=%%a"
if not defined GLOBAL_AUTOCRLF set "GLOBAL_AUTOCRLF=���ݒ�"
echo   ���݂̃O���[�o���ݒ�: %GLOBAL_AUTOCRLF%

echo   ���s: git config --global core.autocrlf false
git config --global core.autocrlf false
if errorlevel 1 (
    echo �x��: �O���[�o��autocrlf�ݒ�̕ύX�Ɏ��s���܂���
    echo [%date% %time%] �x��: �O���[�o��autocrlf�ݒ�ύX���s >> "%LOG_FILE_ABS%"
) else (
    echo   �O���[�o��autocrlf�ݒ��false�ɕύX���܂���
    echo [%date% %time%] �O���[�o��autocrlf�ݒ��false�ɕύX >> "%LOG_FILE_ABS%"
)
echo.

rem ���|�W�g�����X�g�̕\���Əڍ׊m�F
echo �Ώۃ��|�W�g��:
echo ----------------------------------------
type "%REPO_LIST_FILE%"
echo ----------------------------------------
echo.

rem �����Ώۃ��|�W�g�����̕\��
set "TARGET_COUNT=0"
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            set /a TARGET_COUNT+=1
        )
    )
)
echo �����Ώ�: %TARGET_COUNT% ���|�W�g��
echo.

rem �������e�̏ڍא���
echo ========================================
echo ���s����鏈�����e
echo ========================================
echo 1. �e���|�W�g���S�̂�7z�`���Ŋ��S�o�b�N�A�b�v
echo 2. ���R�~�b�g�ύX�̎����X�^�b�V��
echo 3. core.autocrlf=false �ւ̐ݒ�ύX
echo 4. git rm --cached -r . (�S�t�@�C���L���b�V���N���A)
echo 5. git reset --hard HEAD (HEAD�ւ̋������Z�b�g)
echo 6. git clean -fd (���ǐՃt�@�C���폜)
echo.
echo �� ���ӁF���ǐՃt�@�C���͊��S�ɍ폜����܂�
echo �� �o�b�N�A�b�v��F%BACKUP_DIR%
echo �� ���O�o�͐�F%LOG_FILE%
echo.

:ConfirmLoop
set /p "CONFIRM=���������s���܂����H (Y/n): "
if "%CONFIRM%"=="" set "CONFIRM=Y"
if /i "%CONFIRM%"=="Y" goto :StartProcess
if /i "%CONFIRM%"=="N" (
    echo �������L�����Z�����܂����B
    pause
    exit /b 0
)
echo �����ȓ��͂ł��BY�܂���N����͂��Ă��������B
goto :ConfirmLoop

:StartProcess

echo.
echo �������J�n���܂�...
echo.

set "SUCCESS_COUNT=0"
set "ERROR_COUNT=0"

rem ���|�W�g�����X�g�̏���
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    rem �R�����g�s��empty�s���X�L�b�v
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :ProcessRepository "!REPO_NAME!"
        )
    )
)

echo.
echo ========================================
echo ���������T�}���[
echo ========================================
echo ����: %SUCCESS_COUNT% ���|�W�g��
echo �G���[: %ERROR_COUNT% ���|�W�g��
echo �����Ώ�: %TARGET_COUNT% ���|�W�g��
echo.
echo �� �o�b�N�A�b�v��: %BACKUP_DIR%
echo �� ���O�t�@�C��: %LOG_FILE%
echo.
if %ERROR_COUNT% GTR 0 (
    echo ������ �x��: �G���[�������������|�W�g��������܂� ������
    echo ������ ���O�t�@�C���ŏڍׂ��m�F���Ă������� ������
) else (
    echo ������ �S���|�W�g���̏���������Ɋ������܂��� ������
)
echo.

pause
exit /b 0

rem ========================================
rem ���|�W�g�������֐��i���S���d���Łj
rem ========================================
:ProcessRepository
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"
set "PUSHD_SUCCESS=0"

echo ========================================
echo ������: %REPO_NAME%
echo ========================================

rem ���O�o��
echo [%date% %time%] �����J�n: %REPO_NAME% >> "%LOG_FILE_ABS%"

rem ���|�W�g���f�B���N�g���̊m�F
if not exist "%REPO_PATH%" (
    echo �G���[: ���|�W�g���f�B���N�g����������܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: �f�B���N�g���s���� %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem .git�f�B���N�g���̊m�F
if not exist "%REPO_PATH%\.git" (
    echo �G���[: Git���|�W�g���ł͂���܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: Git���|�W�g���ł͂Ȃ� %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem �X�e�b�v1: ���|�W�g���S�̂�7z�o�b�N�A�b�v�i�ŏd�v�j
echo 1. ���|�W�g���S�̃o�b�N�A�b�v�쐬��...
rem PowerShell���g�p���ăo�b�N�A�b�v�p�^�C���X�^���v����
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "BACKUP_TIMESTAMP=%%i"
set "REPO_BACKUP_DIR=%BACKUP_DIR%\%REPO_NAME%_FULL_%BACKUP_TIMESTAMP%"

call :CreateFullRepositoryBackup "%REPO_PATH%" "%REPO_BACKUP_DIR%" || (
    echo ������ �d��G���[: ���|�W�g���S�̂̃o�b�N�A�b�v�Ɏ��s���܂��� ������
    echo ������ �f�[�^�������X�N�̂��߁A���̃��|�W�g���̏����𒆒f���܂� ������
    echo [%date% %time%] �d��G���[: �S�̃o�b�N�A�b�v���s�ɂ�菈�����~ %REPO_NAME% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem �h���C�u���ׂ��\�������邽�߁A�f�B���N�g���ړ�
pushd "%REPO_PATH%" && set "PUSHD_SUCCESS=1" || (
    echo �G���[: �f�B���N�g���Ɉړ��ł��܂���: %REPO_PATH%
    echo [%date% %time%] �G���[: �f�B���N�g���ړ����s %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem �X�e�b�v2: ���݂̃X�e�[�^�X�m�F
echo 2. �X�e�[�^�X�m�F��...
call :CheckGitStatus || (
    echo �G���[: Git��Ԋm�F�Ɏ��s���܂���
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem �X�e�b�v3: �ύX������ꍇ�̃X�^�b�V��
echo 3. �ύX�m�F�E�X�^�b�V����...
call :HandleChanges || (
    echo �G���[: �ύX�����Ɏ��s���܂���
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem �X�e�b�v4: ���݂�autocrlf�ݒ�m�F
echo 4. ���݂�autocrlf�ݒ�m�F��...
echo   ���s: git config core.autocrlf
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "CURRENT_AUTOCRLF=%%a"
if not defined CURRENT_AUTOCRLF set "CURRENT_AUTOCRLF=���ݒ�"
echo   ���݂̐ݒ�: %CURRENT_AUTOCRLF%
echo [%date% %time%] ���݂�autocrlf�ݒ�: %CURRENT_AUTOCRLF% %REPO_NAME% >> "%LOG_FILE_ABS%"

rem �X�e�b�v5: autocrlf=false �ɐݒ�
echo 5. autocrlf=false �ɐݒ蒆...
call :SetAutocrlfFalse || (
    echo �G���[: autocrlf�ݒ�ύX�Ɏ��s���܂���
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem �X�e�b�v6: Git�L���b�V���N���A�EHEAD���Z�b�g�i�댯����j
echo 6. ������ �댯������s��: Git�L���b�V���ꊇ�N���A�EHEAD���Z�b�g ������
call :ResetToHead || (
    echo �G���[: �L���b�V���N���A�EHEAD���Z�b�g�Ɏ��s���܂���
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

if %PUSHD_SUCCESS%==1 popd

echo 7. ������ ����: %REPO_NAME% ������
echo [%date% %time%] ��������: %REPO_NAME% >> "%LOG_FILE_ABS%"
set /a SUCCESS_COUNT+=1

goto :eof

rem ========================================
rem ���|�W�g�����m�F�@�\
rem ========================================
:CheckRepositories
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo ���|�W�g�����m�F
echo ========================================
echo �x�[�X�f�B���N�g��: %BASE_DIR%

rem �O���[�o��autocrlf�ݒ�̕\��
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
exit /b 0

:CheckRepository
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo %REPO_NAME%
echo ----------------------------------------

if not exist "%REPO_PATH%" (
    echo   ���: �f�B���N�g�������݂��܂���
    echo   �p�X: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    goto :eof
)

if not exist "%REPO_PATH%\.git" (
    echo   ���: Git���|�W�g���ł͂���܂���
    echo   �p�X: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    goto :eof
)

pushd "%REPO_PATH%" || goto :eof

rem ���݂̃u�����`
for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%b"
if not defined CURRENT_BRANCH set "CURRENT_BRANCH=�s��"

rem autocrlf�ݒ�
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "AUTOCRLF=%%a"
if not defined AUTOCRLF set "AUTOCRLF=���ݒ�"

rem �ύX��
git diff --quiet 2>nul
if errorlevel 1 (
    set "HAS_CHANGES=����"
) else (
    set "HAS_CHANGES=�Ȃ�"
)

rem �X�^�b�V����
for /f "tokens=*" %%s in ('git stash list 2^>nul ^| find /c /v ""') do set "STASH_COUNT=%%s"
if not defined STASH_COUNT set "STASH_COUNT=0"

rem git-autocrlf-disable�֘A�X�^�b�V����
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

rem �ϐ��N���A
set "CURRENT_BRANCH="
set "AUTOCRLF="
set "HAS_CHANGES="
set "STASH_COUNT="
set "DISABLE_STASH_COUNT="

goto :eof

rem ========================================
rem �X�^�b�V���ꗗ�\���@�\
rem ========================================
:ListStashes
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
exit /b 0

:ShowRepositoryStashes
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

if not exist "%REPO_PATH%\.git" goto :eof

echo ----------------------------------------
echo %REPO_NAME%
echo ----------------------------------------

pushd "%REPO_PATH%" || goto :eof

git stash list 2>nul | findstr /C:"git-autocrlf-disable" >nul
if errorlevel 1 (
    git stash list 2>nul | find /c /v "" > temp_count.txt
    set /p STASH_COUNT=<temp_count.txt
    del temp_count.txt
    if !STASH_COUNT! gtr 0 (
        echo �X�^�b�V����: !STASH_COUNT! �igit-autocrlf-disable�֘A�Ȃ��j
        git stash list 2>nul
    ) else (
        echo �X�^�b�V���Ȃ�
    )
) else (
    git stash list 2>nul
)

popd
goto :eof

rem ========================================
rem git-autocrlf-disable�֘A�X�^�b�V�������@�\
rem ========================================
:RestoreStashes
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
exit /b 0

:RestoreRepositoryStash
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

if not exist "%REPO_PATH%\.git" goto :eof

echo ----------------------------------------
echo %REPO_NAME%
echo ----------------------------------------

pushd "%REPO_PATH%" || goto :eof

rem git-autocrlf-disable�֘A�̃X�^�b�V��������
for /f "tokens=1,* delims=:" %%a in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-disable"') do (
    set "STASH_REF=%%a"
    set "STASH_MSG=%%b"
    echo �X�^�b�V������: !STASH_REF! -!STASH_MSG!
    git stash pop "!STASH_REF!" 2>nul
    if errorlevel 1 (
        echo �G���[: �X�^�b�V�������Ɏ��s���܂���
    ) else (
        echo ����: �X�^�b�V���𕜌����܂���
    )
    goto :RestoreRepositoryStashEnd
)

echo git-autocrlf-disable�֘A�̃X�^�b�V����������܂���

:RestoreRepositoryStashEnd
popd
goto :eof

rem ========================================
rem �ݒ�ƃG���[�n���h�����O�֐�
rem ========================================

:CheckEnvironment
rem Windows���`�F�b�N
if not "%OS%"=="Windows_NT" (
    echo �G���[: ���̃c�[����Windows��p�ł�
    exit /b 1
)

rem PowerShell�`�F�b�N
powershell -Command "Get-Date" >nul 2>&1
if errorlevel 1 (
    echo �G���[: PowerShell��������܂���
    exit /b 1
)

rem �ݒ�t�@�C���ǂݍ��݁i7z.exe�p�X�`�F�b�N�̂��߁j
call :LoadConfig || exit /b 1

rem 7z.exe�`�F�b�N�i�K�{�j
if not defined SEVENZIP_PATH (
    echo �G���[: SEVENZIP_PATH ���ݒ肳��Ă��܂���
    echo conf\config.txt �� 7z.exe �̐������p�X��ݒ肵�Ă�������
    exit /b 1
)

if not exist "%SEVENZIP_PATH%" (
    echo �G���[: 7z.exe ��������܂���: %SEVENZIP_PATH%
    echo conf\config.txt �� 7z.exe �̐������p�X��ݒ肵�Ă�������
    exit /b 1
)

rem 7z.exe����e�X�g
"%SEVENZIP_PATH%" >nul 2>&1
if errorlevel 1 (
    echo �G���[: 7z.exe ������ɓ��삵�܂���: %SEVENZIP_PATH%
    exit /b 1
)

exit /b 0

:ValidateSetup
rem �f�B���N�g���쐬
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

rem ��{�t�@�C���̑��݊m�F
if not exist "%CONFIG_FILE%" (
    echo �G���[: �ݒ�t�@�C�� %CONFIG_FILE% ��������܂���B
    exit /b 1
)

if not exist "%REPO_LIST_FILE%" (
    echo �G���[: ���|�W�g�����X�g�t�@�C�� %REPO_LIST_FILE% ��������܂���B
    exit /b 1
)

exit /b 0

:LoadConfig
rem �ݒ�ǂݍ���
echo �ݒ�t�@�C���ǂݍ��ݒ�: %CONFIG_FILE%
if not exist "%CONFIG_FILE%" (
    echo �G���[: �ݒ�t�@�C�������݂��܂���: %CONFIG_FILE%
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
exit /b 0

:ValidateConfig
rem BASE_DIR�ݒ�m�F
if not defined BASE_DIR (
    echo �G���[: BASE_DIR ���ݒ肳��Ă��܂���B
    exit /b 1
)

rem BASE_DIR�̑��݊m�F
if not exist "%BASE_DIR%" (
    echo �G���[: BASE_DIR �Ŏw�肳�ꂽ�f�B���N�g�������݂��܂���: %BASE_DIR%
    exit /b 1
)

rem �o�b�N�A�b�v�f�B���N�g���̋󂫗e�ʃ`�F�b�N�i�ȈՔŁj
for %%i in ("%BACKUP_DIR%") do set "BACKUP_DRIVE=%%~di"
dir "%BACKUP_DRIVE%" >nul 2>&1 || (
    echo �G���[: �o�b�N�A�b�v��h���C�u�ɃA�N�Z�X�ł��܂���: %BACKUP_DRIVE%
    exit /b 1
)

exit /b 0

:CreateFullRepositoryBackup
set "SOURCE_PATH=%~1"
set "BACKUP_PATH=%~2"

echo   ������ ���s: ���|�W�g���S�̂�7z���k�o�b�N�A�b�v ������
echo   �Ώ�: %SOURCE_PATH%
echo   �o��: %BACKUP_PATH%.7z

rem 7z.exe �ɂ�銮�S�o�b�N�A�b�v�ixcopy�͔p�~�j
"%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 -r >nul 2>&1
if errorlevel 1 (
    echo ������ �d��G���[: 7z���k�o�b�N�A�b�v�Ɏ��s���܂��� ������
    echo [%date% %time%] �d��G���[: 7z���k�o�b�N�A�b�v���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

rem �o�b�N�A�b�v�t�@�C���̑��݂ƃT�C�Y�`�F�b�N
if not exist "%BACKUP_PATH%.7z" (
    echo ������ �d��G���[: �o�b�N�A�b�v�t�@�C�����쐬����܂���ł��� ������
    echo [%date% %time%] �d��G���[: �o�b�N�A�b�v�t�@�C���s���� %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

for %%F in ("%BACKUP_PATH%.7z") do set "BACKUP_SIZE=%%~zF"
if %BACKUP_SIZE% LSS 1024 (
    echo ������ �x��: �o�b�N�A�b�v�t�@�C���T�C�Y���ُ�ɏ������ł�: %BACKUP_SIZE% bytes ������
    echo [%date% %time%] �x��: �o�b�N�A�b�v�t�@�C���T�C�Y�ُ� %BACKUP_SIZE% bytes %REPO_NAME% >> "%LOG_FILE_ABS%"
)

echo   ������ ����: 7z���k�o�b�N�A�b�v���� %BACKUP_PATH%.7z (%BACKUP_SIZE% bytes) ������
echo [%date% %time%] ����: 7z���k�o�b�N�A�b�v���� %BACKUP_PATH%.7z (%BACKUP_SIZE% bytes) >> "%LOG_FILE_ABS%"
exit /b 0

:CheckGitStatus
echo   ���s: git status --porcelain
git status --porcelain >nul 2>&1
if errorlevel 1 (
    echo �G���[: git status �����s���܂���
    echo [%date% %time%] �G���[: git status���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)
exit /b 0

:HandleChanges
echo   ���s: git diff --quiet
git diff --quiet 2>nul
if errorlevel 1 (
    echo �ύX�����o���܂����B�X�^�b�V�����쐬���܂�...
    rem PowerShell���g�p���ăX�^�b�V�����b�Z�[�W�p�̈��S�ȓ��t�����𐶐�
    for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"') do set "STASH_DATETIME=%%i"
    echo   ���s: git stash push -m "git-autocrlf-disable: !STASH_DATETIME!"
    git stash push -m "git-autocrlf-disable: !STASH_DATETIME!" >> "%LOG_FILE_ABS%" 2>&1
    if errorlevel 1 (
        echo �G���[: �X�^�b�V���̍쐬�Ɏ��s���܂���
        echo [%date% %time%] �G���[: �X�^�b�V���쐬���s %REPO_NAME% >> "%LOG_FILE_ABS%"
        exit /b 1
    )
    echo [%date% %time%] �X�^�b�V���쐬���� %REPO_NAME% >> "%LOG_FILE_ABS%"
) else (
    echo �ύX�Ȃ��i�X�^�b�V���s�v�j
)
exit /b 0

:SetAutocrlfFalse
echo   ���s: git config core.autocrlf false
git config core.autocrlf false >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo �G���[: autocrlf�ݒ�̕ύX�Ɏ��s���܂���
    echo [%date% %time%] �G���[: autocrlf�ݒ�ύX���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)
exit /b 0

:ResetToHead
echo   ������ �댯����J�n: ���ǐՃt�@�C���폜�E�L���b�V���N���A�EHEAD���Z�b�g ������
echo   ���s: git rm --cached -r .
git rm --cached -r . >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo �x��: git rm --cached �ňꕔ�t�@�C���̏����Ɏ��s���܂����i�p���j
    echo [%date% %time%] �x��: git rm --cached �ꕔ���s %REPO_NAME% >> "%LOG_FILE_ABS%"
)

echo   ���s: git reset --hard HEAD
git reset --hard HEAD >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo �G���[: git reset --hard HEAD �Ɏ��s���܂���
    echo [%date% %time%] �G���[: git reset --hard HEAD���s %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

echo   ���s: git clean -fd (���ǐՃt�@�C�����S�폜)
git clean -fd >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo �x��: git clean -fd �ňꕔ�t�@�C���̍폜�Ɏ��s���܂����i�p���j
    echo [%date% %time%] �x��: git clean -fd �ꕔ���s %REPO_NAME% >> "%LOG_FILE_ABS%"
)

echo   ������ ����: �댯����I�� - Git�L���b�V���N���A�E���[�L���O�f�B���N�g��HEAD���� ������
echo [%date% %time%] ����: �L���b�V���N���A�EHEAD���Z�b�g�E�N���[���A�b�v���� %REPO_NAME% >> "%LOG_FILE_ABS%"
exit /b 0

rem ========================================
rem �G���[�n���h�����O�p���x��
rem ========================================

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
exit /b 1
