const EARTH_RADIUS: f64 = 6372.8;

fn degree_to_radian(degree: f64) -> f64 {
    degree * 0.01745329251994329577
}

pub fn reference_haversine(lon1: f64, lat1: f64, lon2: f64, lat2: f64) -> f64 {
    let dlat = degree_to_radian(lat2 - lat1);
    let dlon = degree_to_radian(lon2 - lon1);
    let lat1 = degree_to_radian(lat1);
    let lat2 = degree_to_radian(lat2);

    let a = f64::powf((dlat / 2.0).sin(), 2.0) + lat1.cos() * lat2.cos() * f64::powf((dlon / 2.0).sin(), 2.0);
    let c = 2.0 * a.sqrt().asin();
    EARTH_RADIUS * c
}
