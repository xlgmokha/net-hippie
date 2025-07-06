use magnus::{define_module, function, method, Error, Module, Object, Value, class, RHash, TryConvert};
use magnus::value::ReprValue;
use reqwest::{Client, Method, Response};
use std::collections::HashMap;
use std::time::Duration;
use tokio::runtime::Runtime;

#[magnus::wrap(class = "Net::Hippie::RustResponse")]
struct RustResponse {
    status: u16,
    headers: HashMap<String, String>,
    body: String,
}

impl RustResponse {
    fn new(status: u16, headers: HashMap<String, String>, body: String) -> Self {
        Self {
            status,
            headers,
            body,
        }
    }

    fn code(&self) -> String {
        self.status.to_string()
    }

    fn body(&self) -> String {
        self.body.clone()
    }

    fn get_header(&self, name: String) -> Option<String> {
        self.headers.get(&name.to_lowercase()).cloned()
    }
}

#[magnus::wrap(class = "Net::Hippie::RustClient")]
struct RustClient {
    client: Client,
    runtime: Runtime,
}

impl RustClient {
    fn new() -> Result<Self, Error> {
        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .connect_timeout(Duration::from_secs(10))
            .redirect(reqwest::redirect::Policy::none())
            .build()
            .map_err(|e| Error::new(magnus::exception::runtime_error(), e.to_string()))?;

        let runtime = Runtime::new()
            .map_err(|e| Error::new(magnus::exception::runtime_error(), e.to_string()))?;

        Ok(Self { client, runtime })
    }

    fn execute_request(
        &self,
        method_str: String,
        url: String,
        headers: Value,
        body: String,
    ) -> Result<RustResponse, Error> {
        let method = match method_str.to_uppercase().as_str() {
            "GET" => Method::GET,
            "POST" => Method::POST,
            "PUT" => Method::PUT,
            "DELETE" => Method::DELETE,
            "PATCH" => Method::PATCH,
            _ => return Err(Error::new(magnus::exception::arg_error(), "Invalid HTTP method")),
        };

        self.runtime.block_on(async {
            let mut request_builder = self.client.request(method, &url);

            // Add headers if provided
            if let Ok(headers_hash) = RHash::from_value(headers) {
                for (key, value) in headers_hash {
                    if let (Ok(key_str), Ok(value_str)) = (String::try_convert(key), String::try_convert(value)) {
                        request_builder = request_builder.header(&key_str, &value_str);
                    }
                }
            }

            // Add body if not empty
            if !body.is_empty() {
                request_builder = request_builder.body(body);
            }

            let response = request_builder.send().await
                .map_err(|e| self.map_reqwest_error(e))?;

            self.convert_response(response).await
        })
    }

    async fn convert_response(&self, response: Response) -> Result<RustResponse, Error> {
        let status = response.status().as_u16();
        
        let mut headers = HashMap::new();
        for (key, value) in response.headers() {
            if let Ok(value_str) = value.to_str() {
                headers.insert(key.as_str().to_lowercase(), value_str.to_string());
            }
        }

        let body = response.text().await
            .map_err(|e| Error::new(magnus::exception::runtime_error(), e.to_string()))?;

        Ok(RustResponse::new(status, headers, body))
    }

    fn map_reqwest_error(&self, error: reqwest::Error) -> Error {
        if error.is_timeout() {
            Error::new(magnus::exception::runtime_error(), "Net::ReadTimeout")
        } else if error.is_connect() {
            Error::new(magnus::exception::runtime_error(), "Errno::ECONNREFUSED")
        } else {
            Error::new(magnus::exception::runtime_error(), error.to_string())
        }
    }

    fn get(&self, url: String, headers: Value, body: String) -> Result<RustResponse, Error> {
        self.execute_request("GET".to_string(), url, headers, body)
    }

    fn post(&self, url: String, headers: Value, body: String) -> Result<RustResponse, Error> {
        self.execute_request("POST".to_string(), url, headers, body)
    }

    fn put(&self, url: String, headers: Value, body: String) -> Result<RustResponse, Error> {
        self.execute_request("PUT".to_string(), url, headers, body)
    }

    fn delete(&self, url: String, headers: Value, body: String) -> Result<RustResponse, Error> {
        self.execute_request("DELETE".to_string(), url, headers, body)
    }

    fn patch(&self, url: String, headers: Value, body: String) -> Result<RustResponse, Error> {
        self.execute_request("PATCH".to_string(), url, headers, body)
    }
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let net_module = define_module("Net")?;
    let hippie_module = net_module.define_module("Hippie")?;
    
    let rust_client_class = hippie_module.define_class("RustClient", class::object())?;
    rust_client_class.define_singleton_method("new", function!(RustClient::new, 0))?;
    rust_client_class.define_method("get", method!(RustClient::get, 3))?;
    rust_client_class.define_method("post", method!(RustClient::post, 3))?;
    rust_client_class.define_method("put", method!(RustClient::put, 3))?;
    rust_client_class.define_method("delete", method!(RustClient::delete, 3))?;
    rust_client_class.define_method("patch", method!(RustClient::patch, 3))?;

    let rust_response_class = hippie_module.define_class("RustResponse", class::object())?;
    rust_response_class.define_method("code", method!(RustResponse::code, 0))?;
    rust_response_class.define_method("body", method!(RustResponse::body, 0))?;
    rust_response_class.define_method("[]", method!(RustResponse::get_header, 1))?;

    Ok(())
}