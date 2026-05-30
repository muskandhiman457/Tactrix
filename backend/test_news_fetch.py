import urllib.request
import xml.etree.ElementTree as ET
import urllib.parse
from datetime import datetime

def fetch_google_news(query: str):
    encoded_query = urllib.parse.quote(query)
    url = f"https://news.google.com/rss/search?q={encoded_query}&hl=en-IN&gl=IN&ceid=IN:en"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            xml_data = response.read()
            
        root = ET.fromstring(xml_data)
        articles = []
        for item in root.findall('.//item')[:5]: # Get top 5 articles
            title = item.find('title').text if item.find('title') is not None else ''
            link = item.find('link').text if item.find('link') is not None else ''
            pub_date = item.find('pubDate').text if item.find('pubDate') is not None else ''
            description = item.find('description').text if item.find('description') is not None else ''
            
            # Clean title (Google News appends sources like " - ESPN")
            clean_title = title
            source = "Google News"
            if " - " in title:
                parts = title.rsplit(" - ", 1)
                clean_title = parts[0]
                source = parts[1]
                
            articles.append({
                "title": clean_title,
                "link": link,
                "pub_date": pub_date,
                "description": description,
                "source": source
            })
            
        return articles
    except Exception as e:
        print("Error fetching news:", e)
        return []

if __name__ == "__main__":
    print("Fetching cricket news...")
    results = fetch_google_news("cricket Virat Kohli")
    for r in results:
        print(f"Title: {r['title']}")
        print(f"Source: {r['source']}")
        print(f"Date: {r['pub_date']}")
        print("-" * 40)
