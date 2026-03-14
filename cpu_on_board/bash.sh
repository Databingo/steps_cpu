while true; do read -p "Recompile 40 minutes! Not update 10 seconds!:"; 
bash compile.sh && bash burn.sh && bash monitor.sh;
done
