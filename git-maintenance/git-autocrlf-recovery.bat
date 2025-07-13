@echo ofset "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"
set "REPO_LIST_FILE=%SCRIPT_DIR%conf\repositories.txt"
set "LOG_DIR=%SCRIPT_DIR%log"
set "BACKUP_DIR=%SCRIPT_DIR%backup"
set "LOG_FILE=%LOG_DIR%\git-autocrlf-recovery_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"

rem ログファイルの時刻フォーマット調整
set "LOG_FILE=%LOG_FILE: =0%"

rem 初期設定の検証
call :ValidateSetup || goto :SetupError32 >nul
setlocal enabledelayedexpansion

rem ========================================
rem Git AutoCRLF設定変更・復旧バッチ
rem ========================================

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"
set "REPO_LIST_FILE=%SCRIPT_DIR%conf\repositories.txt"
set "LOG_DIR=%SCRIPT_DIR%log"
set "BACKUP_DIR=%SCRIPT_DIR%backup"
set "LOG_FILE=%LOG_DIR%\git-autocrlf-recovery_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"

rem ログファイルの時刻フォーマット調整
set "LOG_FILE=%LOG_FILE: =0%"

echo ========================================
echo Git AutoCRLF 設定変更・復旧ツール
echo ========================================
echo.
echo 実行モードを選択してください:
echo 1. AutoCRLF設定変更・復旧実行
echo 2. リポジトリ情報確認
echo 3. スタッシュ一覧表示  
echo 4. git-autocrlf-recovery関連スタッシュ復元
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
echo [%date% %time%] Git AutoCRLF 設定変更・復旧処理開始 > "%LOG_FILE%"

echo ベースディレクトリ: %BASE_DIR%
echo ログファイル: %LOG_FILE%
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
echo [%date% %time%] 処理開始: %REPO_NAME% >> "%LOG_FILE%"

rem リポジトリディレクトリの確認
if not exist "%REPO_PATH%" (
    echo エラー: リポジトリディレクトリが見つかりません: %REPO_PATH%
    echo [%date% %time%] エラー: ディレクトリ不存在 %REPO_PATH% >> "%LOG_FILE%"
    set /a ERROR_COUNT+=1
    goto :eof
)

rem .gitディレクトリの確認
if not exist "%REPO_PATH%\.git" (
    echo エラー: Gitリポジトリではありません: %REPO_PATH%
    echo [%date% %time%] エラー: Gitリポジトリではない %REPO_PATH% >> "%LOG_FILE%"
    set /a ERROR_COUNT+=1
    goto :eof
)

pushd "%REPO_PATH%"

rem .gitフォルダのバックアップ作成
echo 1. .gitフォルダバックアップ作成中...
set "BACKUP_TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "BACKUP_TIMESTAMP=%BACKUP_TIMESTAMP: =0%"
set "GIT_BACKUP_DIR=%BACKUP_DIR%\%REPO_NAME%_%BACKUP_TIMESTAMP%"

call :CreateBackup "%REPO_PATH%\.git" "%GIT_BACKUP_DIR%" || goto :BackupError

rem 現在のステータス確認
echo 2. ステータス確認中...
call :CheckGitStatus || goto :GitError

rem 変更がある場合のスタッシュ
echo 3. 変更確認中...
call :HandleChanges || goto :StashError

rem 現在のautocrlf設定確認
echo 4. 現在のautocrlf設定確認中...
for /f "tokens=*" %%a in ('git config core.autocrlf 2^>nul') do set "CURRENT_AUTOCRLF=%%a"
if not defined CURRENT_AUTOCRLF set "CURRENT_AUTOCRLF=未設定"
echo   現在の設定: %CURRENT_AUTOCRLF%
echo [%date% %time%] 現在のautocrlf設定: %CURRENT_AUTOCRLF% %REPO_NAME% >> "%LOG_FILE%"

rem autocrlf=false に設定
echo 5. autocrlf=false に設定中...
call :SetAutocrlfFalse || goto :ConfigChangeError

rem GitキャッシュをクリアしてワーキングディレクトリをHEADで上書き
echo 6. Gitキャッシュクリア・HEADリセット中...
call :ResetToHead || goto :ResetError

popd

echo 8. 完了: %REPO_NAME%
echo [%date% %time%] 処理完了: %REPO_NAME% >> "%LOG_FILE%"
set /a SUCCESS_COUNT+=1

goto :eof

