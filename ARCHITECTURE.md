# SURAKSHA SETU — SYSTEM ARCHITECTURE DOCUMENTATION
## AI-Powered Cyber Fraud Intelligence & Investigation Platform
**Target Problem Statement:** Rajasthan Police Cyber Security Hackathon — Cyber Fraud / Phishing / Malicious Apps  
**Document Version:** 2.0.0 (Master Upgrade Architecture)  
**Classification:** Law Enforcement Sensitive / Hackathon Technical Specification

---

## 1. Executive Summary

**Suraksha Setu** is an AI-powered cybercrime intelligence and digital investigation management platform purpose-built for State Police Cyber Crime Divisions and Law Enforcement Agencies (LEAs). The platform bridges two critical cyber defense tiers:
1. **The Citizen Protection Gateway:** Empowers ordinary citizens to safely verify suspicious links, SMS messages, WhatsApp lures, Android APK downloads, and payment requests without technical expertise, automatically escalating high-risk fraud incidents.
2. **The Police Cyber Investigation Cockpit:** Provides cybercrime investigators, intelligence analysts, and station supervisory officers with a centralized environment for automated evidence triage, multi-source OSINT threat intelligence, cross-complaint syndicate correlation, and Section 65B-compliant electronic evidence reporting.

```
+---------------------------------------------------------------------------------------+
|                                    SURAKSHA SETU                                      |
+-------------------------------------------+-------------------------------------------+
|             CITIZEN INTERFACE             |             POLICE COCKPIT                |
|  - Unified Glassmorphic Authentication    |  - High/Critical Risk Triage Queue        |
|  - Multi-Format Threat Scanner (URL/SMS/  |  - Deep Threat Analysis & Scoring (0-100) |
|    APK/App/Web)                           |  - Multi-Source OSINT Threat Intel Feeds  |
|  - Real-Time Explainable Findings         |  - Cross-Case Syndicate Correlation Graph |
|  - Automatic High-Risk Incident Escalation|  - Section 65B/63 Electronic Evidence Gen |
|  - Complaint Status Tracking & Advisory   |  - Role-Based Case Lifecycle Management   |
+-------------------------------------------+-------------------------------------------+
                                     |
                                     v
+---------------------------------------------------------------------------------------+
|                           ENTERPRISE BACKEND ARCHITECTURE                             |
|  - Node.js (v20 LTS) + Express.js REST API                                            |
|  - Supabase PostgreSQL (12 Normalized Schemas, RLS Policies, Indexes, Triggers)       |
|  - Multi-Engine Threat Intel (VirusTotal v3, URLhaus, AbuseIPDB v2, Safe Browsing)     |
|  - Heuristic NLP Social Engineering Classifier & SSRF-Protected Static Analyzers       |
|  - Deterministic Fallback & Offline Standalone Demonstration Resilience               |
+---------------------------------------------------------------------------------------+
```

---

## 2. Baseline Assessment & Gap Analysis

Prior to this master upgrade, Suraksha Setu possessed a functional dark-themed frontend and a lightweight TCP server (`server_tcp.ps1`) backed primarily by browser `localStorage`. The table below outlines the transformation achieved in this master upgrade:

| Capability | Legacy Baseline | Master Upgrade Architecture | Impact |
| :--- | :--- | :--- | :--- |
| **Backend Runtime** | PowerShell 5.1 TcpListener | Node.js (v20 LTS) + Express.js REST API | High-throughput, non-blocking asynchronous I/O, enterprise maintainability |
| **Data Persistence** | Browser `localStorage` + JSON file | Supabase PostgreSQL (12 relational tables) | ACID compliance, referential integrity, multi-station query support |
| **Access Control** | Frontend role check + basic hash | Supabase Row Level Security (RLS) + JWT | Zero-trust backend policy; citizens cannot query police records or APIs |
| **Threat Intelligence** | Static pattern dictionary | Multi-Source OSINT Engine (VirusTotal, URLhaus, AbuseIPDB, Safe Browsing) | Real-world global threat telemetry combined with local heuristics |
| **SSRF Defense** | None | Kernel-level private IP & loopback block | Blocks AWS metadata (`169.254.169.254`), LAN probes (`10.0.0.0/8`), `127.0.0.1` |
| **Correlation** | In-memory client-side loop | Graph Correlation Engine across all complaints & IOCs | Automated detection of mule UPIs, repeated phones, and hosting syndicates |
| **Evidence Admissibility** | Client-generated HTML block | Section 65B IEA / Section 63 BSA Forensic Dossier with SHA-256 Custody Chain | Legally defensible electronic records admissible before trial courts |

---

## 3. System Architecture & Component Interactions

