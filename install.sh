#kurulum dosyası

echo \#\!\/bin\/sh \-e > rc-raw.local
echo "exit 0" >> rc-raw.local
sudo cp rc-raw.local /etc/rc.local
sudo cp rc-raw.local /etc
rm rc-raw.local
sudo chmod +x /etc/rc.local
sudo systemctl is-active rc-local
if [[ "$?" == "3" ]]; then
	sudo systemctl daemon-reload
	sudo systemctl start rc-local

fi
sudo cp coldLock.sh /usr/bin/coldLock
sudo chmod +x /usr/bin/coldLock
echo "Kurulum tamamlandı..."