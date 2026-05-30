import json
import os
import re
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
import hashlib
from datetime import datetime
from email.utils import parsedate_to_datetime
from typing import List, Dict, Optional
from pydantic import BaseModel
from fastapi import APIRouter, HTTPException

router = APIRouter(
    prefix="/api/community",
    tags=["Community Hub"]
)

POSTS_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), "community_posts.json")

# Pydantic schemas
class CommentSchema(BaseModel):
    id: str
    name: str
    handle: str
    content: str
    time: str

class PostSchema(BaseModel):
    id: str
    name: str
    handle: str
    time: str
    content: str
    likes: int
    liked_by: List[str] = [] # User handles who liked this post
    comments: List[CommentSchema] = []

class CreatePostRequest(BaseModel):
    name: str
    handle: str
    content: str

class CreateCommentRequest(BaseModel):
    name: str
    handle: str
    content: str

# Default pre-populated posts
DEFAULT_POSTS = [
    {
        "id": "1",
        "name": "Sarah Jenkins",
        "handle": "@sjenkins_sports",
        "time": "2h ago",
        "content": "What an incredible IPL match! The comeback by CSK in the death overs was absolutely legendary. Dhoni's finishing style is timeless! ⚽🔥 #IPL2026 #CSK",
        "likes": 124,
        "liked_by": ["@user1", "@user2"],
        "comments": [
            {
                "id": "c1",
                "name": "Rohan Sharma",
                "handle": "@rohan_cricket",
                "content": "Absolutely true! The Dhoni aura is unmatched.",
                "time": "1h ago"
            },
            {
                "id": "c2",
                "name": "Amit Patel",
                "handle": "@amit_p",
                "content": "MI bowled poorly in the last 2 overs.",
                "time": "45m ago"
            }
        ]
    },
    {
        "id": "2",
        "name": "David Miller",
        "handle": "@killer_miller",
        "time": "4h ago",
        "content": "Can we talk about Haaland's positioning? The guy is literally a magnet for the ball in the box. 35 goals in a single season is just ridiculous! ⚽👑 #ManCity #Haaland",
        "likes": 98,
        "liked_by": ["@user3"],
        "comments": [
            {
                "id": "c3",
                "name": "John Doe",
                "handle": "@johndoe_football",
                "content": "Best striker in the world right now, no debate.",
                "time": "3h ago"
            }
        ]
    },
    {
        "id": "3",
        "name": "Pawan Kumar",
        "handle": "@pawan_kabaddi",
        "time": "6h ago",
        "content": "That last raid in the Kabaddi finals was mindblowing. Speed, agility, and pure power. That is how champions play! ⚡🦁 #Kabaddi #ProKabaddi",
        "likes": 76,
        "liked_by": [],
        "comments": []
    }
]

# Default pre-populated news
DEFAULT_NEWS = [
    {
        "id": "n1",
        "title": "Real Madrid Clinch 15th Champions League Title",
        "summary": "An late double from Vinicius Jr. sealed the victory for Real Madrid as they defeated Borussia Dortmund at Wembley, cementing their dominance in European football.",
        "time": "2 hours ago",
        "category": "Football",
        "imageUrl": "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=600&auto=format&fit=crop"
    },
    {
        "id": "n2",
        "title": "Virat Kohli Becomes First Player to Reach 8000 Runs in IPL History",
        "summary": "The batting maestro reached another historic milestone during his brilliant knock against Rajasthan Royals, receiving a standing ovation from the crowd.",
        "time": "4 hours ago",
        "category": "Cricket",
        "imageUrl": "https://images.unsplash.com/photo-1531415080290-bc98545ab3ef?w=600&auto=format&fit=crop"
    },
    {
        "id": "n3",
        "title": "Pro Kabaddi League Season 11 Auction Breaks Records",
        "summary": "Top raiders fetch record-breaking bids in the day 1 auction, setting up an extremely competitive upcoming season.",
        "time": "1 day ago",
        "category": "Kabaddi",
        "imageUrl": "https://images.unsplash.com/photo-1517649763962-0c623066013b?w=600&auto=format&fit=crop"
    },
    {
        "id": "n4",
        "title": "Formula 1: Monaco GP Sees Chaotic Wet Race and Surprising Podium",
        "summary": "Sudden downpour in Monaco turned the grid upside down, resulting in tactical masterclasses and a surprising podium finish for the underdogs.",
        "time": "2 days ago",
        "category": "Motorsport",
        "imageUrl": "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=600&auto=format&fit=crop"
    }
]

