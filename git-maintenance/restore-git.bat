@echo off
chcp 932 >nul
setlocal enabledelayedexpansion

echo ========================================
echo .git �t�H���_�����c�[��
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "BACKUP_DIR=%SCRIPT_DIR%backup"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"

rem �ݒ�t�@�C���̓ǂݍ���
if not exist "%CONFIG_FILE%" (
    echo �G���[: �ݒ�t�@�C�� %CONFIG_FILE% ��������܂���B
    echo setup.bat ���Ɏ��s���Ă��������B
    pause
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    if "%%a"=="BASE_DIR" set "BASE_DIR=%%b"
)

if not defined BASE_DIR (
    echo �G���[: BASE_DIR ���ݒ肳��Ă��܂���B
    pause
    exit /b 1
)

rem �o�b�N�A�b�v�f�B���N�g���̊m�F
if not exist "%BACKUP_DIR%" (
    echo �G���[: �o�b�N�A�b�v�f�B���N�g����������܂���: %BACKUP_DIR%
    echo �܂����C�����������s���ăo�b�N�A�b�v���쐬���Ă��������B
    pause
    exit /b 1
)

echo �x�[�X�f�B���N�g��: %BASE_DIR%
echo �o�b�N�A�b�v�f�B���N�g��: %BACKUP_DIR%
echo.

echo ���p�\�ȃo�b�N�A�b�v:
echo ----------------------------------------
dir /b "%BACKUP_DIR%" 2>nul | findstr /R ".*_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]"
echo ----------------------------------------
echo.

set /p "BACKUP_FOLDER=�����������o�b�N�A�b�v�t�H���_������͂��Ă�������: "

if not exist "%BACKUP_DIR%\%BACKUP_FOLDER%" (
    echo �G���[: �w�肳�ꂽ�o�b�N�A�b�v��������܂���: %BACKUP_FOLDER%
    pause
    exit /b 1
)

rem ���|�W�g�����𒊏o�i�t�H���_��������������������j
for /f "tokens=1,2 delims=_" %%a in ("%BACKUP_FOLDER%") do (
    set "REPO_NAME=%%a"
)

set "TARGET_REPO=%BASE_DIR%\%REPO_NAME%"

echo.
echo �����Ώۃ��|�W�g��: %REPO_NAME%
echo ���|�W�g���p�X: %TARGET_REPO%
echo �o�b�N�A�b�v�\�[�X: %BACKUP_DIR%\%BACKUP_FOLDER%
echo.

if not exist "%TARGET_REPO%" (
    echo �G���[: �Ώۃ��|�W�g����������܂���: %TARGET_REPO%
    pause
    exit /b 1
)

echo �x��: ���̑���ɂ�茻�݂�.git�t�H���_���u���������܂��B
echo ���݂�.git�t�H���_�� .git_replaced_YYYYMMDDHHMMSS �Ƃ��đޔ�����܂��B
echo.
set /p "CONFIRM=���������s���܂����H (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo �������L�����Z�����܂����B
    pause
    exit /b 0
)

pushd "%TARGET_REPO%"

rem ���݂�.git�t�H���_��ޔ�
set "REPLACE_TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "REPLACE_TIMESTAMP=%REPLACE_TIMESTAMP: =0%"

if exist ".git" (
    echo ���݂�.git�t�H���_��ޔ�...
    move ".git" ".git_replaced_%REPLACE_TIMESTAMP%" >nul 2>&1
    if errorlevel 1 (
        echo �G���[: ���݂�.git�t�H���_�̑ޔ��Ɏ��s���܂����B
        popd
        pause
        exit /b 1
    )
    echo �ޔ�����: .git_replaced_%REPLACE_TIMESTAMP%
)

rem �o�b�N�A�b�v���畜��
echo .git�t�H���_�𕜌���...
xcopy "%BACKUP_DIR%\%BACKUP_FOLDER%" ".git" /E /I /H /Y >nul 2>&1
if errorlevel 1 (
    echo �G���[: .git�t�H���_�̕����Ɏ��s���܂����B
    if exist ".git_replaced_%REPLACE_TIMESTAMP%" (
        echo ����.git�t�H���_�𕜋����Ă��܂�...
        move ".git_replaced_%REPLACE_TIMESTAMP%" ".git" >nul 2>&1
    )
    popd
    pause
    exit /b 1
)

echo ���������I

rem �����m�F
echo.
echo �����m�F��...
call :ValidateGitRepository || goto :ValidationError

echo �����m�FOK: Git���|�W�g���Ƃ��Đ���ɋ@�\���Ă��܂��B

popd

echo.
echo ========================================
echo ��������
echo ========================================
echo ���|�W�g��: %REPO_NAME%
echo ������: %BACKUP_FOLDER%
echo �ޔ��: .git_replaced_%REPLACE_TIMESTAMP%
echo.
echo ���̎菇:
echo 1. git status �ŏ�Ԃ��m�F
echo 2. git log �ŗ������m�F
echo 3. ���Ȃ���Αޔ��t�H���_(.git_replaced_*)���폜
echo.

pause

rem ========================================
rem ���؂ƃG���[�n���h�����O�֐�
rem ========================================

:ValidateGitRepository
rem ��{�I��Git����̊m�F
git status >nul 2>&1
if errorlevel 1 (
    echo �G���[: git status �����s���܂����B
    exit /b 1
)

rem ���|�W�g���������`�F�b�N
echo ���|�W�g�����������m�F��...
git fsck --full >nul 2>&1
if errorlevel 1 (
    echo �x��: git fsck �Ő������G���[�����o����܂����B
    echo ���|�W�g���ɖ�肪����\��������܂��B
    set /p "CONTINUE=�������G���[������܂��������𑱍s���܂����H (Y/N): "
    if /i not "!CONTINUE!"=="Y" (
        exit /b 1
    )
) else (
    echo �������`�F�b�N����: ���͌�����܂���ł����B
)

rem �u�����`���̊m�F
git branch >nul 2>&1
if errorlevel 1 (
    echo �G���[: �u�����`���̎擾�Ɏ��s���܂����B
    exit /b 1
)

exit /b 0

:ValidationError
echo.
echo ========================================
echo �������؃G���[
echo ========================================
echo.
echo �� ���̃c�[�����񋟂���Ώ��@�F
echo   1. �����������|�W�g���ɖ�肪����܂�
echo   2. �ʂ̃o�b�N�A�b�v���g�p���ĕ����������Ă�������
echo   3. �ޔ���������.git�t�H���_��߂����Ƃ��\�ł�
echo.
echo �� ��ʓI�ȃg���u���V���[�e�B���O�F
echo   - git fsck --full �ŏڍׂȃG���[�����m�F
echo   - �����[�g���|�W�g������ăN���[��������
echo   - �ʂ̓����̃o�b�N�A�b�v�������Ă݂�
echo.
echo ���p�\�ȑ���:
echo 1. ����.git�t�H���_�ɖ߂��imove .git_replaced_%REPLACE_TIMESTAMP% .git�j
echo 2. �ʂ̃o�b�N�A�b�v�ōĎ��s
echo 3. �����[�g����ăN���[��
echo.
popd
pause
exit /b 1
