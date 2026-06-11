import urllib.request
import xml.etree.ElementTree as ET
import urllib.parse
import re
import concurrent.futures
import time

def get_og_image_and_real_url(google_news_url):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        # Google News RSS articles are redirect links.
        # We fetch the headers first or just open it to get the final redirected URL.
        req = urllib.request.Request(google_news_url, headers=headers)
        with urllib.request.urlopen(req, timeout=4) as response:
            real_url = response.geturl()
            html = response.read().decode('utf-8', errors='ignore')
            
        # Parse og:image using regex to avoid external dependency like BeautifulSoup
        og_image_match = re.search(r'<meta\s+[^>]*property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']', html)
        if not og_image_match:
            og_image_match = re.search(r'<meta\s+[^>]*content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']', html)
            
        og_image = og_image_match.group(1) if og_image_match else None
        
        # If no og:image, try twitter:image
        if not og_image:
            twitter_image_match = re.search(r'<meta\s+[^>]*name=["\']twitter:image["\'][^>]*content=["\']([^"\']+)["\']', html)
            og_image = twitter_image_match.group(1) if twitter_image_match else None
            
        return real_url, og_image
    except Exception as e:
        print(f"Error resolving {google_news_url}: {e}")
        return google_news_url, None

if __name__ == "__main__":
    url = "https://news.google.com/rss/search?q=cricket&hl=en-IN&gl=IN&ceid=IN:en"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=8) as response:
        xml_data = response.read()

    root = ET.fromstring(xml_data)
    items = root.findall('.//item')[:5]
    
    start_time = time.time()
    
    # We resolve them concurrently using ThreadPoolExecutor
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(get_og_image_and_real_url, item.find('link').text): item for item in items}
        for future in concurrent.futures.as_completed(futures):
            item = futures[future]
            title = item.find('title').text
            real_url, og_image = future.result()
            print(f"Title: {title}")
            print(f"Real URL: {real_url}")
            print(f"OG Image: {og_image}")
            print("-" * 50)
            
    print(f"Time taken for 5 items: {time.time() - start_time:.2f} seconds")
