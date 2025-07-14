@echo off
chcp 932 >nul

REM ========================================
REM �����[�X�pzip�t�@�C���쐬�c�[��
REM ========================================

set "SCRIPT_DIR=%~dp0"
set "PROJECT_NAME=git-maintenance"

REM PowerShell���g�p���Ĉ��S�ȓ��t����������𐶐�
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "DATETIME_STR=%%i"

REM �o�[�W��������
echo ========================================
echo �����[�X�pzip�t�@�C���쐬
echo ========================================
echo.
set /p "VERSION=�o�[�W�����ԍ�����͂��Ă������� (��: v1.0.0): "
if "%VERSION%"=="" (
    echo �G���[: �o�[�W�����ԍ������͂���Ă��܂���B
    pause
    exit /b 1
)

REM �o�̓t�@�C����
set "OUTPUT_FILE=%PROJECT_NAME%-%VERSION%_%DATETIME_STR%.zip"

echo.
echo �쐬����t�@�C��: %OUTPUT_FILE%
echo �`��: ZIP�iGitHub�z�z�p�j
echo.

REM 7z.exe�̃p�X���擾
set "SEVENZIP_PATH="
if exist "C:\Program Files\7-Zip\7z.exe" (
    set "SEVENZIP_PATH=C:\Program Files\7-Zip\7z.exe"
) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set "SEVENZIP_PATH=C:\Program Files (x86)\7-Zip\7z.exe"
) else (
    echo �G���[: 7z.exe��������܂���B
    echo 7-Zip���C���X�g�[�����邩�A�p�X���m�F���Ă��������B
    pause
    exit /b 1
)

echo 7-Zip�p�X: %SEVENZIP_PATH%
echo.

set /p "CONFIRM=�����[�X�t�@�C�����쐬���܂����H (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo �L�����Z�����܂����B
    pause
    exit /b 0
)

echo.
echo �����[�X�t�@�C���쐬��...

REM �o�[�W�������t�@�C�����쐬
echo Version: %VERSION% > VERSION.txt
echo Build Date: %date% %time% >> VERSION.txt
echo Build Machine: %COMPUTERNAME% >> VERSION.txt

REM zip�t�@�C���쐬�i�s�v�ȃt�@�C�������O�j
"%SEVENZIP_PATH%" a "%OUTPUT_FILE%" ^
    "%SCRIPT_DIR%*" ^
    -xr!.git ^
    -xr!.github ^
    -xr!*.zip ^
    -xr!*.tmp ^
    -xr!temp ^
    -xr!log\*.log ^
    -xr!backup\*.7z ^
    -x!create-release.bat ^
    -x!README.md

if not errorlevel 1 (
    echo.
    echo ========================================
    echo �����[�X�t�@�C���쐬����
    echo ========================================
    echo �t�@�C��: %OUTPUT_FILE%
    echo.
    echo ���̎菇:
    echo 1. GitHub�Ń^�O %VERSION% ���쐬
    echo 2. �����[�X�y�[�W�� %OUTPUT_FILE% ���A�b�v���[�h
    echo 3. �����[�X�m�[�g���L��
    echo.
) else (
    echo �G���[: zip�t�@�C���̍쐬�Ɏ��s���܂����B
)

REM �ꎞ�t�@�C�����폜
if exist "VERSION.txt" del "VERSION.txt"

pause
