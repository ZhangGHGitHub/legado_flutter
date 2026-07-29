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

pub async fn serve<F>(host: F) -> Result<(), String>
where
    F: Fn(SourceBrowserRequestDto) -> DartFnFuture<anyhow::Result<SourceBrowserResponseDto>>,
{
    let (sender, mut receiver) = unbounded_channel::<HostCall>();
    *HOST.lock().map_err(|_| "浏览器宿主锁失败".to_string())? = Some(sender);
    while let Some(call) = receiver.recv().await {
        let result = host(call.request).await.map_err(|error| error.to_string());
        let _ = call.response.send(result);
    }
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
    host.send(HostCall { request, response })
        .map_err(|_| "浏览器宿主已停止".to_string())?;
    receiver
        .recv()
        .map_err(|_| "浏览器宿主未返回结果".to_string())?
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

    #[tokio::test(flavor = "multi_thread")]
    #[serial_test::serial(source_browser_host)]
    async fn service_channel_returns_callback_result_to_blocking_rule_thread() {
        clear_test_host();
        let service = tokio::spawn(serve(|request| {
            Box::pin(async move {
                Ok(SourceBrowserResponseDto {
                    final_url: format!("{}/done", request.url.trim_end_matches('/')),
                    body: format!("{}|callback", request.title),
                })
            })
        }));
        tokio::task::yield_now().await;

        let response = tokio::task::spawn_blocking(|| {
            invoke(SourceBrowserRequestDto {
                source_key: "https://source.example".into(),
                url: "https://source.example/verify".into(),
                title: "验证".into(),
                html: None,
                headers: std::collections::HashMap::new(),
                refetch_after_success: false,
            })
        })
        .await
        .unwrap()
        .unwrap();

        assert_eq!(response.final_url, "https://source.example/verify/done");
        assert_eq!(response.body, "验证|callback");
        service.abort();
    }
}
