-- Seed Data (Simulating 2 Partners)
INSERT INTO [dbo].[IntegrationControl] 
(PartnerName, SourceBucket, SourcePrefix, DestContainer, DestPath, FileNamePattern, IsActive)
VALUES 
('Logistics_Partner_A', 'supply-chain-landing', 'partner-a/inbound/', 'landing-zone', 'partner-a/raw/', '*.json', 1),
('Shipping_Vendor_B', 'supply-chain-landing', 'vendor-b/manifests/', 'landing-zone', 'vendor-b/csv/', '*.csv', 1);
