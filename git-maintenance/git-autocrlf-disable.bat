@echo off
chcp 932 >nul

rem ========================================
rem Git AutoCRLF無効化＋キャッシュクリアツール
rem ========================================

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"
set "REPO_LIST_FILE=%SCRIPT_DIR%conf\repositories.txt"
set "LOG_DIR=%SCRIPT_DIR%log"
set "BACKUP_DIR=%SCRIPT_DIR%backup"

rem PowerShellを使用して安全な日付時刻文字列を生成
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "DATETIME_STR=%%i"
set "LOG_FILE=%LOG_DIR%\git-autocrlf-disable-cache-clear_%DATETIME_STR%.log"

rem ログファイルの絶対パス化（pushd後でも正しく動作するように）
for %%i in ("%LOG_FILE%") do set "LOG_FILE_ABS=%%~fi"

rem 環境依存性チェック
call :CheckEnvironment || goto :EnvironmentError

rem 初期設定の検証
call :ValidateSetup || goto :SetupError
setlocal enabledelayedexpansion

:MainMenu
echo ========================================
echo Git AutoCRLF 無効化＋キャッシュクリア ツール
echo ========================================
echo.
echo 実行モードを選択してください:
echo 1. AutoCRLF無効化＋キャッシュクリア実行
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

echo 無効な選択です。再入力してください。
goto :MainMenu

:EnvironmentError
echo.
echo ========================================
echo 環境エラー
echo ========================================
echo このツールは以下の環境が必要です：
echo.
echo ■ 必須環境：
echo   - Windows OS (CP932/Shift_JIS対応)
echo   - PowerShell (日付時刻生成用)
echo   - 7-Zip (7z.exe) - バックアップ専用
echo.
echo ■ 検出された問題：
echo   - PowerShellまたは7z.exeが見つかりません
echo   - conf\config.txtで正しい7z.exeパスを設定してください
echo.
echo ■ 注意事項：
echo   - xcopyバックアップは安全性の観点から廃止されました
echo   - 7z.exeが利用できない場合は処理を中止します
echo.
pause
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
exit /b 0

:MainProcess
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

rem ログディレクトリとバックアップディレクトリの作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

rem ログファイル初期化
echo [%date% %time%] Git AutoCRLF 無効化＋キャッシュクリア処理開始 > "%LOG_FILE_ABS%"

echo ベースディレクトリ: %BASE_DIR%
echo ログファイル: %LOG_FILE%
echo.

rem グローバルautocrlf設定の確認と変更
echo グローバルautocrlf設定の確認中...
for /f "tokens=*" %%a in ('git config --global core.autocrlf 2^>nul') do set "GLOBAL_AUTOCRLF=%%a"
if not defined GLOBAL_AUTOCRLF set "GLOBAL_AUTOCRLF=未設定"
echo   現在のグローバル設定: %GLOBAL_AUTOCRLF%

echo   実行: git config --global core.autocrlf false
git config --global core.autocrlf false
if errorlevel 1 (
    echo 警告: グローバルautocrlf設定の変更に失敗しました
    echo [%date% %time%] 警告: グローバルautocrlf設定変更失敗 >> "%LOG_FILE_ABS%"
) else (
    echo   グローバルautocrlf設定をfalseに変更しました
    echo [%date% %time%] グローバルautocrlf設定をfalseに変更 >> "%LOG_FILE_ABS%"
)
echo.

rem リポジトリリストの表示と詳細確認
echo 対象リポジトリ:
echo ----------------------------------------
type "%REPO_LIST_FILE%"
echo ----------------------------------------
echo.

rem 処理対象リポジトリ数の表示
set "TARGET_COUNT=0"
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            set /a TARGET_COUNT+=1
        )
    )
)
echo 処理対象: %TARGET_COUNT% リポジトリ
echo.

