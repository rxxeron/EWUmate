
from datetime import datetime

def _parse_days(day_str: str, day_map: dict) -> list:
    """Parse day string like 'MW', 'T R', 'Sunday' into list of day names."""
    days = []
    
    # Try full day name first
    for abbr, full in day_map.items():
        if full.upper() == day_str:
            return [full]
    
    # Split by space if multiple
    tokens = day_str.split()
    if len(tokens) > 1:
        for token in tokens:
            token = token.strip().upper()
            if token in day_map:
                days.append(day_map[token])
    else:
        # Try each character (for "MW", "TR")
        for char in day_str:
            if char in day_map:
                days.append(day_map[char])
    
    return list(set(days))  # Remove duplicates

def test_logic():
    day_map = {
        "S": "Sunday", "SU": "Sunday", "SUN": "Sunday",
        "M": "Monday", "MO": "Monday", "MON": "Monday",
        "T": "Tuesday", "TU": "Tuesday", "TUE": "Tuesday",
        "W": "Wednesday", "WE": "Wednesday", "WED": "Wednesday",
        "R": "Thursday", "TH": "Thursday", "THU": "Thursday",
        "F": "Friday", "FR": "Friday", "FRI": "Friday",
        "A": "Saturday", "SA": "Saturday", "SAT": "Saturday"
    }

    test_cases = [
        "S",   # The problem case
        "R",
        "T",
        "MW",
        "ST",
        "Sunday"
    ]

    print("Testing _parse_days:")
    for t in test_cases:
        res = _parse_days(t, day_map)
        print(f"Input: '{t}' -> Output: {res}")

if __name__ == "__main__":
    test_logic()
