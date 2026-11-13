# Manggot IoT

Aplikasi monitoring dan kontrol inkubator larva BSF (manggot) berbasis ESP32, Firebase Realtime Database, dan GitHub Pages.

```
manggot-iot/
├── index.html, style.css, app.js     aplikasi web (PWA, bisa dipasang di HP)
├── firebase-config.js                 ISI dengan config Firebase kamu
├── manifest.json, sw.js, icons/       supaya bisa "Tambahkan ke layar utama"
├── firmware/                          tempat file .bin untuk update OTA (diisi publish.bat)
├── firebase/database.rules.json       aturan keamanan database
├── esp32/inkubator_manggot_iot/       program ESP32 (.ino + secrets.example.h)
├── wokwi/                             file simulasi Wokwi
└── publish.bat                        sekali klik upload ke GitHub
```

## Pin mapping (sama dengan program awal)

| Komponen | Pin ESP32 | Keterangan |
|---|---|---|
| LCD I2C 20x4 | SDA 21, SCL 22 | alamat 0x27 |
| SHT30 | SDA 21, SCL 22 | alamat 0x44 |
| Relay 1 | GPIO 26 | Peltier + kipas (pendingin), active LOW |
| Relay 2 | GPIO 27 | Lampu pemanas, active LOW |
| LED status | GPIO 2 | nyala = WiFi OK, kedip cepat = cari WiFi, kedip lambat = hotspot setup |

---

## 1. Membuat Firebase (sekali saja, gratis paket Spark)

1. Buka https://console.firebase.google.com lalu **Add project**. Beri nama misalnya `manggot-iot`. Google Analytics boleh dimatikan.
2. **Authentication** (menu Build) lalu **Get started**. Di tab *Sign-in method* aktifkan **Email/Password**.
3. Tab **Users** lalu **Add user**, buat 2 akun:
   * Akun kamu, misalnya `rolas@gmail.com` + password. Ini akan otomatis menjadi **admin** saat pertama login di aplikasi.
   * Akun perangkat: email `esp32@manggot.app` + password kuat. Akun ini hanya dipakai ESP32.
4. **Realtime Database** (menu Build) lalu **Create Database**. Lokasi pilih **Singapore (asia-southeast1)**, mode **Start in locked mode**.
5. Buka tab **Rules**, hapus isinya, tempel isi file `firebase/database.rules.json`, lalu **Publish**.
   Kalau email perangkat kamu bukan `esp32@manggot.app`, ganti semua email itu di rules.
6. Salin **URL database** yang tampil di tab Data, contoh `https://manggot-iot-default-rtdb.asia-southeast1.firebasedatabase.app`.
7. **Project settings** (ikon gerigi) lalu tab General. Di bagian *Your apps* klik ikon **</>** (Web), beri nama, **Register app**. Salin objek `firebaseConfig`.
8. Tempel ke file `firebase-config.js` (ganti semua nilai `ISI_...`). Pastikan `databaseURL` ikut terisi.

> Siapapun bisa membuat akun lewat Firebase Auth kalau tahu apiKey, tetapi **rules** hanya mengizinkan akun yang terdaftar di node `users` (ditambahkan oleh admin) dan akun perangkat. Jadi data tetap aman.

## 2. Program ESP32

1. Arduino IDE, Board Manager pasang **esp32 by Espressif** versi 3.x.
2. Library Manager pasang **LiquidCrystal I2C** (Frank de Brabander) dan **ArduinoJson** (Benoit Blanchon, versi 7).
3. Di folder `esp32/inkubator_manggot_iot/` salin `secrets.example.h` menjadi `secrets.h`, lalu isi:
   * `FB_API_KEY` = apiKey dari langkah 1.7
   * `FB_DB_URL` = URL database dari langkah 1.6 (tanpa `/` di akhir)
   * `FB_DEVICE_EMAIL` dan `FB_DEVICE_PASS` = akun perangkat dari langkah 1.3
   * WiFi bawaan (WiFi lain bisa ditambah dari aplikasi)
4. Tools: Board **ESP32 Dev Module**, Partition Scheme **Minimal SPIFFS (1.9MB APP with OTA/190KB SPIFFS)**.
5. Upload. Di Serial Monitor (115200) akan muncul `[CLOUD] Login Firebase OK`.

Perintah Serial: `SET 31`, `MODE AUTO`, `MODE MANUAL`, `HEAT ON/OFF`, `COOL ON/OFF`, `WIFI LIST`, `WIFI ADD nama;password`, `WIFI DEL 2`, `REBOOT`, `STATUS`, `HELP`.

