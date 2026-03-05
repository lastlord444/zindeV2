import os

def fix_file(path, replacements):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        
        new_content = content
        for k, v in replacements.items():
            new_content = new_content.replace(k, v)
            
        if new_content != content:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Fixed {path}")
        else:
            print(f"No changes needed for {path}")
    except Exception as e:
        print(f"Error on {path}: {e}")

profil_replacements = {
    "= Gnlk Kalori": "🔥 Günlük Kalori",
    "= Protein": "🥩 Protein",
    " x Karbonhidrat": "🍞 Karbonhidrat",
    ">Q Ya": "🥑 Yağ",
    "Profili Gncelle": "Profili Güncelle",
    "120 farkl1 ara n": "120 farklı ara öğün",
    "Yeni ak_am yemekleri": "Yeni akşam yemekleri",
    "Tm kategorilerde e_itlilik": "Tüm kategorilerde çeşitlilik",
    " imdi \"Plan Olu_tur\" butonuna bas1n!": " Şimdi \"Plan Oluştur\" butonuna basın!",
    "Plan1n1z1": "Planınızı",
    "Makrolar Hesapland1!": "Makrolar Hesaplandı!",
    "Yemek Veritaban1n1 Yenile": "Yemek Veritabanını Yenile",
    "Profil kaydedildi! Beslenme plan1n1z olu_turuluyor...": "Profil kaydedildi! Beslenme planınız oluşturuluyor..."
}

empty_state_replacements = {
    "Beslenme Plan1 Olu_tur": "Beslenme Planı Oluştur",
    "Gnk beslenme plan1n1z1 olu_turmak iin\\na_a1daki butona t1klay1n": "Günlük beslenme planınızı oluşturmak için\\naşağıdaki butona tıklayın",
    "Plan Olu_tur": "Plan Oluştur",
    "Bir Hata Olu_tu": "Bir Hata Oluştu",
    "Beklenmeyen bir sorun olu_tu.\\nLtfen tekrar deneyin.": "Beklenmeyen bir sorun oluştu.\\nLütfen tekrar deneyin.",
    "Bu tarih iin henz bir plan olu_turulmam1_": "Bu tarih için henüz bir plan oluşturulmamış",
    "0nternet Balant1s1 Yok": "İnternet Bağlantısı Yok",
    "Ltfen internet balant1n1z1 kontrol edip\\ntekrar deneyin": "Lütfen internet bağlantınızı kontrol edip\\ntekrar deneyin",
    "Ba_ar1l1!": "Başarılı!",
    "0_lem ba_ar1yla tamamland1": "İşlem başarıyla tamamlandı",
    " n Bulunamad1": "Öğün Bulunamadı",
    "Veritaban1nda bu kriterlere uygun  n bulunamad1": "Veritabanında bu kriterlere uygun öğün bulunamadı",
    "Filtre Dei_tir": "Filtre Değiştir",
    "Henz favori yemek eklemediniz.\\nBeendiiniz yemekleri favorilere ekleyerek kolayca eri_ebilirsiniz.": "Henüz favori yemek eklemediniz.\\nBeğendiğiniz yemekleri favorilere ekleyerek kolayca erişebilirsiniz.",
    "Yemek Ke_fet": "Yemek Keşfet",
    "Ba_ar1yla gncellendi!": "Başarıyla güncellendi!",
    "Gncelleme ba_ar1s1z": "Güncelleme başarısız"
}

fix_file(r"d:\zindeV.2.0\lib\presentation\pages\profil_page.dart", profil_replacements)
fix_file(r"d:\zindeV.2.0\lib\presentation\widgets\empty_state_widget.dart", empty_state_replacements)

