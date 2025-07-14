@echo off
chcp 932 >nul

REM ========================================
REM Git AutoCRLF無効化＋キャッシュクリアツール
REM ========================================

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"
set "REPO_LIST_FILE=%SCRIPT_DIR%conf\repositories.txt"
set "LOG_DIR=%SCRIPT_DIR%log"
set "BACKUP_DIR=%SCRIPT_DIR%backup"

REM PowerShellを使用して安全な日付時刻文字列を生成
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "DATETIME_STR=%%i"
set "LOG_FILE=%LOG_DIR%\git-autocrlf-disable-cache-clear_%DATETIME_STR%.log"

REM ログファイルの絶対パス化（pushd後でも正しく動作するように）
for %%i in ("%LOG_FILE%") do set "LOG_FILE_ABS=%%~fi"

REM 初期設定の検証
call :ValidateSetup || goto :SetupError
setlocal enabledelayedexpansion

echo ========================================
echo Git AutoCRLF 無効化＋キャッシュクリア ツール
echo ========================================
echo.
echo 実行モードを選択してください:
echo 1. AutoCRLF無効化＋キャッシュクリア実行（リポジトリ全体バックアップ付き）
echo 2. リポジトリ情報確認
echo 3. スタッシュ一覧表示  
echo 4. git-autocrlf-disable関連スタッシュ復元
echo 5. 終了
echo.
set /p "MODE=選択してください (1-5): "

if "%MODE%"=="1" goto :MainProcess
if "%MODE%"=="2" goto :CheckRepositories
if "%MODE%"=="3" goto :ListStashes
if "%MODE%"=="4" goto :RestoreStashes
if "%MODE%"=="5" goto :Exit

echo 無効な選択です。
pause
endlocal
exit /b 1

:SetupError
echo.
echo ========================================
echo セットアップエラー
echo ========================================
echo 初期設定に問題があります。以下を確認してください：
echo.
echo ■ このツールが提供する対処法：
echo   1. setup.bat を実行して初期設定を完了してください
echo   2. conf\config.txt で BASE_DIR を正しく設定してください
echo   3. conf\repositories.txt にリポジトリ名を列挙してください
echo.
echo ■ 一般的なトラブルシューティング：
echo   - ファイルパスにスペースや特殊文字が含まれていないか確認
echo   - ディスクの空き容量が十分にあるか確認
echo   - ウイルス対策ソフトによるブロックがないか確認
echo.
pause
exit /b 1

:Exit
echo ツールを終了します。
endlocal
exit /b 0

:MainProcess
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

REM ログディレクトリとバックアップディレクトリの作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM ログファイル初期化
echo [%date% %time%] Git AutoCRLF 無効化＋キャッシュクリア処理開始（2フェーズ実行・リポジトリ全体バックアップ付き） > "%LOG_FILE_ABS%"

echo ベースディレクトリ: %BASE_DIR%
echo ログファイル: %LOG_FILE%
echo.

REM グローバルautocrlf設定の確認と変更
echo グローバルautocrlf設定の確認中...
for /f "tokens=*" %%a in ('git config --global core.autocrlf 2^>nul') do set "GLOBAL_AUTOCRLF=%%a"
if not defined GLOBAL_AUTOCRLF set "GLOBAL_AUTOCRLF=未設定"
echo   現在のグローバル設定: %GLOBAL_AUTOCRLF%

echo   実行: git config --global core.autocrlf false
git config --global core.autocrlf false
if not errorlevel 1 (
    echo   グローバルautocrlf設定をfalseに変更しました
    echo [%date% %time%] グローバルautocrlf設定をfalseに変更 >> "%LOG_FILE_ABS%"
) else (
    echo 警告: グローバルautocrlf設定の変更に失敗しました
    echo [%date% %time%] 警告: グローバルautocrlf設定変更失敗 >> "%LOG_FILE_ABS%"
)
echo.

REM リポジトリリストの表示
echo 対象リポジトリ:
echo ----------------------------------------
type "%REPO_LIST_FILE%"
echo ----------------------------------------
echo.

echo.
echo ========================================
echo 重要な注意事項
echo ========================================
echo バッチ実行中は対象リポジトリやEclipse等の関連ツールを
echo 使用しないでください。
echo.
echo - Git操作を行うツール（Eclipse、IntelliJ、SourceTree等）を閉じてください
echo - 対象ディレクトリ内のファイルを直接編集しないでください
echo - バックアップとリセット処理が完了するまでお待ちください
echo ========================================
echo.

