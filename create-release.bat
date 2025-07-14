@echo off
chcp 932 >nul

REM ========================================
REM リリース用zipファイル作成ツール
REM ========================================

set "SCRIPT_DIR=%~dp0"
set "PROJECT_NAME=git-maintenance"

REM PowerShellを使用して安全な日付時刻文字列を生成
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "DATETIME_STR=%%i"

REM バージョン入力
echo ========================================
echo リリース用zipファイル作成
echo ========================================
echo.
set /p "VERSION=バージョン番号を入力してください (例: v1.0.0): "
if "%VERSION%"=="" (
    echo エラー: バージョン番号が入力されていません。
    pause
    exit /b 1
)

REM 出力ファイル名
set "OUTPUT_FILE=%PROJECT_NAME%-%VERSION%_%DATETIME_STR%.zip"

echo.
echo 作成するファイル: %OUTPUT_FILE%
echo 形式: ZIP（GitHub配布用）
echo.

REM 7z.exeのパスを取得
set "SEVENZIP_PATH="
if exist "C:\Program Files\7-Zip\7z.exe" (
    set "SEVENZIP_PATH=C:\Program Files\7-Zip\7z.exe"
) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set "SEVENZIP_PATH=C:\Program Files (x86)\7-Zip\7z.exe"
) else (
    echo エラー: 7z.exeが見つかりません。
    echo 7-Zipをインストールするか、パスを確認してください。
    pause
    exit /b 1
)

echo 7-Zipパス: %SEVENZIP_PATH%
echo.

set /p "CONFIRM=リリースファイルを作成しますか？ (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo キャンセルしました。
    pause
    exit /b 0
)

echo.
echo リリースファイル作成中...

REM バージョン情報ファイルを作成
echo Version: %VERSION% > VERSION.txt
echo Build Date: %date% %time% >> VERSION.txt
echo Build Machine: %COMPUTERNAME% >> VERSION.txt

REM zipファイル作成（不要なファイルを除外）
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
    echo リリースファイル作成完了
    echo ========================================
    echo ファイル: %OUTPUT_FILE%
    echo.
    echo 次の手順:
    echo 1. GitHubでタグ %VERSION% を作成
    echo 2. リリースページで %OUTPUT_FILE% をアップロード
    echo 3. リリースノートを記入
    echo.
) else (
    echo エラー: zipファイルの作成に失敗しました。
)

REM 一時ファイルを削除
if exist "VERSION.txt" del "VERSION.txt"

pause
