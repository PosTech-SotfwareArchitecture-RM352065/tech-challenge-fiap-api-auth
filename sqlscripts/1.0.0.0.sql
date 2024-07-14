IF(OBJECT_ID('CostumerRequests') IS NOT NULL) DROP TABLE CostumerRequests
IF(OBJECT_ID('Costumers') IS NOT NULL) DROP TABLE Costumers
IF(OBJECT_ID('dbo.Sp_AddCostumer') IS NOT NULL) DROP PROCEDURE dbo.Sp_AddCostumer
IF(OBJECT_ID('dbo.Sp_ValidateLogin') IS NOT NULL) DROP PROCEDURE dbo.Sp_ValidateLogin

CREATE TABLE Costumers (
    Id          UNIQUEIDENTIFIER    NOT NULL
,   CPF         VARCHAR(11)         NOT NULL
,   [Name]      VARCHAR(50)         NOT NULL
,   Email       VARCHAR(50)         NOT NULL
,   [Password]  BINARY(64)          NOT NULL
,   [Active]    BIT                 NOT NULL DEFAULT(1)
,   CONSTRAINT Pk_Costumer PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Uk1_Costumer UNIQUE CLUSTERED (CPF)
)
GO

CREATE TABLE CostumerRequests (    
    Id          UNIQUEIDENTIFIER    NOT NULL
,   CostumerId  UNIQUEIDENTIFIER    NOT NULL
,   RequestedAt DATETIME            NOT NULL
,   [Type]      VARCHAR(10)         NOT NULL
,   [Status]    VARCHAR(10)         NOT NULL DEFAULT ('REQUESTED')
,   [Comments]  VARCHAR(200)        NULL
,   CONSTRAINT Pk_Costumer PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Fk1_Costumer FOREIGN KEY (CostumerId) REFERENCES Costumers (Id)
)
GO


CREATE PROCEDURE dbo.Sp_AddCostumer
    @Id              UNIQUEIDENTIFIER
,   @CPF             VARCHAR(11)
,   @Name            VARCHAR(50)
,   @Email           VARCHAR(50)
,   @Password        NVARCHAR(50)

AS
BEGIN
    INSERT INTO dbo.Costumers (Id, CPF, Name, Email, Password, Active)
    VALUES(@Id, @CPF, @Name, @Email, HASHBYTES('SHA2_512', @Password + CAST(@Id AS NVARCHAR(36))), 1)
END
GO

CREATE PROCEDURE dbo.Sp_ValidateLogin
    @Username       VARCHAR(11)
,   @Password       NVARCHAR(50)
,   @Id             UNIQUEIDENTIFIER OUTPUT

AS
BEGIN

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SET @Id
        = (SELECT TOP 1 Id
             FROM dbo.Costumers 
            WHERE Cpf = @Username
              AND Active = 1
              AND [Password] = HASHBYTES('SHA2_512', @Password + CAST(Id AS NVARCHAR(36))))
END
GO