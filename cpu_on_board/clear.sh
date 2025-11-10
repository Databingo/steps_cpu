#sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
#sudo systemctl stop cups avahi-daemon bluetooth


#sudo apt update
#sudo apt install qemu-guest-agent
#sudo systemctl enable --now qemu-guest-agent
<<<<<<< HEAD
=======
systemctl start qemu-guest-agent
systemctl status qemu-guest-agent

>>>>>>> 688ec555d2cc34ad3e5970057b33fe9a57b1c9c7
