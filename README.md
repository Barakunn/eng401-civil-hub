# ENG401 - İnşaat Mühendisliği Saha Hesap & Veri Servisi Portalı

Bu proje, inşaat mühendisliği saha hesaplamalarını gerçekleştiren, formül sonuçlarını yerel cihazda saklayan ve uzaktaki bir servis/bulut API ile çift yönlü (POST / GET) veri senkronizasyonu sağlayan **Flutter & Dart** tabanlı modüler bir mobil/web uygulamasıdır.

---

## 🏛️ Mimari Tasarım: Composition Root & Temiz Katmanlar

Uygulama, kod şişkinliğini (bloat) önlemek, maksimum bellek ve CPU optimizasyonu sağlamak adına **Composition Root** deseni ve **SOLID** prensipleri üzerine inşa edilmiştir:

```
lib/
├── bootstrap.dart                      # [COMPOSITION ROOT] Tüm servis & stratejilerin tek bağlantı noktası
├── main.dart                           # Uygulama başlangıcı ve Root Injection
├── app.dart                            # Ana Navigasyon Gövdesi (Navigation Shell)
│
├── core/                               # Çekirdek Altyapı
│   ├── contracts/                      # Saf Arayüzler (Interfaces / Dependency Inversion)
│   │   ├── calculation_strategy.dart   # İnşaat Formülü Strateji Arayüzü (Strategy Pattern)
│   │   ├── history_repository.dart     # Yerel Veri Depolama Arayüzü
│   │   └── sync_service.dart           # Bulut Servis & Senkronizasyon Arayüzü
│   ├── di/
│   │   └── app_scope.dart              # Saf InheritedWidget ile Dependency Injection (Sıfır Paket Yükü)
│   ├── theme/
│   │   └── app_theme.dart              # Optimize Material 3 İnşaat Mühendisliği Teması
│   └── utils/
│       └── formatters.dart             # Saha Rapor Çıktı & Paylaşım Yardımcıları
│
└── features/
    ├── dashboard/                      # [Modül 1] Ana Kontrol Paneli & Hızlı Sayaçlar
    ├── calculations/                   # [Modül 2] İnşaat Hesaplama Motoru (Pure Dart)
    │   ├── domain/
    │   │   ├── calculation_record.dart # Alan Varlığı (Entity) & JSON Serileştirme
    │   │   └── strategies/
    │   │       ├── concrete_strength_strategy.dart  # Beton Basınç Dayanımı & TS EN 206 Sınıfı
    │   │       ├── rebar_weight_strategy.dart       # Donatı Metraj & Tonaj Hesabı (TS 708)
    │   │       └── soil_bearing_strategy.dart       # Zemin Emniyetli Taşıma Gücü (Terzaghi)
    │   └── presentation/               # Dinamik ve reaktif Form Arayüzü
    │
    ├── history/                        # [Modül 3] Şantiye Kayıtları & Yerel Depolama (Offline First)
    └── sync/                           # [Modül 4] Bulut Servis, REST API & JSON Veri Alışverişi
```

---

## ⚡ Temel Modüller ve Yetenekler

### 1. Dinamik Hesaplama Motoru (Strategy Pattern)
* Formüller saf Dart (`Pure Dart`) ile yazılmıştır; arayüzden ve grafik motorundan bağımsızdır. Sıfır gecikmeyle (0ms) çalışır.
* **Mevcut Formüller:**
  1. **Beton Basınç Dayanımı ($f_{ck}$):** Su/çimento oranı ve doza göre 28 günlük basınç dayanımı, küp/silindir dönüşümü ve TBDY 2018 taşıyıcı sistem güvenlik denetimi.
  2. **Donatı Metrajı:** Donatı çapı ($\Phi$), adet, çubuk boyu ve şantiye fire payına göre toplam ağırlık ($kg$) ve sipariş tonajı.
  3. **Zemin Taşıma Gücü (Terzaghi):** Kohezyon ($c$), içsel sürtünme açısı ($\phi$), zemin birim ağırlığı ve temel geometrisine göre $q_u$ ve $q_{safe}$ hesabı.
* **Genişletilebilirlik:** Mansur Hoca yeni bir formül istediğinde sadece `CalculationStrategy` uygulayan tek bir sınıf yazılıp `bootstrap.dart` listesine eklenir.

### 2. Yerel Veri Kaydı (Offline First)
* Sahada internet çekmediğinde yapılan hesaplamalar şantiye ve blok adı verilerek cihaz hafızasına kaydedilir.
* Geçmiş kayıtlar listelenebilir, incelenebilir, silinebilir ve tekrar hesaplama motoruna geri yüklenebilir.

### 3. Çift Yönlü Veri Servisi (Cloud Sync & REST API)
* Mansur Hoca'nın talep ettiği *"data alıp verebilen servis uygulaması"* yapısı:
  * **POST Sync:** Yerel hesaplama verilerini bulut sunucuya yükler.
  * **GET Fetch:** Buluttaki şantiye kayıtlarını indirip cihaza aktarır.
  * **REST API Desteği:** Gerçek bir backend linki girildiğinde HTTP üzerinden REST istekleri yapar; offline veya mock modunda ise simüle edilmiş bulut servisiyle kesintisiz çalışır.
  * **JSON Görüntüleyici:** Gönderilen ve alınan paketleri doğrudan ham JSON olarak inceleme imkanı.

### 4. Saha Raporlama & Paylaşım
* Yapılan hesaplamaları tek tıkla şantiye şefine veya hocaya WhatsApp üzerinden iletilebilecek teknik bir mühendislik raporu metnine dönüştürür ve panoya kopyalar.

---

## 🚀 Çalıştırma

Projeyi test etmek ve çalıştırmak için terminalden:

```bash
# Bağımlılıkları kontrol et
flutter pub get

# Testleri çalıştır
flutter test

# Uygulamayı başlat (Chrome, Android veya Windows)
flutter run
```
