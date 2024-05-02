@echo off
set cw_win_app_config=--bitcoin --ethereum
set cw_root=%cd%
set cw_archive_name=Cake Wallet.zip
set cw_archive_path=%cw_root%\%cw_archive_name%
set secrets_file_path=lib\.secrets.g.dart
set release_dir=build\windows\runner\Release
set tools_root=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC\14.36.32532\x64\Microsoft.VC143.CRT

echo === Generating pubspec.yaml ===
copy /Y pubspec_description.yaml pubspec.yaml > nul
call flutter pub get > nul
call dart run tool\generate_pubspec.dart
call flutter pub get > nul
call dart run tool\configure.dart %cw_win_app_config%

IF NOT EXIST "%secrets_file_path%" (
    echo === Generating new secrets file ===
    call dart run tool\generate_new_secrets.dart
) ELSE (echo === Using previously/already generated secrets file: %secrets_file_path% ===)

echo === Generating mobx models ===
for /d %%i in (cw_core cw_bitcoin cw_ethereum cw_monero .) do (
    cd %%i
    call flutter pub get > nul
    call dart run build_runner build --delete-conflicting-outputs > nul
    cd /d %cw_root%
)

echo === Generating localization files ===
call dart run tool\generate_localization.dart

echo === Building the application executable file ===
call flutter build windows --dart-define-from-file=env.json --release

echo === Prepare distribution actions. Copy needed files to the application bundle ===
copy /Y "%tools_root%\msvcp140.dll" "%release_dir%\" > nul
copy /Y "%tools_root%\vcruntime140.dll" "%release_dir%\" > nul
copy /Y "%tools_root%\vcruntime140_1.dll" "%release_dir%\" > nul

echo === Generate the application archive ===
xcopy /s /e /v /Y "%release_dir%\*.*" "build\Cake Wallet\" > nul
tar acf "%cw_archive_name%" -C build\ "Cake Wallet"

echo === Open Explorer with the application archive ===
echo Cake Wallet created archive at: %cw_archive_path%
%SystemRoot%\explorer.exe /select, %cw_archive_path%