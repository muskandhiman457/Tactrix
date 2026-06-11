import urllib.request

url = "https://news.google.com/rss/articles/CBMiZkFVX3lxTE4tY1doU19Zc2VzbThHQlZrS3FMMnJVZjVhdldMUEs3ME9hTE04alVyMW1vcDVSVEpPZ281elk5NVZyUU9OYWozTFRfbnZRdEEtdFk3NzAtV1ZPeklDMnhVWjliRV81dw?oc=5&hl=en-IN&gl=IN&ceid=IN:en"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}
req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req, timeout=8) as response:
        print("Status code:", response.status)
        print("Response URL:", response.geturl())
        html = response.read().decode('utf-8', errors='ignore')
        print("HTML length:", len(html))
        print("HTML start:")
        print(html[:2000])
        print("HTML end:")
        print(html[-2000:])
except Exception as e:
    print("Error:", e)