rem ========================================
rem リポジトリ情報確認機能
rem ========================================
:CheckRepositories
echo.
echo ========================================
echo リポジトリ情報確認
echo ========================================

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

pushd "%REPO_PATH%"

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

rem git-autocrlf-recovery関連スタッシュ数
for /f "tokens=*" %%t in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-recovery" ^| find /c /v ""') do set "RECOVERY_STASH_COUNT=%%t"
if not defined RECOVERY_STASH_COUNT set "RECOVERY_STASH_COUNT=0"

popd

echo   状態: 正常
echo   パス: %REPO_PATH%
echo   ブランチ: %CURRENT_BRANCH%
echo   autocrlf: %AUTOCRLF%
echo   未保存変更: %HAS_CHANGES%
echo   スタッシュ数: %STASH_COUNT% (recovery関連: %RECOVERY_STASH_COUNT%)

set /a VALID_COUNT+=1

rem 変数クリア
set "CURRENT_BRANCH="
set "AUTOCRLF="
set "HAS_CHANGES="
set "STASH_COUNT="
set "RECOVERY_STASH_COUNT="

goto :eof

rem ========================================
rem スタッシュ一覧表示機能
rem ========================================
:ListStashes
echo.
echo ========================================
echo スタッシュ一覧
echo ========================================

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

pushd "%REPO_PATH%"

git stash list 2>nul | findstr /C:"git-autocrlf-recovery" >nul
if errorlevel 1 (
    git stash list 2>nul | find /c /v "" > temp_count.txt
    set /p STASH_COUNT=<temp_count.txt
    del temp_count.txt
    if !STASH_COUNT! gtr 0 (
        echo スタッシュ数: !STASH_COUNT! （git-autocrlf-recovery関連なし）
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
rem git-autocrlf-recovery関連スタッシュ復元機能
rem ========================================
:RestoreStashes
echo.
echo ========================================
echo git-autocrlf-recovery関連スタッシュ復元
echo ========================================
echo.
echo 注意: この操作により、git-autocrlf-recoveryで作成された
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

pushd "%REPO_PATH%"

rem git-autocrlf-recovery関連のスタッシュを検索
for /f "tokens=1,* delims=:" %%a in ('git stash list 2^>nul ^| findstr /C:"git-autocrlf-recovery"') do (
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

echo git-autocrlf-recovery関連のスタッシュが見つかりません

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
for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    if "%%a"=="BASE_DIR" set "BASE_DIR=%%b"
    if "%%a"=="SEVENZIP_PATH" set "SEVENZIP_PATH=%%b"
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
    "%SEVENZIP_PATH%" a "%BACKUP_PATH%.7z" "%SOURCE_PATH%" -mx5 >nul 2>&1
    if not errorlevel 1 (
        echo   7z圧縮バックアップ完了: %BACKUP_PATH%.7z
        echo [%date% %time%] 7z圧縮バックアップ完了: %BACKUP_PATH%.7z >> "%LOG_FILE%"
        exit /b 0
    ) else (
        echo 警告: 7z圧縮に失敗しました。xcopyを使用します。
        echo [%date% %time%] 警告: 7z圧縮失敗、xcopy使用 %REPO_NAME% >> "%LOG_FILE%"
    )
)

rem xcopyによるフォルダコピー
xcopy "%SOURCE_PATH%" "%BACKUP_PATH%" /E /I /H /Y >nul 2>&1
if errorlevel 1 (
    echo エラー: .gitフォルダのバックアップに失敗しました
    echo [%date% %time%] エラー: .gitバックアップ失敗 %REPO_NAME% >> "%LOG_FILE%"
    exit /b 1
)

echo   フォルダバックアップ完了: %BACKUP_PATH%
echo [%date% %time%] フォルダバックアップ完了: %BACKUP_PATH% >> "%LOG_FILE%"
exit /b 0

:CheckGitStatus
git status --porcelain >nul 2>&1
if errorlevel 1 (
    echo エラー: git status が失敗しました
    echo [%date% %time%] エラー: git status失敗 %REPO_NAME% >> "%LOG_FILE%"
    exit /b 1
)
exit /b 0

:HandleChanges
git diff --quiet 2>nul
if errorlevel 1 (
    echo 変更を検出しました。スタッシュを作成します...
    git stash push -m "git-autocrlf-recovery: %date% %time%" >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        echo エラー: スタッシュの作成に失敗しました
        echo [%date% %time%] エラー: スタッシュ作成失敗 %REPO_NAME% >> "%LOG_FILE%"
        exit /b 1
    )
    echo [%date% %time%] スタッシュ作成完了 %REPO_NAME% >> "%LOG_FILE%"
) else (
    echo 変更なし（スタッシュ不要）
)
exit /b 0

:SetAutocrlfFalse
git config core.autocrlf false >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo エラー: autocrlf設定の変更に失敗しました
    echo [%date% %time%] エラー: autocrlf設定変更失敗 %REPO_NAME% >> "%LOG_FILE%"
    exit /b 1
)
exit /b 0

