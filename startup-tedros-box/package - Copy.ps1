$version = "18.01"
$miniVersion = "17.0.1-SNAPSHOT"
$jar = "startup-tedros-box-$miniVersion-jar-with-dependencies.jar"
$input = "packaging-input"  # Mudança: Renomeado para evitar conflito com o diretório Maven 'target'
$output = "packages"
$name = "TedrosBox"
$mainClass = "com.tedros.TedrosLauncher"
$icon = "tedrosico.ico"

# JDK 17 Paths - User Defined
$jdkHome = "D:\java\jdk\jdk-17.0.10"
$jpackage = "$jdkHome\bin\jpackage.exe"
$javac = "$jdkHome\bin\javac.exe"
$jarTool = "$jdkHome\bin\jar.exe"

# Caminho para o SDK JavaFX (baixe do GluonHQ e ajuste se necessário)
$javafxSdkPath = "D:\java\openjfx-sdk\17.0.11\lib"

# Define Java Options
$javaOptions = @(
    "-Xms512m",
    "-Xmx2048m",
    "-Dprism.maxvram=2G",
    "--add-opens=javafx.graphics/javafx.scene.layout=ALL-UNNAMED",
    "--add-exports=javafx.graphics/com.sun.javafx.css=ALL-UNNAMED",
    "--add-exports=javafx.base/com.sun.javafx.collections=ALL-UNNAMED",
    "--add-exports=javafx.base/com.sun.javafx.property=ALL-UNNAMED",
    "--add-exports=javafx.web/com.sun.javafx.webkit=ALL-UNNAMED",
    "--add-exports=javafx.web/com.sun.webkit=ALL-UNNAMED"
)

# Ensure output directory exists and clean it
if (Test-Path $output) {
    Remove-Item -Recurse -Force $output
}
New-Item -ItemType Directory -Force -Path $output | Out-Null

# Nova: Limpa e recria o diretório input para incluir apenas o necessário
if (Test-Path $input) {
    Remove-Item -Recurse -Force $input
}
New-Item -ItemType Directory -Force -Path $input | Out-Null

# Nova: Verifica se o JAR existe (gerado por mvn)
if (-not (Test-Path "target/$jar")) {
    Write-Host "JAR not found at target/$jar. Please run 'mvn clean package' first to build the project." -ForegroundColor Red
    exit 1
}

# Nova: Verifica se o SDK JavaFX existe
if (-not (Test-Path "$javafxSdkPath")) {
    Write-Host "JavaFX SDK not found at $javafxSdkPath." -ForegroundColor Red
    Write-Host "Download from https://download2.gluonhq.com/openjfx/17.0.11/openjfx-17.0.11_windows-x64_bin-sdk.zip" -ForegroundColor Yellow
    Write-Host "Extract the ZIP and place the contents in D:\java\openjfx-sdk\17.0.11 so that lib/ contains the JARs and DLLs." -ForegroundColor Yellow
    exit 1
}

# Copia o JAR da app (gerado pelo Maven) para input
Copy-Item -Path "target/$jar" -Destination $input

# Nova: Copia JARs e nativos (DLLs) do SDK JavaFX para input como arquivos soltos
Copy-Item -Path "$javafxSdkPath\*" -Destination $input -Recurse

Write-Host "Compiling Launcher with JDK 17..."
& $javac -cp "$input/$jar" -d "$input/classes" src/main/java/com/tedros/TedrosLauncher.java

Write-Host "Updating Jar with Launcher..."
& $jarTool uf "$input/$jar" -C "$input/classes" com/tedros/TedrosLauncher.class

Write-Host "Packaging $name with JDK 17..."

$jpackageArgs = @(
    "--type", "exe",
    "--dest", $output,
    "--name", $name,
    "--input", $input,
    "--main-jar", $jar,
    "--main-class", $mainClass,
    "--icon", $icon,
    "--app-version", $version,
    "--vendor", "Tedros",
    "--win-shortcut",
    "--win-menu",
    "--win-console"
)

# Add each java option individually
foreach ($opt in $javaOptions) {
    $jpackageArgs += "--java-options"
    $jpackageArgs += $opt
}

# Execute jpackage
& $jpackage @jpackageArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful!" -ForegroundColor Green
    Get-ChildItem $output
} else {
    Write-Host "Build Failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}