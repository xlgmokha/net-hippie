Version 1.2.1

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Fixed
- Add explicit dependency on `base64` gem
- Add explicit dependency on `json` gem
- Add explicit dependency on `net-http` gem
- Add explicit dependency on `openss` gem

## [1.2.0] - 2024-12-05
### Changed
- Disable logger by default

## [1.1.1] - 2021-01-30
### Changed
- Update Gem Metadata

## [1.1.0] - 2020-12-26
### Added
- Add support for Ruby 3.0

## [1.0.1] - 2020-07-31
### Fixed
- Load version before client

## [1.0.0] - 2020-07-31
### Added
- Add simpler API to remove the need to instantiate a `Client` directly.
- Default to 3 retries using simple API.
- Re-use client connection for connections to the same scheme, host, and port.

### Removed
- Remove support for Ruby 2.4
- Remove legacy `Api` class.

### Changed
- Limit mutable options on Client.
- Change default `read_timeout` to 10 seconds.
- Change default `open_timeout` to 10 seconds.
- Log to `STDERR` by default instead of `STDOUT`.

## [0.3.2] - 2020-01-28
### Fixed
- Follow relative path redirects

## [0.3.1] - 2020-01-14
### Fixed
- Parse location header in response then follow redirect.
- Follow redirect using GET regardless of the original request method.

## [0.3.0] - 2020-01-13
### Added
- Allow following HTTP redirects.

## [0.2.7] - 2019-10-04
### Added
- add additional connection errors

### Changed
- specify ruby 2.4 and minimum required.

## [0.2.6] - 2019-04-30
### Added
- add support for PATCH verb.

## [0.2.5] - 2019-02-06
### Changed
- revert change introduced in 0.2.4. See [5.12][https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html]

## [0.2.4] - 2019-02-06
### Changed
- Send path instead of full uri.

## [0.2.3] - 2019-02-01
### Added
- Default verify mode

## [0.2.2] - 2019-02-01
### Added
- open\_timeout added to client.

## [0.2.1] - 2019-02-01
### Added
- with\_retry.
- authorization header helpers

[Unreleased]: https://github.com/xlgmokha/net-hippie/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/xlgmokha/net-hippie/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/xlgmokha/net-hippie/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/xlgmokha/net-hippie/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/xlgmokha/net-hippie/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/xlgmokha/net-hippie/compare/v0.3.2...v1.0.0
[0.3.2]: https://github.com/xlgmokha/net-hippie/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/xlgmokha/net-hippie/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/xlgmokha/net-hippie/compare/v0.2.7...v0.3.0
[0.2.7]: https://github.com/xlgmokha/net-hippie/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/xlgmokha/net-hippie/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/xlgmokha/net-hippie/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/xlgmokha/net-hippie/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/xlgmokha/net-hippie/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/xlgmokha/net-hippie/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/xlgmokha/net-hippie/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/xlgmokha/net-hippie/compare/v0.1.9...v0.2.0
[0.1.9]: https://github.com/xlgmokha/net-hippie/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/xlgmokha/net-hippie/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/xlgmokha/net-hippie/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/xlgmokha/net-hippie/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/xlgmokha/net-hippie/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/xlgmokha/net-hippie/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/xlgmokha/net-hippie/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/xlgmokha/net-hippie/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/xlgmokha/net-hippie/compare/v0.1.0...v0.1.1
