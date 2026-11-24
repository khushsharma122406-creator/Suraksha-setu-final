# SURAKSHA SETU — REST API INTEGRATION REFERENCE
## Law Enforcement & Citizen Protection Web Services
**Version:** 2.0.0  
**Base URL:** `http://localhost:8088/api` (or live HTTPS tunnel: `https://2b0f8664399b89.app.lhr.life/api`)  
**Data Format:** `application/json`

---

## 1. Authentication & Session Services (`/api/auth`)

### 1.1 Citizen Registration
Register a new citizen account with phone/email verification.
- **Endpoint:** `POST /api/auth/register`
- **Access:** Public / Unauthenticated
- **Request Body:**
```json
{
  "name": "Vikram Rathore",
  "email": "vikram.rathore@rajasthan.in",
  "phone": "+91 94140 12345",
  "password": "SecurePassword@2026"
}
```
- **Response (201 Created):**
```json
{
  "success": true,
  "message": "Citizen registered successfully.",
  "sessionToken": "ss_jwt_89f02c34a...",
  "user": {
    "id": "CIT-812",
    "name": "Vikram Rathore",
    "email": "vikram.rathore@rajasthan.in",
    "role": "citizen"
  }
}
```

---

### 1.2 Unified Login (Citizen & Police Officer)
Authenticates citizens or authorized police officers through the unified portal.
- **Endpoint:** `POST /api/auth/login`
- **Access:** Public
- **Request Body (Citizen):**
```json
{
  "role": "citizen",
  "identifier": "vikram.rathore@rajasthan.in",
  "password": "SecurePassword@2026"
}
```
- **Request Body (Police Officer):**
```json
{
  "role": "police",
  "identifier": "OFF-8412",
  "password": "cybercop2026"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Police officer authenticated successfully.",
  "sessionToken": "ss_jwt_4b78912c...",
  "user": {
    "id": "OFF-8412",
    "name": "Inspector R. K. Sharma",
    "email": "r.sharma@delhipolice.gov.in",
    "role": "police",
    "badge": "DL-CY-8412",
    "rank": "Senior Cyber Crime Investigator",
    "unit": "Cyber Crime Police Station, Central District"
  }
}
```

---

### 1.3 Active Session Verification
Validates client token and returns current user profile and role privileges.
- **Endpoint:** `GET /api/auth/me`
- **Headers:** `Authorization: Bearer <sessionToken>`
- **Response (200 OK):**
```json
{
  "success": true,
  "authenticated": true,
  "role": "police",
  "user": { "id": "OFF-8412", "name": "Inspector R. K. Sharma", "badge": "DL-CY-8412" }
}
```

---

## 2. Threat Analysis & Scanning Services (`/api/scan`)

### 2.1 Suspicious URL Scanner (with SSRF Guard)
Executes static heuristic evaluation and multi-source threat intelligence lookup.
- **Endpoint:** `POST /api/scan/url`
- **Request Body:**
```json
{
  "url": "http://sbi-rewards-redeem.in/login.php?ref=sms_claim",
  "citizenId": "CIT-101"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "analysis": {
    "target": "http://sbi-rewards-redeem.in/login.php?ref=sms_claim",
    "domain": "sbi-rewards-redeem.in",
    "riskScore": 98,
    "riskLevel": "Critical",
    "isEscalatedToPolice": true,
    "indicators": [
      { "type": "Protocol Insecurity", "value": "http://", "severity": "Medium" },
      { "type": "Brand Impersonation", "value": "SBI (State Bank of India)", "severity": "Critical" },
      { "type": "VirusTotal Threat Detection", "value": "14 / 92 AV engines", "severity": "Critical" }
    ],
    "entropy": 3.92,
    "analyzedAt": "2026-11-24T10:55:00.000Z"
  },
  "autoReport": {
    "reportId": "CR-2026-3151",
    "status": "New – Pending Police Review",
    "evidenceHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }
}
```
- **SSRF Blocked Response (400 Bad Request):**
```json
{
  "success": false,
  "error": "SSRF_BLOCKED",
  "message": "Security Violation: Analysis target was rejected by the SSRF defense firewall.",
  "details": "Target IP is within reserved or private RFC 1918/link-local address space."
}
```

---

