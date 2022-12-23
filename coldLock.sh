#!/bin/bash

#***********************************************************
# coldLock - Deepfreeze application for linux systems.
#***********************************************************
# Version        :0.0.5 tr
# Created by     :Tekin Toraman
# E-Mail	 :ttoraman@gmail.com
# Created date   :16.12.2022
#***********************************************************


#Renk kodları
kirmizi='\033[0;31m'          # Red
yesil='\033[0;32m'        # Green
sari='\033[0;33m'       # Yellow
mavi='\033[0;34m'         # Blue
mor='\033[0;35m'       # Purple
beyaz='\033[0;37m'        # White
renkReset='\033[0m'

# Eğer .coldLock-pwd dosyası mevcutsa ilk bu kod bloğu çalışarak parola girmeniz istenecektir. 
if [[ -e /etc/coldLock/.coldLock-pwd ]]; then
	kayitliParola=$(</etc/coldLock/.coldLock-pwd)
	echo -n "Parolanızı yazınız:"
	read -s parola
	sifreCevir=$(echo -n ${parola} | sha256sum | cut -c 1-50)
	if [[ $sifreCevir != $kayitliParola ]]; then
		echo
		echo -e "${kirmizi}Hata: Hatalı parola girdiniz!${renkReset}"
		echo
		exit 0
	fi

fi

echo -e "${sari}"
echo "********************Menu********************"
echo "1. Bu kullanıcı için sistemi kilitle"
echo "2. Belirtilen kullanıcı için sistemi kilitle"
echo "3. Tüm kullanıcılar için sistemi kilitle"
echo "4. Sistem kilidini kaldır"
echo "5. Sistem durumunu görüntüle"
echo "6. Parola ayarla"
echo "7. Çıkış"
echo -e "${renkReset}"

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
	echo -e "${kirmizi}Hata: $dosyaAdi dosyası bulunamadı...${renkReset}"
fi
}

#dosyaDogrula fonksiyonuyla dosyaların olup olmadığını ve sorun varsa hangi dosya ile ilgili olduğu bulunur.
function dosyaDogrula(){
	if [ $dosyaVar -eq 1 -a $dosyaVar2 -eq 1 ]; then
		sonuc="True"
		echo $sonuc
	elif [ $dosyaVar -eq 0 -a $dosyaVar2 -eq 1 ]; then
		sonuc="${kirmizi}Hata: ${durumDosyasi} dosyası eksik.${renkReset}"
		echo -e $sonuc
	elif [ $dosyaVar -eq 1 -a $dosyaVar2 -eq 0 ]; then
		sonuc="${kirmizi}Hata: ${durumDosyasi2} dosyası eksik.${renkReset}"
		echo -e $sonuc	
	else
		sonuc="${kirmizi}Hata: ${durumDosyasi} ve ${durumDosyasi2} dosyaları eksik.${renkReset}"
		echo -e $sonuc
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
	echo -e "${mor}Bu kullanıcı için sistemi kilitleyi seçtiniz!${renkReset}"
	elif [[ "$coldSecim" == "2" ]]; then
	secim=True
	secilenIslem=2
	echo -e "${mor}Belirtilen kullanıcı için sistemi kilitleyi seçtiniz!${renkReset}"
	elif [[ "$coldSecim" == "3" ]]; then
	secim=True
	secilenIslem=3
	echo -e "${mor}Tüm kullanıcılar için sistemi kilitleyi seçtiniz!${renkReset}"
	elif [[ "$coldSecim" == "4" ]]; then
	secim=True
	secilenIslem=4
	echo -e "${mor}kiliti kaldırmayı seçtiniz${renkReset}"
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
	echo -e "${mor}Çıkış yaptınız...${renkReset}"
	exit
	else
	echo -e "${kirmizi}Yanlış seçim yaptınız.Tekrar deneyiniz...${renkReset}"
	secim=false
	fi
done

#case yapısını kullanarak seçilen işlemler yaptırılır.
case $secilenIslem in 
	1) 	if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ "$(dosyaFark)" != "" ]]; then
	   
	   			echo -e "${kirmizi}Hata: Bu sistem zaten kilitli.${renkReset}"
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
				echo -e "${yesil}Sistem başarıyla kilitlendi.${renkReset}"
			fi
		else
			dosyaDogrula
		fi
		
		;;

	2) 	if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ "$(dosyaFark)" != "" ]]; then
	   
	   			echo -e "${kirmizi}Hata: Bu sistem zaten kilitli.${renkReset}"
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
					echo -e "${yesil}Sistem başarıyla kilitlendi.${renkReset}"
				else
					echo -e "${kirmizi}Hata: Böyle bir kullanıcı yok!${renkReset}"
					exit 0
				fi
			fi
		else
			dosyaDogrula
		fi
		
		;;
	3) 	if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ "$(dosyaFark)" != "" ]]; then
	   
	   			echo -e "${kirmizi}Hata: Bu sistem zaten kilitli.${renkReset}"
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
				echo -e "${yesil}Sistem başarıyla kilitlendi.${renkReset}"
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
				
				echo -e "${yesil}Sistem kilidi başarıyla kaldırıldı...${renkReset}"
			
			else
				echo -e "${kirmizi}Hata: Sistem zaten kilitli değil.${renkReset}"
			fi
		else

			dosyaDogrula
		fi
		;;

	5) if [[ "$(dosyaDogrula)" == "True" ]]; then

			if [[ $(dosyaFark) != "" ]]; then

				echo -e "${yesil}Sistem şu an kilitli durumda...${renkReset}"
				
				
			else
				echo -e "${kirmizi}Sistem şu anda kilitli değil.${renkReset}"
			fi
		else

			dosyaDogrula
		fi
		;;
	
	6) echo -e "${sari}**********Parola ayarla**********"
		echo
		echo "Mevcut parolanızı kaldırmak için iki defa Enter tuşuna basınız."
		echo	
			echo -n "Parolanızı yazınız:"
			read -s parola
			echo
			echo -n "Parolanızı tekrar yazınız:"
			read -s rparola
			echo -e "${renkReset}"

		if [[ $parola == $rparola ]];then
			

			if [[ $parola != "" ]];then

				sifre=$(echo -n ${parola}| sha256sum | cut -c 1-50)
				sudo echo "${sifre}">.coldLock-pwd
				sudo cp .coldLock-pwd /etc/coldLock
				rm .coldLock-pwd
				echo -e "${yesil}Parola başarıyla oluşturuldu...${renkReset}"
				echo
				exit 0
			else

				if [[ -e /etc/coldLock/.coldLock-pwd ]];then
					sudo rm /etc/coldLock/.coldLock-pwd
					echo
					echo -e "${yesil}Parola başarıyla kaldırıldı...${renkReset}"
					exit 0
									

				fi
			fi
		else 
			echo -e "${kirmizi}Hata: Parolalar uyuşmadı!${renkReset}"
			exit 0
		fi
		   ;;
	   
	7) echo -e "${mor}İşlem sonlandırıldı...${renkReset}"
		   exit 0
		   ;;

	*) echo -e "${kirmizi}hatalı bir durum oldu...${renkReset}"
		exit 1
esac



	
	
	




	
	
	
