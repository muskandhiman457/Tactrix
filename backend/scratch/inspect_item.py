import urllib.request
import xml.etree.ElementTree as ET

url = "https://news.google.com/rss/search?q=sports&hl=en-IN&gl=IN&ceid=IN:en"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}
req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=8) as response:
    xml_data = response.read()

root = ET.fromstring(xml_data)
for i, item in enumerate(root.findall('.//item')[:3]):
    print(f"--- Item {i+1} ---")
    desc = item.find('description')
    if desc is not None:
        print("Description:", desc.text)

