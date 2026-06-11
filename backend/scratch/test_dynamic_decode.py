import urllib.request
import xml.etree.ElementTree as ET
from googlenewsdecoder import new_decoderv1, gnewsdecoder

url = "https://news.google.com/rss/search?q=sports&hl=en-IN&gl=IN&ceid=IN:en"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}
req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=8) as response:
    xml_data = response.read()

root = ET.fromstring(xml_data)
items = root.findall('.//item')
if items:
    fresh_url = items[0].find('link').text
    print("Fresh URL from RSS:", fresh_url)
    
    print("\nTrying new_decoderv1:")
    try:
        res1 = new_decoderv1(fresh_url, interval=1)
        print("res1 status:", res1.get("status"))
        print("res1 url:", res1.get("decoded_url"))
    except Exception as e:
        print("new_decoderv1 error:", e)
        
    print("\nTrying gnewsdecoder:")
    try:
        res2 = gnewsdecoder(fresh_url, interval=1)
        print("res2 status:", res2.get("status"))
        print("res2 url:", res2.get("decoded_url"))
    except Exception as e:
        print("gnewsdecoder error:", e)
else:
    print("No items found in RSS feed")
