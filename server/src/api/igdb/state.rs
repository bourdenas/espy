use crate::util::rate_limiter::RateLimiter;

#[derive(Debug)]
pub struct IgdbApiState {
    pub client_id: String,
    pub oauth_token: String,
    pub qps: RateLimiter,
}
