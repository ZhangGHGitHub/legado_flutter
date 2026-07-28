use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use once_cell::sync::Lazy;
use tokio::sync::{OwnedSemaphorePermit, Semaphore};
use tokio::time::sleep;

/// Cap concurrent HTTP to one host (TOC+ajax+detail can otherwise stampede an overloaded DB).
const DEFAULT_HOST_CONCURRENCY: usize = 2;

#[derive(Clone)]
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

    fn wait_ms(&mut self, source_url: &str) -> u64 {
        let config = match self.configs.get(source_url) {
            Some(c) => c.clone(),
            None => return 0,
        };

        let now = now_ms();
        let times = self
            .request_times
            .entry(source_url.to_string())
            .or_default();

        if config.interval_ms > 0 {
            if let Some(&last) = times.last() {
                let elapsed = now.saturating_sub(last);
                if elapsed < config.interval_ms {
                    return config.interval_ms - elapsed;
                }
            }
        } else if config.count > 0 && config.window_ms > 0 {
            let window_start = now.saturating_sub(config.window_ms);
            times.retain(|&t| t >= window_start);
            if times.len() >= config.count as usize {
                if let Some(&oldest) = times.first() {
                    let wait = oldest + config.window_ms - now + 1;
                    if wait > 0 {
                        return wait;
                    }
                }
            }
        }
        0
    }

    fn record_request(&mut self, source_url: &str) {
        let times = self
            .request_times
            .entry(source_url.to_string())
            .or_default();
        times.push(now_ms());
        if times.len() > 100 {
            let cutoff = now_ms().saturating_sub(60_000);
            times.retain(|&t| t >= cutoff);
        }
    }
}

static RATE_LIMITER: Lazy<Mutex<RateLimiter>> = Lazy::new(|| Mutex::new(RateLimiter::new()));

static HOST_SEMAPHORES: Lazy<Mutex<HashMap<String, Arc<Semaphore>>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

pub fn configure(source_url: &str, config_str: &str) {
    RATE_LIMITER
        .lock()
        .unwrap()
        .configure(source_url, config_str);
}

pub async fn wait_if_needed(source_url: &str) -> Result<(), String> {
    let wait_ms = {
        let mut limiter = RATE_LIMITER.lock().unwrap();
        limiter.wait_ms(source_url)
    };
    if wait_ms > 0 {
        sleep(Duration::from_millis(wait_ms)).await;
    }
    RATE_LIMITER.lock().unwrap().record_request(source_url);
    Ok(())
}

fn host_key(url: &str) -> String {
    url::Url::parse(url)
        .ok()
        .and_then(|u| u.host_str().map(|h| h.to_ascii_lowercase()))
        .unwrap_or_else(|| "unknown".to_string())
}

fn semaphore_for_host(host: &str) -> Arc<Semaphore> {
    let mut map = HOST_SEMAPHORES.lock().unwrap();
    map.entry(host.to_string())
        .or_insert_with(|| Arc::new(Semaphore::new(DEFAULT_HOST_CONCURRENCY)))
        .clone()
}

/// Acquire a per-host permit (max 2 in flight). Caller drops permit when done.
pub async fn acquire_host_permit(url: &str) -> Result<OwnedSemaphorePermit, String> {
    let host = host_key(url);
    let sem = semaphore_for_host(&host);
    sem.acquire_owned()
        .await
        .map_err(|_| format!("主机并发闸损坏: {host}"))
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn host_permit_limits_concurrency() {
        let a = acquire_host_permit("https://example.com/a").await.unwrap();
        let b = acquire_host_permit("https://example.com/b").await.unwrap();
        // Third would block; verify only 2 available by trying_acquire on same sem
        let host = host_key("https://example.com/c");
        let sem = semaphore_for_host(&host);
        assert!(sem.try_acquire().is_err());
        drop(a);
        drop(b);
        assert!(sem.try_acquire().is_ok());
    }
}
