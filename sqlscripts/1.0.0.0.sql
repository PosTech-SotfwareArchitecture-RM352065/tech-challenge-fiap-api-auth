IF(OBJECT_ID('CustomerRequests') IS NOT NULL) DROP TABLE CustomerRequests
IF(OBJECT_ID('Customers') IS NOT NULL) DROP TABLE Customers
IF(OBJECT_ID('dbo.Sp_AddCustomer') IS NOT NULL) DROP PROCEDURE dbo.Sp_AddCustomer
IF(OBJECT_ID('dbo.Sp_ValidateLogin') IS NOT NULL) DROP PROCEDURE dbo.Sp_ValidateLogin

CREATE TABLE Customers (
    Id          UNIQUEIDENTIFIER    NOT NULL
,   CPF         VARCHAR(11)         NOT NULL
,   [Name]      VARCHAR(50)         NOT NULL
,   Email       VARCHAR(50)         NOT NULL
,   [Password]  BINARY(64)          NOT NULL
,   [Active]    BIT                 NOT NULL DEFAULT(1)
,   CONSTRAINT Pk_Customer PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Uk1_Customer UNIQUE CLUSTERED (CPF)
)
GO

CREATE TABLE CustomerRequests (    
    Id              UNIQUEIDENTIFIER    NOT NULL
,   CustomerId      UNIQUEIDENTIFIER    NOT NULL
,   RequestedAt     DATETIME            NOT NULL
,   [Type]          VARCHAR(15)         NOT NULL
,   [Status]        VARCHAR(15)         NOT NULL DEFAULT ('REQUESTED')
,   [Comments]      VARCHAR(200)        NULL
,   CONSTRAINT Pk_CustomerRequests PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Fk1_CustomerRequests FOREIGN KEY (CustomerId) REFERENCES Customers (Id)
)
GO


CREATE PROCEDURE dbo.Sp_AddCustomer
    @Id              UNIQUEIDENTIFIER
,   @CPF             VARCHAR(11)
,   @Name            VARCHAR(50)
,   @Email           VARCHAR(50)
,   @Password        NVARCHAR(50)

AS
BEGIN
    INSERT INTO dbo.Customers (Id, CPF, Name, Email, Password, Active)
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
             FROM dbo.Customers 
            WHERE Cpf = @Username
              AND Active = 1
              AND [Password] = HASHBYTES('SHA2_512', @Password + CAST(Id AS NVARCHAR(36))))
END
GO