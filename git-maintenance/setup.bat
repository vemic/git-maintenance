@echo off
chcp 932 >nul

echo ========================================
echo Git AutoCRLF �c�[�� ����Z�b�g�A�b�v
echo ========================================
echo.

rem conf�f�B���N�g���̊m�F
if not exist "conf" (
    echo conf�f�B���N�g�����쐬���܂�...
    mkdir conf
)

rem �ݒ�t�@�C���̃R�s�[
if not exist "conf\config.txt" (
    if exist "conf\config.txt.sample" (
        echo config.txt ���쐬���܂�...
        copy "conf\config.txt.sample" "conf\config.txt" >nul
        echo �쐬����: conf\config.txt
    ) else (
        echo �G���[: conf\config.txt.sample ��������܂���B
    )
) else (
    echo conf\config.txt �͊��ɑ��݂��܂��B
)

if not exist "conf\repositories.txt" (
    if exist "conf\repositories.txt.sample" (
        echo repositories.txt ���쐬���܂�...
        copy "conf\repositories.txt.sample" "conf\repositories.txt" >nul
        echo �쐬����: conf\repositories.txt
    ) else (
        echo �G���[: conf\repositories.txt.sample ��������܂���B
    )
) else (
    echo conf\repositories.txt �͊��ɑ��݂��܂��B
)

rem �f�B���N�g���쐬
if not exist "log" (
    echo log�f�B���N�g�����쐬���܂�...
    mkdir log
)

if not exist "backup" (
    echo backup�f�B���N�g�����쐬���܂�...
    mkdir backup
)

echo.
echo ========================================
echo �Z�b�g�A�b�v����
echo ========================================
echo.
echo ���̎菇:
echo 1. conf\config.txt ��ҏW����BASE_DIR��ݒ�
echo 2. conf\repositories.txt ��ҏW���đΏۃ��|�W�g����ǉ�
echo 3. git-autocrlf-recovery.bat �����s
echo.

echo �Z�b�g�A�b�v���������܂����B
pause
