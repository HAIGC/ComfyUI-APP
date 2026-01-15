# auto_build.ps1
# 自动化配置 Android 构建环境并打包 APK

$ErrorActionPreference = "Stop"

# 定义全局路径
$WorkDir = "D:\桌面\ComfyuiApp\ComfyController\.build_env"
$JdkDir = "$WorkDir\jdk-17"
$SdkDir = "$WorkDir\android-sdk"
$CmdLineToolsDir = "$SdkDir\cmdline-tools\latest"
$SdkManagerBat = "$CmdLineToolsDir\bin\sdkmanager.bat"

# 1. 创建工作目录
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

Write-Host "WorkDir: $WorkDir"
Write-Host "SdkDir: $SdkDir"

# ---------------------------------------------------------
# 2. 下载并配置 Java JDK 17
# ---------------------------------------------------------
Write-Host "`n>>> [1/5] Checking Java JDK 17..." -ForegroundColor Cyan

# 智能查找 JDK 根目录
$JdkActualDir = Get-ChildItem -Path $WorkDir -Directory | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1
if ($JdkActualDir) {
    $JdkDir = $JdkActualDir.FullName
} else {
    Write-Host "    Downloading Microsoft OpenJDK 17..."
    $JdkUrl = "https://aka.ms/download-jdk/microsoft-jdk-17.0.9-windows-x64.zip"
    $JdkZip = "$WorkDir\jdk.zip"
    Invoke-WebRequest -Uri $JdkUrl -OutFile $JdkZip
    
    Write-Host "    Extracting JDK..."
    Expand-Archive -Path $JdkZip -DestinationPath $WorkDir -Force
    Remove-Item $JdkZip
    
    $JdkActualDir = Get-ChildItem -Path $WorkDir -Directory | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1
    if ($JdkActualDir) {
        $JdkDir = $JdkActualDir.FullName
    } else {
        Write-Error "Could not find JDK directory in $WorkDir"
    }
}

# 设置 JAVA_HOME
$env:JAVA_HOME = $JdkDir
$env:Path = "$JdkDir\bin;$env:Path"
Write-Host "    JAVA_HOME set to: $env:JAVA_HOME"
& "$JdkDir\bin\java.exe" -version

# ---------------------------------------------------------
# 3. 下载并配置 Android Command Line Tools
# ---------------------------------------------------------
Write-Host "`n>>> [2/5] Checking Android Command Line Tools..." -ForegroundColor Cyan

if (!(Test-Path $SdkManagerBat)) {
    Write-Host "    Downloading Android Command Line Tools..."
    $SdkUrl = "https://dl.google.com/android/repository/commandlinetools-win-10406996_latest.zip"
    $SdkZip = "$WorkDir\cmdline-tools.zip"
    Invoke-WebRequest -Uri $SdkUrl -OutFile $SdkZip
    
    Write-Host "    Extracting SDK Tools..."
    # 临时解压目录
    $TempUnzipDir = "$WorkDir\temp_sdk_unzip"
    if (Test-Path $TempUnzipDir) { Remove-Item -Recurse -Force $TempUnzipDir }
    New-Item -ItemType Directory -Path $TempUnzipDir | Out-Null
    
    Expand-Archive -Path $SdkZip -DestinationPath $TempUnzipDir -Force
    
    # 构建正确的目标结构: android-sdk/cmdline-tools/latest
    if (!(Test-Path "$SdkDir\cmdline-tools")) { New-Item -ItemType Directory -Path "$SdkDir\cmdline-tools" -Force | Out-Null }
    
    # 移动
    $Source = "$TempUnzipDir\cmdline-tools"
    if (Test-Path $CmdLineToolsDir) { Remove-Item -Recurse -Force $CmdLineToolsDir }
    Move-Item -Path $Source -Destination $CmdLineToolsDir
    
    # 清理
    Remove-Item -Recurse -Force $TempUnzipDir
    Remove-Item $SdkZip
} else {
    Write-Host "    Command Line Tools already exists."
}

# 设置 ANDROID_HOME
$env:ANDROID_HOME = $SdkDir
$env:Path = "$CmdLineToolsDir\bin;$env:Path"

# ---------------------------------------------------------
# 4. 安装 Android SDK 组件 (Platforms, Build-Tools)
# ---------------------------------------------------------
Write-Host "`n>>> [3/5] Installing Android SDK Components..." -ForegroundColor Cyan
# 创建 repositories.cfg 防止警告
if (!(Test-Path "$env:USERPROFILE\.android\repositories.cfg")) {
    if (!(Test-Path "$env:USERPROFILE\.android")) { New-Item -ItemType Directory -Path "$env:USERPROFILE\.android" | Out-Null }
    New-Item -ItemType File -Path "$env:USERPROFILE\.android\repositories.cfg" -Force | Out-Null
}

if (!(Test-Path $SdkManagerBat)) {
    Write-Error "SdkManager not found at $SdkManagerBat"
}

Write-Host "    DEBUG: SdkManagerBat is '$SdkManagerBat'"

Write-Host "    Accepting licenses..."
# 直接调用 cmd，不使用中间变量传递命令字符串，避免空值风险
# 注意：PowerShell 传递带引号的参数给 native command 很麻烦
# 使用 Start-Process 比较稳妥
$ProcArgs1 = "/c echo y | `"$SdkManagerBat`" --licenses"
Write-Host "    Executing: cmd $ProcArgs1"
Start-Process -FilePath "cmd.exe" -ArgumentList $ProcArgs1 -Wait -NoNewWindow

Write-Host "    Installing components..."
# 硬编码组件列表，防止变量为空
$ProcArgs2 = "/c echo y | `"$SdkManagerBat`" platforms;android-34 build-tools;34.0.0"
Write-Host "    Executing: cmd $ProcArgs2"
Start-Process -FilePath "cmd.exe" -ArgumentList $ProcArgs2 -Wait -NoNewWindow

# ---------------------------------------------------------
# 5. 构建 APK
# ---------------------------------------------------------
Write-Host "`n>>> [4/5] Building APK with Gradle..." -ForegroundColor Cyan
Set-Location $PSScriptRoot
# 再次确保环境变量，防止被覆盖
$env:JAVA_HOME = $JdkDir 
$env:Path = "$JdkDir\bin;$env:Path"

# 首次运行 gradlew 可能需要下载 gradle distribution，这也会比较慢
.\gradlew.bat assembleDebug

# ---------------------------------------------------------
# 6. 完成
# ---------------------------------------------------------
Write-Host "`n>>> [5/5] Build Complete!" -ForegroundColor Green
$ApkPath = "$PSScriptRoot\app\build\outputs\apk\debug\app-debug.apk"
if (Test-Path $ApkPath) {
    Write-Host "SUCCESS! APK generated at:" -ForegroundColor Green
    Write-Host $ApkPath
    # 尝试在资源管理器中选中文件
    $explorerParams = '/select,"' + $ApkPath + '"'
    Start-Process "explorer.exe" -ArgumentList $explorerParams
} else {
    Write-Host "ERROR: APK file not found." -ForegroundColor Red
}