rem 処理内容の詳細説明
echo ========================================
echo 実行される処理内容
echo ========================================
echo 1. 各リポジトリ全体を7z形式で完全バックアップ
echo 2. 未コミット変更の自動スタッシュ
echo 3. core.autocrlf=false への設定変更
echo 4. git rm --cached -r . (全ファイルキャッシュクリア)
echo 5. git reset --hard HEAD (HEADへの強制リセット)
echo 6. git clean -fd (未追跡ファイル削除)
echo.
echo ■ 注意：未追跡ファイルは完全に削除されます
echo ■ バックアップ先：%BACKUP_DIR%
echo ■ ログ出力先：%LOG_FILE%
echo.

:ConfirmLoop
set /p "CONFIRM=処理を実行しますか？ (Y/n): "
if "%CONFIRM%"=="" set "CONFIRM=Y"
if /i "%CONFIRM%"=="Y" goto :StartProcess
if /i "%CONFIRM%"=="N" (
    echo 処理をキャンセルしました。
    pause
    exit /b 0
)
echo 無効な入力です。YまたはNを入力してください。
goto :ConfirmLoop

:StartProcess

echo.
echo 処理を開始します...
echo.

set "SUCCESS_COUNT=0"
set "ERROR_COUNT=0"

rem リポジトリリストの処理
for /f "usebackq tokens=*" %%r in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%r"
    
    rem コメント行やempty行をスキップ
    if not "!REPO_NAME!"=="" (
        if not "!REPO_NAME:~0,1!"=="#" (
            call :ProcessRepository "!REPO_NAME!"
        )
    )
)

echo.
echo ========================================
echo 処理完了サマリー
echo ========================================
echo 成功: %SUCCESS_COUNT% リポジトリ
echo エラー: %ERROR_COUNT% リポジトリ
echo 処理対象: %TARGET_COUNT% リポジトリ
echo.
echo ■ バックアップ先: %BACKUP_DIR%
echo ■ ログファイル: %LOG_FILE%
echo.
if %ERROR_COUNT% GTR 0 (
    echo ■■■ 警告: エラーが発生したリポジトリがあります ■■■
    echo ■■■ ログファイルで詳細を確認してください ■■■
) else (
    echo ■■■ 全リポジトリの処理が正常に完了しました ■■■
)
echo.

pause
exit /b 0

rem ========================================
rem リポジトリ処理関数（安全性重視版）
rem ========================================
:ProcessRepository
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"
set "PUSHD_SUCCESS=0"

echo ========================================
echo 処理中: %REPO_NAME%
echo ========================================

rem ログ出力
echo [%date% %time%] 処理開始: %REPO_NAME% >> "%LOG_FILE_ABS%"

