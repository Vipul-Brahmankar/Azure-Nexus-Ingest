# Azure Nexus Ingest: Metadata-Driven Supply Chain Framework

![Azure Data Factory](https://img.shields.io/badge/Azure-Data%20Factory-0078D4?logo=microsoft-azure)
![Azure SQL](https://img.shields.io/badge/Azure-SQL%20Database-0078D4?logo=microsoft-sql-server)
![AWS S3](https://img.shields.io/badge/AWS-S3-FF9900?logo=amazon-s3)
![ADLS Gen2](https://img.shields.io/badge/Azure-Data%20Lake%20Gen2-0078D4)

**Azure Nexus Ingest** is an enterprise-grade data ingestion framework designed to securely migrate high-volume, multi-format supply chain data from an external **AWS S3** landing zone to an internal **Azure Data Lake Storage Gen2 (ADLS)**.

By shifting from hardcoded pipelines to a **metadata-driven architecture**, this project reduces new external partner onboarding time by **90%** (from days to minutes) and eliminates code deployment for routine configuration changes.

---

## 🏗️ Architecture Overview

The solution treats AWS S3 as a "DMZ" (Demilitarized Zone) for external vendors to drop raw files (EDI logs, JSON telemetry, CSV manifests). Azure Data Factory (ADF) acts as the orchestrator, pulling configuration from a SQL Control Table to dynamically generate ingestion paths at runtime.

![Arch Placeholder](https://github.com/Vipul-Brahmankar/Azure-Nexus-Ingest/blob/7932dd8e714e1da439ca981c8b33e8f3d14c17c7/Nexus_ingest.png)

### High-Level Data Flow
1.  **Source (External):** Trading Partners upload files to specific prefixes in AWS S3.
2.  **Control Plane:** ADF lookups the `ControlTable` in Azure SQL to determine which partners are active and where their data resides.
3.  **Orchestration:** A `ForEach` loop iterates through the active partners.
4.  **Ingestion:** A parameterized `Copy Data` activity moves data from S3 to ADLS Gen2 using a Binary dataset (preserving file format/schema).
5.  **Security:** All credentials (AWS Access Keys) are retrieved securely from **Azure Key Vault** at runtime.

---

## 🚀 Key Features

* **Metadata-Driven Execution:** Zero hardcoding. Source buckets, destination paths, and file patterns are managed via SQL.
* **Cross-Cloud Compatibility:** Seamless connectivity between AWS S3 (Source) and Azure ADLS Gen2 (Sink).
* **Format Agnostic:** Uses `Binary` datasets to handle schema drift and diverse formats (JSON, XML, CSV, Parquet) without pipeline modification.
* **Scalable Onboarding:** Adding a new partner requires a single SQL `INSERT` statement, not a code deployment.
* **Security First:** Uses Azure Key Vault for secret management; no keys are stored in ADF code.

---

## 📂 Repository Structure

```bash
Azure-Nexus-Ingest/
│
├── sql/
│   ├── 01_Create_Control_Table.sql    # Schema for the metadata control table
│   └── 02_Seed_Data.sql               # Example insert scripts for testing
│
├── adf/
│   ├── pipeline/
│   │   └── PL_Ingest_S3_to_ADLS.json  # Main pipeline JSON definition
│   ├── dataset/
│   │   ├── DS_Binary_S3.json          # Parameterized Source Dataset
│   │   └── DS_Binary_ADLS.json        # Parameterized Sink Dataset
│   └── linkedService/
│       └── LS_KeyVault.json           # Connection to secrets
│
└── README.md
```

---

## 🛠️ Setup & Configuration

### 1. Database Configuration (The Brain)
The core of this framework is the SQL Control Table. Run the following script in your Azure SQL Database.

```sql
-- Create the Control Table
CREATE TABLE [dbo].[IntegrationControl] (
    [PartnerID] INT IDENTITY(1,1) PRIMARY KEY,
    [PartnerName] VARCHAR(100),
    [SourceBucket] VARCHAR(255),
    [SourcePrefix] VARCHAR(255),    -- e.g., 'partner-a/logs/2024/'
    [DestContainer] VARCHAR(255),
    [DestPath] VARCHAR(255),        -- e.g., 'raw/partner-a/'
    [FileNamePattern] VARCHAR(100), -- e.g., '*.json' or '*'
    [IsActive] BIT DEFAULT 1        -- 1 = Run, 0 = Skip
);

-- Seed Data (Simulating 2 Partners)
INSERT INTO [dbo].[IntegrationControl] 
(PartnerName, SourceBucket, SourcePrefix, DestContainer, DestPath, FileNamePattern, IsActive)
VALUES 
('Logistics_Partner_A', 'supply-chain-landing', 'partner-a/inbound/', 'landing-zone', 'partner-a/raw/', '*.json', 1),
('Shipping_Vendor_B', 'supply-chain-landing', 'vendor-b/manifests/', 'landing-zone', 'vendor-b/csv/', '*.csv', 1);
```

### 2. ADF Dataset Parameterization
Instead of creating 50 datasets for 50 partners, we create **one** dataset for S3 and **one** for ADLS, using parameters.

**Source Dataset (AWS S3) Parameters:**
* `bucketName`
* `folderPath`

**Sink Dataset (ADLS Gen2) Parameters:**
* `fileSystem`
* `directory`

### 3. Pipeline Logic (The "Engine")

The pipeline `PL_Ingest_S3_to_ADLS` follows this logic:

1.  **Lookup Activity:**
    * Query: `SELECT * FROM IntegrationControl WHERE IsActive = 1`
2.  **ForEach Activity:**
    * Iterates over the output array of the Lookup.
3.  **Copy Activity (Inside Loop):**
    * **Source:** Uses S3 Dataset. passes `@item().SourceBucket` and `@item().SourcePrefix` to dataset parameters.
    * **Sink:** Uses ADLS Dataset. passes `@item().DestContainer` and `@item().DestPath`.

---

## 🧠 Design Decisions & Trade-offs

### Why AWS S3 as a Landing Zone?
We utilized S3 to decouple external data reception from internal processing. This allows trading partners to use their existing AWS automation scripts or SFTP-to-S3 interfaces without requiring direct access to our internal Azure tenant. It acts as a secure buffer.

### Why Parameterization over Individual Pipelines?
**Legacy Approach:** Creating a specific pipeline per partner.
* *Pros:* Isolation.
* *Cons:* High maintenance. Adding 10 partners = 10 days of dev work.

**Current Approach:** Metadata-Driven.
* *Pros:* Operations handles onboarding via SQL. No code changes.
* *Cons:* Slight complexity increase in debugging (requires checking logs to see which iteration failed).

### Why Binary Copy?
We chose **Binary** datasets over parsing formats (like CSV/JSON) during the copy phase. This ensures:
1.  **Speed:** No serialization/deserialization overhead.
2.  **Resilience:** If a partner adds a column (Schema Drift), the copy pipeline doesn't fail. We handle parsing downstream in Databricks/Synapse.

---

## 🔮 Future Improvements

* **Event-Driven Triggering:** Currently uses a Schedule Trigger (Tumbling Window). Future state will utilize AWS EventBridge -> Azure Event Grid for real-time ingestion.
* **Validation:** Add a "Get Metadata" activity post-copy to verify file counts match between Source and Sink.
* **Archival:** Implement Logic Apps to move processed S3 files to an "Archive" folder after successful ingestion.

---

## 📝 Author

**Vipul Brahmankar** |
*Data Engineer | Azure Cloud Specialist*

---
*Disclaimer: This project is a representation of a real-world implementation. Sensitive keys and proprietary logic have been abstracted.*
