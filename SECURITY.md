# SURAKSHA SETU — SECURITY ARCHITECTURE & COMPLIANCE
## Zero-Trust Posture, SSRF Hardening & Section 65B Evidence Integrity
**Target:** Rajasthan Police Cyber Security Hackathon (Cyber Fraud / Phishing / Malicious Apps)  
**Standard:** Law Enforcement Agency (LEA) Operational Security Guideline

---

## 1. Zero-Trust Access Architecture

Suraksha Setu enforces a strict defense-in-depth model across the application stack:

```
[ Client Request ]
       |
       v
[ Helmet HTTP Security Headers ] (HSTS, No-Sniff, Frame-Options)
       |
       v
[ Express Rate Limiter ] (100 req/15min per IP)
       |
       v
[ SSRF Defense Firewall ] (Blocks 127.0.0.1, RFC 1918, 169.254.169.254)
       |
       v
[ Auth Middleware ] (Bearer JWT / Session token verification)
       |
       v
[ RBAC Enforcement ] (Role segregation: Citizen vs Police vs Admin)
       |
       v
[ Supabase PostgreSQL RLS Policies ] (Row Level Security at database level)
```

### Role-Based Access Control Matrix

| System Domain / Endpoint | Citizen | Police Investigator | Station Admin | Special Prosecutor |
| :--- | :---: | :---: | :---: | :---: |
| **Unified Login Gateway** | Yes | Yes | Yes | Yes |
| **Citizen Quick Scanner** | Yes | Yes | Yes | Yes |
| **View Own Submitted Reports**| Yes | Yes | Yes | Yes |
| **Police Case Investigation Queue**| **BLOCKED** | Read / Write | Read / Write | Read-Only |
| **Threat Intelligence Graph**| **BLOCKED** | Full Access | Full Access | Full Access |
| **Section 65B Dossier Generator**| **BLOCKED** | Authorized Signatory | Authorized Signatory | Trial Reviewer |
| **Evidence Hash Verification**| **BLOCKED** | Full Access | Full Access | Full Access |
| **User Management & Audit Logs**| **BLOCKED** | **BLOCKED** | Administrator Only | Read-Only |

---

## 2. Server-Side Request Forgery (SSRF) Defense

When an intelligence platform analyzes untrusted URLs submitted by users, attackers frequently exploit the server to probe internal infrastructure, pivot to local services, or exfiltrate cloud instance metadata.

### SSRF Prevention Controls in Suraksha Setu (`backend/src/middleware/ssrf.js`)

1. **Protocol Restriction:** Only `http:` and `https:` schemes are accepted. Internal schemes such as `file://`, `gopher://`, `ftp://`, or `dict://` are immediately rejected.
2. **Blocked IP Range Filtering:**
   - `127.0.0.0/8` (Loopback interface)
   - `10.0.0.0/8` (RFC 1918 Class A private network)
   - `172.16.0.0/12` (RFC 1918 Class B private network)
   - `192.168.0.0/16` (RFC 1918 Class C private network)
   - `169.254.169.254` / `169.254.0.0/16` (AWS, GCP, Azure Instance Metadata Services)
   - `0.0.0.0/8` (Broadcast / current network)
   - `::1` (IPv6 localhost)
   - `fc00::/7` (IPv6 unique local addresses)
3. **DNS Rebinding Protection:** The target domain name is resolved using public DNS resolvers before issuing outbound requests; if any resolved IP address falls within the prohibited ranges, the analysis is terminated with HTTP 400 `SSRF_BLOCKED`.

---

## 3. Cryptographic Chain of Custody & Section 65B Compliance

Under Section 65B of the Indian Evidence Act, 1872 and Section 63 of the Bharatiya Sakshya Adhiniyam, 2023, electronic records are admissible in court only if their technical authenticity, origin, and lack of tampering can be certified.

### Cryptographic Controls in Suraksha Setu:

1. **FIPS 180-4 SHA-256 Hashing:**
   - Every seized digital artifact (phishing URL string, SMS body, APK binary manifest) is passed through a deterministic SHA-256 hashing routine.
   - The computed hash is permanently written to the immutable investigation case record.
2. **Tamper Verification Routine:**
   - Investigating officers or judicial prosecutors can invoke `/api/evidence/verify` at any time to re-hash the seized digital record against the initial custody record.
   - Any difference in bitstream immediately triggers `TAMPER_DETECTED`.
3. **Automated Section 65B Technical Certificate:**
   - Generates court-formatted legal certificates containing:
     - Identification of the computer system and hashing engine.
     - Confirmation of ordinary course of law enforcement duties.
     - Signature, badge ID, and unit of the Investigating Officer (IO).
     - Full SHA-256 evidence digest.

---

## 4. Secret Management & Frontend Security

1. **Zero Client Secrets:** External API keys (VirusTotal, AbuseIPDB, URLhaus, Google Safe Browsing) and Supabase Service Role Keys are strictly confined to the backend `.env` file. They are never compiled, bundled, or exposed to browser JavaScript.
2. **Salted Password Hashing:** User passwords are encrypted with SHA-256 and a dedicated cryptographic salt (`suraksha_setu_salt_2026`) prior to authentication validation.
3. **Immutable Audit Logging:** Every login attempt, case assignment, evidence download, and status change generates a non-repudiable audit event stored in `public.audit_logs`.
