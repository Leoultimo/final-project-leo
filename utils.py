"""Earthquake data processing and visualization utilities."""
import io
from collections import defaultdict
from datetime import datetime, timedelta

import matplotlib.pyplot as plt
import requests

# Country configuration
COUNTRIES = {
    "Tel Aviv, Israel": {"lat": 32.0853, "lon": 34.7818, "radius": 100},
    "United States (California)": {"lat": 36.7783, "lon": -119.4179, "radius": 300},
    "Japan": {"lat": 36.2048, "lon": 138.2529, "radius": 300},
    "Indonesia": {"lat": -0.7893, "lon": 113.9213, "radius": 300},
    "Chile": {"lat": -35.6751, "lon": -71.5430, "radius": 300}
}

def generate_graph(days, lat, lon, radius, title_suffix=""):
    """Generate a bar chart of earthquake occurrences over time.

    Args:
        days: Number of days to query
        lat: Latitude of location
        lon: Longitude of location
        radius: Search radius in km
        title_suffix: Additional text for chart title

    Returns:
        BytesIO object containing the PNG image
    """
    start_time = (datetime.utcnow() - timedelta(days=days)).strftime('%Y-%m-%d')
    params = {
        'format': 'geojson',
        'latitude': lat,
        'longitude': lon,
        'maxradiuskm': radius,
        'starttime': start_time
    }
    usgs_url = "https://earthquake.usgs.gov/fdsnws/event/1/query"
    response = requests.get(usgs_url, params=params, timeout=10)

    plt.figure(figsize=(10, 5))
    if response.status_code != 200:
        plt.text(0.5, 0.5, "Error fetching data", horizontalalignment='center',
                 verticalalignment='center', fontsize=14)
        plt.axis('off')
    else:
        _plot_earthquake_data(response, days, title_suffix)

    img = io.BytesIO()
    plt.savefig(img, format='png')
    plt.close()
    img.seek(0)
    return img


def _plot_earthquake_data(response, days, title_suffix):
    """Helper function to plot earthquake data.

    Args:
        response: Requests response object
        days: Number of days being displayed
        title_suffix: Additional text for chart title
    """
    data = response.json()
    counts_by_day = defaultdict(int)
    for feature in data.get('features', []):
        timestamp = feature.get('properties', {}).get('time')
        if timestamp:
            event_date = datetime.utcfromtimestamp(timestamp / 1000).date()
            counts_by_day[event_date] += 1
    days_list = sorted(counts_by_day.keys())
    counts = [counts_by_day[day] for day in days_list]

    if days_list:
        plt.bar(days_list, counts)
        plt.xlabel('Date')
        plt.ylabel('Number of Earthquakes')
        plt.title(f'Earthquakes in Last {days} Days {title_suffix}')
        plt.xticks(rotation=45)
        plt.tight_layout()
    else:
        plt.text(0.5, 0.5, "No earthquake data available",
                 horizontalalignment='center', verticalalignment='center', fontsize=14)
        plt.axis('off')

def get_top_earthquakes(limit=5):
    """Get the top earthquakes by magnitude from the last 30 days.

    Args:
        limit: Maximum number of events to return

    Returns:
        List of earthquake features sorted by magnitude
    """
    start_time = (datetime.utcnow() - timedelta(days=30)).strftime('%Y-%m-%d')
    params = {
        'format': 'geojson',
        'starttime': start_time,
        'minmagnitude': 1
    }
    usgs_url = "https://earthquake.usgs.gov/fdsnws/event/1/query"
    response = requests.get(usgs_url, params=params, timeout=10)
    if response.status_code != 200:
        return []
    data = response.json()
    events = data.get('features', [])
    events = sorted(events, key=lambda f: f.get('properties', {}).get('mag', 0),
                    reverse=True)
    return events[:limit]

def get_last_earthquake():
    """Get the most recent earthquake from the last 30 days.

    Returns:
        Earthquake feature dict, or None if no earthquakes found
    """
    start_time = (datetime.utcnow() - timedelta(days=30)).strftime('%Y-%m-%d')
    params = {
        'format': 'geojson',
        'starttime': start_time,
        'minmagnitude': 1
    }
    usgs_url = "https://earthquake.usgs.gov/fdsnws/event/1/query"
    response = requests.get(usgs_url, params=params, timeout=10)
    if response.status_code != 200:
        return None
    data = response.json()
    events = data.get('features', [])
    events = sorted(events, key=lambda f: f.get('properties', {}).get('time', 0),
                    reverse=True)
    return events[0] if events else None

def timestamp_to_str(ts):
    """Convert Unix timestamp in milliseconds to formatted string.

    Args:
        ts: Unix timestamp in milliseconds

    Returns:
        Formatted datetime string
    """
    return datetime.utcfromtimestamp(ts / 1000).strftime('%Y-%m-%d %H:%M:%S')
