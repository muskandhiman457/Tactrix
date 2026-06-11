from googlenewsdecoder import new_decoderv1
import urllib.request
import re
import xml.etree.ElementTree as ET

def get_real_image(url):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=4) as response:
            html = response.read().decode('utf-8', errors='ignore')
            
        og_image_match = re.search(r'<meta\s+[^>]*property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']', html)
        if not og_image_match:
            og_image_match = re.search(r'<meta\s+[^>]*content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']', html)
            
        og_image = og_image_match.group(1) if og_image_match else None
        return og_image
    except Exception as e:
        print(f"Error fetching image for {url}: {e}")
        return None

if __name__ == "__main__":
    google_url = "https://news.google.com/rss/articles/CBMi9AFBVV95cUxOZ0lSaEdrYXRyMHpSTmNiMlFDVXkwMmpiWUdwVVBBNmhvVTJxVllta3dubE1UWHRTX3pYUnVFek1UMTJkYm90NDl3dHpwYW42UzVwSHFIdjUwZC1fSENsekttb0FQQ1FBdS16SnR1TVFvVFFwd1JTNmxPNURqRUljV1piNmFoZlhZbVVmNjVURFFDV3VYaXhzZWF3OGhJvl9tNHdYME9Eak90ZmVodXd3UE5lVmJLbmROUmVsSE1mNHBGN1dsODFkSUZJbE45QlZOV0FUdmY1RUJoaF8tSWlMWThOLU1zSWh6WURmek10TDJYR19h"
    
    # Try decoding
    print("Decoding Google News URL...")
    decoded = new_decoderv1(google_url, interval=1)
    print("Decoded status:", decoded.get("status"))
    print("Decoded URL:", decoded.get("decoded_url"))
    
    if decoded.get("status"):
        real_url = decoded.get("decoded_url")
        image = get_real_image(real_url)
        print("Extracted OG Image URL:", image)