### Cara kerja penyimpanan
* **Setelan** (target, mode, batas, WiFi, reboot otomatis) disimpan di **Preferences/NVS**, yaitu EEPROM versi ESP32. Tetap ada walau listrik mati dan dipakai saat offline.
* **Riwayat** selalu ditulis dulu ke flash **LittleFS** (sekitar 6000 data, sekitar 4 hari pada interval 1 menit). Saat online, data dikirim bertahap ke Firebase. Jika penuh, data paling lama ditimpa.
* Kalau WiFi hilang 60 detik, ESP32 membuat hotspot **MANGGOT-SETUP** (password di `AP_PASS`). Sambungkan HP, buka `192.168.4.1` untuk menambah WiFi, ubah target, reboot, atau upload firmware `.bin`.

## 3. Upload ke GitHub (sekali klik)

**Cara paling mudah (pertama kali):** klik dua kali `setup-github.bat`. File ini memasang Git bila belum ada, membuka browser untuk login GitHub (cukup login lalu klik Authorize, tanpa kode verifikasi), membuat repo publik `manggot-iot`, mengupload kode, mengaktifkan GitHub Pages, lalu membuka aplikasinya. Setelah itu, update berikutnya cukup pakai `publish.bat`.

Cara manual:

1. Pasang Git: https://git-scm.com/download/win
2. Buat repo **kosong** di https://github.com/new (jangan centang README). Boleh Public.
3. Klik dua kali **`publish.bat`**. Pertama kali akan ditanya nama, email, dan URL repo, lalu muncul jendela login GitHub.
4. Di GitHub: **Settings > Pages > Source: Deploy from a branch > main / (root) > Save**.
5. Aplikasi bisa dibuka di `https://USERNAME.github.io/NAMA-REPO/`. Di HP buka lewat Chrome lalu **Tambahkan ke layar utama**.

Selanjutnya cukup klik `publish.bat` setiap ada perubahan. File `secrets.h` tidak akan pernah ikut ter-upload.

## 4. Update firmware dari aplikasi (OTA)

1. Ubah kode, naikkan `#define FW_VERSION "2.0.1"`.
2. Arduino IDE: **Sketch > Export Compiled Binary**.
3. Klik `publish.bat`. File `.bin` otomatis disalin ke `firmware/manggot.bin` dan `firmware/version.json` diperbarui.
4. Tunggu 1 sampai 2 menit (GitHub Pages memperbarui file), lalu buka aplikasi > **Sistem > Update Firmware > Update ke v2.0.1**.
5. LCD menampilkan progres. Setelah selesai perangkat restart dan log aktivitas mencatat versi baru.

## 5. Fitur aplikasi

* **Beranda**: animasi inkubator (lampu menyala dan bercahaya, kipas berputar dan udara dingin mengalir), manggot ekspresif (nyaman, kepanasan berkeringat, kedinginan menggigil, tidur saat offline), suhu, RH, status aktuator, peringatan.
* **Kontrol**: mode AUTO atau MANUAL, tombol pemanas dan pendingin (interlock), target suhu, histeresis, batas peringatan, batas aman, interval riwayat.
* **Riwayat**: grafik suhu, RH, target dan pita pemanas atau pendingin, statistik, tabel, **unduh CSV** (format Excel Indonesia atau standar), log aktivitas (siapa mengubah apa), hapus data lama.
* **Sistem**: info perangkat, multi WiFi (maks 5), reboot otomatis (tiap N jam atau jam tertentu) dan reboot sekarang, update firmware, kelola pengguna (admin atau operator), ganti password, notifikasi.
* Jika `firebase-config.js` belum diisi, aplikasi berjalan dalam **mode demo** dengan data simulasi.

## 6. Simulasi Wokwi

1. Buka https://wokwi.com/projects/new/esp32
2. Ganti isi `sketch.ino` dan `diagram.json` dengan file dari folder `wokwi/`.
3. Tambah file baru (tombol **+** atau panah di samping tab): `libraries.txt`, `secrets.h`, `sht30.chip.json`, `sht30.chip.c`, isi dengan file dari folder `wokwi/`.
4. Isi `secrets.h` dengan data Firebase (WiFi sudah `Wokwi-GUEST`).
5. Klik **Play**. Klik sensor SHT30 untuk menggeser suhu dan kelembapan. LED kuning = lampu, LED biru = peltier + kipas.
6. Simulasi terhubung ke Firebase yang sama, jadi aplikasi ikut menampilkan datanya.

Catatan: file `wokwi/sketch.ino` sama dengan program asli, hanya `WOKWI_SIM 1` (relay Wokwi aktif HIGH).

## Struktur database

```
users/{uid}: { name, email, role: "admin" | "operator" }
devices/manggot01/
  status   : data langsung dari ESP32 (t, h, cool, heat, mode, al, rssi, ip, fw, q, seen, ota)
  config   : mode, sp, hy, wtl, wth, whl, whh, smax, smin, mc, mh, hs
  system   : wifi[{s,p}], rbEn, rbMode, rbHours, rbAt, rebootReq, ota{url,ver,req}
  history  : t<epoch>: { t, h, f, a }   (f bit: 1 pendingin, 2 pemanas, 4 manual, 16 sensor ok)
  events   : { ts, u, m }
```
