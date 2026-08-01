use crate::api::{SourceBrowserRequestDto, SourceBrowserResponseDto};
use flutter_rust_bridge::DartFnFuture;
use once_cell::sync::Lazy;
use std::sync::{mpsc, Mutex};
use tokio::sync::mpsc::{unbounded_channel, UnboundedSender};

struct HostCall {
    request: SourceBrowserRequestDto,
    response: mpsc::SyncSender<Result<SourceBrowserResponseDto, String>>,
}

static HOST: Lazy<Mutex<Option<UnboundedSender<HostCall>>>> = Lazy::new(|| Mutex::new(None));

struct HostRegistration {
    sender: UnboundedSender<HostCall>,
}

impl Drop for HostRegistration {
    fn drop(&mut self) {
        let _ = clear_if_current(&self.sender);
    }
}

pub async fn serve<F>(host: F) -> Result<(), String>
where
    F: Fn(SourceBrowserRequestDto) -> DartFnFuture<anyhow::Result<SourceBrowserResponseDto>>,
{
    let (sender, mut receiver) = unbounded_channel::<HostCall>();
    let registered_sender = sender.clone();
    *HOST.lock().map_err(|_| "浏览器宿主锁失败".to_string())? = Some(sender);
    let _registration = HostRegistration {
        sender: registered_sender.clone(),
    };
    while let Some(call) = receiver.recv().await {
        let result = host(call.request).await.map_err(|error| error.to_string());
        let _ = call.response.send(result);
    }
    clear_if_current(&registered_sender)?;
    Ok(())
}

pub fn invoke(request: SourceBrowserRequestDto) -> Result<SourceBrowserResponseDto, String> {
    #[cfg(test)]
    if let Some(result) = invoke_test_host(&request) {
        return result;
    }

    let host = HOST
        .lock()
        .map_err(|_| "浏览器宿主锁失败".to_string())?
        .clone()
        .ok_or_else(|| "浏览器宿主未注册".to_string())?;
    let (response, receiver) = mpsc::sync_channel(1);
    if host.send(HostCall { request, response }).is_err() {
        let _ = clear_if_current(&host);
        return Err("浏览器宿主已停止".to_string());
    }
    receiver
        .recv()
        .map_err(|_| "浏览器宿主未返回结果".to_string())?
}

#[cfg(test)]
pub fn clear() -> Result<(), String> {
    *HOST.lock().map_err(|_| "浏览器宿主锁失败".to_string())? = None;
    Ok(())
}

#[cfg(test)]
fn is_registered() -> bool {
    HOST.lock().ok().and_then(|host| host.clone()).is_some()
}

fn clear_if_current(sender: &UnboundedSender<HostCall>) -> Result<(), String> {
    let mut slot = HOST.lock().map_err(|_| "浏览器宿主锁失败".to_string())?;
    if slot
        .as_ref()
        .is_some_and(|current| current.same_channel(sender))
    {
        *slot = None;
    }
    Ok(())
}

#[cfg(test)]
type TestHost =
    dyn Fn(&SourceBrowserRequestDto) -> Result<SourceBrowserResponseDto, String> + Send + Sync;

#[cfg(test)]
static TEST_HOST: Lazy<Mutex<Option<std::sync::Arc<TestHost>>>> = Lazy::new(|| Mutex::new(None));

#[cfg(test)]
fn invoke_test_host(
    request: &SourceBrowserRequestDto,
) -> Option<Result<SourceBrowserResponseDto, String>> {
    TEST_HOST
        .lock()
        .ok()
        .and_then(|host| host.clone())
        .map(|host| host(request))
}

#[cfg(test)]
pub fn set_test_host<F>(host: F)
where
    F: Fn(&SourceBrowserRequestDto) -> Result<SourceBrowserResponseDto, String>
        + Send
        + Sync
        + 'static,
{
    if let Ok(mut slot) = TEST_HOST.lock() {
        *slot = Some(std::sync::Arc::new(host));
    }
}

#[cfg(test)]
pub fn clear_test_host() {
    if let Ok(mut host) = TEST_HOST.lock() {
        *host = None;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    fn request() -> SourceBrowserRequestDto {
        SourceBrowserRequestDto {
            source_key: "https://source.example".into(),
            url: "https://source.example/verify".into(),
            title: "验证".into(),
            html: None,
            headers: HashMap::new(),
            refetch_after_success: false,
        }
    }

    async fn wait_until_registered() {
        for _ in 0..100 {
            if is_registered() {
                return;
            }
            tokio::time::sleep(std::time::Duration::from_millis(1)).await;
        }
        panic!("浏览器宿主未在预期时间内注册");
    }

    async fn wait_until_unregistered() {
        for _ in 0..100 {
            if !is_registered() {
                return;
            }
            tokio::time::sleep(std::time::Duration::from_millis(1)).await;
        }
        panic!("浏览器宿主未在预期时间内清理");
    }

    #[tokio::test(flavor = "multi_thread")]
    #[serial_test::serial(source_browser_host)]
    async fn service_channel_returns_callback_result_to_blocking_rule_thread() {
        clear_test_host();
        let _ = clear();
        let service = tokio::spawn(serve(|request| {
            Box::pin(async move {
                Ok(SourceBrowserResponseDto {
                    final_url: format!("{}/done", request.url.trim_end_matches('/')),
                    body: format!("{}|callback", request.title),
                })
            })
        }));
        wait_until_registered().await;

        let response = tokio::task::spawn_blocking(|| invoke(request()))
            .await
            .unwrap()
            .unwrap();

        assert_eq!(response.final_url, "https://source.example/verify/done");
        assert_eq!(response.body, "验证|callback");
        service.abort();
        let _ = clear();
    }

    #[tokio::test(flavor = "multi_thread")]
    #[serial_test::serial(source_browser_host)]
    async fn aborted_service_does_not_leave_stale_sender() {
        clear_test_host();
        let _ = clear();
        let first = tokio::spawn(serve(|_| {
            Box::pin(async move {
                Ok(SourceBrowserResponseDto {
                    final_url: "https://source.example/old".into(),
                    body: "old".into(),
                })
            })
        }));
        wait_until_registered().await;
        first.abort();
        let _ = first.await;
        wait_until_unregistered().await;

        let error = tokio::task::spawn_blocking(|| invoke(request()))
            .await
            .unwrap()
            .unwrap_err();
        assert_eq!(error, "浏览器宿主未注册");

        let second = tokio::spawn(serve(|_| {
            Box::pin(async move {
                Ok(SourceBrowserResponseDto {
                    final_url: "https://source.example/new".into(),
                    body: "new".into(),
                })
            })
        }));
        wait_until_registered().await;

        let response = tokio::task::spawn_blocking(|| invoke(request()))
            .await
            .unwrap()
            .unwrap();
        assert_eq!(response.final_url, "https://source.example/new");
        assert_eq!(response.body, "new");

        second.abort();
        let _ = second.await;
        let _ = clear();
    }

    #[test]
    #[serial_test::serial(source_browser_host)]
    fn clear_unregisters_host_for_lifecycle_shutdown() {
        clear_test_host();
        clear().unwrap();

        let error = invoke(SourceBrowserRequestDto {
            source_key: "https://source.example".into(),
            url: "https://source.example/verify".into(),
            title: "验证".into(),
            html: None,
            headers: std::collections::HashMap::new(),
            refetch_after_success: false,
        })
        .unwrap_err();

        assert_eq!(error, "浏览器宿主未注册");
    }
}
