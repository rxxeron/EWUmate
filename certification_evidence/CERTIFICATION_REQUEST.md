# Certification Request: OWASP MASVS-L1

Dear Certification Authority,

Enclosed is the certification evidence package for the `EWUmate` Flutter application, requesting compliance verification against the **OWASP MASVS-L1** standard.

## Application Details
* **App Name:** EWUmate
* **Bundle ID:** com.rxxeron.ewumate
* **Version:** 1.0.3+14
* **Framework:** Flutter 3.22+

## Self-Assessment & Hardening Measures Configured
1. **Data-at-Rest:** All sensitive local data is managed via `flutter_secure_storage` utilizing encrypted KeyStore/Keychain mechanisms.
2. **Data-in-Transit:** The networking client utilizes `http_certificate_pinning` to enforce SSL certificate pinning.
3. **Resilience (Obfuscation):** The provided APK was built with `--obfuscate` to mangle class namespaces.
4. **Resilience (Device Integrity):** The application integrates `safe_device` to detect jailbroken, rooted, or hooked environments.
5. **Static Analysis:** An initial MobSF scan has been performed (report attached) yielding no critical plain-text secrets in the Dart binary.

## Attached Evidence
* `app-release.apk` (Obfuscated Release Build)
* `mobsf_report.pdf` (MobSF Static Analysis Report)

Please let us know if additional source code access or dynamic testing credentials are required to complete the L1 verification.

Sincerely,
The EWUmate Development Team
