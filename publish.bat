@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title Publish Manggot IoT ke GitHub

echo ==================================================
echo    PUBLISH MANGGOT IoT KE GITHUB
echo ==================================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [X] Git belum terpasang. Download di https://git-scm.com/download/win
  echo     lalu jalankan file ini lagi.
  pause
  exit /b 1
)

REM ---------- 1. Salin firmware hasil Export Compiled Binary ----------
set "SKETCH=esp32\inkubator_manggot_iot\inkubator_manggot_iot.ino"
set "BIN="
for /r "esp32" %%F in (*.ino.bin) do (
  echo %%~nxF | findstr /i /c:"bootloader" /c:"merged" /c:"partitions" >nul || set "BIN=%%F"
)
if defined BIN (
  set "VER="
  for /f "tokens=3" %%V in ('findstr /b /c:"#define FW_VERSION" "%SKETCH%"') do set "VER=%%~V"
  if not exist firmware mkdir firmware
  copy /y "!BIN!" "firmware\manggot.bin" >nul
  powershell -NoProfile -Command "$s=(Get-Item 'firmware\manggot.bin').Length; $o=[ordered]@{version='!VER!';file='manggot.bin';size=$s}; [IO.File]::WriteAllText((Join-Path (Get-Location) 'firmware\version.json'), ($o | ConvertTo-Json))"
  echo [OK] Firmware v!VER! disalin ke firmware\manggot.bin
) else (
  echo [i] Tidak ada file .bin. Lewati firmware.
  echo     Untuk OTA: Arduino IDE ^> Sketch ^> Export Compiled Binary dulu.
)
echo.

REM ---------- 2. Siapkan repo git ----------
if not exist ".git" (
  git init >nul
  git branch -M main
  echo [OK] Repo git baru dibuat
)

for /f "delims=" %%E in ('git config user.email') do set "GEMAIL=%%E"
if not defined GEMAIL (
  set /p GNAME=Nama untuk commit GitHub:
  set /p GEMAIL=Email GitHub kamu:
  git config --global user.name "!GNAME!"
  git config --global user.email "!GEMAIL!"
)

git remote get-url origin >nul 2>nul
if errorlevel 1 (
  echo.
  echo Buat repo KOSONG dulu di https://github.com/new  ^(tanpa README^)
  set /p REPO=Tempel URL repo, contoh https://github.com/USER/manggot-iot.git :
  git remote add origin "!REPO!"
)

REM ---------- 3. Pengaman: jangan pernah upload secrets.h ----------
git rm --cached -r -q --ignore-unmatch esp32/inkubator_manggot_iot/secrets.h wokwi/secrets.h >nul 2>nul

REM ---------- 4. Commit dan push ----------
git add -A
git diff --cached --name-only | findstr /i /e "secrets.h" >nul
if not errorlevel 1 (
  echo [X] secrets.h ikut ter-add. Dibatalkan demi keamanan.
  git reset -q
  pause
  exit /b 1
)

set "MSG=Update %date% %time:~0,5%"
git commit -m "!MSG!" >nul 2>nul
if errorlevel 1 (echo [i] Tidak ada perubahan baru untuk di-commit.) else (echo [OK] Commit: !MSG!)

echo.
echo Mengirim ke GitHub...
git push -u origin main
if errorlevel 1 (
  echo [!] Push ditolak, mencoba sinkron dulu...
  git pull --rebase origin main
  git push -u origin main
  if errorlevel 1 (
    echo [X] Push gagal. Cek koneksi / login GitHub, lalu coba lagi.
    pause
    exit /b 1
  )
)

echo.
for /f "delims=" %%U in ('git remote get-url origin') do set "URL=%%U"
echo [SELESAI] Kode terkirim ke !URL!
echo Aplikasi akan aktif 1-2 menit lagi di GitHub Pages:
echo   https://USERNAME.github.io/NAMA-REPO/
echo ^(pertama kali: Settings ^> Pages ^> Branch main / root ^> Save^)
echo.
pause
