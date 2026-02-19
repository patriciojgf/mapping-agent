USE [MappingDW];
GO

DECLARE @now DATETIME2 = SYSUTCDATETIME();
DECLARE @usr NVARCHAR(100) = N'seed';

BEGIN TRANSACTION;

/* Lookups */
IF NOT EXISTS (SELECT 1 FROM dbo.TipoMotorBaseDeDatos WHERE Nombre = N'SQLServer')
BEGIN
    INSERT INTO dbo.TipoMotorBaseDeDatos (Nombre, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion)
    VALUES (N'SQLServer', @now, @now, @usr, @usr);
END;

DECLARE @TipoMotorId INT = (SELECT TOP 1 Id FROM dbo.TipoMotorBaseDeDatos WHERE Nombre = N'SQLServer' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.TipoServer WHERE Nombre = N'LOCALHOST_SQLSERVER')
BEGIN
    INSERT INTO dbo.TipoServer (Nombre, TipoMotorBaseDeDatosId, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion)
    VALUES (N'LOCALHOST_SQLSERVER', @TipoMotorId, @now, @now, @usr, @usr);
END;

DECLARE @TipoServerId INT = (SELECT TOP 1 Id FROM dbo.TipoServer WHERE Nombre = N'LOCALHOST_SQLSERVER' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.TipoEsquema WHERE Nombre = N'dbo' AND TipoServerId = @TipoServerId)
BEGIN
    INSERT INTO dbo.TipoEsquema (Nombre, TipoServerId, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion)
    VALUES (N'dbo', @TipoServerId, @now, @now, @usr, @usr);
END;

DECLARE @TipoEsquemaId INT = (SELECT TOP 1 Id FROM dbo.TipoEsquema WHERE Nombre = N'dbo' AND TipoServerId = @TipoServerId ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.TipoDato WHERE Nombre = N'INT')
BEGIN
    INSERT INTO dbo.TipoDato (Nombre, NecesitaLongitud, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion)
    VALUES (N'INT', 0, @now, @now, @usr, @usr);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.TipoDato WHERE Nombre = N'NVARCHAR')
BEGIN
    INSERT INTO dbo.TipoDato (Nombre, NecesitaLongitud, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion)
    VALUES (N'NVARCHAR', 1, @now, @now, @usr, @usr);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.TipoDato WHERE Nombre = N'DATETIME2')
BEGIN
    INSERT INTO dbo.TipoDato (Nombre, NecesitaLongitud, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion)
    VALUES (N'DATETIME2', 0, @now, @now, @usr, @usr);
END;

DECLARE @TipoDatoInt INT = (SELECT TOP 1 Id FROM dbo.TipoDato WHERE Nombre = N'INT' ORDER BY Id);
DECLARE @TipoDatoNVarChar INT = (SELECT TOP 1 Id FROM dbo.TipoDato WHERE Nombre = N'NVARCHAR' ORDER BY Id);
DECLARE @TipoDatoDatetime2 INT = (SELECT TOP 1 Id FROM dbo.TipoDato WHERE Nombre = N'DATETIME2' ORDER BY Id);

/* Core entities */
IF NOT EXISTS (SELECT 1 FROM dbo.Aplicacion WHERE Nombre = N'MAPPING_AGENT_DEMO')
BEGIN
    INSERT INTO dbo.Aplicacion (Nombre, Descripcion, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, Estado)
    VALUES (N'MAPPING_AGENT_DEMO', N'Aplicacion demo para bootstrap local', @now, @now, @usr, @usr, 1);
END;

DECLARE @AplicacionId INT = (SELECT TOP 1 Id FROM dbo.Aplicacion WHERE Nombre = N'MAPPING_AGENT_DEMO' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.Tabla WHERE Nombre = N'STG_CLIENTES_RAW' AND AplicacionId = @AplicacionId)
BEGIN
    INSERT INTO dbo.Tabla
    (
        Nombre, Descripcion, AplicacionId, TipoMotorBaseDeDatosId, TipoServerId, TipoEsquemaId,
        Estado, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, Tipo, ResguardoHistorico
    )
    VALUES
    (
        N'STG_CLIENTES_RAW', N'Tabla staging de clientes', @AplicacionId, @TipoMotorId, @TipoServerId, @TipoEsquemaId,
        1, @now, @now, @usr, @usr, 1, 0
    );
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Tabla WHERE Nombre = N'DW_CLIENTES' AND AplicacionId = @AplicacionId)
BEGIN
    INSERT INTO dbo.Tabla
    (
        Nombre, Descripcion, AplicacionId, TipoMotorBaseDeDatosId, TipoServerId, TipoEsquemaId,
        Estado, fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, Tipo, ResguardoHistorico
    )
    VALUES
    (
        N'DW_CLIENTES', N'Tabla destino de clientes', @AplicacionId, @TipoMotorId, @TipoServerId, @TipoEsquemaId,
        1, @now, @now, @usr, @usr, 2, 1
    );
