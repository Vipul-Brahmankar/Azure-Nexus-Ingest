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
