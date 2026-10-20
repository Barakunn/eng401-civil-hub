# ENG401 - İnşaat Mühendisliği Saha Hesap & Veri Servisi Portalı

Bu proje, inşaat mühendisliği saha hesaplamalarını gerçekleştiren, formül sonuçlarını yerel cihazda saklayan, uzaktaki bir servis/bulut API ile çift yönlü (POST / GET) veri senkronizasyonu sağlayan ve **7-Girdili Algoritma Web Servisi** ile mobil-sunucu iletişimini yöneten **Flutter & Dart** tabanlı modüler bir mobil/web uygulamasıdır.

---

## 🏛️ Mimari Tasarım: Composition Root & Temiz Katmanlar

Uygulama, kod şişkinliğini (bloat) önlemek, maksimum bellek ve CPU optimizasyonu sağlamak adına **Composition Root** deseni ve **SOLID** prensipleri üzerine inşa edilmiştir:

```
Eng401/
├── server/                             # 🌐 MANSUR HOCA WEB SERVİSİ (Backend)
│   ├── server.js                       # Node.js yerleşik HTTP sunucusu (node server/server.js)
│   └── server.dart                     # Dart yerleşik HTTP sunucusu (dart run server/server.dart)
│
├── lib/
│   ├── bootstrap.dart                  # [COMPOSITION ROOT] Tüm servis & stratejilerin tek bağlantı noktası
│   ├── main.dart                       # Uygulama başlangıcı ve Root Injection
│   ├── app.dart                        # Ana Navigasyon Gövdesi (Navigation Shell)
│   │
│   ├── core/                           # Çekirdek Altyapı
│   │   ├── contracts/                  # Saf Arayüzler (Interfaces / Dependency Inversion)
│   │   ├── di/app_scope.dart           # Saf InheritedWidget ile Dependency Injection (Sıfır Paket Yükü)
│   │   ├── theme/app_theme.dart        # Optimize Material 3 İnşaat Mühendisliği Teması
│   │   └── utils/formatters.dart       # Saha Rapor Çıktı & Paylaşım Yardımcıları
│   │
│   └── features/
│       ├── dashboard/                  # [Modül 1] Ana Kontrol Paneli & Hızlı Sayaçlar
│       ├── calculations/               # [Modül 2] İnşaat Hesaplama Motoru (Pure Dart)
│       │   ├── domain/strategies/      # Beton Dayanımı, Donatı Metrajı, Zemin Taşıma Gücü
│       │   └── presentation/           # Dinamik ve reaktif Form Arayüzü
│       ├── history/                    # [Modül 3] Şantiye Kayıtları & Yerel Depolama (Offline First)
│       ├── sync/                       # [Modül 4] Bulut Servis, REST API & JSON Veri Alışverişi
│       └── remote_algorithm/           # [Modül 5] 🌐 7-GİRDİLİ WEB SERVİS ALGORİTMASI (Mansur Hoca)
│           ├── data/                   # HTTP POST client & Simülasyon yedeği
│           ├── domain/                 # 1 Çıktı (Output) & Sunucu sonuç modeli
│           └── presentation/           # 7 Textbox'lı Mobil İletişim Arayüzü
```

---

## 🌐 7-Girdili Web Servis Algoritması (Mansur Hoca Modülü)

Mansur Hoca'nın talep ettiği *"mobil textbox düğüm olsun, web servise veri atsın, sunucu hesaplayıp toplasın ve mobile tek çıktı dönsün"* kurgusu:

1. **Mobil Cihaz (Client):** Ekranda 7 adet Textbox ($x_1 \dots x_7$) ile girdi alır.
2. **Web Servis (Backend - `POST /api/calculate`):** Girdileri JSON olarak alır:
   $$\text{Sonuç} = (x_1 + x_2 + x_3 + x_4) - (x_5 + x_6 + x_7)$$
3. **Tek Çıktı (Output):** Web servis çıktıyı hesaplar ve JSON olarak döner:
   ```json
   {
     "status": "success",
     "output": 60.0,
     "formula": "(10 + 20 + 30 + 40) - (5 + 10 + 15)",
     "details": "Toplanan: 100.00, Çıkarılan: 30.00",
     "timestamp": "2026-10-20T16:30:00Z"
   }
   ```
4. **Kolay Revize Edilebilir:** Hoca yarın formülü değiştirdiğinde mobil kodlara hiç dokunulmaz; sadece `server/server.js` veya `server/server.dart` dosyasındaki formül fonksiyonu güncellenir!

---

## 🚀 Nasıl Çalıştırılır?

### 1. Web Servisini Başlatma (Backend):
Bilgisayarında bir terminal açıp şu iki komuttan birini çalıştırman yeterlidir (Harici kurulum gerektirmez):
```bash
# Node.js ile çalıştırmak için:
node server/server.js

# VEYA Dart ile çalıştırmak için:
dart run server/server.dart
```
*Sunucu `http://localhost:3000` adresinde 7 girdi bekleyen `POST /api/calculate` servisini anında ayağa kaldırır.*

### 2. Mobil Uygulamayı Başlatma (Frontend):
İkinci bir terminalde:
```bash
# Web tarayıcıda çalıştırmak için:
flutter run -d chrome

# veya bağlı telefon / emülatörde:
flutter run
```

Uygulama açıldığında Dashboard'daki **"7-Girdili Algoritma Web Servisi"** kartına tıklayarak doğrudan test edebilirsiniz. Sunucu kapalıyken bile akıllı simülasyon modu sayesinde uygulama asla çökmez.
