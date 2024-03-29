from cmath import cos, sin, sqrt, asin
from math import atan2


def degree_to_radian(degree: float) -> float:
    return 0.01745329251994329577 * degree


def reference_haversine(lon1: float, lat1: float, lon2: float, lat2: float, earth_radius: float = 6372.8) -> complex:
    dlat = degree_to_radian(lat2 - lat1)
    dlon = degree_to_radian(lon2 - lon1)
    lat1 = degree_to_radian(lat1)
    lat2 = degree_to_radian(lat2)

    a = (sin(dlat / 2.0)) ** 2 + cos(lat1) * cos(lat2) * (sin(dlon / 2.0)) ** 2
    c = 2.0 * asin(sqrt(a))

    return earth_radius * c
