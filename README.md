# SURAKSHA SETU (सुरक्षा सेतु)
## AI-Powered Cyber Fraud Intelligence & Investigation Platform
### Designed for State Police Cyber Crime Divisions & Citizen Protection
**Target Problem Statement:** Rajasthan Police Cyber Security Hackathon — Cyber Fraud / Phishing / Malicious Apps  
**Platform Version:** 2.0.0 (Enterprise Upgrade)  
**Live Public Demo:** [https://2b0f8664399b89.app.lhr.life](https://2b0f8664399b89.app.lhr.life)

---

## 🛡️ Executive Summary

**Suraksha Setu** transforms isolated citizen cyber scam complaints into actionable, explainable, and legally admissible cybercrime intelligence. Built for modern law enforcement agencies, the platform bridges citizen protection with police intelligence workflows:
1. **Citizen Portal:** A clean, intuitive gateway for ordinary citizens to scan suspicious URLs, phishing SMS/WhatsApp lures, fraudulent APKs, and payment requests, receiving instant explainable safety guidance. High-risk threats are **automatically registered** into the Police Investigation Dashboard.
2. **Police Cockpit:** A command dashboard for cyber investigators, intelligence analysts, and station supervisory officers providing a real-time high-risk triage queue, multi-source OSINT threat intelligence, cross-complaint syndicate correlation, and Section 65B Indian Evidence Act compliant forensic reports.

---

## 🚀 Key Innovations & Features

### 1. Multi-Format Threat Analysis Center
- **Suspicious Message Analysis:** Natural language processing that extracts Indian mobile numbers (+91), mule UPI IDs (`@oksbi`, `@paytm`, `@ybl`), URLs, and detects urgency patterns (electricity disconnection, digital arrest, KBC lottery, bank freeze).
- **Advanced URL Scanner:** 0–100 calibrated risk scoring, TLD reputation (.xyz, .top, .icu vs .in, .gov.in), brand typosquatting heuristics (SBI, HDFC, Income Tax), Shannon entropy for DGA detection, and SSRF firewall protection.
- **Android APK Static Analyzer:** Evaluates dangerous permissions (Accessibility Service trojans, SMS interception, deceptive screen overlays, dropper capabilities) and decompiled C2 strings.
- **App-Store Link Analysis:** Verifies developer domain legitimacy, privacy policy compliance, and loan app naming patterns against RBI digital lending guidelines.
- **Government Impersonation Detector:** Identifies deceptive portals spoofing the Ministry of Home Affairs (MHA), CBI, or State Police seals.

### 2. Multi-Source Threat Intelligence Engine
- **VirusTotal v3 Integration:** URL scan stats, domain reputation, and multi-vendor antivirus verdicts.
- **URLhaus API Integration:** Real-time query against abuse.ch active malware repository.
- **AbuseIPDB v2 Integration:** IP abuse confidence scores, reporting history, and geolocation.
- **Google Safe Browsing v4:** Cross-checks against Google social engineering and deceptive site blacklists.
- **High-Fidelity Demo Fallback:** Operates with rich deterministic intelligence when external API keys are omitted, ensuring seamless hackathon demonstration resilience.

### 3. Cybercrime Correlation & Syndicate Engine
- **Cross-Complaint IOC Mapping:** Aggregates indicators across citizen scans and police cases.
- **Automated Syndicate Clustering:** Identifies organized rings (e.g. *Operation ElectroLocker*, *Operation ShadowBank*, *Predatory Loan Ring*) sharing the same mule UPI handles, call center phone numbers, or bulletproof hosting servers.
- **Interactive Force-Directed Threat Graph:** Canvas-based interactive visualization showing connections between victims, complaints, indicators, and syndicates.

### 4. Section 65B Electronic Evidence Management
- **Cryptographic Chain of Custody:** Calculates and permanently stores SHA-256 bitstream digests of all analyzed evidence.
- **Court-Admissible Electronic Certificates:** Generates technical certificates complying with Section 65B(4) of the Indian Evidence Act, 1872 / Section 63 of the Bharatiya Sakshya Adhiniyam, 2023.
- **High-Contrast Print/Export Stylesheet:** Clean printable forensic reports ready for judicial submission.

### 5. Unified Glassmorphic Portal & Strict RBAC
- Single unified gateway card with role selection tabs (`👤 Public / Citizen` and `🛡️ Police Officer`).
- Server-side role verification with salted password hashing.
- Strict route protection: citizens cannot navigate to police views, police dossiers, or administrative tools.

---

## 🏛️ System Architecture

```
+---------------------------------------------------------------------------------------+
|                                    SURAKSHA SETU                                      |
+-------------------------------------------+-------------------------------------------+
|             CITIZEN INTERFACE             |             POLICE COCKPIT                |
|  - Unified Glassmorphic Gateway           |  - High/Critical Risk Triage Queue        |
|  - Multi-Format Threat Scanner            |  - Deep Threat Analysis & Scoring (0-100) |
|  - Real-Time Explainable Findings         |  - Multi-Source OSINT Threat Intel Feeds  |
|  - Automatic High-Risk Incident Escalation|  - Cross-Case Syndicate Correlation Graph |
|  - Complaint Status Tracking & Advisory   |  - Section 65B/63 Electronic Evidence Gen |
|  - Clean Minimalist Navy-Blue UI          |  - Role-Based Case Lifecycle Management   |
+-------------------------------------------+-------------------------------------------+
                                     |
                                     v
+---------------------------------------------------------------------------------------+
|                           ENTERPRISE BACKEND ARCHITECTURE                             |
|  - Node.js (v20 LTS) + Express.js REST API                                            |
|  - Supabase PostgreSQL (12 Relational Tables, RLS Policies, Indexes, Triggers)        |
|  - Multi-Engine Threat Intel (VirusTotal v3, URLhaus, AbuseIPDB v2, Safe Browsing)     |
|  - SSRF-Protected Static Analyzers & Heuristic NLP Social Engineering Classifier      |
|  - Deterministic Fallback & Offline Standalone Demonstration Resilience               |
+---------------------------------------------------------------------------------------+
```

---

## 📁 Project Documentation

Detailed technical documentation is provided across dedicated specification files:

- [ARCHITECTURE.md](file:///c:/Users/Ashok%20Bairwa/OneDrive/Desktop/udy/ARCHITECTURE.md) — System Architecture, Data Flow & Component Model
- [DATABASE_SCHEMA.md](file:///c:/Users/Ashok%20Bairwa/OneDrive/Desktop/udy/DATABASE_SCHEMA.md) — 12-Table Relational Schema & Row Level Security
- [DATABASE_SCHEMA.sql](file:///c:/Users/Ashok%20Bairwa/OneDrive/Desktop/udy/DATABASE_SCHEMA.sql) — Executable PostgreSQL DDL with Indexes and Triggers
- [API_INTEGRATION.md](file:///c:/Users/Ashok%20Bairwa/OneDrive/Desktop/udy/API_INTEGRATION.md) — REST API Endpoints & Request/Response Payloads
- [SECURITY.md](file:///c:/Users/Ashok%20Bairwa/OneDrive/Desktop/udy/SECURITY.md) — Zero-Trust Security, SSRF Firewall & Section 65B Compliance
- [TESTING.md](file:///c:/Users/Ashok%20Bairwa/OneDrive/Desktop/udy/TESTING.md) — 20-Scenario Benchmark Test Suite & Execution Results
- [.env.example](file:///c:/Users/Ashok%20Bairwa/OneDrive/Desktop/udy/.env.example) — Environment Variable Configuration Template

---

## ⚡ Quickstart & Local Setup

### Prerequisites
- Node.js (v18+ or v20 LTS)
- npm (v9+)
- Any modern web browser (Chrome, Edge, Firefox, Safari)

### 1. Installation
Clone the repository and install backend dependencies:
```bash
git clone https://github.com/your-org/suraksha-setu.git
cd suraksha-setu/backend
npm install
```

### 2. Environment Configuration
Create a `.env` file in the root or `backend/` directory:
```bash
cp .env.example backend/.env
```
*(Configure optional API keys for VirusTotal, AbuseIPDB, URLhaus, and Supabase. If left blank, the platform automatically activates high-fidelity demo simulation mode).*

### 3. Start Application
```bash
npm start
```
The application will launch on `http://localhost:8088`.

---

## 🔑 Demo Credentials

| Role | Username / Badge ID | Password | Access Scope |
| :--- | :--- | :--- | :--- |
| **Police Investigator** | `DL-CY-8412` (or `r.sharma@delhipolice.gov.in`) | `cybercop2026` | Full Police Cockpit, Cases, Threat Intel, Evidence |
| **Police Supervisor (Admin)**| `OFF-1002` (or `sunita.rao@delhipolice.gov.in`) | `cybercop2026` | Full Administrative Privileges & Audit Logs |
| **Citizen** | `amit.patel@gmail.com` | `citizen123` | Citizen Dashboard, Multi-Format Scanner, Report History |
| **New Citizen** | Click "Create New Account" in Unified Portal | User-chosen | Self-registered Citizen Account |

---

## 🏆 Hackathon Alignment

- **Category:** Rajasthan Police Cyber Security Hackathon — Cyber Fraud / Phishing / Malicious Apps
- **Statutory Alignment:** Complies with Section 65B Indian Evidence Act, Section 63 Bharatiya Sakshya Adhiniyam (BSA) 2023, and IT Act Section 69A / 91 CrPC workflows.
- **Operational Impact:** Reduces complaint triage turnaround from hours to seconds; automates digital evidence hashing; discovers hidden criminal syndicates across inter-state police jurisdictions.
