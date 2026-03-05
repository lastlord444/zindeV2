import os
import re

file_path = 'lib/presentation/pages/profil_page.dart'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Fix Makro Cards
content = re.sub(r"'=% G.*?nl.*?k Kalori'", "'🔥 Günlük Kalori'", content)
content = re.sub(r"' x.*?a Karbonhidrat'", "'🥖 Karbonhidrat'", content)
content = re.sub(r"'>Q Ya\s*'", "'🥑 Yağ'", content)

# Fix other broken strings
content = re.sub(r"L.*?tfen t.*?m gerekli alanlar.*? doldurun", "Lütfen tüm gerekli alanları doldurun", content)
content = re.sub(r"Profil kaydedilemedi:", "Profil kaydedilemedi:", content)
content = re.sub(r"Profil kaydedildi! Beslenme plan.*?n.*?z olu.*?turuluyor\.\.\.", "Profil kaydedildi! Beslenme planınız oluşturuluyor...", content)
content = re.sub(r"'= Otomatik K.*?s.*?tlamalar.*?'", "'⚙️ Otomatik Kısıtlamalar'", content)
content = re.sub(r"rn: Ceviz, F.*?nd.*?k, Soya", "🥜 Örn: Ceviz, Fındık, Soya", content)
content = re.sub(r"a.*? Manuel Alerjiler:", "⚠️ Manuel Alerjiler:", content)
content = re.sub(r"Toplam (\${.*?}?) K.*?s.*?tlama", r"Toplam \1 Kısıtlama", content)
content = re.sub(r"Makrolar Hesapland.*?!", "Makrolar Hesaplandı!", content)
content = re.sub(r"Profili G.*?ncelle", "Profili Güncelle", content)
content = re.sub(r"YEN.*? YEMEK VER.*?TABANI YEN.*?LEME BUTONU", "YENİ YEMEK VERİTABANI YENİLEME BUTONU", content)
content = re.sub(r"Yemek Veritaban.*?n.*? Yenile.*?}", "Yemek Veritabanını Yenile'}", content)
content = re.sub(r"Eski yemekler silinip yeni yemekler y.*?klenecek\.", "Eski yemekler silinip yeni yemekler yüklenecek.", content)
content = re.sub(r"120 farkl.*? ara.*?n", "120 farklı ara öğün", content)
content = re.sub(r"Yeni ak\.*?am yemekleri", "Yeni akşam yemekleri", content)
content = re.sub(r"T.*?m kategorilerde .*?itlilik", "Tüm kategorilerde çeşitlilik", content)
content = re.sub(r"Planlar yeniden olu.*?turulacak\. Devam edilsin mi\?", "Planlar yeniden oluşturulacak. Devam edilsin mi?", content)
content = re.sub(r"Yeni yemekler y.*?kleniyor\.\.\.", "Yeni yemekler yükleniyor...", content)
content = re.sub(r"PostgreSQL modunda yemek yenileme .*?zelli.*?i devre d.*?.*?.*?.*?_.*?", "PostgreSQL modunda yemek yenileme özelliği devre dışı", content)

content = content.replace("Yemek Veritabanın1 Yenile (120 Ara  n Ekle)", "Yemek Veritabanını Yenile (120 Ara Öğün Ekle)")
content = content.replace("Yemek verileri bulutta saklanıyor ve admin panel zerinden ynetilir", "Yemek verileri bulutta saklanıyor ve admin panel üzerinden yönetilir")
content = content.replace("Yeni yemekler yklendi! Şimdi \"Plan Oluştur\" butonuna basın!", "Yeni yemekler yüklendi! Şimdi \"Plan Oluştur\" butonuna basın!")
content = content.replace("R Ykleme ba_arısız!", "❌ Yükleme başarısız!")
content = content.replace("R Hata", "❌ Hata")


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done fixing strings via Python.')