END;

DECLARE @TablaStgId INT = (SELECT TOP 1 Id FROM dbo.Tabla WHERE Nombre = N'STG_CLIENTES_RAW' AND AplicacionId = @AplicacionId ORDER BY Id);
DECLARE @TablaDwId INT = (SELECT TOP 1 Id FROM dbo.Tabla WHERE Nombre = N'DW_CLIENTES' AND AplicacionId = @AplicacionId ORDER BY Id);

/* Columns */
IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'CLIENTE_ID')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (1, N'CLIENTE_ID', N'ID cliente origen', @TipoDatoInt, NULL, 0, 0, 0, @now, @now, @usr, @usr, @TablaStgId);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'NOMBRE_COMPLETO')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (2, N'NOMBRE_COMPLETO', N'Nombre completo en staging', @TipoDatoNVarChar, N'300', 1, 0, 0, @now, @now, @usr, @usr, @TablaStgId);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'EMAIL')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (3, N'EMAIL', N'Email de contacto', @TipoDatoNVarChar, N'255', 1, 0, 0, @now, @now, @usr, @usr, @TablaStgId);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'ALTA_TS')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (4, N'ALTA_TS', N'Fecha alta técnica', @TipoDatoDatetime2, NULL, 1, 0, 0, @now, @now, @usr, @usr, @TablaStgId);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'CLIENTE_ID')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (1, N'CLIENTE_ID', N'ID cliente destino', @TipoDatoInt, NULL, 0, 1, 1, @now, @now, @usr, @usr, @TablaDwId);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'NOMBRE')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (2, N'NOMBRE', N'Nombre normalizado', @TipoDatoNVarChar, N'200', 0, 0, 0, @now, @now, @usr, @usr, @TablaDwId);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'EMAIL')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (3, N'EMAIL', N'Email destino', @TipoDatoNVarChar, N'255', 1, 0, 0, @now, @now, @usr, @usr, @TablaDwId);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'FECHA_ALTA')
BEGIN
    INSERT INTO dbo.Columna
    (
        numeroOrden, Nombre, Descripcion, TipoDatoId, Longitud, Nullable, ClavePrimaria, IndicePrimario,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion, TablaId
    )
    VALUES
    (4, N'FECHA_ALTA', N'Fecha alta de negocio', @TipoDatoDatetime2, NULL, 1, 0, 0, @now, @now, @usr, @usr, @TablaDwId);
END;

/* ETL lineage */
IF NOT EXISTS (SELECT 1 FROM dbo.Jcl WHERE NombreJcl = N'JCL_MAP_CLIENTES')
BEGIN
    INSERT INTO dbo.Jcl (NombreJcl) VALUES (N'JCL_MAP_CLIENTES');
END;

DECLARE @JclId INT = (SELECT TOP 1 Id FROM dbo.Jcl WHERE NombreJcl = N'JCL_MAP_CLIENTES' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.Sequence WHERE JclId = @JclId AND NombreSequence = N'SEQ_MAP_CLIENTES')
BEGIN
    INSERT INTO dbo.Sequence (JclId, NombreSequence, Tipo)
    VALUES (@JclId, N'SEQ_MAP_CLIENTES', 'FULL');
END;

DECLARE @SequenceId INT = (SELECT TOP 1 Id FROM dbo.Sequence WHERE JclId = @JclId AND NombreSequence = N'SEQ_MAP_CLIENTES' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.Etl WHERE SequenceId = @SequenceId AND NombreEtl = N'ETL_MAP_CLIENTES')
BEGIN
    INSERT INTO dbo.Etl (SequenceId, NombreEtl, NombreHilo2, Tipo, Paso)
    VALUES (@SequenceId, N'ETL_MAP_CLIENTES', N'HILO2_CLIENTES', N'LOAD', 1);