rem リポジトリディレクトリの確認
if not exist "%REPO_PATH%" (
    echo エラー: リポジトリディレクトリが見つかりません: %REPO_PATH%
    echo [%date% %time%] エラー: ディレクトリ不存在 %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem .gitディレクトリの確認
if not exist "%REPO_PATH%\.git" (
    echo エラー: Gitリポジトリではありません: %REPO_PATH%
    echo [%date% %time%] エラー: Gitリポジトリではない %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem ステップ1: リポジトリ全体の7zバックアップ（最重要）
echo 1. リポジトリ全体バックアップ作成中...
rem PowerShellを使用してバックアップ用タイムスタンプ生成
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "BACKUP_TIMESTAMP=%%i"
set "REPO_BACKUP_DIR=%BACKUP_DIR%\%REPO_NAME%_FULL_%BACKUP_TIMESTAMP%"

call :CreateFullRepositoryBackup "%REPO_PATH%" "%REPO_BACKUP_DIR%" || (
    echo ■■■ 重大エラー: リポジトリ全体のバックアップに失敗しました ■■■
    echo ■■■ データ消失リスクのため、このリポジトリの処理を中断します ■■■
    echo [%date% %time%] 重大エラー: 全体バックアップ失敗により処理中止 %REPO_NAME% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem ドライブを跨ぐ可能性があるため、ディレクトリ移動
pushd "%REPO_PATH%" && set "PUSHD_SUCCESS=1" || (
    echo エラー: ディレクトリに移動できません: %REPO_PATH%
    echo [%date% %time%] エラー: ディレクトリ移動失敗 %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem ステップ2: 現在のステータス確認
echo 2. ステータス確認中...
call :CheckGitStatus || (
    echo エラー: Git状態確認に失敗しました
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem ステップ3: 変更がある場合のスタッシュ
echo 3. 変更確認・スタッシュ中...
call :HandleChanges || (
    echo エラー: 変更処理に失敗しました
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem ステップ4: 現在のautocrlf設定確認
echo 4. 現在のautocrlf設定確認中...
echo   実行: git config core.autocrlf
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "CURRENT_AUTOCRLF=%%a"
if not defined CURRENT_AUTOCRLF set "CURRENT_AUTOCRLF=未設定"
echo   現在の設定: %CURRENT_AUTOCRLF%
echo [%date% %time%] 現在のautocrlf設定: %CURRENT_AUTOCRLF% %REPO_NAME% >> "%LOG_FILE_ABS%"

rem ステップ5: autocrlf=false に設定
echo 5. autocrlf=false に設定中...
call :SetAutocrlfFalse || (
    echo エラー: autocrlf設定変更に失敗しました
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem ステップ6: Gitキャッシュクリア・HEADリセット（危険操作）
echo 6. ■■■ 危険操作実行中: Gitキャッシュ一括クリア・HEADリセット ■■■
call :ResetToHead || (
    echo エラー: キャッシュクリア・HEADリセットに失敗しました
    if %PUSHD_SUCCESS%==1 popd
    set /a ERROR_COUNT+=1
    goto :eof
)

if %PUSHD_SUCCESS%==1 popd

echo 7. ■■■ 完了: %REPO_NAME% ■■■
echo [%date% %time%] 処理完了: %REPO_NAME% >> "%LOG_FILE_ABS%"
set /a SUCCESS_COUNT+=1

goto :eof

rem ========================================
rem リポジトリ情報確認機能
rem ========================================
:CheckRepositories
call :LoadConfig || goto :ConfigError
call :ValidateConfig || goto :ConfigError

echo.
echo ========================================
echo リポジトリ情報確認
echo ========================================
echo ベースディレクトリ: %BASE_DIR%

rem グローバルautocrlf設定の表示
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
exit /b 0

:CheckRepository
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo %REPO_NAME%
echo ----------------------------------------

if not exist "%REPO_PATH%" (
    echo   状態: ディレクトリが存在しません
    echo   パス: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    goto :eof
)

if not exist "%REPO_PATH%\.git" (
    echo   状態: Gitリポジトリではありません
    echo   パス: %REPO_PATH%
    set /a CHECK_ERROR_COUNT+=1
    goto :eof
)

pushd "%REPO_PATH%" || goto :eof

rem 現在のブランチ
for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%b"
if not defined CURRENT_BRANCH set "CURRENT_BRANCH=不明"

rem autocrlf設定
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "AUTOCRLF=%%a"
if not defined AUTOCRLF set "AUTOCRLF=未設定"

rem 変更状況
git diff --quiet 2>nul
if errorlevel 1 (
    set "HAS_CHANGES=あり"
) else (
    set "HAS_CHANGES=なし"
)

rem スタッシュ数
for /f "tokens=*" %%s in ('git stash list 2^>nul ^| find /c /v ""') do set "STASH_COUNT=%%s"
if not defined STASH_COUNT set "STASH_COUNT=0"

rem git-autocrlf-disable関連スタッシュ数
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

rem 変数クリア
set "CURRENT_BRANCH="
set "AUTOCRLF="
set "HAS_CHANGES="
set "STASH_COUNT="
set "DISABLE_STASH_COUNT="

goto :eof

rem ========================================
rem スタッシュ一覧表示機能
rem ========================================
:ListStashes
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
        echo スタッシュ数: !STASH_COUNT! （git-autocrlf-disable関連なし）
        git stash list 2>nul
    ) else (
        echo スタッシュなし
    )
) else (
    git stash list 2>nul
)

popd
goto :eof

rem ========================================
rem git-autocrlf-disable関連スタッシュ復元機能
rem ========================================
:RestoreStashes
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

rem git-autocrlf-disable関連のスタッシュを検索
for /f "tokens=1,* delims=:" %%a in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-disable"') do (
    set "STASH_REF=%%a"
    set "STASH_MSG=%%b"
    echo スタッシュ復元: !STASH_REF! -!STASH_MSG!
    git stash pop "!STASH_REF!" 2>nul
    if errorlevel 1 (
        echo エラー: スタッシュ復元に失敗しました
    ) else (
        echo 成功: スタッシュを復元しました
    )
    goto :RestoreRepositoryStashEnd
)

echo git-autocrlf-disable関連のスタッシュが見つかりません

:RestoreRepositoryStashEnd
popd
goto :eof

rem ========================================
rem 設定とエラーハンドリング関数
rem ========================================

:CheckEnvironment
rem Windows環境チェック
if not "%OS%"=="Windows_NT" (
    echo エラー: このツールはWindows専用です
    exit /b 1
)

rem PowerShellチェック
powershell -Command "Get-Date" >nul 2>&1
if errorlevel 1 (
    echo エラー: PowerShellが見つかりません
    exit /b 1
)

rem 設定ファイル読み込み（7z.exeパスチェックのため）
call :LoadConfig || exit /b 1

rem 7z.exeチェック（必須）
if not defined SEVENZIP_PATH (
    echo エラー: SEVENZIP_PATH が設定されていません
    echo conf\config.txt で 7z.exe の正しいパスを設定してください
    exit /b 1
)

if not exist "%SEVENZIP_PATH%" (
    echo エラー: 7z.exe が見つかりません: %SEVENZIP_PATH%
    echo conf\config.txt で 7z.exe の正しいパスを設定してください
    exit /b 1
)

rem 7z.exe動作テスト
"%SEVENZIP_PATH%" >nul 2>&1
if errorlevel 1 (
    echo エラー: 7z.exe が正常に動作しません: %SEVENZIP_PATH%
    exit /b 1
)

exit /b 0

:ValidateSetup
rem ディレクトリ作成
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

rem 基本ファイルの存在確認
if not exist "%CONFIG_FILE%" (
    echo エラー: 設定ファイル %CONFIG_FILE% が見つかりません。
    exit /b 1
)

if not exist "%REPO_LIST_FILE%" (
    echo エラー: リポジトリリストファイル %REPO_LIST_FILE% が見つかりません。
    exit /b 1
)

exit /b 0

:LoadConfig
rem 設定読み込み
echo 設定ファイル読み込み中: %CONFIG_FILE%
if not exist "%CONFIG_FILE%" (
    echo エラー: 設定ファイルが存在しません: %CONFIG_FILE%
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
exit /b 0

:ValidateConfig
rem BASE_DIR設定確認
if not defined BASE_DIR (
    echo エラー: BASE_DIR が設定されていません。
    exit /b 1
)

rem BASE_DIRの存在確認
if not exist "%BASE_DIR%" (
    echo エラー: BASE_DIR で指定されたディレクトリが存在しません: %BASE_DIR%
    exit /b 1
)

rem バックアップディレクトリの空き容量チェック（簡易版）
for %%i in ("%BACKUP_DIR%") do set "BACKUP_DRIVE=%%~di"
dir "%BACKUP_DRIVE%" >nul 2>&1 || (
    echo エラー: バックアップ先ドライブにアクセスできません: %BACKUP_DRIVE%
    exit /b 1
)

exit /b 0

:CreateFullRepositoryBackup
set "SOURCE_PATH=%~1"
set "BACKUP_PATH=%~2"

echo   ■■■ 実行: リポジトリ全体を7z圧縮バックアップ ■■■
echo   対象: %SOURCE_PATH%
echo   出力: %BACKUP_PATH%.7z

rem 7z.exe による完全バックアップ（xcopyは廃止）
"%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 -r >nul 2>&1
if errorlevel 1 (
    echo ■■■ 重大エラー: 7z圧縮バックアップに失敗しました ■■■
    echo [%date% %time%] 重大エラー: 7z圧縮バックアップ失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

rem バックアップファイルの存在とサイズチェック
if not exist "%BACKUP_PATH%.7z" (
    echo ■■■ 重大エラー: バックアップファイルが作成されませんでした ■■■
    echo [%date% %time%] 重大エラー: バックアップファイル不存在 %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

for %%F in ("%BACKUP_PATH%.7z") do set "BACKUP_SIZE=%%~zF"
if %BACKUP_SIZE% LSS 1024 (
    echo ■■■ 警告: バックアップファイルサイズが異常に小さいです: %BACKUP_SIZE% bytes ■■■
    echo [%date% %time%] 警告: バックアップファイルサイズ異常 %BACKUP_SIZE% bytes %REPO_NAME% >> "%LOG_FILE_ABS%"
)

echo   ■■■ 成功: 7z圧縮バックアップ完了 %BACKUP_PATH%.7z (%BACKUP_SIZE% bytes) ■■■
echo [%date% %time%] 成功: 7z圧縮バックアップ完了 %BACKUP_PATH%.7z (%BACKUP_SIZE% bytes) >> "%LOG_FILE_ABS%"
exit /b 0

:CheckGitStatus
echo   実行: git status --porcelain
git status --porcelain >nul 2>&1
if errorlevel 1 (
    echo エラー: git status が失敗しました
    echo [%date% %time%] エラー: git status失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)
exit /b 0

:HandleChanges
echo   実行: git diff --quiet
git diff --quiet 2>nul
if errorlevel 1 (
    echo 変更を検出しました。スタッシュを作成します...
    rem PowerShellを使用してスタッシュメッセージ用の安全な日付時刻を生成
    for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"') do set "STASH_DATETIME=%%i"
    echo   実行: git stash push -m "git-autocrlf-disable: !STASH_DATETIME!"
    git stash push -m "git-autocrlf-disable: !STASH_DATETIME!" >> "%LOG_FILE_ABS%" 2>&1
    if errorlevel 1 (
        echo エラー: スタッシュの作成に失敗しました
        echo [%date% %time%] エラー: スタッシュ作成失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
        exit /b 1
    )
    echo [%date% %time%] スタッシュ作成完了 %REPO_NAME% >> "%LOG_FILE_ABS%"
) else (
    echo 変更なし（スタッシュ不要）
)
exit /b 0

:SetAutocrlfFalse
echo   実行: git config core.autocrlf false
git config core.autocrlf false >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo エラー: autocrlf設定の変更に失敗しました
    echo [%date% %time%] エラー: autocrlf設定変更失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)
exit /b 0

:ResetToHead
echo   ■■■ 危険操作開始: 未追跡ファイル削除・キャッシュクリア・HEADリセット ■■■
echo   実行: git rm --cached -r .
git rm --cached -r . >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo 警告: git rm --cached で一部ファイルの処理に失敗しました（継続）
    echo [%date% %time%] 警告: git rm --cached 一部失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
)

echo   実行: git reset --hard HEAD
git reset --hard HEAD >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo エラー: git reset --hard HEAD に失敗しました
    echo [%date% %time%] エラー: git reset --hard HEAD失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

echo   実行: git clean -fd (未追跡ファイル完全削除)
git clean -fd >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo 警告: git clean -fd で一部ファイルの削除に失敗しました（継続）
    echo [%date% %time%] 警告: git clean -fd 一部失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
)

echo   ■■■ 完了: 危険操作終了 - Gitキャッシュクリア・ワーキングディレクトリHEAD復元 ■■■
echo [%date% %time%] 成功: キャッシュクリア・HEADリセット・クリーンアップ完了 %REPO_NAME% >> "%LOG_FILE_ABS%"
exit /b 0

rem ========================================
rem エラーハンドリング用ラベル
rem ========================================

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
exit /b 1