def load_posts() -> List[dict]:
    if os.path.exists(POSTS_FILE):
        try:
            with open(POSTS_FILE, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading posts: {e}")
    return DEFAULT_POSTS

def save_posts(posts: List[dict]):
    try:
        with open(POSTS_FILE, "w") as f:
            json.dump(posts, f, indent=2)
    except Exception as e:
        print(f"Error saving posts: {e}")

@router.get("/posts", response_model=List[PostSchema])
def get_posts():
    return load_posts()

@router.post("/posts", response_model=PostSchema)
def create_post(req: CreatePostRequest):
    posts = load_posts()
    new_post = {
        "id": str(len(posts) + 1),
        "name": req.name,
        "handle": req.handle,
        "time": "Just now",
        "content": req.content,
        "likes": 0,
        "liked_by": [],
        "comments": []
    }
    posts.insert(0, new_post) # Add to the top of feed
    save_posts(posts)
    return new_post

@router.post("/posts/{post_id}/like", response_model=PostSchema)
def toggle_like(post_id: str, handle: str = "@alex_champ"):
    posts = load_posts()
    for post in posts:
        if post["id"] == post_id:
            if "liked_by" not in post:
                post["liked_by"] = []
            
            if handle in post["liked_by"]:
                post["liked_by"].remove(handle)
                post["likes"] = max(0, post["likes"] - 1)
            else:
                post["liked_by"].append(handle)
                post["likes"] += 1
            
            save_posts(posts)
            return post
            
    raise HTTPException(status_code=404, detail="Post not found")

@router.post("/posts/{post_id}/comment", response_model=PostSchema)
def add_comment(post_id: str, req: CreateCommentRequest):
    posts = load_posts()
    for post in posts:
        if post["id"] == post_id:
            comments = post.get("comments", [])
            new_comment = {
                "id": f"c{len(comments) + 1}_{datetime.now().timestamp()}",
                "name": req.name,
                "handle": req.handle,
                "content": req.content,
                "time": "Just now"
            }
            comments.append(new_comment)
            post["comments"] = comments
            save_posts(posts)
            return post
            
    raise HTTPException(status_code=404, detail="Post not found")

def clean_html(raw_html: str) -> str:
    if not raw_html:
        return ""
    cleanr = re.compile('<.*?>')
    cleantext = re.sub(cleanr, '', raw_html)
    cleantext = re.sub(r'\s+', ' ', cleantext).strip()
    return cleantext

def format_relative_time(pub_date_str: str) -> str:
    try:
        dt = parsedate_to_datetime(pub_date_str)
        now = datetime.now(dt.tzinfo)
        diff = now - dt
        if diff.days > 0:
            if diff.days == 1:
                return "1 day ago"
            return f"{diff.days} days ago"
        seconds = diff.seconds
        hours = seconds // 3600
        if hours > 0:
            if hours == 1:
                return "1 hour ago"
            return f"{hours} hours ago"
        minutes = seconds // 60
        if minutes > 0:
            if minutes == 1:
                return "1 minute ago"
            return f"{minutes} minutes ago"
        return "Just now"
    except Exception:
        return "Recent"

def get_unsplash_image(title: str, category: str) -> str:
    text = (title + " " + category).lower()
    if "cricket" in text or "ipl" in text or "kohli" in text or "dhoni" in text or "rohit" in text:
        return "https://images.unsplash.com/photo-1531415080290-bc98545ab3ef?w=600&auto=format&fit=crop"
    if "football" in text or "messi" in text or "ronaldo" in text or "haaland" in text or "laliga" in text or "real" in text or "barcelona" in text or "champions league" in text:
        return "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=600&auto=format&fit=crop"
    if "kabaddi" in text or "pawan" in text or "pro kabaddi" in text:
        return "https://images.unsplash.com/photo-1517649763962-0c623066013b?w=600&auto=format&fit=crop"
    if "formula" in text or "f1" in text or "motorsport" in text or "hamilton" in text or "verstappen" in text:
        return "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=600&auto=format&fit=crop"
    return "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=600&auto=format&fit=crop"

def get_category_from_text(title: str, summary: str, default_sports: List[str]) -> str:
    text = (title + " " + summary).lower()
    if "cricket" in text or "ipl" in text or "kohli" in text or "dhoni" in text:
        return "Cricket"
    if "football" in text or "messi" in text or "ronaldo" in text or "champions league" in text:
        return "Football"
    if "kabaddi" in text:
        return "Kabaddi"
    if "formula" in text or "f1" in text or "motorsport" in text:
        return "Motorsport"
    if default_sports:
        return default_sports[0].capitalize()
    return "Sports"

def fetch_personalized_news(sports_str: Optional[str], players_str: Optional[str]) -> List[dict]:
    terms = []
    default_sports = []
    
    if sports_str:
        s_list = [s.strip() for s in sports_str.split(",") if s.strip()]
        for s in s_list:
            default_sports.append(s)
            terms.append(s)
            
    if players_str:
        p_list = [p.strip() for p in players_str.split(",") if p.strip()]
        for p in p_list:
            if " " in p:
                terms.append(f'"{p}"')
            else:
                terms.append(p)
                
    if not terms:
        return DEFAULT_NEWS
        
    query = f"({ ' OR '.join(terms) }) sports"
    encoded_query = urllib.parse.quote(query)
    url = f"https://news.google.com/rss/search?q={encoded_query}&hl=en-IN&gl=IN&ceid=IN:en"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=6) as response:
            xml_data = response.read()
            
        root = ET.fromstring(xml_data)
        articles = []
        
        for item in root.findall('.//item')[:12]:
            title = item.find('title').text if item.find('title') is not None else ''
            link = item.find('link').text if item.find('link') is not None else ''
            pub_date = item.find('pubDate').text if item.find('pubDate') is not None else ''
            description = item.find('description').text if item.find('description') is not None else ''
            
            clean_title = title
            if " - " in title:
                parts = title.rsplit(" - ", 1)
                clean_title = parts[0]
                
            clean_desc = clean_html(description)
            if "Google News" in clean_desc:
                clean_desc = clean_desc.split("Google News")[0].strip()
                
            if not clean_desc or len(clean_desc) < 10:
                clean_desc = f"Latest updates and match coverage regarding {clean_title}."
                
            if len(clean_desc) > 180:
                clean_desc = clean_desc[:177] + "..."
                
            news_id = "n_rss_" + hashlib.md5(link.encode('utf-8')).hexdigest()[:8]
            category = get_category_from_text(clean_title, clean_desc, default_sports)
            image_url = get_unsplash_image(clean_title, category)
            
            articles.append({
                "id": news_id,
                "title": clean_title,
                "summary": clean_desc,
                "time": format_relative_time(pub_date),
                "category": category,
                "imageUrl": image_url,
                "link": link
            })
            
        if not articles:
            return DEFAULT_NEWS
            
        if len(articles) < 4:
            articles.extend(DEFAULT_NEWS[:4 - len(articles)])
            
        return articles
    except Exception as e:
        print(f"Error fetching personalized news: {e}")
        return DEFAULT_NEWS

@router.get("/news")
def get_news(sports: Optional[str] = None, players: Optional[str] = None):
    return fetch_personalized_news(sports, players)
