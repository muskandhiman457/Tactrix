import urllib.request
import re
import xml.etree.ElementTree as ET
import concurrent.futures
import time
from googlenewsdecoder import new_decoderv1

def get_og_image(url):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=3) as response:
            html = response.read().decode('utf-8', errors='ignore')
            
        og_image_match = re.search(r'<meta\s+[^>]*property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']', html)
        if not og_image_match:
            og_image_match = re.search(r'<meta\s+[^>]*content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']', html)
            
        og_image = og_image_match.group(1) if og_image_match else None
        return og_image
    except Exception:
        return None

def process_item(item):
    title = item.find('title').text if item.find('title') is not None else ''
    google_url = item.find('link').text if item.find('link') is not None else ''
    pub_date = item.find('pubDate').text if item.find('pubDate') is not None else ''
    description = item.find('description').text if item.find('description') is not None else ''
    
    # Clean title
    clean_title = title
    source = "Google News"
    if " - " in title:
        parts = title.rsplit(" - ", 1)
        clean_title = parts[0]
        source = parts[1]
        
    real_url = google_url
    image_url = None
    
    # Decode Google News URL
    try:
        decoded = new_decoderv1(google_url, interval=0) # use 0 interval for concurrent calls
        if decoded.get("status"):
            real_url = decoded.get("decoded_url")
            image_url = get_og_image(real_url)
    except Exception as e:
        print(f"Error decoding URL: {e}")
        
    return {
        "title": clean_title,
        "source": source,
        "pub_date": pub_date,
        "description": description,
        "link": real_url,
        "image_url": image_url
    }

if __name__ == "__main__":
    url = "https://news.google.com/rss/search?q=sports&hl=en-IN&gl=IN&ceid=IN:en"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=8) as response:
        xml_data = response.read()

    root = ET.fromstring(xml_data)
    items = root.findall('.//item')[:6] # Process top 6 items
    
    print(f"Processing {len(items)} items concurrently...")
    start_time = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
        results = list(executor.map(process_item, items))
        
    end_time = time.time()
    print(f"Completed in {end_time - start_time:.2f} seconds\n")
    
    for i, res in enumerate(results):
        print(f"--- Article {i+1} ---")
        print(f"Title: {res['title']}")
        print(f"Link: {res['link']}")
        print(f"Image: {res['image_url']}")
        print(f"Source: {res['source']}")
        print()
