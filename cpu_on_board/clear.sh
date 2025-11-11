<<<<<<< HEAD
=======
#host sudo purge
>>>>>>> 621cc05f9f7605be488d22c40a3c5593e69b7f6c
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
sudo systemctl stop cups avahi-daemon bluetooth


#sudo apt update
#sudo apt install qemu-guest-agent
#sudo systemctl enable --now qemu-guest-agent
systemctl start qemu-guest-agent
systemctl status qemu-guest-agent
