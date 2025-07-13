@echo off
chcp 932 >nul
setlocal enabledelayedexpansion

echo ========================================
echo .git フォルダ復旧ツール
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "BACKUP_DIR=%SCRIPT_DIR%backup"
set "CONFIG_FILE=%SCRIPT_DIR%conf\config.txt"

rem 設定ファイルの読み込み
if not exist "%CONFIG_FILE%" (
    echo エラー: 設定ファイル %CONFIG_FILE% が見つかりません。
    echo setup.bat を先に実行してください。
    pause
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    if "%%a"=="BASE_DIR" set "BASE_DIR=%%b"
)

if not defined BASE_DIR (
    echo エラー: BASE_DIR が設定されていません。
    pause
    exit /b 1
)

rem バックアップディレクトリの確認
if not exist "%BACKUP_DIR%" (
    echo エラー: バックアップディレクトリが見つかりません: %BACKUP_DIR%
    echo まずメイン処理を実行してバックアップを作成してください。
    pause
    exit /b 1
)

echo ベースディレクトリ: %BASE_DIR%
echo バックアップディレクトリ: %BACKUP_DIR%
echo.

echo 利用可能なバックアップ:
echo ----------------------------------------
dir /b "%BACKUP_DIR%" 2>nul | findstr /R ".*_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]"
echo ----------------------------------------
echo.

set /p "BACKUP_FOLDER=復旧したいバックアップフォルダ名を入力してください: "

if not exist "%BACKUP_DIR%\%BACKUP_FOLDER%" (
    echo エラー: 指定されたバックアップが見つかりません: %BACKUP_FOLDER%
    pause
    exit /b 1
)

rem リポジトリ名を抽出（フォルダ名から日時部分を除去）
for /f "tokens=1,2 delims=_" %%a in ("%BACKUP_FOLDER%") do (
    set "REPO_NAME=%%a"
)

set "TARGET_REPO=%BASE_DIR%\%REPO_NAME%"

echo.
echo 復旧対象リポジトリ: %REPO_NAME%
echo リポジトリパス: %TARGET_REPO%
echo バックアップソース: %BACKUP_DIR%\%BACKUP_FOLDER%
echo.

if not exist "%TARGET_REPO%" (
    echo エラー: 対象リポジトリが見つかりません: %TARGET_REPO%
    pause
    exit /b 1
)

echo 警告: この操作により現在の.gitフォルダが置き換えられます。
echo 現在の.gitフォルダは .git_replaced_YYYYMMDDHHMMSS として退避されます。
echo.
set /p "CONFIRM=復旧を実行しますか？ (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 復旧をキャンセルしました。
    pause
    exit /b 0
)

pushd "%TARGET_REPO%"

rem 現在の.gitフォルダを退避
set "REPLACE_TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "REPLACE_TIMESTAMP=%REPLACE_TIMESTAMP: =0%"

if exist ".git" (
    echo 現在の.gitフォルダを退避中...
    move ".git" ".git_replaced_%REPLACE_TIMESTAMP%" >nul 2>&1
    if errorlevel 1 (
        echo エラー: 現在の.gitフォルダの退避に失敗しました。
        popd
        pause
        exit /b 1
    )
    echo 退避完了: .git_replaced_%REPLACE_TIMESTAMP%
)

rem バックアップから復元
echo .gitフォルダを復元中...
xcopy "%BACKUP_DIR%\%BACKUP_FOLDER%" ".git" /E /I /H /Y >nul 2>&1
if errorlevel 1 (
    echo エラー: .gitフォルダの復元に失敗しました。
    if exist ".git_replaced_%REPLACE_TIMESTAMP%" (
        echo 元の.gitフォルダを復旧しています...
        move ".git_replaced_%REPLACE_TIMESTAMP%" ".git" >nul 2>&1
    )
    popd
    pause
    exit /b 1
)

echo 復元完了！

rem 復旧確認
echo.
echo 復旧確認中...
call :ValidateGitRepository || goto :ValidationError

echo 復旧確認OK: Gitリポジトリとして正常に機能しています。

popd

echo.
echo ========================================
echo 復旧完了
echo ========================================
echo リポジトリ: %REPO_NAME%
echo 復旧元: %BACKUP_FOLDER%
echo 退避先: .git_replaced_%REPLACE_TIMESTAMP%
echo.
echo 次の手順:
echo 1. git status で状態を確認
echo 2. git log で履歴を確認
echo 3. 問題なければ退避フォルダ(.git_replaced_*)を削除
echo.

pause

rem ========================================
rem 検証とエラーハンドリング関数
rem ========================================

:ValidateGitRepository
rem 基本的なGit操作の確認
git status >nul 2>&1
if errorlevel 1 (
    echo エラー: git status が失敗しました。
    exit /b 1
)

rem リポジトリ整合性チェック
echo リポジトリ整合性を確認中...
git fsck --full >nul 2>&1
if errorlevel 1 (
    echo 警告: git fsck で整合性エラーが検出されました。
    echo リポジトリに問題がある可能性があります。
    set /p "CONTINUE=整合性エラーがありますが復旧を続行しますか？ (Y/N): "
    if /i not "!CONTINUE!"=="Y" (
        exit /b 1
    )
) else (
    echo 整合性チェック完了: 問題は見つかりませんでした。
)

rem ブランチ情報の確認
git branch >nul 2>&1
if errorlevel 1 (
    echo エラー: ブランチ情報の取得に失敗しました。
    exit /b 1
)

exit /b 0

:ValidationError
echo.
echo ========================================
echo 復旧検証エラー
echo ========================================
echo.
echo ■ このツールが提供する対処法：
echo   1. 復旧したリポジトリに問題があります
echo   2. 別のバックアップを使用して復旧を試してください
echo   3. 退避した元の.gitフォルダを戻すことも可能です
echo.
echo ■ 一般的なトラブルシューティング：
echo   - git fsck --full で詳細なエラー情報を確認
echo   - リモートリポジトリから再クローンを検討
echo   - 別の日時のバックアップを試してみる
echo.
echo 利用可能な操作:
echo 1. 元の.gitフォルダに戻す（move .git_replaced_%REPLACE_TIMESTAMP% .git）
echo 2. 別のバックアップで再試行
echo 3. リモートから再クローン
echo.
popd
pause
exit /b 1
