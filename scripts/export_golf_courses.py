#!/usr/bin/env python3
"""
Export OSM golf course data to a bundled SQLite database for offline use.

Run once from the repo root to regenerate the DB:
    pip install requests
    python scripts/export_golf_courses.py

Output: GolfBuddy/golf_courses.db  (~8-15 MB uncompressed)

The script runs regional Overpass queries to avoid server-side timeout/size limits,
then a second pass fetches all golf=pin / golf=tee nodes and associates them with
the nearest course within ~2 km.
"""

import sqlite3
import requests
import json
import time
import math
import os
import sys

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
OUTPUT_PATH  = os.path.join(os.path.dirname(__file__), "..", "GolfBuddy", "golf_courses.db")

# Major golfing regions as (min_lon, min_lat, max_lon, max_lat, label)
REGIONS = [
    (-168,  18,  -52,  72, "North America"),
    (  -8,  49,    3,  61, "United Kingdom & Ireland"),
    ( -12,  35,   45,  72, "Europe"),
    (  25, -35,   52,  38, "Africa (south+east)"),
    ( -18,  10,   55,  38, "Middle East & North Africa"),
    (  60,   1,  145,  55, "Asia"),
    ( 110, -46,  180, -10, "Australia & New Zealand"),
    ( -82, -56,  -32,  15, "South America"),
    ( -92,  15,  -60,  33, "Central America & Caribbean"),
]

# ---------------------------------------------------------------------------
# Overpass helpers
# ---------------------------------------------------------------------------

def overpass_post(query: str, retries: int = 4) -> dict:
    for attempt in range(retries):
        try:
            r = requests.post(OVERPASS_URL, data={"data": query}, timeout=120)
            r.raise_for_status()
            return r.json()
        except Exception as exc:
            wait = 15 * (2 ** attempt)
            print(f"  Overpass error ({exc}), retrying in {wait}s …", flush=True)
            time.sleep(wait)
    return {"elements": []}


def fetch_courses(bbox) -> list[dict]:
    """Return list of course dicts from a bounding-box Overpass query."""
    s, w, n, e = bbox
    query = f"""
[out:json][timeout:90][maxsize:536870912];
(
  way["leisure"="golf_course"]["name"]({s},{w},{n},{e});
  relation["leisure"="golf_course"]["name"]({s},{w},{n},{e});
  node["leisure"="golf_course"]["name"]({s},{w},{n},{e});
);
out center tags;
"""
    data = overpass_post(query)
    courses = []
    for el in data.get("elements", []):
        tags = el.get("tags", {})
        name = tags.get("name", "").strip()
        if not name:
            continue
        # Determine centroid
        if el["type"] == "node":
            lat, lon = el["lat"], el["lon"]
        elif "center" in el:
            lat, lon = el["center"]["lat"], el["center"]["lon"]
        else:
            continue
        hole_count = int(tags.get("holes", 0) or 0) or 18
        city    = (tags.get("addr:city") or tags.get("addr:suburb") or "").strip()
        country = (tags.get("addr:country") or tags.get("country") or "").strip()
        courses.append({
            "osm_id":     el["id"],
            "name":       name,
            "lat":        lat,
            "lon":        lon,
            "city":       city,
            "country":    country,
            "hole_count": hole_count,
        })
    return courses


def fetch_hole_nodes(bbox) -> list[dict]:
    """Return pin and tee nodes for a bounding box."""
    s, w, n, e = bbox
    query = f"""
[out:json][timeout:90][maxsize:536870912];
(
  node["golf"="pin"]["ref"]({s},{w},{n},{e});
  node["golf"="tee"]["ref"]({s},{w},{n},{e});
);
out body;
"""
    data = overpass_post(query)
    nodes = []
    for el in data.get("elements", []):
        tags = el.get("tags", {})
        try:
            ref = int(tags.get("ref", ""))
        except ValueError:
            continue
        if not (1 <= ref <= 18):
            continue
        kind = tags.get("golf")  # "pin" or "tee"
        nodes.append({
            "kind":   kind,
            "number": ref,
            "lat":    el["lat"],
            "lon":    el["lon"],
            "tee_preference": tags.get("tee", tags.get("golf:use", "")),
        })
    return nodes

# ---------------------------------------------------------------------------
# Spatial helpers
# ---------------------------------------------------------------------------

def haversine_km(lat1, lon1, lat2, lon2) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


def nearest_course(node_lat, node_lon, courses: list, max_km=2.0):
    best, best_d = None, max_km
    for c in courses:
        d = haversine_km(node_lat, node_lon, c["lat"], c["lon"])
        if d < best_d:
            best, best_d = c, d
    return best

# ---------------------------------------------------------------------------
# Database setup
# ---------------------------------------------------------------------------

