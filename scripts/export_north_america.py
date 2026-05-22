#!/usr/bin/env python3
"""
Patch script: fetches North America golf data in 6 sub-regions and upserts
into the existing golf_courses.db (all other regions remain untouched).

    python scripts/export_north_america.py
"""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from export_golf_courses import (
    OVERPASS_URL, HEADERS, OUTPUT_PATH,
    fetch_courses, fetch_hole_nodes, nearest_course,
    open_db, upsert_courses, upsert_hole
)
import time, sqlite3

# 6 sub-regions covering lat 18-72, lon -168 to -52
# 3 columns × 2 rows; INSERT OR IGNORE deduplicates any tiny overlaps
NA_REGIONS = [
    # Northern row (lat 45-72)
    (-168, 45, -120, 72, "Alaska & NW Canada"),
    (-120, 45,  -85, 72, "Central Canada"),
    ( -85, 45,  -52, 72, "Eastern Canada"),
    # Southern row (lat 18-47)
    (-130, 18, -100, 47, "Pacific US & Mexico West"),
    (-100, 18,  -75, 47, "Central US & Mexico"),
    ( -75, 18,  -52, 47, "Eastern US & Caribbean"),
]

def main():
    print(f"Patching: {os.path.abspath(OUTPUT_PATH)}\n")
    conn = open_db(OUTPUT_PATH)

    for lon_min, lat_min, lon_max, lat_max, label in NA_REGIONS:
        print(f"{'='*60}\n{label}  ({lat_min},{lon_min} → {lat_max},{lon_max})")
        bbox = (lat_min, lon_min, lat_max, lon_max)

        print("  Fetching courses …", end=" ", flush=True)
        time.sleep(3)
        courses = fetch_courses(bbox)
        print(f"{len(courses)} found")
        id_map = upsert_courses(conn, courses)

        print("  Fetching pin/tee nodes …", end=" ", flush=True)
        time.sleep(3)
        nodes = fetch_hole_nodes(bbox)
        pins = tees = 0

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
                pins += 1
            else:
                pref = ["regular", "white", "mens", "men"]
                is_preferred = any(p in node["tee_preference"].lower() for p in pref)
                existing = conn.execute(
                    "SELECT tee_lat FROM holes WHERE course_id=? AND number=?", (row_id, n)
                ).fetchone()
                if existing is None or existing[0] is None or is_preferred:
                    upsert_hole(conn, row_id, n, tee_lat=node["lat"], tee_lon=node["lon"])
                tees += 1

        conn.commit()
        print(f"  → {pins} pins, {tees} tees stored")
        time.sleep(5)

    conn.execute("ANALYZE")
    conn.execute("VACUUM")
    conn.close()

    size_mb = os.path.getsize(OUTPUT_PATH) / 1_048_576
    total = sqlite3.connect(OUTPUT_PATH).execute("SELECT COUNT(*) FROM courses").fetchone()[0]
    print(f"\nDone. {total} total courses in DB  |  {size_mb:.1f} MB")

if __name__ == "__main__":
    main()
