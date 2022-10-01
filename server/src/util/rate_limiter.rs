use std::sync::Mutex;
use std::time::{Duration, SystemTime};

/// Thread-safe RateLimiter for fixed amount of queries per second (QPS).
#[derive(Debug)]
pub struct RateLimiter {
    qps_rate: i32,
    state: Mutex<RateLimiterState>,
}

#[derive(Debug)]
struct RateLimiterState {
    available_capacity: i32,
    next_reset: SystemTime,
}

impl RateLimiter {
    pub fn new(qps_rate: i32) -> RateLimiter {
        RateLimiter {
            qps_rate,
            state: Mutex::new(RateLimiterState {
                available_capacity: qps_rate,
                next_reset: SystemTime::now(),
            }),
        }
    }

    // Blocks execution thread until it is ok to execute next operation based on
    // QPS limit. Returns the duration the thread was blocked. Returns 0 if the
    // thread did not have to block.
    pub fn wait(&self) -> Duration {
        let mut total_wait_time = Duration::from_micros(0);

        loop {
            let wait_time = self.try_wait();
            if wait_time == Duration::from_micros(0) {
                break;
            }

            total_wait_time += wait_time;
            std::thread::sleep(wait_time);
        }

        total_wait_time
    }

    // Non-blocking variation of the above. Returns duration before the resource
    // can be tried again. Retuns 0 if execution can proceed immidiately.
    pub fn try_wait(&self) -> Duration {
        let now = SystemTime::now();
        let mut state = self.state.lock().unwrap();

        if state.next_reset < now {
            state.available_capacity = self.qps_rate;
            state.next_reset = now.checked_add(Duration::from_secs(1)).unwrap();
        }

        match state.available_capacity > 0 {
            true => {
                state.available_capacity -= 1;
                Duration::from_micros(0)
            }
            false => state.next_reset.duration_since(now).unwrap(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sequencial_under_qps() {
        let limiter = RateLimiter::new(4);

        let start = SystemTime::now();
        for _ in 0..2 {
            let wait_time = limiter.wait();
            assert_eq!(wait_time, Duration::from_micros(0))
        }
        assert!(start.elapsed().unwrap() < Duration::from_secs(1));
    }

    #[test]
    fn sequencial_over_qps() {
        let limiter = RateLimiter::new(4);

        let start = SystemTime::now();
        for _ in 0..4 {
            let wait_time = limiter.wait();
            assert_eq!(wait_time, Duration::from_micros(0))
        }
        assert!(start.elapsed().unwrap() < Duration::from_secs(1));

        let wait_time = limiter.wait();
        assert!(wait_time > Duration::from_micros(0));
        assert!(start.elapsed().unwrap() > Duration::from_secs(1));
    }

    use std::sync::Arc;
    use std::thread;

    #[test]
    fn parallel_under_qps() {
        let limiter = Arc::new(RateLimiter::new(4));

        let start = SystemTime::now();
        let threads = (0..2)
            .map(|_| {
                let limiter = Arc::clone(&limiter);
                thread::spawn(move || {
                    let wait_time = limiter.wait();
                    assert_eq!(wait_time, Duration::from_micros(0))
                })
            })
            .collect::<Vec<_>>();

        for thread in threads {
            let _ = thread.join();
        }
        assert!(start.elapsed().unwrap() < Duration::from_secs(1));
    }

    #[test]
    fn parallel_over_qps() {
        let limiter = Arc::new(RateLimiter::new(4));

        let start = SystemTime::now();
        let threads = (0..5)
            .map(|_| {
                let limiter = Arc::clone(&limiter);
                thread::spawn(move || {
                    let _ = limiter.wait();
                })
            })
            .collect::<Vec<_>>();

        for thread in threads {
            let _ = thread.join();
        }
        assert!(start.elapsed().unwrap() > Duration::from_secs(1));
    }
}
