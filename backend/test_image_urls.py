"""Test various Cricbuzz image URL patterns to find which ones actually return images."""
import requests

IMAGE_ID = 860053  # Mumbai Indians team imageId from the API

URL_PATTERNS = [
    f"https://www.cricbuzz.com/a/img/v1/152x152/i1/c{IMAGE_ID}/i.jpg",
    f"https://static.cricbuzz.com/a/img/v1/152x152/i1/c{IMAGE_ID}/i.jpg",
    f"https://www.cricbuzz.com/a/img/v1/100x100/i1/c{IMAGE_ID}/i.jpg",
    f"https://www.cricbuzz.com/a/img/v1/i1/c{IMAGE_ID}/i.jpg",
    f"https://img1.hscicdn.com/image/upload/f_auto,t_ds_square_w_160/lsci/db/PICTURES/CMS/{IMAGE_ID}.jpg",
    # Try Cricbuzz without /i1/ prefix
    f"https://www.cricbuzz.com/a/img/v1/152x152/c{IMAGE_ID}/i.jpg",
    # Try with /i2/ prefix
    f"https://www.cricbuzz.com/a/img/v1/152x152/i2/c{IMAGE_ID}/i.jpg",
    # Try PNG
    f"https://www.cricbuzz.com/a/img/v1/152x152/i1/c{IMAGE_ID}/i.png",
    # Try the RapidAPI image endpoint
    f"https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/c{IMAGE_ID}/i.jpg",
]

headers_browser = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"}

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

for url in URL_PATTERNS:
    try:
        h = RAPIDAPI_HEADERS if "rapidapi" in url else headers_browser
        r = requests.get(url, headers=h, timeout=8, allow_redirects=True)
        content_type = r.headers.get("content-type", "unknown")
        is_image = "image" in content_type.lower() or len(r.content) > 1000
        print(f"[{'OK' if r.status_code == 200 and is_image else 'FAIL'}] {r.status_code} | {len(r.content):>8} bytes | {content_type[:40]} | {url}")
    except Exception as e:
        print(f"[ERR ] {str(e)[:60]} | {url}")
