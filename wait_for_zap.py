import time
import urllib.request
import sys

print('Esperando a ZAP en localhost:8081...', end='', flush=True)
ready = False
for _ in range(30):
    try:
        urllib.request.urlopen('http://localhost:8081')
        ready = True
        break
    except Exception:
        print('.', end='', flush=True)
        time.sleep(2)
        
if ready:
    print('\n✅ ¡ZAP Listo!')
else:
    print('\n❌ Error: ZAP tardó demasiado.')
    sys.exit(1)