Suraksha Setu follows a decoupled 3-tier architecture with clean separation of presentation, business logic, threat intelligence pipelines, and relational persistence.

```
+-----------------------------------------------------------------------------------------+
|                                    PRESENTATION TIER                                    |
|  HTML5 Semantic Shell  *  Tailwind CSS & Glassmorphism  *  Vanilla ES6+ Client Engines  |
|  - index.html (Unified Gateway, Citizen Cockpit, Police Triage, Intel Graph, Evidence)  |
|  - js/app.js (SPA Router, Session Management, UI Synchronization, Chart.js Telemetry)   |
|  - js/analyzer.js (5-format Static Client Evaluator & Input Validator)                  |
|  - js/intelligence.js (Canvas-based Interactive Syndicate Relationship Graph)           |
|  - js/casemanager.js (Investigator Dossier Explorer, Triage Filters, Status Transitions)|
|  - js/evidence.js (Section 65B Print/PDF Forensic Generator with Cryptographic Hashes)  |
+--------------------------------------------+--------------------------------------------+
                                             | HTTP / REST (JSON)
                                             v
+-----------------------------------------------------------------------------------------+
|                                    APPLICATION TIER                                     |
|                              Node.js + Express.js Server                                |
|                                                                                         |
|  [ Middleware Pipeline ]                                                                |
|  - Helmet Security Headers (HSTS, CSP, X-Frame-Options)                                 |
|  - Express Rate Limiting (100 req/15min general; 10 req/15min auth/scan)                |
|  - Strict CORS Policy (Restricted to authorized frontend domains)                       |
|  - SSRF Defense Interceptor (Blocks RFC 1918 / loopback / cloud metadata)               |
|  - RBAC Middleware (Citizen vs Investigator vs Station Admin vs Prosecutor)             |
|                                                                                         |
|  [ Controller & Service Domain ]                                                        |
|  - AuthController: Salted PBKDF2/SHA-256 session issuance & role validation             |
|  - ScanController: Multi-format analysis orchestration & risk score calculation         |
|  - IntelService: VirusTotal v3, URLhaus, AbuseIPDB v2, Google Safe Browsing client      |
|  - CorrelationService: Cross-complaint IOC graph generator & syndicate cluster profiler |
|  - CaseController: Full case lifecycle management, assignment & status progression     |
|  - EvidenceController: Section 65B integrity hashing, storage, and custody logging      |
+--------------------------------------------+--------------------------------------------+
                                             | Connection Pool / Supabase SDK
                                             v
+-----------------------------------------------------------------------------------------+
|                                    DATA PERSISTENCE TIER                                |
|                               Supabase PostgreSQL Database                              |
|                                                                                         |
|  1. profiles             2. citizen_reports     3. police_cases     4. case_assignments |
|  5. threat_analyses      6. threat_indicators   7. report_indicators 8. evidence_files |
|  9. investigation_notes 10. audit_logs         11. intel_sources   12. api_usage_logs   |
|                                                                                         |
|  - Row Level Security (RLS) policies enforcing zero-trust data segregation             |
|  - Composite B-Tree & Hash Indexes on hashes, indicators, statuses, and foreign keys   |
|  - Automated database triggers for timestamp synchronization and counter increments     |
+-----------------------------------------------------------------------------------------+
```

---

## 4. Threat Intelligence & Scoring Engine

The threat evaluation pipeline implements a transparent, explainable 0–100 calibrated risk scoring algorithm. Scores are categorized into four tactical operational levels:

- **LOW (0–29):** Informational; no indicators of deceptive intent detected. Results displayed to citizen; no police case created.
- **MEDIUM (30–59):** Cautionary; suspicious heuristic patterns observed (e.g. newly registered TLD, unusual query parameters). Marked for optional citizen re-verification; not automatically escalated.
- **HIGH (60–79):** Confirmed Threat; high-confidence indicators of phishing, malware, or extortion detected. **Automatically registered into Police Cockpit** as a citizen report with status `New – Pending Police Review`.
- **CRITICAL (80–100):** Severe Threat; active credential harvester, malicious banking dropper, or known syndicate endpoint detected. Automatically escalated, assigned Priority 1, and flagged for emergency domain takedown / bank account freeze.