set /p "CONFIRM=上記を理解して処理を実行しますか？ (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 処理をキャンセルしました。
    pause
    endlocal
    exit /b 0
)

echo.
echo ========================================
echo フェーズ1: 全リポジトリのバックアップ実行
echo ========================================
echo.

set "BACKUP_SUCCESS_COUNT=0"
set "BACKUP_ERROR_COUNT=0"

REM 全リポジトリのバックアップを最初に実行
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    REM コメント行やempty行をスキップ
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :BackupRepository "!REPO_NAME!"
        )
    )
)

echo.
echo ========================================
echo バックアップ結果
echo ========================================
echo 成功: %BACKUP_SUCCESS_COUNT% リポジトリ
echo エラー: %BACKUP_ERROR_COUNT% リポジトリ

if %BACKUP_ERROR_COUNT% gtr 0 (
    echo.
    echo エラー: バックアップに失敗したリポジトリがあるため、
    echo 変更処理を中止します。
    echo ログファイル: %LOG_FILE%
    echo.
    pause
    endlocal
    exit /b 1
)

echo.
echo ========================================
echo フェーズ2: AutoCRLF設定変更・キャッシュクリア実行
echo ========================================
echo.

set "SUCCESS_COUNT=0"
set "ERROR_COUNT=0"

REM 全バックアップが成功した場合のみ変更処理を実行
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    REM コメント行やempty行をスキップ
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :ProcessRepository "!REPO_NAME!"
        )
    )
)

echo.
echo ========================================
echo 処理完了
echo ========================================
echo バックアップ成功: %BACKUP_SUCCESS_COUNT% リポジトリ
echo 変更処理成功: %SUCCESS_COUNT% リポジトリ
echo 変更処理エラー: %ERROR_COUNT% リポジトリ
echo ログファイル: %LOG_FILE%
echo.

pause
endlocal
exit /b 0

REM ========================================
REM バックアップ専用処理関数
REM ========================================
:BackupRepository
setlocal enabledelayedexpansion
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo バックアップ中: %REPO_NAME%
echo ----------------------------------------

REM ログ出力
echo [%date% %time%] バックアップ開始: %REPO_NAME% >> "%LOG_FILE_ABS%"

