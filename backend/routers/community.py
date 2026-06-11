import json
import os
import re
import time
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
import hashlib
import concurrent.futures
from datetime import datetime
from email.utils import parsedate_to_datetime
from typing import List, Dict, Optional
from pydantic import BaseModel
from fastapi import APIRouter, HTTPException
from googlenewsdecoder import new_decoderv1


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

class PollSchema(BaseModel):
    question: str
    options: List[str]
    votes: List[int]
    userVotedIndex: Optional[int] = -1

class LineupSchema(BaseModel):
    teamName: str
    sport: str
    formation: str
    captain: str
    viceCaptain: str
    players: List[str]

class PostSchema(BaseModel):
    id: str
    name: str
    handle: str
    time: str
    content: str
    likes: int
    liked_by: List[str] = [] # User handles who liked this post
    comments: List[CommentSchema] = []
    poll: Optional[PollSchema] = None
    lineup: Optional[LineupSchema] = None
    badges: Optional[List[dict]] = []

class CreatePostRequest(BaseModel):
    name: str
    handle: str
    content: str
    poll: Optional[PollSchema] = None
    lineup: Optional[LineupSchema] = None
    badges: Optional[List[dict]] = []

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
        ],
        "badges": [
            {
                "id": "top_predictor",
                "badge_name": "Top Predictor",
                "badge_icon_url": "https://img.icons8.com/color/48/star--v1.png",
                "badge_type": "performance",
                "assigned_at": "2026-06-01T12:00:00Z",
                "description": "Top Predictor - Assigned for 75%+ accurate match predictions"
            }
        ]
    },
    {
        "id": "poll_post",
        "name": "Predictor Bot",
        "handle": "@predictor_bot",
        "time": "1h ago",
        "content": "Who will score more fantasy points tonight in RCB vs GT? Vote now! 📊 #RCBvGT",
        "likes": 42,
        "liked_by": [],
        "comments": [],
        "poll": {
            "question": "Who will score more fantasy points tonight?",
            "options": ["Virat Kohli", "Shubman Gill", "Rashid Khan"],
            "votes": [145, 98, 54],
            "userVotedIndex": -1
        },
        "badges": [
            {
                "id": "top_predictor",
                "badge_name": "Top Predictor",
                "badge_icon_url": "https://img.icons8.com/color/48/star--v1.png",
                "badge_type": "performance",
                "assigned_at": "2026-06-01T12:00:00Z",
                "description": "Top Predictor - Assigned for 75%+ accurate match predictions"
            }
        ]
    },
    {
        "id": "lineup_post",
        "name": "Pro Analyst",
        "handle": "@pro_analyst",
        "time": "3h ago",
        "content": "Here is my ultimate combination for the upcoming IPL match. The bowling lineup looks lethal. Let me know your thoughts! 🏏🔥 #DreamTeam #IPL2026",
        "likes": 56,
        "liked_by": [],
        "comments": [],
        "lineup": {
            "teamName": "Lethal Bowling XI",
            "sport": "Cricket",
            "formation": "Balanced (1-4-2-4)",
            "captain": "Virat Kohli",
            "viceCaptain": "Jasprit Bumrah",
            "players": ["MS Dhoni (WK)", "Virat Kohli", "Rohit Sharma", "Suryakumar Yadav", "Shivam Dube", "Hardik Pandya", "Ravindra Jadeja", "Jasprit Bumrah", "Mohammed Siraj", "Yash Dayal", "Yuzvendra Chahal"]
        },
        "badges": [
            {
                "id": "super_chatter",
                "badge_name": "Super Chatter",
                "badge_icon_url": "https://img.icons8.com/color/48/chat--v1.png",
                "badge_type": "engagement",
                "assigned_at": "2026-06-01T12:00:00Z",
                "description": "Super Chatter - Assigned for reaching high chat activity score"
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
        ],
        "badges": []
    },
    {
        "id": "3",
        "name": "Pawan Kumar",
        "handle": "@pawan_kabaddi",
        "time": "6h ago",
        "content": "That last raid in the Kabaddi finals was mindblowing. Speed, agility, and pure power. That is how champions play! ⚡🦁 #Kabaddi #ProKabaddi",
        "likes": 76,
        "liked_by": [],
        "comments": [],
        "badges": []
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
    if db is not None:
        try:
            docs = db.collection("posts").order_by("order").stream()
            posts = []
            for doc in docs:
                post_data = doc.to_dict()
                if "order" in post_data:
                    del post_data["order"]
                posts.append(post_data)
            if posts:
                return posts
            else:
                print("Firestore posts collection is empty. Seeding defaults...")
                save_posts(DEFAULT_POSTS)
                return DEFAULT_POSTS
        except Exception as e:
            print(f"Error loading posts from Firestore: {e}")

    # Fallback to local file
    if os.path.exists(POSTS_FILE):
        try:
            with open(POSTS_FILE, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading posts locally: {e}")
    return DEFAULT_POSTS

def save_posts(posts: List[dict]):
    # Keep local backup
    try:
        with open(POSTS_FILE, "w") as f:
            json.dump(posts, f, indent=2)
    except Exception as e:
        print(f"Error saving posts locally: {e}")

    # Sync to Firestore
    if db is not None:
        try:
            # We write each post as a document to preserve scalability
            for index, post in enumerate(posts):
                post_copy = post.copy()
                post_copy["order"] = index
                db.collection("posts").document(post["id"]).set(post_copy)
        except Exception as e:
            print(f"Error syncing posts to Firestore: {e}")

@router.get("/posts", response_model=List[PostSchema])
def get_posts():
    return load_posts()

@router.post("/posts", response_model=PostSchema)
def create_post(req: CreatePostRequest):
    posts = load_posts()
    new_post = {
        "id": f"p_{len(posts) + 1}_{int(datetime.now().timestamp())}",
        "name": req.name,
        "handle": req.handle,
        "time": "Just now",
        "content": req.content,
        "likes": 0,
        "liked_by": [],
        "comments": [],
        "poll": req.poll.dict() if req.poll else None,
        "lineup": req.lineup.dict() if req.lineup else None,
        "badges": req.badges if req.badges else []
    }
    posts.insert(0, new_post) # Add to the top of feed
    save_posts(posts)
    return new_post

@router.post("/posts/{post_id}/vote", response_model=PostSchema)
def vote_poll(post_id: str, index: int, handle: str = "@sports_fan"):
    posts = load_posts()
    for post in posts:
        if post["id"] == post_id:
            if "poll" in post and post["poll"]:
                votes = post["poll"]["votes"]
                if index >= 0 and index < len(votes):
                    # We can directly increment the vote
                    votes[index] += 1
                    post["poll"]["userVotedIndex"] = index
                    save_posts(posts)
                    return post
    raise HTTPException(status_code=404, detail="Post or poll not found")

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

# In-memory news cache: { cache_key: (timestamp, articles) }
NEWS_CACHE: Dict[str, tuple] = {}
CACHE_DURATION_SECONDS = 600
NEWS_EXECUTOR = concurrent.futures.ThreadPoolExecutor(max_workers=20)


def scrape_og_image(url: str) -> Optional[str]:
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

def process_feed_item(item, default_sports: List[str]) -> dict:
    title = item.find('title').text if item.find('title') is not None else ''
    google_url = item.find('link').text if item.find('link') is not None else ''
    pub_date = item.find('pubDate').text if item.find('pubDate') is not None else ''
    description = item.find('description').text if item.find('description') is not None else ''
    
    clean_title = title
    source = "Google News"
    if " - " in title:
        parts = title.rsplit(" - ", 1)
        clean_title = parts[0]
        source = parts[1]
        
    clean_desc = clean_html(description)
    if "Google News" in clean_desc:
        clean_desc = clean_desc.split("Google News")[0].strip()
        
    if not clean_desc or len(clean_desc) < 10:
        clean_desc = f"Latest updates and match coverage regarding {clean_title}."
        
    if len(clean_desc) > 180:
        clean_desc = clean_desc[:177] + "..."
        
    news_id = "n_rss_" + hashlib.md5(google_url.encode('utf-8')).hexdigest()[:8]
    category = get_category_from_text(clean_title, clean_desc, default_sports)
    
    real_url = google_url
    image_url = None
    
    # Try decoding the Google News link to target URL
    try:
        decoded = new_decoderv1(google_url, interval=0)
        if decoded.get("status"):
            real_url = decoded.get("decoded_url")
            # Scrape original image from resolved URL
            image_url = scrape_og_image(real_url)
    except Exception as e:
        print(f"Error decoding Google News URL: {e}")
        
    # Fallback to category placeholder if image scraping failed
    if not image_url:
        image_url = get_unsplash_image(clean_title, category)
        
    return {
        "id": news_id,
        "title": clean_title,
        "summary": clean_desc,
        "time": format_relative_time(pub_date),
        "category": category,
        "imageUrl": image_url,
        "link": real_url
    }

def process_feed_item_fallback(item, default_sports: List[str]) -> dict:
    title = item.find('title').text if item.find('title') is not None else ''
    google_url = item.find('link').text if item.find('link') is not None else ''
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
        
    news_id = "n_rss_" + hashlib.md5(google_url.encode('utf-8')).hexdigest()[:8]
    category = get_category_from_text(clean_title, clean_desc, default_sports)
    image_url = get_unsplash_image(clean_title, category)
    
    return {
        "id": news_id,
        "title": clean_title,
        "summary": clean_desc,
        "time": format_relative_time(pub_date),
        "category": category,
        "imageUrl": image_url,
        "link": google_url
    }

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
        # Default query terms if no favorites exist
        terms = ["sports"]
        
    query = f"({ ' OR '.join(terms) }) sports"
    
    # Check cache first
    now = time.time()
    cache_key = f"{sports_str}_{players_str}"
    if cache_key in NEWS_CACHE:
        timestamp, cached_articles = NEWS_CACHE[cache_key]
        if now - timestamp < CACHE_DURATION_SECONDS:
            print(f"Returning cached news for: {cache_key}")
            return cached_articles
            
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
        items = root.findall('.//item')[:6] # Top 6 items
        
        articles = []
        if items:
            # Concurrently submit feed item processing to global executor
            futures = {NEWS_EXECUTOR.submit(process_feed_item, item, default_sports): item for item in items}
            # Wait for up to 3.5 seconds
            done, not_done = concurrent.futures.wait(futures.keys(), timeout=3.5)
            
            # Retrieve completed items in order
            item_to_future = {item: f for f, item in futures.items()}
            
            for item in items:
                f = item_to_future[item]
                if f in done:
                    try:
                        art = f.result()
                        if art:
                            articles.append(art)
                    except Exception as e:
                        print(f"Error processing news item: {e}")
                        articles.append(process_feed_item_fallback(item, default_sports))
                else:
                    # Timed out, use fallback
                    f.cancel()
                    articles.append(process_feed_item_fallback(item, default_sports))

                        
        # Filter out empty or failed articles
        articles = [a for a in articles if a]
        
        if not articles:
            return DEFAULT_NEWS
            
        # Cache the fetched articles
        NEWS_CACHE[cache_key] = (now, articles)
        return articles
    except Exception as e:
        print(f"Error fetching personalized news: {e}")
        if cache_key in NEWS_CACHE:
            return NEWS_CACHE[cache_key][1]
        return DEFAULT_NEWS



@router.get("/news")
def get_news(sports: Optional[str] = None, players: Optional[str] = None):
    return fetch_personalized_news(sports, players)

# Dynamic User Badge Assignment System
db = None
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    if not firebase_admin._apps:
        # Auto-detect Firebase JSON file in current or parent directory
        cred_path = None
        for d in [".", ".."]:
            exact_p = os.path.join(d, "firebase_credentials.json")
            if os.path.exists(exact_p):
                cred_path = exact_p
                break
            try:
                for f in os.listdir(d):
                    if f.endswith(".json") and ("adminsdk" in f.lower() or "firebase" in f.lower() or f.startswith("sports-hub-")):
                        cred_path = os.path.join(d, f)
                        break
            except Exception:
                pass
            if cred_path:
                break
                
        if cred_path:
            print(f"Initializing Firebase with certificate: {cred_path}")
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            print("Initializing Firebase with default credentials")
            firebase_admin.initialize_app()
    db = firestore.client()
except Exception as e:
    print(f"Firestore Admin SDK not fully initialized: {e}")

class UserBadgeMetricsRequest(BaseModel):
    uid: str
    prediction_accuracy_rate: float
    chat_activity_score: int

@router.post("/badges/calculate")
def calculate_user_badges(req: UserBadgeMetricsRequest):
    badges = []
    now_str = datetime.now().isoformat()
    
    # 1. Prediction Accuracy badge
    rate = req.prediction_accuracy_rate
    is_top_predictor = False
    if rate > 1.0:
        is_top_predictor = rate > 75.0
        pct = rate
    else:
        is_top_predictor = rate > 0.75
        pct = rate * 100

    if is_top_predictor:
        badges.append({
            "id": "top_predictor",
            "badge_name": "Top Predictor",
            "badge_icon_url": "https://img.icons8.com/color/48/star--v1.png",
            "badge_type": "performance",
            "assigned_at": now_str,
            "description": f"Top Predictor - Assigned for {pct:.0f}% accurate match predictions"
        })
        
    # 2. Chat Activity badge
    if req.chat_activity_score > 50:
        badges.append({
            "id": "super_chatter",
            "badge_name": "Super Chatter",
            "badge_icon_url": "https://img.icons8.com/color/48/chat--v1.png",
            "badge_type": "engagement",
            "assigned_at": now_str,
            "description": f"Super Chatter - Assigned for reaching high chat activity score ({req.chat_activity_score})"
        })
        
    firestore_updated = False
    if db is not None:
        try:
            user_ref = db.collection("users").document(req.uid)
            user_ref.update({
                "prediction_accuracy_rate": req.prediction_accuracy_rate,
                "chat_activity_score": req.chat_activity_score,
                "badges": badges
            })
            firestore_updated = True
        except Exception as e:
            print(f"Error updating Firestore user document: {e}")
            
    return {
        "status": "success",
        "uid": req.uid,
        "prediction_accuracy_rate": req.prediction_accuracy_rate,
        "chat_activity_score": req.chat_activity_score,
        "badges": badges,
        "firestore_updated": firestore_updated
    }