### 2.2 AI Scam Message Analyzer
Extracts Indian phone numbers (+91), mule UPI handles, URLs, and detects psychological coercion.
- **Endpoint:** `POST /api/scan/message`
- **Request Body:**
```json
{
  "message": "Dear consumer electricity power will be disconnected tonight 9:30 PM from power office because your previous month bill was not updated. Please immediately contact our power officer at 9876543210."
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "analysis": {
    "riskScore": 90,
    "riskLevel": "Critical",
    "isEscalatedToPolice": true,
    "categoriesMatched": ["Electricity / Utility Disconnection"],
    "extractedEntities": {
      "phones": ["9876543210"],
      "upis": [],
      "urls": []
    },
    "indicators": [
      { "type": "Social Engineering Pattern", "value": "Electricity Disconnection", "severity": "Critical" },
      { "type": "Repeated Syndicate Phone", "value": "9876543210", "severity": "Critical" }
    ],
    "recommendations": [
      "Verify through official state DISCOM portal / 1912 helpline. Do not call provided personal mobile number."
    ]
  },
  "autoReport": { "reportId": "CR-2026-8942", "status": "New – Pending Police Review" }
}
```

---

## 3. Police Case Management (`/api/cases`)
*(Requires Police Officer or Admin Role)*

### 3.1 List Investigation Cases
- **Endpoint:** `GET /api/cases?query=sbi&risk=Critical&status=Under%20Review`
- **Headers:** `Authorization: Bearer <sessionToken>`
- **Response (200 OK):**
```json
{
  "success": true,
  "total": 1,
  "cases": [
    {
      "id": "SS-2026-1049",
      "date": "2026-11-24T10:15:00Z",
      "type": "URL",
      "title": "Fake SBI Rewards Redemption Phishing",
      "riskScore": 92,
      "riskLevel": "Critical",
      "status": "Under Review",
      "assignedOfficer": "Inspector R. K. Sharma",
      "station": "Cyber Police Station Central, Delhi",
      "evidenceHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    }
  ]
}
```

---

### 3.2 Update Case Status & Add Investigation Note
- **Endpoint:** `PATCH /api/cases/:id/status`
- **Request Body:**
```json
{
  "status": "Investigating",
  "note": "Section 91 CrPC notice dispatched to domain registrar. Preliminary CDR analysis confirms sender nexus."
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Status updated successfully.",
  "case": { "id": "SS-2026-1049", "status": "Investigating" }
}
```

---

## 4. Threat Intelligence & Syndicate Correlation (`/api/intelligence`)
*(Requires Police Officer or Admin Role)*

### 4.1 Cross-Case Syndicate Correlation Graph
- **Endpoint:** `GET /api/intelligence/correlations`
- **Response (200 OK):**
```json
{
  "success": true,
  "totalCorrelations": 3,
  "recurringIndicators": [
    {
      "type": "Phone Number",
      "indicatorType": "PHONE",
      "value": "9876543210",
      "occurrences": 14,
      "caseIds": ["SS-2026-1048"],
      "severity": "Critical",
      "syndicate": "Operation ElectroLocker / KBC Syndicate"
    },
    {
      "type": "Mule UPI Handle",
      "indicatorType": "UPI",
      "value": "quickloan88@ybl",
      "occurrences": 3,
      "severity": "High",
      "syndicate": "Predatory Loan Ring"
    }
  ],
  "graph": {
    "nodes": [
      { "id": "syn_electrolocker", "label": "Operation ElectroLocker", "type": "syndicate" },
      { "id": "ioc_PHONE_0", "label": "9876543210", "type": "indicator" }
    ],
    "links": [
      { "source": "ioc_PHONE_0", "target": "syn_electrolocker", "type": "PART_OF_SYNDICATE" }
    ]
  }
}
```

---

## 5. Forensic Evidence Services (`/api/evidence`)
*(Requires Police Officer or Admin Role)*

### 5.1 Generate Section 65B Certificate
- **Endpoint:** `GET /api/evidence/certificate/:caseId`
- **Response (200 OK):**
```json
{
  "success": true,
  "certificate": {
    "certificateId": "CERT-65B-D9A14B",
    "caseId": "SS-2026-1049",
    "evidenceHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "investigatingOfficer": {
      "name": "Inspector R. K. Sharma",
      "badge": "DL-CY-8412",
      "rank": "Senior Cyber Crime Investigator"
    },
    "declaration": "I, Inspector R. K. Sharma, hereby solemnly declare under Section 65B(4)...",
    "certificationTimestamp": "2026-11-24T10:55:00.000Z",
    "isValid": true
  }
}
```

### 5.2 Verify Evidence Hash
- **Endpoint:** `POST /api/evidence/verify`
- **Request Body:**
```json
{
  "content": "http://sbi-rewards-redeem.in/login.php?ref=sms_claim",
  "expectedHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "isValid": true,
  "calculatedHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "expectedHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "message": "Integrity verified: SHA-256 bitstream matches original seized evidence."
}
```