```
       +-------------------------------------------------------------+
       |             Incoming Digital Content / Artifact             |
       +-------------------------------------------------------------+
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
         v                            v                            v
   [ URL Engine ]              [ Message Engine ]            [ APK Engine ]
   - TLD Reputation            - Phone Extraction (+91)      - Dangerous Permissions
   - Shannon Entropy           - Mule UPI Extraction         - Accessibility Trojan Cues
   - Typosquatting / IDN       - Disconnection / Arrest Cues - Screen Overlay Cues
   - SSRF-Safe DNS Lookup      - Bank / KYC Freeze Cues      - Package Dropper Cues
         |                            |                            |
         +----------------------------+----------------------------+
                                      |
                                      v
                  +---------------------------------------+
                  |  Multi-Source OSINT Threat Intelligence |
                  |  - VirusTotal v3 Domain/URL/File Hash |
                  |  - URLhaus Active Malware Feeds       |
                  |  - AbuseIPDB v2 IP Confidence Score   |
                  |  - Google Safe Browsing Threat Alerts |
                  +---------------------------------------+
                                      |
                                      v
                  +---------------------------------------+
                  |   Calibrated Risk Score (0 - 100)     |
                  |  - Explainable Indicators List        |
                  |  - Forensic SHA-256 Evidence Hash     |
                  +---------------------------------------+
                                      |
                  +-------------------+-------------------+
                  |                                       |
           Score >= 60 (High/Critical)               Score < 60
                  |                                       |
                  v                                       v
      [ Auto-Submit to Police ]               [ Citizen Safety Advisory ]
      - Case ID: CR-2026-XXXX                 - Visual Risk Gauge
      - Status: Pending Review                - Immediate Safety Advice
      - Real-Time Investigator Alert
```

---

## 5. Security Posture & Zero-Trust Model

1. **Role-Based Access Control (RBAC):**
   - **Citizen:** Read/write own submitted scans and reports; strictly blocked from all police dossiers, suspect identities, internal investigation notes, and officer directories.
   - **Police Officer (Investigator / Analyst / Prosecutor):** Access assigned and open cases, triage queue, evidence repository, Section 65B generator, and correlation graph.
   - **Admin (ACP / Supervisory Officer):** Full administrative controls, audit log inspection, officer onboarding, and system configuration.
2. **Server-Side Request Forgery (SSRF) Defense:**
   - All URL analysis routines parse and resolve the target hostname before issuing any network requests.
   - Prohibits resolution to IPv4 loopback (`127.0.0.0/8`), RFC 1918 private subnets (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`), link-local metadata addresses (`169.254.169.254`), and IPv6 localhost (`::1`).
3. **Cryptographic Chain of Custody:**
   - Every uploaded artifact or captured threat report is hashed using SHA-256 (`crypto.subtle` / Node.js `crypto`).
   - Hash values are permanently recorded in `evidence_files` and `police_cases` with immutable timestamps.
4. **Section 65B Legal Admissibility:**
   - Automated generation of technical certificates complying with Section 65B of the Indian Evidence Act, 1872 / Section 63 of the Bharatiya Sakshya Adhiniyam, 2023.
   - Captures system parameters, hash values, officer declarations, and tamper-verification checksums.

---

## 6. Directory Structure Overview

```
udy/
|-- ARCHITECTURE.md                 # System Architecture & Technical Specifications
|-- DATABASE_SCHEMA.md             # Supabase PostgreSQL 12-Table Schema Documentation
|-- DATABASE_SCHEMA.sql            # Executable PostgreSQL DDL with RLS & Triggers
|-- API_INTEGRATION.md             # REST API Reference & Threat Intel Documentation
|-- SECURITY.md                    # Zero-Trust Security, SSRF & Section 65B Compliance
|-- TESTING.md                     # Comprehensive 20-Scenario Test Plan & Results
|-- README.md                      # Hackathon Overview & Deployment Instructions
|-- .env.example                   # Environment Variable Template
|-- index.html                     # Unified Application Shell & Dashboards
|-- css/
|   `-- styles.css                 # Dark Navy-Blue Glassmorphic Theme & Print Rules
|-- js/
|   |-- app.js                     # Main SPA Router, Auth & Telemetry Controller
|   |-- data.js                    # Persistence Layer & Supabase/Offline Store
|   |-- analyzer.js                # 5-Format Static Threat Evaluation Engine
|   |-- intelligence.js            # Syndicate Correlation Graph & Canvas Visualizer
|   |-- casemanager.js             # Case Triage, Filtering & Dossier Manager
|   |-- evidence.js                # Section 65B Forensic Evidence Report Generator
|   `-- tests.js                   # Automated Test Suite Runner (CYBER-T01 to T20)
`-- backend/
    |-- package.json               # Express, Supabase SDK, Axios, Helmet, CORS
    |-- server.js                  # Master Express API Server & Static Host
    `-- src/
        |-- config/                # Supabase & Environment Configuration
        |-- middleware/            # Auth, RBAC, SSRF Protection, Rate Limiting
        |-- routes/                # Auth, Scan, Cases, Intel, Evidence Routes
        |-- controllers/           # Endpoint Request Handlers
        `-- services/              # Threat Intel, URL Analysis, NLP & Graph Services
```
