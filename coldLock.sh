#!/bin/bash

#***********************************************************
# coldLock - Deepfreeze application for linux systems.
#***********************************************************
# Version        :0.0.2 tr
# Created by     :Tekin Toraman
# E-Mail		 :ttoraman@gmail.com
# Created date   :16.12.2022
#***********************************************************
# Eğer .coldLock-pwd dosyası mevcutsa ilk bu kod bloğu çalışarak parola girmeniz istenecektir. 
if [[ -e /etc/coldLock/.coldLock-pwd ]]; then
	kayitliParola=$(</etc/coldLock/.coldLock-pwd)
	echo -n "Parolanızı yazınız:"
	read -s parola
	sifreCevir=$(echo -n ${parola} | sha256sum | cut -c 1-50)
	if [[ $sifreCevir != $kayitliParola ]]; then
		echo
		echo "Hata: Hatalı parola girdiniz!"
		echo
		exit 0
	fi

fi

echo
echo "********************Menu********************"
echo "1. Bu kullanıcı için sistemi kilitle"
echo "2. Belirtilen kullanıcı için sistemi kilitle"
echo "3. Tüm kullanıcılar için sistemi kilitle"
echo "4. Sistem kilidini kaldır"
echo "5. Sistem durumunu görüntüle"
echo "6. Parola ayarla"
echo "7. Çıkış"
echo

secim=False
durumDosyasi='/etc/coldLock/rc-raw.local'
durumDosyasi2='/etc/rc.local'
dosyaAdi='/etc/coldLock/coldLock.tmp'


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
#rc-local servisinde kullanılacak dosyaların olup olmadığı bilgisini değişkenlere aktarır.
dosyaVar=$(dosyaDurumu $durumDosyasi)
dosyaVar2=$(dosyaDurumu $durumDosyasi2)


function bilgiAl(){
if [[ -e $dosyaAdi ]]; then

	while read line 
	do
		echo $line
	done <$dosyaAdi
else 
	echo "Hata: $dosyaAdi dosyası bulunamadı..."
fi
}

#dosyaDogrula fonksiyonuyla dosyaların olup olmadığını ve sorun varsa hangi dosya ile ilgili olduğu bulunur.
function dosyaDogrula(){
	if [ $dosyaVar -eq 1 -a $dosyaVar2 -eq 1 ]; then
		sonuc="True"
		echo $sonuc
	elif [ $dosyaVar -eq 0 -a $dosyaVar2 -eq 1 ]; then
		sonuc="Hata: ${durumDosyasi} dosyası eksik."
		echo $sonuc
	elif [ $dosyaVar -eq 1 -a $dosyaVar2 -eq 0 ]; then
		sonuc="Hata: ${durumDosyasi2} dosyası eksik."
		echo $sonuc	
	else
		sonuc="Hata: ${durumDosyasi} ve ${durumDosyasi2} dosyaları eksik."
		echo $sonuc
	fi
	}

#dosyaFark fonsiyonu iki dosyanın aynı olup olmadığını tespit eder.Dosyalar aynı ise boş değer döndürür ve bu sistem kilitli değil anlamındadır.
function dosyaFark(){

		sonuc=$(diff -q ${durumDosyasi} ${durumDosyasi2})
		echo $sonuc
	
	}
		
	
	
#Menüden seçilen işlemin değerini coldSecim değişkenine aktarır.
while [ "$secim" != "True" ];
	 do
	echo -n "Yapmak istediğiniz işlem numarasını yazınız:"
	read coldSecim
	
	if [[ "$coldSecim" == "1" ]]; then
	secim=True
	secilenIslem=1
	echo "Bu kullanıcı için sistemi kilitleyi seçtiniz!"
	elif [[ "$coldSecim" == "2" ]]; then
	secim=True
	secilenIslem=2
	echo "Belirtilen kullanıcı için sistemi kilitleyi seçtiniz!"
	elif [[ "$coldSecim" == "3" ]]; then
	secim=True
	secilenIslem=3
	echo "Tüm kullanıcılar için sistemi kilitleyi seçtiniz!"
	elif [[ "$coldSecim" == "4" ]]; then
	secim=True
	secilenIslem=4
	echo "kiliti kaldırmayı seçtiniz"
	elif [[ "$coldSecim" == "5" ]]; then
	echo "******Sistem Durumu*******"
	secilenIslem=5
	secim=True
	elif [[ "$coldSecim" == "6" ]]; then
	secilenIslem=6
	secim=True
	elif [[ "$coldSecim" == "7" ]]; then
	secilenIslem=
	secim=True
	echo "Çıkış yaptınız..."
	exit
	else
	echo "Yanlış seçim yaptınız.Tekrar deneyiniz..."
	secim=false
	fi
done