END;

DECLARE @EtlId INT = (SELECT TOP 1 Id FROM dbo.Etl WHERE SequenceId = @SequenceId AND NombreEtl = N'ETL_MAP_CLIENTES' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.Mapping WHERE Nombre = N'MAP_CLIENTES' AND TablaDestinoId = @TablaDwId)
BEGIN
    INSERT INTO dbo.Mapping
    (
        Nombre, Descripcion, ArchivoOrigen, Responsable, Estado,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion,
        Frecuencia, EtlId, TablaDestinoId
    )
    VALUES
    (
        N'MAP_CLIENTES', N'Mapeo demo STG_CLIENTES_RAW -> DW_CLIENTES', N'clientes_raw.csv', N'data-eng', 1,
        @now, @now, @usr, @usr, 1, @EtlId, @TablaDwId
    );
END;

DECLARE @MappingId INT = (SELECT TOP 1 Id FROM dbo.Mapping WHERE Nombre = N'MAP_CLIENTES' AND TablaDestinoId = @TablaDwId ORDER BY Id);

DECLARE @StgClienteId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'CLIENTE_ID' ORDER BY Id);
DECLARE @StgNombreCompletoId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'NOMBRE_COMPLETO' ORDER BY Id);
DECLARE @StgEmailId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'EMAIL' ORDER BY Id);
DECLARE @StgAltaTsId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaStgId AND Nombre = N'ALTA_TS' ORDER BY Id);

DECLARE @DwClienteId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'CLIENTE_ID' ORDER BY Id);
DECLARE @DwNombreId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'NOMBRE' ORDER BY Id);
DECLARE @DwEmailId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'EMAIL' ORDER BY Id);
DECLARE @DwFechaAltaId INT = (SELECT TOP 1 Id FROM dbo.Columna WHERE TablaId = @TablaDwId AND Nombre = N'FECHA_ALTA' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.Transformacion WHERE MappingId = @MappingId AND Posicion = 1)
BEGIN
    INSERT INTO dbo.Transformacion
    (
        MappingId, CampoOrigenId, CampoDestinoId, Posicion, TransformacionMapping, Relacion,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion,
        CampoOrigenComentario, CampoDestinoComentario
    )
    VALUES
    (@MappingId, @StgClienteId, @DwClienteId, 1, NULL, N'1:1', @now, @now, @usr, @usr, N'CLIENTE_ID', N'CLIENTE_ID');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Transformacion WHERE MappingId = @MappingId AND Posicion = 2)
BEGIN
    INSERT INTO dbo.Transformacion
    (
        MappingId, CampoOrigenId, CampoDestinoId, Posicion, TransformacionMapping, Relacion,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion,
        CampoOrigenComentario, CampoDestinoComentario
    )
    VALUES
    (@MappingId, @StgNombreCompletoId, @DwNombreId, 2, N'UPPER(LTRIM(RTRIM(NOMBRE_COMPLETO)))', N'transform', @now, @now, @usr, @usr, N'NOMBRE_COMPLETO', N'NOMBRE');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Transformacion WHERE MappingId = @MappingId AND Posicion = 3)
BEGIN
    INSERT INTO dbo.Transformacion
    (
        MappingId, CampoOrigenId, CampoDestinoId, Posicion, TransformacionMapping, Relacion,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion,
        CampoOrigenComentario, CampoDestinoComentario
    )
    VALUES
    (@MappingId, @StgEmailId, @DwEmailId, 3, NULL, N'1:1', @now, @now, @usr, @usr, N'EMAIL', N'EMAIL');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Transformacion WHERE MappingId = @MappingId AND Posicion = 4)
BEGIN
    INSERT INTO dbo.Transformacion
    (
        MappingId, CampoOrigenId, CampoDestinoId, Posicion, TransformacionMapping, Relacion,
        fechaCreacion, fechaModificacion, usuarioCreacion, usuarioModificacion,
        CampoOrigenComentario, CampoDestinoComentario
    )
    VALUES
    (@MappingId, @StgAltaTsId, @DwFechaAltaId, 4, NULL, N'1:1', @now, @now, @usr, @usr, N'ALTA_TS', N'FECHA_ALTA');
END;

COMMIT TRANSACTION;
GO
