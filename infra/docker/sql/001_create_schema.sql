/* ============================================================
   MappingDW - Schema bootstrap (DB + tables + FKs)
   Target: SQL Server
   ============================================================ */

DECLARE @DbName SYSNAME = N'MappingDW';

IF DB_ID(@DbName) IS NULL
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'CREATE DATABASE ' + QUOTENAME(@DbName) + N';';
    EXEC sp_executesql @sql;
END
GO

USE [MappingDW];
GO

/* ============================================================
   Lookup tables
   ============================================================ */

IF OBJECT_ID('dbo.TipoMotorBaseDeDatos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TipoMotorBaseDeDatos (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoMotorBaseDeDatos PRIMARY KEY,
        Nombre NVARCHAR(MAX) NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL
    );
END
GO

IF OBJECT_ID('dbo.TipoServer', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TipoServer (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoServer PRIMARY KEY,
        Nombre NVARCHAR(MAX) NOT NULL,
        TipoMotorBaseDeDatosId INT NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL
    );
END
GO

IF OBJECT_ID('dbo.TipoEsquema', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TipoEsquema (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoEsquema PRIMARY KEY,
        Nombre NVARCHAR(MAX) NOT NULL,
        TipoServerId INT NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL
    );
END
GO

IF OBJECT_ID('dbo.TipoDato', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TipoDato (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoDato PRIMARY KEY,
        Nombre NVARCHAR(MAX) NOT NULL,
        NecesitaLongitud BIT NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL
    );
END
GO

IF OBJECT_ID('dbo.ReglasModelado', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReglasModelado (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ReglasModelado PRIMARY KEY,
        Sufijo CHAR(10) NOT NULL,
        Descripcion NVARCHAR(MAX) NOT NULL,
        Nulleable BIT NOT NULL,
        ValorDefault NVARCHAR(MAX) NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NOT NULL,
        usuarioModificacion NVARCHAR(MAX) NOT NULL
    );
END
GO

/* ============================================================
   Core tables
   ============================================================ */

IF OBJECT_ID('dbo.Aplicacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Aplicacion (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Aplicacion PRIMARY KEY,
        Nombre NVARCHAR(MAX) NOT NULL,
        Descripcion NVARCHAR(MAX) NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL,
        Estado INT NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Tabla', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Tabla (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Tabla PRIMARY KEY,
        Nombre NVARCHAR(MAX) NOT NULL,
        Descripcion NVARCHAR(MAX) NOT NULL,
        AplicacionId INT NOT NULL,
        TipoMotorBaseDeDatosId INT NOT NULL,
        TipoServerId INT NOT NULL,
        TipoEsquemaId INT NOT NULL,
        Estado INT NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL,
        Tipo INT NOT NULL,
        ResguardoHistorico BIT NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Columna', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Columna (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Columna PRIMARY KEY,
        numeroOrden INT NOT NULL,
        Nombre NVARCHAR(MAX) NOT NULL,
        Descripcion NVARCHAR(MAX) NOT NULL,
        TipoDatoId INT NOT NULL,
        Longitud NVARCHAR(MAX) NULL,
        Nullable BIT NOT NULL,
        ClavePrimaria BIT NOT NULL,
        IndicePrimario BIT NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL,
        TablaId INT NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Jcl', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Jcl (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Jcl PRIMARY KEY,
        NombreJcl NVARCHAR(510) NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Sequence', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Sequence (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sequence PRIMARY KEY,
        JclId INT NOT NULL,
        NombreSequence NVARCHAR(510) NOT NULL,
        Tipo VARCHAR(10) NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Etl', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Etl (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Etl PRIMARY KEY,
        SequenceId INT NOT NULL,
        NombreEtl NVARCHAR(510) NOT NULL,
        NombreHilo2 NVARCHAR(510) NOT NULL,
        Tipo NVARCHAR(510) NOT NULL,
        Paso INT NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.MainframeApp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MainframeApp (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MainframeApp PRIMARY KEY,
        NombreMainframeApp NVARCHAR(510) NOT NULL,
        Periodicidad NVARCHAR(510) NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.RelacionJclMainframeApp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RelacionJclMainframeApp (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RelacionJclMainframeApp PRIMARY KEY,
        MainframeAppId INT NOT NULL,
        JclId INT NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Mapping', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Mapping (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Mapping PRIMARY KEY,
        Nombre NVARCHAR(MAX) NOT NULL,
        Descripcion NVARCHAR(MAX) NULL,
        ArchivoOrigen NVARCHAR(MAX) NULL,
        Responsable NVARCHAR(MAX) NOT NULL,
        Estado INT NOT NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL,
        Frecuencia INT NOT NULL,
        EtlId INT NOT NULL,
        TablaDestinoId INT NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Transformacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Transformacion (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Transformacion PRIMARY KEY,
        MappingId INT NOT NULL,
        CampoOrigenId INT NULL,
        CampoDestinoId INT NULL,
        Posicion INT NOT NULL,
        TransformacionMapping NVARCHAR(MAX) NULL,
        Relacion NVARCHAR(MAX) NULL,
        fechaCreacion DATETIME2 NOT NULL,
        fechaModificacion DATETIME2 NOT NULL,
        usuarioCreacion NVARCHAR(MAX) NULL,
        usuarioModificacion NVARCHAR(MAX) NULL,
        CampoOrigenComentario NVARCHAR(MAX) NULL,
        CampoDestinoComentario NVARCHAR(MAX) NULL
    );
END
GO

IF OBJECT_ID('dbo.AuditLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLog (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLog PRIMARY KEY,
        Fecha DATETIME NOT NULL,
        Usuario NVARCHAR(200) NOT NULL,
        Accion NVARCHAR(20) NOT NULL,
        Entidad NVARCHAR(100) NOT NULL,
        EntidadId INT NOT NULL,
        MappingId INT NULL,
        MappingNombre NVARCHAR(300) NULL,
        TablaId INT NULL,
        TablaNombre NVARCHAR(300) NULL,
        ColumnaId INT NULL,
        ColumnaNombre NVARCHAR(300) NULL,
        TransformacionId INT NULL,
        ValoresInicial NVARCHAR(MAX) NULL,
        ValoresFinal NVARCHAR(MAX) NULL
    );
END
GO

IF OBJECT_ID('dbo.tmp_CamposConDescripciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tmp_CamposConDescripciones (
        LINEA INT NOT NULL,
        ARCHIVO VARCHAR(MAX) NULL,
        FIELD01 VARCHAR(MAX) NULL,
        FIELD02 VARCHAR(MAX) NULL,
        FIELD03 VARCHAR(MAX) NULL,
        FIELD04 VARCHAR(MAX) NULL,
        FIELD05 VARCHAR(MAX) NULL,
        FIELD06 VARCHAR(MAX) NULL,
        FIELD07 VARCHAR(MAX) NULL,
        FIELD08 VARCHAR(MAX) NULL,
        FIELD09 VARCHAR(MAX) NULL,
        FIELD10 VARCHAR(MAX) NULL
    );
END
GO

/* ============================================================
   Foreign Keys (only add if missing)
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Columna_Tabla_TablaId')
BEGIN
    ALTER TABLE dbo.Columna
    ADD CONSTRAINT FK_Columna_Tabla_TablaId
        FOREIGN KEY (TablaId) REFERENCES dbo.Tabla(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Columna_TipoDato_TipoDatoId')
BEGIN
    ALTER TABLE dbo.Columna
    ADD CONSTRAINT FK_Columna_TipoDato_TipoDatoId
        FOREIGN KEY (TipoDatoId) REFERENCES dbo.TipoDato(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Etl_Sequence')
BEGIN
    ALTER TABLE dbo.Etl
    ADD CONSTRAINT FK_Etl_Sequence
        FOREIGN KEY (SequenceId) REFERENCES dbo.Sequence(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Sequence_Jcl')
BEGIN
    ALTER TABLE dbo.Sequence
    ADD CONSTRAINT FK_Sequence_Jcl
        FOREIGN KEY (JclId) REFERENCES dbo.Jcl(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RelacionJclMainframeApp_Jcl_JclId')
BEGIN
    ALTER TABLE dbo.RelacionJclMainframeApp
    ADD CONSTRAINT FK_RelacionJclMainframeApp_Jcl_JclId
        FOREIGN KEY (JclId) REFERENCES dbo.Jcl(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RelacionJclMainframeApp_MainframeApp_MainframeAppId')
BEGIN
    ALTER TABLE dbo.RelacionJclMainframeApp
    ADD CONSTRAINT FK_RelacionJclMainframeApp_MainframeApp_MainframeAppId
        FOREIGN KEY (MainframeAppId) REFERENCES dbo.MainframeApp(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Tabla_Aplicacion_AplicacionId')
BEGIN
    ALTER TABLE dbo.Tabla
    ADD CONSTRAINT FK_Tabla_Aplicacion_AplicacionId
        FOREIGN KEY (AplicacionId) REFERENCES dbo.Aplicacion(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Tabla_TipoEsquema_TipoEsquemaId')
BEGIN
    ALTER TABLE dbo.Tabla
    ADD CONSTRAINT FK_Tabla_TipoEsquema_TipoEsquemaId
        FOREIGN KEY (TipoEsquemaId) REFERENCES dbo.TipoEsquema(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Tabla_TipoMotorBaseDeDatos_TipoMotorBaseDeDatosId')
BEGIN
    ALTER TABLE dbo.Tabla
    ADD CONSTRAINT FK_Tabla_TipoMotorBaseDeDatos_TipoMotorBaseDeDatosId
        FOREIGN KEY (TipoMotorBaseDeDatosId) REFERENCES dbo.TipoMotorBaseDeDatos(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Tabla_TipoServer_TipoServerId')
BEGIN
    ALTER TABLE dbo.Tabla
    ADD CONSTRAINT FK_Tabla_TipoServer_TipoServerId
        FOREIGN KEY (TipoServerId) REFERENCES dbo.TipoServer(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TipoEsquema_TipoServer_TipoServerId')
BEGIN
    ALTER TABLE dbo.TipoEsquema
    ADD CONSTRAINT FK_TipoEsquema_TipoServer_TipoServerId
        FOREIGN KEY (TipoServerId) REFERENCES dbo.TipoServer(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TipoServer_TipoMotorBaseDeDatos_TipoMotorBaseDeDatosId')
BEGIN
    ALTER TABLE dbo.TipoServer
    ADD CONSTRAINT FK_TipoServer_TipoMotorBaseDeDatos_TipoMotorBaseDeDatosId
        FOREIGN KEY (TipoMotorBaseDeDatosId) REFERENCES dbo.TipoMotorBaseDeDatos(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Transformacion_Columna_CampoDestinoId')
BEGIN
    ALTER TABLE dbo.Transformacion
    ADD CONSTRAINT FK_Transformacion_Columna_CampoDestinoId
        FOREIGN KEY (CampoDestinoId) REFERENCES dbo.Columna(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Transformacion_Columna_CampoOrigenId')
BEGIN
    ALTER TABLE dbo.Transformacion
    ADD CONSTRAINT FK_Transformacion_Columna_CampoOrigenId
        FOREIGN KEY (CampoOrigenId) REFERENCES dbo.Columna(Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Transformacion_Mapping_MappingId')
BEGIN
    ALTER TABLE dbo.Transformacion
    ADD CONSTRAINT FK_Transformacion_Mapping_MappingId
        FOREIGN KEY (MappingId) REFERENCES dbo.Mapping(Id);
END
GO