REM リポジトリディレクトリの確認
if not exist "%REPO_PATH%" (
    echo エラー: リポジトリディレクトリが見つかりません: %REPO_PATH%
    echo [%date% %time%] エラー: ディレクトリ不存在 %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a BACKUP_ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM .gitディレクトリの確認
if not exist "%REPO_PATH%\.git" (
    echo エラー: Gitリポジトリではありません: %REPO_PATH%
    echo [%date% %time%] エラー: Gitリポジトリではない %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a BACKUP_ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM リポジトリ全体のバックアップ作成
REM PowerShellを使用してバックアップ用タイムスタンプ生成
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "BACKUP_TIMESTAMP=%%i"
set "REPO_BACKUP_DIR=%BACKUP_DIR%\%REPO_NAME%_full_%BACKUP_TIMESTAMP%"

call :CreateFullRepositoryBackup "%REPO_PATH%" "%REPO_BACKUP_DIR%" || (
    echo エラー: リポジトリ全体のバックアップに失敗しました
    echo [%date% %time%] エラー: 全体バックアップ失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    set /a BACKUP_ERROR_COUNT+=1
    endlocal
    goto :eof
)

echo 完了: %REPO_NAME% のバックアップが完了しました
echo [%date% %time%] バックアップ完了: %REPO_NAME% >> "%LOG_FILE_ABS%"
set /a BACKUP_SUCCESS_COUNT+=1

endlocal
goto :eof

REM ========================================
REM リポジトリ処理関数
REM ========================================
:ProcessRepository
setlocal enabledelayedexpansion
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo 処理中: %REPO_NAME%
echo ----------------------------------------

REM ログ出力
echo [%date% %time%] 処理開始: %REPO_NAME% >> "%LOG_FILE_ABS%"

REM リポジトリディレクトリの確認
if not exist "%REPO_PATH%" (
    echo エラー: リポジトリディレクトリが見つかりません: %REPO_PATH%
    echo [%date% %time%] エラー: ディレクトリ不存在 %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM .gitディレクトリの確認
if not exist "%REPO_PATH%\.git" (
    echo エラー: Gitリポジトリではありません: %REPO_PATH%
    echo [%date% %time%] エラー: Gitリポジトリではない %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM ドライブを跨ぐ可能性があるため、ディレクトリ移動
pushd "%REPO_PATH%" || (
    echo エラー: ディレクトリに移動できません: %REPO_PATH%
    echo [%date% %time%] エラー: ディレクトリ移動失敗 %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    endlocal
    goto :eof
)

REM 現在のステータス確認
echo 1. ステータス確認中...
call :CheckGitStatus || (
    echo エラー: Git状態確認に失敗しました
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

REM 変更がある場合のスタッシュ
echo 2. 変更確認・スタッシュ中...
call :HandleChanges || (
    echo エラー: 変更処理に失敗しました
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

REM 現在のautocrlf設定確認
echo 3. 現在のautocrlf設定確認中...
echo   実行: git config core.autocrlf
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "CURRENT_AUTOCRLF=%%a"
if not defined CURRENT_AUTOCRLF set "CURRENT_AUTOCRLF=未設定"
echo   現在の設定: %CURRENT_AUTOCRLF%
echo [%date% %time%] 現在のautocrlf設定: %CURRENT_AUTOCRLF% %REPO_NAME% >> "%LOG_FILE_ABS%"

REM autocrlf=false に設定
echo 4. autocrlf=false に設定中...
call :SetAutocrlfFalse || (
    echo エラー: autocrlf設定変更に失敗しました
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

REM GitキャッシュをクリアしてワーキングディレクトリをHEADで上書き
echo 5. Gitキャッシュ一括クリア・HEADリセット中...
call :ResetToHead || (
    echo エラー: キャッシュクリア・HEADリセットに失敗しました
    popd
    endlocal
    set /a ERROR_COUNT+=1
    goto :eof
)

popd

echo 6. 完了: %REPO_NAME%
echo [%date% %time%] 処理完了: %REPO_NAME% >> "%LOG_FILE_ABS%"
set /a SUCCESS_COUNT+=1

endlocal
goto :eof

REM ========================================
REM リポジトリ情報確認機能
REM ========================================
:CheckRepositories
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo リポジトリ情報確認
echo ========================================
echo ベースディレクトリ: %BASE_DIR%

REM グローバルautocrlf設定の表示
for /f "tokens=*" %%a in ('git config --global core.autocrlf 2^>nul') do set "GLOBAL_AUTOCRLF=%%a"
if not defined GLOBAL_AUTOCRLF set "GLOBAL_AUTOCRLF=未設定"
echo グローバルautocrlf設定: %GLOBAL_AUTOCRLF%
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
echo 集計結果
echo ========================================
echo 総数: %TOTAL_COUNT% リポジトリ
echo 有効: %VALID_COUNT% リポジトリ
echo エラー: %CHECK_ERROR_COUNT% リポジトリ
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
    echo   状態: ディレクトリが存在しません
    echo   パス: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    endlocal
    goto :eof
)

if not exist "%REPO_PATH%\.git" (
    echo   状態: Gitリポジトリではありません
    echo   パス: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    endlocal
    goto :eof
)

pushd "%REPO_PATH%" || (
    endlocal
    goto :eof
)

REM 現在のブランチ
for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%b"
if not defined CURRENT_BRANCH set "CURRENT_BRANCH=不明"

REM autocrlf設定
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "AUTOCRLF=%%a"
if not defined AUTOCRLF set "AUTOCRLF=未設定"

REM 変更状況
git diff --quiet 2>nul
if not errorlevel 1 (
    set "HAS_CHANGES=なし"
) else (
    set "HAS_CHANGES=あり"
)

REM スタッシュ数
for /f "tokens=*" %%s in ('git stash list 2^>nul ^| find /c /v ""') do set "STASH_COUNT=%%s"
if not defined STASH_COUNT set "STASH_COUNT=0"

REM git-autocrlf-disable関連スタッシュ数
for /f "tokens=*" %%t in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-disable" ^| find /c /v ""') do set "DISABLE_STASH_COUNT=%%t"
if not defined DISABLE_STASH_COUNT set "DISABLE_STASH_COUNT=0"

popd

echo   状態: 正常
echo   パス: %REPO_PATH%
echo   ブランチ: %CURRENT_BRANCH%
echo   autocrlf: %AUTOCRLF%
echo   未保存変更: %HAS_CHANGES%
echo   スタッシュ数: %STASH_COUNT% (disable関連: %DISABLE_STASH_COUNT%)

set /a VALID_COUNT+=1

popd
endlocal
goto :eof

REM ========================================
REM スタッシュ一覧表示機能
REM ========================================
:ListStashes
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo スタッシュ一覧
echo ========================================
echo ベースディレクトリ: %BASE_DIR%
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
        echo スタッシュ数: !STASH_COUNT! （git-autocrlf-disable関連なし）
        git stash list 2>nul
    ) else (
        echo スタッシュなし
    )
)

popd
endlocal
goto :eof

REM ========================================
REM git-autocrlf-disable関連スタッシュ復元機能
REM ========================================
:RestoreStashes
setlocal enabledelayedexpansion
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo git-autocrlf-disable関連スタッシュ復元
echo ========================================
echo ベースディレクトリ: %BASE_DIR%
echo.
echo 注意: この操作により、git-autocrlf-disableで作成された
echo スタッシュが復元されます。現在の変更は失われる可能性があります。
echo.
set /p "RESTORE_CONFIRM=実行しますか？ (Y/N): "
if /i not "%RESTORE_CONFIRM%"=="Y" (
    echo キャンセルしました。
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

REM git-autocrlf-disable関連のスタッシュを検索
for /f "tokens=1,* delims=:" %%a in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-disable"') do (
    set "STASH_REF=%%a"
    set "STASH_MSG=%%b"
    echo スタッシュ復元: !STASH_REF! -!STASH_MSG!
    git stash pop "!STASH_REF!" 2>nul
    if not errorlevel 1 (
        echo 成功: スタッシュを復元しました
    ) else (
        echo エラー: スタッシュ復元に失敗しました
    )
    goto :RestoreRepositoryStashEnd
)

echo git-autocrlf-disable関連のスタッシュが見つかりません

:RestoreRepositoryStashEnd
popd
endlocal
goto :eof

REM ========================================
REM 設定とエラーハンドリング関数
REM ========================================

:ValidateSetup
setlocal
REM ディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM 基本ファイルの存在確認
if not exist "%CONFIG_FILE%" (
    echo エラー: 設定ファイル %CONFIG_FILE% が見つかりません。
    endlocal
    exit /b 1
)

if not exist "%REPO_LIST_FILE%" (
    echo エラー: リポジトリリストファイル %REPO_LIST_FILE% が見つかりません。
    endlocal
    exit /b 1
)

endlocal
exit /b 0

:LoadConfig
setlocal
REM 設定読み込み
echo 設定ファイル読み込み中: %CONFIG_FILE%
if not exist "%CONFIG_FILE%" (
    echo エラー: 設定ファイルが存在しません: %CONFIG_FILE%
    endlocal
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    if "%%a"=="BASE_DIR" (
        set "BASE_DIR=%%b"
        echo 読み込み: BASE_DIR=%%b
    )
    if "%%a"=="SEVENZIP_PATH" (
        set "SEVENZIP_PATH=%%b"
        echo 読み込み: SEVENZIP_PATH=%%b
    )
)
endlocal & set "BASE_DIR=%BASE_DIR%" & set "SEVENZIP_PATH=%SEVENZIP_PATH%"
exit /b 0

:ValidateConfig
setlocal
REM BASE_DIR設定確認
if not defined BASE_DIR (
    echo エラー: BASE_DIR が設定されていません。
    endlocal
    exit /b 1
)

REM BASE_DIRの存在確認
if not exist "%BASE_DIR%" (
    echo エラー: BASE_DIR で指定されたディレクトリが存在しません: %BASE_DIR%
    endlocal
    exit /b 1
)

REM 7z.exeの必須確認（7z.exeが必須になったので警告に変更）
if defined SEVENZIP_PATH (
    if not exist "%SEVENZIP_PATH%" (
        echo エラー: 指定された7z.exeが見つかりません: %SEVENZIP_PATH%
        echo この新バージョンでは7z.exeは必須です。
        endlocal
        exit /b 1
    )
) else (
    echo エラー: SEVENZIP_PATHが設定されていません。
    echo この新バージョンでは7z.exeは必須です。
    endlocal
    exit /b 1
)

endlocal
exit /b 0

:CreateBackup
setlocal enabledelayedexpansion
set "SOURCE_PATH=%~1"
set "BACKUP_PATH=%~2"

REM 7z.exe使用が必須
if not defined SEVENZIP_PATH (
    echo エラー: 7z.exeが設定されていません
    endlocal
    exit /b 1
)

echo   実行: "%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5
"%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 2>&1
if not errorlevel 1 (
    echo   7z圧縮バックアップ完了: %BACKUP_PATH%.7z
    echo [%date% %time%] 7z圧縮バックアップ完了: %BACKUP_PATH%.7z >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 0
) else (
    echo エラー: 7z圧縮に失敗しました（終了コード: %ERRORLEVEL%）
    echo [%date% %time%] エラー: 7z圧縮失敗（終了コード: %ERRORLEVEL%） %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:CreateFullRepositoryBackup
setlocal enabledelayedexpansion
set "SOURCE_PATH=%~1"
set "BACKUP_PATH=%~2"

REM 7z.exe使用が必須
if not defined SEVENZIP_PATH (
    echo エラー: 7z.exeが設定されていません
    endlocal
    exit /b 1
)

echo   実行: "%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5
"%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 2>&1
if not errorlevel 1 (
    echo   リポジトリ全体の7z圧縮バックアップ完了: %BACKUP_PATH%.7z
    echo [%date% %time%] リポジトリ全体の7z圧縮バックアップ完了: %BACKUP_PATH%.7z >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 0
) else (
    echo エラー: リポジトリ全体の7z圧縮に失敗しました（終了コード: %ERRORLEVEL%）
    echo [%date% %time%] エラー: リポジトリ全体の7z圧縮失敗（終了コード: %ERRORLEVEL%） %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:CheckGitStatus
setlocal
echo   実行: git status --porcelain
git status --porcelain >nul 2>&1
if not errorlevel 1 (
    endlocal
    exit /b 0
) else (
    echo エラー: git status が失敗しました
    echo [%date% %time%] エラー: git status失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:HandleChanges
setlocal enabledelayedexpansion
echo   実行: git diff --quiet
git diff --quiet 2>nul
if not errorlevel 1 (
    echo 変更なし（スタッシュ不要）
    endlocal
    exit /b 0
) else (
    echo 変更を検出しました。スタッシュを作成します...
    REM PowerShellを使用してスタッシュメッセージ用の安全な日付時刻を生成
    for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"') do set "STASH_DATETIME=%%i"
    echo   実行: git stash push -m "git-autocrlf-disable: !STASH_DATETIME!"
    git stash push -m "git-autocrlf-disable: !STASH_DATETIME!" >> "%LOG_FILE_ABS%" 2>&1
    if not errorlevel 1 (
        echo [%date% %time%] スタッシュ作成完了 %REPO_NAME% >> "%LOG_FILE_ABS%"
        endlocal
        exit /b 0
    ) else (
        echo エラー: スタッシュの作成に失敗しました
        echo [%date% %time%] エラー: スタッシュ作成失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
        endlocal
        exit /b 1
    )
)

:SetAutocrlfFalse
setlocal
echo   実行: git config core.autocrlf false
git config core.autocrlf false >> "%LOG_FILE_ABS%" 2>&1
if not errorlevel 1 (
    endlocal
    exit /b 0
) else (
    echo エラー: autocrlf設定の変更に失敗しました
    echo [%date% %time%] エラー: autocrlf設定変更失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

:ResetToHead
setlocal
echo   実行: git rm --cached -r .
git rm --cached -r . >> "%LOG_FILE_ABS%" 2>&1
echo   実行: git reset --hard HEAD
git reset --hard HEAD >> "%LOG_FILE_ABS%" 2>&1
if not errorlevel 1 (
    REM ワーキングディレクトリをクリーンアップ
    echo   実行: git clean -fd
    git clean -fd >> "%LOG_FILE_ABS%" 2>&1

    echo   完了: Gitキャッシュクリア・ワーキングディレクトリをHEADの状態に復元しました
    echo [%date% %time%] キャッシュクリア・HEADリセット・クリーンアップ完了 %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 0
) else (
    echo エラー: キャッシュクリア・HEADリセットに失敗しました
    echo [%date% %time%] エラー: キャッシュクリア・HEADリセット失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    endlocal
    exit /b 1
)

REM ========================================
REM エラーハンドリング用ラベル
REM ========================================

:ConfigError
echo.
echo ========================================
echo 設定エラー
echo ========================================
echo.
echo ■ このツールが提供する対処法：
echo   1. conf\config.txt で BASE_DIR を正しく設定してください
echo   2. 指定したディレクトリが存在することを確認してください
echo   3. setup.bat を再実行して設定ファイルを作り直してください
echo.
echo ■ 一般的なトラブルシューティング：
echo   - パス名に2バイト文字や特殊文字が含まれていないか確認
echo   - ネットワークドライブを避けてローカルドライブを使用
echo   - ユーザー権限でアクセス可能なディレクトリかどうか確認
echo.
pause
endlocal
exit /b 1
