"""
Get/set ratio benchmarks. Merges DB-stored values with defaults from config.
"""
from app.models import AppConfig
from app.config.ratio_benchmarks import DEFAULT_RATIO_BENCHMARKS

RATIO_BENCHMARKS_KEY = "ratio_benchmarks"


def get_ratio_benchmarks():
    """Return merged ratio benchmarks: DB overrides defaults. Values are float or None."""
    out = dict(DEFAULT_RATIO_BENCHMARKS)
    try:
        row = AppConfig.objects.filter(key=RATIO_BENCHMARKS_KEY).first()
        if row and isinstance(row.value, dict):
            for k, v in row.value.items():
                if k in out or k in DEFAULT_RATIO_BENCHMARKS:
                    out[k] = v if v is None or isinstance(v, (int, float)) else out.get(k)
    except Exception:
        pass
    return out


def set_ratio_benchmarks(data):
    """Save ratio benchmarks to DB. data: dict of key -> value (float or None)."""
    if not isinstance(data, dict):
        raise ValueError("data must be a dict")
    # Only allow keys that exist in defaults
    allowed = set(DEFAULT_RATIO_BENCHMARKS.keys())
    to_save = {}
    for k, v in data.items():
        if k in allowed:
            if v is None or isinstance(v, (int, float)):
                to_save[k] = float(v) if v is not None else None
            else:
                to_save[k] = v
    obj, _ = AppConfig.objects.update_or_create(
        key=RATIO_BENCHMARKS_KEY,
        defaults={"value": to_save},
    )
    return obj
