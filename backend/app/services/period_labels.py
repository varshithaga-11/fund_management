"""
India financial year (Apr–Mar) period label parsing.
Supports: Apr_2024, Q1_FY_2024_25, H1_FY_2024_25, FY_2024_25
"""
import re
from datetime import datetime
from calendar import monthrange


# Abbreviated month names (India FY: Apr=1, Mar=12 of next year)
MONTH_ABBREV = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
}


def parse_period_label(label: str) -> dict:
    """
    Parse period label from filename (without extension).
    Returns dict with: label, start_date, end_date, period_type
    or empty dict if not matched.

    Supported formats (India FY Apr–Mar):
    - MONTHLY: Apr_2024, May_2024, ..., Mar_2025
    - QUARTERLY: Q1_FY_2024_25, Q2_FY_2024_25, Q3_FY_2024_25, Q4_FY_2024_25
    - HALF_YEARLY: H1_FY_2024_25, H2_FY_2024_25
    - YEARLY: FY_2024_25
    """
    if not label or not isinstance(label, str):
        return {}
    s = label.strip()
    if not s:
        return {}

    # MONTHLY: Apr_2024, May_2024, Jun_2024, Jul_2024, Aug_2024, Sep_2024,
    #          Oct_2024, Nov_2024, Dec_2024, Jan_2025, Feb_2025, Mar_2025
    m = re.search(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[_\-\s]*(\d{4})(?:\D|$)', s, re.I)
    if m:
        month_abbr = m.group(1).lower()[:3]
        year = int(m.group(2))
        if month_abbr not in MONTH_ABBREV:
            return {}
        month_num = MONTH_ABBREV[month_abbr]
        start = datetime(year, month_num, 1)
        _, last_day = monthrange(year, month_num)
        end = datetime(year, month_num, last_day)
        canonical_label = f"{m.group(1).capitalize()}_{year}"
        return {
            'label': canonical_label,
            'start_date': start.strftime('%Y-%m-%d'),
            'end_date': end.strftime('%Y-%m-%d'),
            'period_type': 'MONTHLY',
        }

    # QUARTERLY: Q1_FY_2024_25, Q2_FY_2024_25, Q3_FY_2024_25, Q4_FY_2024_25
    m = re.search(r'Q([1-4])[_\-\s]*FY[_\-\s]*(\d{4})[_\-\s]*(\d{2})\b', s, re.I)
    if m:
        q = int(m.group(1))
        start_year = int(m.group(2))
        end_year = int(m.group(3))  # last 2 digits, e.g. 25 -> 2025
        if end_year < 100:
            end_year = 2000 + end_year
        # Q1=Apr-Jun, Q2=Jul-Sep, Q3=Oct-Dec, Q4=Jan-Mar
        if q == 1:
            start = datetime(start_year, 4, 1)
            end = datetime(start_year, 6, 30)
        elif q == 2:
            start = datetime(start_year, 7, 1)
            end = datetime(start_year, 9, 30)
        elif q == 3:
            start = datetime(start_year, 10, 1)
            end = datetime(start_year, 12, 31)
        else:
            start = datetime(end_year, 1, 1)
            end = datetime(end_year, 3, 31)
        return {
            'label': f"Q{q}_FY_{start_year}_{str(end_year)[-2:]}",
            'start_date': start.strftime('%Y-%m-%d'),
            'end_date': end.strftime('%Y-%m-%d'),
            'period_type': 'QUARTERLY',
        }

    # HALF_YEARLY: H1_FY_2024_25, H2_FY_2024_25
    m = re.search(r'H([12])[_\-\s]*FY[_\-\s]*(\d{4})[_\-\s]*(\d{2})\b', s, re.I)
    if m:
        h = int(m.group(1))
        start_year = int(m.group(2))
        end_year = int(m.group(3))
        if end_year < 100:
            end_year = 2000 + end_year
        if h == 1:
            start = datetime(start_year, 4, 1)
            end = datetime(start_year, 9, 30)
        else:
            start = datetime(start_year, 10, 1)
            end = datetime(end_year, 3, 31)
        return {
            'label': f"H{h}_FY_{start_year}_{str(end_year)[-2:]}",
            'start_date': start.strftime('%Y-%m-%d'),
            'end_date': end.strftime('%Y-%m-%d'),
            'period_type': 'HALF_YEARLY',
        }

    # YEARLY: FY_2024_25 or FY-2024-25 (avoid matching Q1_FY/H1_FY prefix)
    m = None
    if not re.search(r'Q[1-4][_\-\s]*FY|H[12][_\-\s]*FY', s, re.I):
        m = re.search(r'FY[_\-\s]*(\d{4})[_\-\s]*(\d{2})\b', s, re.I)
    if m:
        start_year = int(m.group(1))
        end_year = int(m.group(2))
        if end_year < 100:
            end_year = 2000 + end_year
        start = datetime(start_year, 4, 1)
        end = datetime(end_year, 3, 31)
        return {
            'label': f"FY_{start_year}_{str(end_year)[-2:]}",
            'start_date': start.strftime('%Y-%m-%d'),
            'end_date': end.strftime('%Y-%m-%d'),
            'period_type': 'YEARLY',
        }

    return {}