SCHEMA = """
CREATE TABLE IF NOT EXISTS courses (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    osm_id     INTEGER UNIQUE NOT NULL,
    name       TEXT NOT NULL,
    lat        REAL NOT NULL,
    lon        REAL NOT NULL,
    city       TEXT,
    country    TEXT,
    hole_count INTEGER NOT NULL DEFAULT 18
);

CREATE TABLE IF NOT EXISTS holes (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    number    INTEGER NOT NULL,
    tee_lat   REAL,
    tee_lon   REAL,
    pin_lat   REAL,
    pin_lon   REAL,
    UNIQUE(course_id, number)
);

CREATE INDEX IF NOT EXISTS courses_name   ON courses(name);
CREATE INDEX IF NOT EXISTS courses_latlon ON courses(lat, lon);
CREATE INDEX IF NOT EXISTS holes_course   ON holes(course_id);
"""


def open_db(path: str) -> sqlite3.Connection:
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    conn = sqlite3.connect(path)
    conn.executescript(SCHEMA)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    return conn


def upsert_courses(conn: sqlite3.Connection, courses: list) -> dict[int, int]:
    """Insert/ignore courses; returns {osm_id: row_id}."""
    id_map: dict[int, int] = {}
    for c in courses:
        conn.execute("""
            INSERT OR IGNORE INTO courses(osm_id, name, lat, lon, city, country, hole_count)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (c["osm_id"], c["name"], c["lat"], c["lon"], c["city"], c["country"], c["hole_count"]))
    conn.commit()
    for c in courses:
        row = conn.execute("SELECT id FROM courses WHERE osm_id = ?", (c["osm_id"],)).fetchone()
        if row:
            id_map[c["osm_id"]] = row[0]
    return id_map


def upsert_hole(conn: sqlite3.Connection, course_row_id: int, number: int,
                tee_lat=None, tee_lon=None, pin_lat=None, pin_lon=None):
    conn.execute("""
        INSERT INTO holes(course_id, number, tee_lat, tee_lon, pin_lat, pin_lon)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(course_id, number) DO UPDATE SET
            tee_lat = COALESCE(excluded.tee_lat, tee_lat),
            tee_lon = COALESCE(excluded.tee_lon, tee_lon),
            pin_lat = COALESCE(excluded.pin_lat, pin_lat),
            pin_lon = COALESCE(excluded.pin_lon, pin_lon)
    """, (course_row_id, number, tee_lat, tee_lon, pin_lat, pin_lon))

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print(f"Output: {os.path.abspath(OUTPUT_PATH)}")
    conn = open_db(OUTPUT_PATH)

    total_courses = 0
    total_pins    = 0
    total_tees    = 0

    for lon_min, lat_min, lon_max, lat_max, label in REGIONS:
        print(f"\n{'='*60}\n{label}  ({lat_min},{lon_min} → {lat_max},{lon_max})")
        bbox = (lat_min, lon_min, lat_max, lon_max)

        # -- courses --
        print("  Fetching courses …", end=" ", flush=True)
        time.sleep(3)  # be polite to Overpass
        courses = fetch_courses(bbox)
        print(f"{len(courses)} found")
        id_map = upsert_courses(conn, courses)
        total_courses += len(id_map)

        # -- hole nodes --
        print("  Fetching pin/tee nodes …", end=" ", flush=True)
        time.sleep(3)
        nodes = fetch_hole_nodes(bbox)
        pins_this = tees_this = 0

        for node in nodes:
            c = nearest_course(node["lat"], node["lon"], courses)
            if c is None:
                continue
            row_id = id_map.get(c["osm_id"])
            if row_id is None:
                continue
            n = node["number"]
            if node["kind"] == "pin":
                upsert_hole(conn, row_id, n, pin_lat=node["lat"], pin_lon=node["lon"])
                pins_this += 1
            else:  # tee — prefer regular/white/mens tee
                pref = ["regular", "white", "mens", "men"]
                is_preferred = any(p in node["tee_preference"].lower() for p in pref)
                existing = conn.execute(
                    "SELECT tee_lat FROM holes WHERE course_id=? AND number=?", (row_id, n)
                ).fetchone()
                if existing is None or existing[0] is None or is_preferred:
                    upsert_hole(conn, row_id, n, tee_lat=node["lat"], tee_lon=node["lon"])
                tees_this += 1

        conn.commit()
        total_pins += pins_this
        total_tees += tees_this
        print(f"  → {pins_this} pins, {tees_this} tees stored")
        time.sleep(5)  # rate-limit between regions

    conn.execute("ANALYZE")
    conn.execute("VACUUM")
    conn.close()

    size_mb = os.path.getsize(OUTPUT_PATH) / 1_048_576
    print(f"\nDone. {total_courses} courses · {total_pins} pins · {total_tees} tees")
    print(f"File size: {size_mb:.1f} MB  →  {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
