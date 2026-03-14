while true; do read -p "Recompile 40 minutes! Not update 10 seconds! Enter to continue: "; 
bash compile.sh && bash burn.sh && bash monitor.sh;
done
