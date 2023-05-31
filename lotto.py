#!/usr/bin/python3
from os import system
from selenium import webdriver
from selenium.webdriver import FirefoxOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from sys import argv, exit

# This command is used to send email with ssmtp.
#cmd = 'echo -e "To: amit.ugol@gmail.com,yigal.dalal@gmail.com,nlevinki@redhat.com,rbartal@redhat.com,lshilin@redhat.com\nSubject: Lotto has reached a large sum.\n" |'
#cmd += '(cat - && uuencode /tmp/next.png next.png) |'
#cmd += '/usr/sbin/ssmtp amit.ugol@gmail.com yigal.dalal@gmail.com nlevinki@redhat.com rbartal@redhat.com lshilin@redhat.com'

cmd = 'echo -e "To: amit.ugol@gmail.com\nSubject: Lotto has reached a large sum.\n" |'
cmd += '(cat - && uuencode /tmp/next.png next.png) |'
cmd += '/usr/sbin/ssmtp amit.ugol@gmail.com'

# Expecting a single argument.
if len(argv) != 2:
    exit("usage: lotto.py INT; where INT is the prize you are waiting for.")

# Trying to cast to an integer. If it fails, its not really an integer.
try:
    prize = int(argv[1])
except Exception as e:
    exit(e)

# Values should be between the smallest amount 4 and the maximum which is 80.
if 4 > prize > 80:
    exit("Expected ammunt should be between 4 and 80 (million).")

# Tweaking Firefox to run headless, and to dump Selenium's log.
capa = DesiredCapabilities.FIREFOX
capa['loggingPrefs'] = {'browser': 'NONE'}

opts = FirefoxOptions()
opts.binary_location = "/usr/lib64/firefox/firefox"
opts.add_argument("--headless")

# ff = webdriver.Firefox(options=opts, capabilities=capa)
ff = webdriver.Firefox(options=opts)

try:
    ff.get("https://www.pais.co.il/lotto/")
except Exception as e:
    exit(e)

try:
    price = ff.find_element(By.ID, "firstPrizeDouble")
except Exception as e:
    exit(e)

try:
    sum = int(price.text.split(None, 1)[0])
except Exception as e:
    exit(e)

try:
    ticker = ff.find_element(By.CLASS_NAME, "ticker_group")
except Exception as e:
    exit(e)

if sum >= prize:
    ticker.screenshot("/tmp/next.png")
    system(cmd)

ff.close()
system("rm -rf /home/augol/geckodriver.log")
system("rm -rf /tmp/next.png")
