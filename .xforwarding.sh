function setxfw () {
xauth list $DISPLAY | head -1 > /tmp/xauth
echo $DISPLAY > /tmp/display
echo "1. change to the user you want = sudo su - root"
echo "2. Run this command - xauth add '$(cat /tmp/xauth)'; export DISPLAY='$(cat /tmp/display)';"
echo "3. Thenrun whatever command you need as that user to have it x-forwarded to your local display"
}


