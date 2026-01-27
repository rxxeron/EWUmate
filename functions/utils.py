from datetime import datetime

def parse_time_to_minutes(time_str):
    """
    Parse time string like '08:30 AM' or '14:00' to minutes from midnight.
    Returns None if parsing fails.
    """
    if not time_str:
        return None
    try:
        time_str = time_str.strip().upper()
        if "AM" in time_str or "PM" in time_str:
            dt = datetime.strptime(time_str, "%I:%M %p")
        else:
            # Handle 24-hour format if necessary
            dt = datetime.strptime(time_str, "%H:%M")
        return dt.hour * 60 + dt.minute
    except ValueError:
        return None

def times_conflict(start1, end1, start2, end2):
    """
    Check if two time ranges (in minutes) overlap.
    Ranges are [start, end).
    """
    if start1 is None or end1 is None or start2 is None or end2 is None:
        return False
    return max(start1, start2) < min(end1, end2)

def is_day_conflict(days1, days2):
    """
    Check if two day strings overlap (e.g., "MW" and "M T").
    """
    # Normalize days: 'Sat'->'S', 'Sun'->'U', etc if needed, or just standard charset
    # Assuming days are stored as "M W", "S T", etc. or compacted "MW"
    # Simple set intersection
    set1 = set(days1.replace(" ", "").upper())
    set2 = set(days2.replace(" ", "").upper())
    return not set1.isdisjoint(set2)
