IP=$(ifconfig | grep "inet " | grep -v 127.0.0 | awk '{print $2}' | head -n 1) 
