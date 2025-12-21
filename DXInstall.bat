@echo off
setlocal enabledelayedexpansion

:: 1. 启用ANSI颜色和UTF-8编码
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>nul
chcp 65001 >nul 2>nul
title DirectX Runtime Installation Tool

:: 2. 定义颜色代码
set "C_INFO=[36m"
set "C_SUCCESS=[32m"
set "C_WARN=[33m"
set "C_ERROR=[31m"
set "C_RESET=[0m"

:: 3. 检测系统语言（获取默认UI语言）
for /f "tokens=2 delims==" %%i in ('wmic os get MUILanguages /value ^| find "="') do set "SYS_LANG=%%i"
:: 兼容备用检测方式（若以上命令失败）
if not defined SYS_LANG (
    for /f "tokens=3 delims=." %%i in ('chcp') do set "CP=%%i"
    if "!CP!"=="936" set "SYS_LANG=zh-CN"    :: 简体中文代码页
    if "!CP!"=="950" set "SYS_LANG=zh-TW"    :: 【新增】繁体中文代码页
    if "!CP!"=="437" set "SYS_LANG=en-US"
    if "!CP!"=="932" set "SYS_LANG=ja-JP"
    if "!CP!"=="850" set "SYS_LANG=de-DE"
)

:: 【修改】调整语言代码处理逻辑：保留完整的zh-TW/zh-CN，仅对其他语言简化前5位
if "!SYS_LANG:~0,5!"=="zh-TW" (
    set "LANG_CODE=zh-TW"
) else if "!SYS_LANG:~0,5!"=="zh-CN" (
    set "LANG_CODE=zh-CN"
) else (
    set "LANG_CODE=!SYS_LANG:~0,5!"
)

:: 【修改】优先使用检测到的语言文件，仅当文件不存在时才回退到zh-CN
if not exist "%~dp0Lang\!LANG_CODE!.ini" set "LANG_CODE=zh-CN"

:: 4. 加载语言配置文件
call :LoadLang "%~dp0Lang\!LANG_CODE!.ini"

:: 5. 清屏显示标题
cls
echo.
echo ==============================================
echo          !C_INFO!!Title!!C_RESET!
echo ==============================================
echo.
echo !C_WARN!!Warning_DoNotClose!!C_RESET!
echo.

:: 6. 第一步：文件存在性校验
echo [!C_INFO!1/3!C_RESET!] !Step1_CheckFile!
set "CHECK_RESULT=SUCCESS"
if not exist "%~dp0\DirectX\Jun2010\DXSETUP.exe" (
    call :FormatText "!Err_FileNotFound!" "%~dp0\DirectX\Jun2010\DXSETUP.exe"
    echo !C_ERROR!!FORMATTED_TEXT!!C_RESET!
    echo !C_ERROR!!Err_FileCheck!!C_RESET!
    set "CHECK_RESULT=FAIL"
)

if !CHECK_RESULT! == SUCCESS (
    echo !C_SUCCESS!!Succ_FileCheck!!C_RESET!
    echo.

    :: 7. 第二步：执行安装
    echo [!C_INFO!2/3!C_RESET!] !Step2_Install!
    echo !C_WARN!!Tips_InstallWait!!C_RESET!
    start /w "" "%~dp0\DirectX\Jun2010\DXSETUP.exe" /silent 2>nul
    set "INSTALL_ERR=%ERRORLEVEL%"

    :: 8. 第三步：安装结果判断
    echo.
    echo [!C_INFO!3/3!C_RESET!] !Step3_CheckResult!
    echo.
    if !INSTALL_ERR! == 3010 (
        echo !C_SUCCESS!!Succ_Install!!C_RESET!
        echo !C_WARN!!Tips_Restart!!C_RESET!
    ) else if !INSTALL_ERR! == 0 (
        echo !C_SUCCESS!!Succ_Install!!C_RESET!
    ) else if !INSTALL_ERR! == 1605 (
        echo !C_INFO!!Tips_SkipInstall!!C_RESET!
    ) else if !INSTALL_ERR! == 1602 (
        echo !C_ERROR!!Err_Install_Cancel!!C_RESET!
    ) else if !INSTALL_ERR! == 1638 (
        echo !C_ERROR!!Err_Install_Version!!C_RESET!
    ) else if !INSTALL_ERR! == 1641 (
        echo !C_SUCCESS!!Succ_Install!!C_RESET!
        echo !C_WARN!!Tips_AutoRestart!!C_RESET!
    ) else if !INSTALL_ERR! == 5 (
        echo !C_ERROR!!Err_Install_Permission!!C_RESET!
    ) else if !INSTALL_ERR! == 1603 (
        echo !C_ERROR!!Err_Install_Corrupt!!C_RESET!
    ) else if !INSTALL_ERR! == 2 (
        echo !C_ERROR!!Err_Install_Path!!C_RESET!
    ) else (
        call :FormatText "!Err_Install_Unknown!" "!INSTALL_ERR!"
        echo !C_ERROR!!FORMATTED_TEXT!!C_RESET!
    )
)

:: 9. 最终统一提示
echo.
echo ==============================================
echo !C_INFO!!Tips_Finish!!C_RESET!
echo ==============================================
pause >nul
endlocal
exit /b

:: 【子程序】加载语言配置文件
:LoadLang
set "LANG_FILE=%~1"
for /f "usebackq delims=" %%a in ("!LANG_FILE!") do (
    set "LINE=%%a"
    :: 跳过注释和空行
    if "!LINE:~0,1!"=="[" goto :eof
    if "!LINE:~0,1!"==";" goto :eof
    if "!LINE!"=="" goto :eof
    :: 解析键值对（key=value）
    for /f "tokens=1,2 delims==" %%k in ("!LINE!") do (
        set "%%k=%%l"
    )
)
goto :eof

:: 【子程序】格式化带占位符的文本（%s/%d）
:FormatText
set "TEMPLATE=%~1"
set "ARG1=%~2"
set "FORMATTED_TEXT=!TEMPLATE:%s=!ARG1!!"
set "FORMATTED_TEXT=!FORMATTED_TEXT:%d=!ARG1!!"
goto :eof