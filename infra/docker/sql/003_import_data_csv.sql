USE [MappingDW];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

/* Clean current data (respect FK order) */
DELETE FROM dbo.Transformacion;
DELETE FROM dbo.Mapping;
DELETE FROM dbo.RelacionJclMainframeApp;
DELETE FROM dbo.Etl;
DELETE FROM dbo.[Sequence];
DELETE FROM dbo.MainframeApp;
DELETE FROM dbo.Columna;
DELETE FROM dbo.Tabla;
DELETE FROM dbo.Aplicacion;
DELETE FROM dbo.ReglasModelado;
DELETE FROM dbo.TipoEsquema;
DELETE FROM dbo.TipoServer;
DELETE FROM dbo.TipoDato;
DELETE FROM dbo.TipoMotorBaseDeDatos;
DELETE FROM dbo.Jcl;

/* Load CSVs */
SET IDENTITY_INSERT dbo.TipoMotorBaseDeDatos ON;
BULK INSERT dbo.TipoMotorBaseDeDatos
FROM '/var/opt/mssql/import/TipoMotorBaseDeDatos.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.TipoMotorBaseDeDatos OFF;

SET IDENTITY_INSERT dbo.TipoServer ON;
BULK INSERT dbo.TipoServer
FROM '/var/opt/mssql/import/TipoServer.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.TipoServer OFF;

SET IDENTITY_INSERT dbo.TipoEsquema ON;
BULK INSERT dbo.TipoEsquema
FROM '/var/opt/mssql/import/TipoEsquema.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.TipoEsquema OFF;

SET IDENTITY_INSERT dbo.TipoDato ON;
BULK INSERT dbo.TipoDato
FROM '/var/opt/mssql/import/TipoDato.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.TipoDato OFF;

SET IDENTITY_INSERT dbo.ReglasModelado ON;
BULK INSERT dbo.ReglasModelado
FROM '/var/opt/mssql/import/ReglasModelado.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.ReglasModelado OFF;

SET IDENTITY_INSERT dbo.Aplicacion ON;
BULK INSERT dbo.Aplicacion
FROM '/var/opt/mssql/import/Aplicacion.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.Aplicacion OFF;

SET IDENTITY_INSERT dbo.Tabla ON;
BULK INSERT dbo.Tabla
FROM '/var/opt/mssql/import/tabla.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.Tabla OFF;

SET IDENTITY_INSERT dbo.Columna ON;
BULK INSERT dbo.Columna
FROM '/var/opt/mssql/import/Columna.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.Columna OFF;

SET IDENTITY_INSERT dbo.Jcl ON;
BULK INSERT dbo.Jcl
FROM '/var/opt/mssql/import/jcl.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.Jcl OFF;

SET IDENTITY_INSERT dbo.[Sequence] ON;
BULK INSERT dbo.[Sequence]
FROM '/var/opt/mssql/import/Sequence.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.[Sequence] OFF;

SET IDENTITY_INSERT dbo.Etl ON;
BULK INSERT dbo.Etl
FROM '/var/opt/mssql/import/etl.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.Etl OFF;

SET IDENTITY_INSERT dbo.MainframeApp ON;
BULK INSERT dbo.MainframeApp
FROM '/var/opt/mssql/import/MainframeApp.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.MainframeApp OFF;

SET IDENTITY_INSERT dbo.RelacionJclMainframeApp ON;
BULK INSERT dbo.RelacionJclMainframeApp
FROM '/var/opt/mssql/import/RelacionJclMainframeApp.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.RelacionJclMainframeApp OFF;

SET IDENTITY_INSERT dbo.Mapping ON;
BULK INSERT dbo.Mapping
FROM '/var/opt/mssql/import/mapping.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS,
    KEEPIDENTITY
);
SET IDENTITY_INSERT dbo.Mapping OFF;

CREATE TABLE #TransformacionRaw
(
    c1 NVARCHAR(100) NULL,
    c2 NVARCHAR(100) NULL,
    c3 NVARCHAR(100) NULL,
    c4 NVARCHAR(100) NULL,
    c5 NVARCHAR(100) NULL,
    c6 NVARCHAR(MAX) NULL,
    c7 NVARCHAR(MAX) NULL,
    c8 NVARCHAR(100) NULL,
    c9 NVARCHAR(100) NULL,
    c10 NVARCHAR(MAX) NULL,
    c11 NVARCHAR(MAX) NULL,
    c12 NVARCHAR(MAX) NULL,
    c13 NVARCHAR(MAX) NULL
);

BULK INSERT #TransformacionRaw
FROM '/var/opt/mssql/import/Transformacion.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0d0a',
    KEEPNULLS
);

SET IDENTITY_INSERT dbo.Transformacion ON;
INSERT INTO dbo.Transformacion
(
    Id,
    MappingId,
    CampoOrigenId,
    CampoDestinoId,
    Posicion,
    TransformacionMapping,
    Relacion,
    fechaCreacion,
    fechaModificacion,
    usuarioCreacion,
    usuarioModificacion,
    CampoOrigenComentario,
    CampoDestinoComentario
)
SELECT
    TRY_CONVERT(INT, c1),
    TRY_CONVERT(INT, c2),
    TRY_CONVERT(INT, NULLIF(c3, 'NULL')),
    TRY_CONVERT(INT, NULLIF(c4, 'NULL')),
    TRY_CONVERT(INT, c5),
    NULLIF(NULLIF(c6, ''), 'NULL'),
    NULLIF(NULLIF(c7, ''), 'NULL'),
    TRY_CONVERT(DATETIME2, c8),
    TRY_CONVERT(DATETIME2, c9),
    NULLIF(NULLIF(c10, ''), 'NULL'),
    NULLIF(NULLIF(c11, ''), 'NULL'),
    NULLIF(NULLIF(c12, ''), 'NULL'),
    NULLIF(NULLIF(c13, ''), 'NULL')
FROM #TransformacionRaw;
SET IDENTITY_INSERT dbo.Transformacion OFF;

DROP TABLE #TransformacionRaw;

COMMIT TRANSACTION;
GO
