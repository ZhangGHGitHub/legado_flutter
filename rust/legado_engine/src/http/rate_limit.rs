use std::collections::HashMap;
use std::sync::Mutex;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use once_cell::sync::Lazy;

struct RateConfig {
    interval_ms: u64,
    count: u32,
    window_ms: u64,
}

struct RateLimiter {
    configs: HashMap<String, RateConfig>,
    request_times: HashMap<String, Vec<u64>>,
}

impl RateLimiter {
    fn new() -> Self {
        Self {
            configs: HashMap::new(),
            request_times: HashMap::new(),
        }
    }

    fn configure(&mut self, source_url: &str, config_str: &str) {
        if config_str.is_empty() {
            return;
        }
        if let Some((count_str, window_str)) = config_str.split_once('/') {
            if let (Ok(count), Ok(window)) = (count_str.trim().parse(), window_str.trim().parse()) {
                if count > 0 && window > 0 {
                    self.configs.insert(
                        source_url.to_string(),
                        RateConfig {
                            interval_ms: 0,
                            count,
                            window_ms: window,
                        },
                    );
                }
            }
        } else if let Ok(interval) = config_str.trim().parse::<u64>() {
            if interval > 0 {
                self.configs.insert(
                    source_url.to_string(),
                    RateConfig {
                        interval_ms: interval,
                        count: 0,
                        window_ms: 0,
                    },
                );
            }
        }
    }

    fn wait_if_needed(&mut self, source_url: &str) -> Result<(), String> {
        let config = match self.configs.get(source_url) {
            Some(c) => c.clone(),
            None => return Ok(()),
        };

        let now = now_ms();
        let times = self.request_times.entry(source_url.to_string()).or_default();

        if config.interval_ms > 0 {
            if let Some(&last) = times.last() {
                let elapsed = now.saturating_sub(last);
                if elapsed < config.interval_ms {
                    let wait = config.interval_ms - elapsed;
                    thread::sleep(Duration::from_millis(wait));
                }
            }
        } else if config.count > 0 && config.window_ms > 0 {
            let window_start = now.saturating_sub(config.window_ms);
            times.retain(|&t| t >= window_start);
            if times.len() >= config.count as usize {
                if let Some(&oldest) = times.first() {
                    let wait = oldest + config.window_ms - now + 1;
                    if wait > 0 {
                        thread::sleep(Duration::from_millis(wait));
                    }
                }
            }
        }

        times.push(now_ms());
        if times.len() > 100 {
            let cutoff = now_ms().saturating_sub(60_000);
            times.retain(|&t| t >= cutoff);
        }
        Ok(())
    }
}

static RATE_LIMITER: Lazy<Mutex<RateLimiter>> =
    Lazy::new(|| Mutex::new(RateLimiter::new()));

pub fn configure(source_url: &str, config_str: &str) {
    RATE_LIMITER
        .lock()
        .unwrap()
        .configure(source_url, config_str);
}

pub fn wait_if_needed(source_url: &str) -> Result<(), String> {
    RATE_LIMITER
        .lock()
        .unwrap()
        .wait_if_needed(source_url)
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}
