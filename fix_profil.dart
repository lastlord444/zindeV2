import 'dart:io';

void main() {
  final file = File('lib/presentation/pages/profil_page.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll('Ltfen tm gerekli alanlar1 doldurun', 'Lütfen tüm gerekli alanları doldurun');
  content = content.replaceAll('R Profil kaydedilemedi:', '❌ Profil kaydedilemedi:');
  content = content.replaceAll('  Profil kaydedildi: ', '✅ Profil kaydedildi: ');
  content = content.replaceAll('  Profil kaydedildi! Beslenme plan1n1z olu_turuluyor...', '✅ Profil kaydedildi! Beslenme planınız oluşturuluyor...');
  content = content.replaceAll('Ki_isel Bilgiler', 'Kişisel Bilgiler');
  content = content.replaceAll("label: 'Ya_'", "label: 'Yaş'");
  content = content.replaceAll("suffix: 'y1l'", "suffix: 'yıl'");
  content = content.replaceAll('= Otomatik K1s1tlamalar', '⚙️ Otomatik Kısıtlamalar');
  content = content.replaceAll('Manuel Alerji/K1s1tlama Ekle', 'Manuel Alerji/Kısıtlama Ekle');
  content = content.replaceAll('rn: Ceviz, F1nd1k, Soya', 'Örn: Ceviz, Fındık, Soya');
  content = content.replaceAll('a️ Manuel Alerjiler:', '⚠️ Manuel Alerjiler:');
  content = content.replaceAll('Toplam \${_tumKisitlamalar.length} K1s1tlama', 'Toplam \${_tumKisitlamalar.length} Kısıtlama');
  content = content.replaceAll('Makrolar Hesapland1!', 'Makrolar Hesaplandı!');
  content = content.replaceAll('=% Gnlk Kalori', '🔥 Günlük Kalori');
  content = content.replaceAll('= Protein', '💪 Protein');
  content = content.replaceAll(' xa Karbonhidrat', '🥖 Karbonhidrat');
  content = content.replaceAll('>Q Ya ', '🥑 Yağ');
  content = content.replaceAll('Profili Gncelle', 'Profili Güncelle');
  content = content.replaceAll('Yemek Veritaban1n1 Yenile', 'Yemek Veritabanını Yenile');
  content = content.replaceAll('Eski yemekler silinip yeni yemekler yklenecek.', 'Eski yemekler silinip yeni yemekler yüklenecek.');
  content = content.replaceAll('  120 farkl1 ara  n', '  120 farklı ara öğün');
  content = content.replaceAll('  Yeni ak_am yemekleri', '  Yeni akşam yemekleri');
  content = content.replaceAll('  Tm kategorilerde e_itlilik', '  Tüm kategorilerde çeşitlilik');
  content = content.replaceAll('Planlar yeniden olu_turulacak. Devam edilsin mi?', 'Planlar yeniden oluşturulacak. Devam edilsin mi?');
  content = content.replaceAll("Text('0ptal')", "Text('İptal')");
  content = content.replaceAll("Yemek Veritaban1n1 Yenile (120 Ara  n Ekle)", "Yemek Veritabanını Yenile (120 Ara Öğün Ekle)");
  content = content.replaceAll("Yeni yemekler ykleniyor...", "Yeni yemekler yükleniyor...");
  content = content.replaceAll("a️ PostgreSQL modunda yemek yenileme zelli i devre d1_1", "⚠️ PostgreSQL modunda yemek yenileme özelliği devre dışı");
  content = content.replaceAll("Yemek verileri bulutta saklan1yor ve admin panel zerinden ynetilir", "Yemek verileri bulutta saklanıyor ve admin panel üzerinden yönetilir");
  content = content.replaceAll("Devam d1_1", "Devre dışı");
  content = content.replaceAll("  Yeni yemekler yklendi! Şimdi \"Plan Olu_tur\" butonuna bas1n!", "✅ Yeni yemekler yüklendi! Şimdi \"Plan Oluştur\" butonuna basın!");
  content = content.replaceAll("R Ykleme ba_ar1s1z!", "❌ Yükleme başarısız!");

  file.writeAsStringSync(content);
  print('Fixed strings in profil_page.dart');
}
