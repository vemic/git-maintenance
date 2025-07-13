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

rem 初期設定の検証
call :ValidateSetup || goto :SetupError
setlocal enabledelayedexpansion

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

echo 無効な選択です。
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

rem リポジトリリストの表示
echo 対象リポジトリ:
echo ----------------------------------------
type "%REPO_LIST_FILE%"
echo ----------------------------------------
echo.

set /p "CONFIRM=処理を実行しますか？ (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 処理をキャンセルしました。
    pause
    exit /b 0
)

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
echo 処理完了
echo ========================================
echo 成功: %SUCCESS_COUNT% リポジトリ
echo エラー: %ERROR_COUNT% リポジトリ
echo ログファイル: %LOG_FILE%
echo.

pause
exit /b 0

rem ========================================
rem リポジトリ処理関数
rem ========================================
:ProcessRepository
set "REPO_NAME=%~1"
set "REPO_PATH=%BASE_DIR%\%REPO_NAME%"

echo ----------------------------------------
echo 処理中: %REPO_NAME%
echo ----------------------------------------

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

rem ドライブを跨ぐ可能性があるため、ディレクトリ移動
pushd "%REPO_PATH%" || (
    echo エラー: ディレクトリに移動できません: %REPO_PATH%
    echo [%date% %time%] エラー: ディレクトリ移動失敗 %REPO_PATH% >> "%LOG_FILE_ABS%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem 現在のステータス確認
echo 1. ステータス確認中...
call :CheckGitStatus || (
    echo エラー: Git状態確認に失敗しました
    popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem 変更がある場合のスタッシュ
echo 2. 変更確認・スタッシュ中...
call :HandleChanges || (
    echo エラー: 変更処理に失敗しました
    popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem .gitフォルダのバックアップ作成（スタッシュ後に実行）
echo 3. .gitフォルダバックアップ作成中...
rem PowerShellを使用してバックアップ用タイムスタンプ生成
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "BACKUP_TIMESTAMP=%%i"
set "GIT_BACKUP_DIR=%BACKUP_DIR%\%REPO_NAME%_%BACKUP_TIMESTAMP%"

call :CreateBackup "%REPO_PATH%\.git" "%GIT_BACKUP_DIR%" || (
    echo エラー: .gitフォルダのバックアップに失敗しました
    echo [%date% %time%] エラー: バックアップ失敗により処理中止 %REPO_NAME% >> "%LOG_FILE_ABS%"
    popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem 現在のautocrlf設定確認
echo 4. 現在のautocrlf設定確認中...
echo   実行: git config core.autocrlf
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "CURRENT_AUTOCRLF=%%a"
if not defined CURRENT_AUTOCRLF set "CURRENT_AUTOCRLF=未設定"
echo   現在の設定: %CURRENT_AUTOCRLF%
echo [%date% %time%] 現在のautocrlf設定: %CURRENT_AUTOCRLF% %REPO_NAME% >> "%LOG_FILE_ABS%"

rem autocrlf=false に設定
echo 5. autocrlf=false に設定中...
call :SetAutocrlfFalse || (
    echo エラー: autocrlf設定変更に失敗しました
    popd
    set /a ERROR_COUNT+=1
    goto :eof
)

rem GitキャッシュをクリアしてワーキングディレクトリをHEADで上書き
echo 6. Gitキャッシュ一括クリア・HEADリセット中...
call :ResetToHead || (
    echo エラー: キャッシュクリア・HEADリセットに失敗しました
    popd
    set /a ERROR_COUNT+=1
    goto :eof
)

popd

echo 7. 完了: %REPO_NAME%
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

rem 7z.exeの存在確認（設定されている場合のみ）
if defined SEVENZIP_PATH (
    if not exist "%SEVENZIP_PATH%" (
        echo 警告: 指定された7z.exeが見つかりません: %SEVENZIP_PATH%
        echo xcopyによるバックアップを使用します。
        set "SEVENZIP_PATH="
    )
)

exit /b 0

:CreateBackup
set "SOURCE_PATH=%~1"
set "BACKUP_PATH=%~2"

rem 7z.exeが使用可能な場合は圧縮バックアップ
if defined SEVENZIP_PATH (
    echo   実行: "%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5
    "%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 >nul 2>&1
    if not errorlevel 1 (
        echo   7z圧縮バックアップ完了: %BACKUP_PATH%.7z
        echo [%date% %time%] 7z圧縮バックアップ完了: %BACKUP_PATH%.7z >> "%LOG_FILE_ABS%"
        exit /b 0
    ) else (
        echo 警告: 7z圧縮に失敗しました。xcopyを使用します。
        echo [%date% %time%] 警告: 7z圧縮失敗、xcopy使用 %REPO_NAME% >> "%LOG_FILE_ABS%"
    )
)

rem xcopyによるフォルダコピー
echo   実行: xcopy "%SOURCE_PATH%" "%BACKUP_PATH%" /E /I /H /Y
xcopy "%SOURCE_PATH%" "%BACKUP_PATH%" /E /I /H /Y >nul 2>&1
if errorlevel 1 (
    echo エラー: .gitフォルダのバックアップに失敗しました
    echo [%date% %time%] エラー: .gitバックアップ失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

echo   フォルダバックアップ完了: %BACKUP_PATH%
echo [%date% %time%] フォルダバックアップ完了: %BACKUP_PATH% >> "%LOG_FILE_ABS%"
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
echo   実行: git rm --cached -r .
git rm --cached -r . >> "%LOG_FILE_ABS%" 2>&1
echo   実行: git reset --hard HEAD
git reset --hard HEAD >> "%LOG_FILE_ABS%" 2>&1
if errorlevel 1 (
    echo エラー: キャッシュクリア・HEADリセットに失敗しました
    echo [%date% %time%] エラー: キャッシュクリア・HEADリセット失敗 %REPO_NAME% >> "%LOG_FILE_ABS%"
    exit /b 1
)

rem ワーキングディレクトリをクリーンアップ
echo   実行: git clean -fd
git clean -fd >> "%LOG_FILE_ABS%" 2>&1

echo   完了: Gitキャッシュクリア・ワーキングディレクトリをHEADの状態に復元しました
echo [%date% %time%] キャッシュクリア・HEADリセット・クリーンアップ完了 %REPO_NAME% >> "%LOG_FILE_ABS%"
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