#case yapısını kullanarak seçilen işlemler yaptırılır.
case $secilenIslem in 
	1) 	if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ "$(dosyaFark)" != "" ]]; then
	   
	   			echo "Hata: Bu sistem zaten kilitli."
	   			echo
	   		else
	   			echo "Sistem kilitleniyor..."
	   			isim="$USER"
	   			echo $isim>coldLock.tmp
	   			sudo mv coldLock.tmp /etc/coldLock
	   			sudo rsync -a /home/${isim} /root
	   			sleep 10
				grep -v "exit 0" /etc/rc.local > yeni.tmp
				echo "sudo rsync -a --delete /root/${isim} /home" >>yeni.tmp
				echo "chown -R ${isim}:${isim} /home/${isim}" >> yeni.tmp
				#echo "echo '${isim}:1881'|chpasswd" >> yeni.tmp
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

	2) 	if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ "$(dosyaFark)" != "" ]]; then
	   
	   			echo "Hata: Bu sistem zaten kilitli."
	   			echo
	   		else
	   			echo -n "Kilitleme yapılacak kullanıcı adını yazınız:"
				read isim
				if [[ -d /home/${isim} ]]; then
					echo $isim>coldLock.tmp
	   				sudo mv coldLock.tmp /etc/coldLock
	   				echo "Sistem kilitleniyor..."
	   				sudo rsync -a /home/${isim} /root
	   				sleep 10
					grep -v "exit 0" /etc/rc.local > yeni.tmp
					echo "sudo rsync -a --delete /root/${isim} /home" >>yeni.tmp
					echo "chown -R ${isim}:${isim} /home/${isim}" >> yeni.tmp
					
					echo "exit 0" >>yeni.tmp
					sudo rm /etc/rc.local
					sudo cp yeni.tmp /etc/rc.local
					sudo chmod +x /etc/rc.local
					rm yeni.tmp
					echo "Sistem başarıyla kilitlendi."
				else
					echo "Hata: Böyle bir kullanıcı yok!"
					exit 0
				fi
			fi
		else
			dosyaDogrula
		fi
		
		;;
	3) 	if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ "$(dosyaFark)" != "" ]]; then
	   
	   			echo "Hata: Bu sistem zaten kilitli."
	   			echo
	   		else
	   			echo "">coldLock.tmp
	   			sudo mv coldLock.tmp /etc/coldLock
	   			echo "Sistem kilitleniyor..."
	   			sudo rsync -a /home/ /root
	   			sleep 10
				grep -v "exit 0" /etc/rc.local > yeni.tmp
				echo "sudo rsync -a --delete /root/ /home" >>yeni.tmp
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

	4) if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ $(dosyaFark) != "" ]]; then

				bilgiAl
				if [[ $(bilgiAl) == "" ]]; then

					sil="rm -rf /root/"

				else

					sil="rm -rf /root/$(bilgiAl)"

				fi

				echo "Sistem kilidi kaldırılıyor..."
				sudo $sil
				sudo rm /etc/rc.local
				sudo cp /etc/coldLock/rc-raw.local /etc/rc.local
				sudo chmod +x /etc/rc.local
				
				echo "Sistem kilidi başarıyla kaldırıldı..."
			
			else
				echo "Hata: Sistem zaten kilitli değil."
			fi
		else

			dosyaDogrula
		fi
		;;

	5) if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ $(dosyaFark) != "" ]]; then

				echo "Sistem şu an kilitli durumda..."
				
				
			else
				echo "Sistem şu anda kilitli değil."
			fi
		else

			dosyaDogrula
		fi
		;;
	
	6) echo "**********Parola ayarla**********"
		echo
		echo "Mevcut parolanızı kaldırmak için iki defa Enter tuşuna basınız."
		echo	
			echo -n "Parolanızı yazınız:"
			read -s parola
			echo
			echo -n "Parolanızı tekrar yazınız:"
			read -s rparola
			echo

		if [[ $parola == $rparola ]];then
			

			if [[ $parola != "" ]];then

				sifre=$(echo -n ${parola}| sha256sum | cut -c 1-50)
				echo "${sifre}">.coldLock-pwd
				sudo cp .coldLock-pwd /etc/coldLock
				rm .coldLock-pwd
				echo "Parola başarıyla değiştirildi..."
				echo
				exit 0
			else

				if [[ -e /etc/coldLock/.coldLock-pwd ]];then
					sudo rm /etc/coldLock/.coldLock-pwd
					echo
					echo "Parola başarıyla kaldırıldı..."
					exit 0
									

				fi
			fi
		else 
			echo "Hata: Parolalar uyuşmadı!"
			exit 0
		fi
		   ;;
	   
	7) echo "İşlem sonlandırıldı..."
		   exit 0
		   ;;

	*) echo "hatalı bir durum oldu..."
		exit 1
esac



	
	
	




	
	
	