:ResetToHead
git rm --cached -r . >> "%LOG_FILE%" 2>&1
git reset --hard HEAD >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo エラー: HEADリセットに失敗しました
    echo [%date% %time%] エラー: HEADリセット失敗 %REPO_NAME% >> "%LOG_FILE%"
    exit /b 1
)

rem ワーキングディレクトリをクリーンアップ
git clean -fd >> "%LOG_FILE%" 2>&1

echo   完了: ワーキングディレクトリをHEADの状態に復元しました
echo [%date% %time%] HEADリセット・クリーンアップ完了 %REPO_NAME% >> "%LOG_FILE%"
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

:BackupError
echo.
echo ========================================
echo バックアップエラー
echo ========================================
echo リポジトリ: %REPO_NAME%
echo.
echo ■ このツールが提供する対処法：
echo   1. バックアップエラーのため処理を中止しました
echo   2. ディスク容量を確認してください
echo   3. 7z.exeを使用する場合はパスを確認してください
echo.
echo ■ 一般的なトラブルシューティング：
echo   - ディスクの空き容量が十分にあるか確認
echo   - ウイルス対策ソフトによるファイルブロックがないか確認
echo   - 管理者権限で実行してみる
echo.
popd
set /a ERROR_COUNT+=1
pause
goto :eof

:GitError
echo.
echo ========================================
echo Git操作エラー
echo ========================================
echo リポジトリ: %REPO_NAME%
echo.
echo ■ このツールが提供する対処法：
echo   1. Gitリポジトリが破損している可能性があります
echo   2. バックアップから.gitフォルダを復旧してください
echo   3. restore-git.bat を使用して復旧を試してください
echo.
echo ■ 一般的なトラブルシューティング：
echo   - git fsck でリポジトリの整合性を確認
echo   - リモートリポジトリから再クローンを検討
echo   - .git/index ファイルの削除を試す
echo.
popd
set /a ERROR_COUNT+=1
pause
goto :eof

:StashError
echo.
echo ========================================
echo スタッシュエラー
echo ========================================
echo リポジトリ: %REPO_NAME%
echo.
echo ■ このツールが提供する対処法：
echo   1. 未コミットの変更をスタッシュできませんでした
echo   2. 手動でコミットまたは変更を破棄してから再実行してください
echo   3. git stash list でスタッシュの状況を確認してください
echo.
echo ■ 一般的なトラブルシューティング：
echo   - git status で現在の状態を確認
echo   - 大きなバイナリファイルが含まれていないか確認
echo   - ディスク容量が不足していないか確認
echo.
popd
set /a ERROR_COUNT+=1
pause
goto :eof

:ConfigChangeError
echo.
echo ========================================
echo 設定変更エラー
echo ========================================
echo リポジトリ: %REPO_NAME%
echo.
echo ■ このツールが提供する対処法：
echo   1. git config core.autocrlf の設定変更に失敗しました
echo   2. .git/config ファイルの権限を確認してください
echo   3. 手動で「git config core.autocrlf false」を実行してください
echo.
echo ■ 一般的なトラブルシューティング：
echo   - .git/config ファイルが読み取り専用になっていないか確認
echo   - リポジトリが破損していないか git fsck で確認
echo   - 管理者権限で実行してみる
echo.
popd
set /a ERROR_COUNT+=1
pause
goto :eof

:ResetError
echo.
echo ========================================
echo リセットエラー
echo ========================================
echo リポジトリ: %REPO_NAME%
echo.
echo ■ このツールが提供する対処法：
echo   1. git reset --hard HEAD に失敗しました
echo   2. バックアップから.gitフォルダを復旧してください
echo   3. restore-git.bat を使用して復旧を試してください
echo.
echo ■ 一般的なトラブルシューティング：
echo   - git fsck でリポジトリの整合性を確認
echo   - .git/index ファイルを削除してから git reset を試す
echo   - リモートリポジトリから再クローンを検討
echo.
popd
set /a ERROR_COUNT+=1
pause
goto :eof
