#!/bin/bash
# ******************************************************
#  coldLock - Deepfreeze application for linux systems.
# ******************************************************
# Version       : 0.0.1 tr
# Created by    : Tekin Toraman
# E-Mail        : ttoraman@gmail.com
# Created date  : December, 16th 2022

echo "....Menu...."
echo "1. Bu kullanıcı için sistemi kilitle"
echo "2. Sistem kilidini kaldır"
echo "3. Sistem durumuna bak"
echo "4. Çıkış"

secim=False
durumDosyasi='/etc/rc-raw.local'
durumDosyasi2='/etc/rc.local'


#sistem durumunu saklayan dosyasının mevcut olup olmadığını kontrol ediyoruz.

function dosyaDurumu(){
	if [[ -f "$1" ]]; then
		dosya=1
		echo $dosya
	else
		dosya=0
		echo $dosya
	fi

}

#işlemi otomatik hale getirmek için kullanılacak iki dosyanın da olup olmadığını değişkenlere aktarıyoruz.
dosyaVar=$(dosyaDurumu $durumDosyasi)
dosyaVar2=$(dosyaDurumu $durumDosyasi2)


#bu fonksiyonda sistem kullanıcısının adını değişkene aktarıyoruz. Bu bilgiyi $USER komutuylada alabilirdik.
function kullaniciAdi(){

	kullanici="${HOME:$kullanici}"
	IFS="/"
	set $kullanici
	kullanici2=$3
	echo $kullanici2


}
#dosyaDogrula fonksiyonuyla dosyaların olup olmadığını ve sorun varsa hangi dosya ile ilgili oldugunu buluyoruz.
function dosyaDogrula(){
	if [ $dosyaVar -eq 1 -a $dosyaVar2 -eq 1 ]; then
		sonuc="True"
		echo $sonuc
	elif [ $dosyaVar -eq 0 -a $dosyaVar2 -eq 1 ]; then
		sonuc="Hata: /etc/rc-raw.local dosyası eksik."
		echo $sonuc
	elif [ $dosyaVar -eq 1 -a $dosyaVar2 -eq 0 ]; then
		sonuc="Hata: /etc/rc.local dosyası eksik."
		echo $sonuc	
	else
		sonuc="Hata: /etc/rc-raw.local ve /etc/rc.local dosyaları eksik."
		echo $sonuc
	fi
	}
#dosyaFark fonksiyonuyla sistemin kilitli olup olmadığına karar veriyoruz.
function dosyaFark(){

		sonuc=$(diff -q /etc/rc.local /etc/rc-raw.local)
		echo $sonuc
	
	}
		
	
	
#Menüden seçilen işleme göre secilenIslem değişkenine ilgili sayıyı aktarıyoruz.
while [ "$secim" != "True" ];
	 do
	echo -n "Yapmak istediğiniz işlem numarasını yazınız:"
	read coldSecim
	
	if [[ "$coldSecim" == "1" ]]; then
	secim=True
	secilenIslem=1
	echo "sistem kilitlemeyi seçtiniz!"
	elif [[ "$coldSecim" == "2" ]]; then
	secim=True
	secilenIslem=2
	echo "kiliti kaldırmayı seçtiniz"
	elif [[ "$coldSecim" == "3" ]]; then
	echo "******Sistem Durumu*******"
	secilenIslem=3
	secim=True
	elif [[ "$coldSecim" == "4" ]]; then
	secilenIslem=4
	secim=True
	echo "Çıkış yaptınız..."
	exit
	else
	echo "Yanlış seçim yaptınız.Tekrar deneyiniz..."
	secim=false
	fi
done
#case yapısını kullanarak seçilen işlemi yapıyoruz.
case $secilenIslem in 
	1) 	if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ "$(dosyaFark)" != "" ]]; then
	   
	   			echo "Hata: Bu sistem zaten kilitli."
	   			echo
	   		else
	   			echo "Sistem kilitleniyor..."
	   			isim=$(kullaniciAdi)
	   			
	   			sudo rsync -a /home/${isim} /root
				grep -v "exit 0" /etc/rc.local > yeni.tmp
				echo "rm -r /home/${isim}">>yeni.tmp
				echo "sudo rsync -a --delete /root/${isim} /home" >>yeni.tmp
				echo "chown -R ${isim}:${isim} /home/${isim}" >> yeni.tmp
				echo "echo '${isim}:1881'|chpasswd" >> yeni.tmp
				echo "exit 0" >>yeni.tmp
				sudo rm /etc/rc.local
				sudo cp yeni.tmp /etc/rc.local
				sudo chmod +x /etc/rc.local
				rm yeni.tmp
				echo "Sistem başarıyla kilitlendi."
			fi
		else
			dosyaDogrula
		fi
		
		;;

	2) if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ $(dosyaFark) != "" ]]; then

				echo "Sistem kilidi kaldırılıyor..."
				sudo rm -r /root/${isim}
				sudo rm /etc/rc.local
				sudo cp /etc/rc-raw.local /etc/rc.local
				sudo chmod +x /etc/rc.local
				
				echo "Sistem kilidi başarıyla kaldırıldı..."
			
			else
				echo "Hata: Sistem zaten kilitli değil."
			fi
		else

			dosyaDogrula
		fi
		;;

	3) if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ $(dosyaFark) != "" ]]; then

				echo "Sistem şu an kilitli durumda..."
				
				
			else
				echo "Sistem şu anda kilitli değil."
			fi
		else

			dosyaDogrula
		fi
		;;
		   
	4) echo "İşlem sonlandırıldı..."
		   exit 0
		   ;;

	*) echo "hatalı bir durum oldu..."
		exit 1
esac



	
	
	
