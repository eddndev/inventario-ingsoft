-- ============================================================================
-- 0001_esquema_inicial.sql -- Migracion baseline (estado inicial del esquema)
-- Equivale a database/schema.sql consolidado. Cambios futuros: 0002_*, 0003_*...
-- Reversion: DROP de las tablas creadas (ver database/migrations/README.md).
-- ============================================================================

-- ============================================================================
-- schema.sql -- Esquema de la base de datos (version refinada)
-- Sistema de Inventario con POS y Analisis Predictivo -- Tienda Peterby's
-- Motor: SQLite 3.  24 tablas.
-- ----------------------------------------------------------------------------
-- Convenciones (ver CONVENTIONS.md):
--   * Nombres en espanol sin acentos (dominio del negocio, ASCII).
--   * PK 'id' INTEGER AUTOINCREMENT; FK con sufijo '_id'.
--   * fecha_creacion en altas; fecha_actualizacion en entidades editables.
--   * Catalogos de estado controlados con CHECK (rol, estado, tipo, metodo_pago).
--   * Reglas de negocio expresables a nivel de datos via CHECK (stock >= 0, etc.).
-- Nota: SQLite no impone longitud de VARCHAR ni escala de NUMERIC (son afinidad
--   de tipo); se conservan como documentacion del dominio. Las restricciones
--   que SI se imponen son NOT NULL, UNIQUE, FOREIGN KEY y CHECK.
-- ============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ===========================================================================
-- A. CATALOGOS BASE (sin dependencias)
-- ===========================================================================

-- -- 1. COLORES -------------------------------------------------------------
-- Paleta de colores disponible para las variantes de producto.
CREATE TABLE IF NOT EXISTS colores (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre      VARCHAR(50)  NOT NULL UNIQUE,
    codigo_hex  VARCHAR(7)   DEFAULT '#000000'
                CHECK (codigo_hex GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')
);

-- -- 2. MARCAS --------------------------------------------------------------
-- Marcas o etiquetas comerciales de los productos.
CREATE TABLE IF NOT EXISTS marcas (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre          VARCHAR(100) NOT NULL UNIQUE,
    descripcion     TEXT,
    url_logo        TEXT,
    activo          INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_creacion  TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 3. TALLAS --------------------------------------------------------------
-- Catalogo de tallas (XS, S, M, L, 28, 30, ...). orden_visual ordena la UI.
CREATE TABLE IF NOT EXISTS tallas (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre        VARCHAR(20) NOT NULL UNIQUE,
    descripcion   TEXT,
    orden_visual  INTEGER NOT NULL DEFAULT 0
);

-- -- 4. TEMPORADAS ----------------------------------------------------------
-- Temporadas comerciales (Primavera-Verano 2025, etc.) para clasificar surtido.
CREATE TABLE IF NOT EXISTS temporadas (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre        VARCHAR(100) NOT NULL,
    anio          INTEGER NOT NULL CHECK (anio BETWEEN 2000 AND 2100),
    activo        INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_inicio  DATE,
    fecha_fin     DATE,
    CHECK (fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio)
);

-- -- 5. CATEGORIAS ----------------------------------------------------------
-- Categorias de producto, jerarquicas (categoria_padre_id autorreferencia).
CREATE TABLE IF NOT EXISTS categorias (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre              VARCHAR(100) NOT NULL,
    descripcion         TEXT,
    categoria_padre_id  INTEGER REFERENCES categorias(id) ON DELETE SET NULL,
    activo              INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1))
);

-- -- 6. PROVEEDORES ---------------------------------------------------------
-- Proveedores mayoristas que surten la mercancia.
CREATE TABLE IF NOT EXISTS proveedores (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_empresa   VARCHAR(200) NOT NULL,
    nombre_contacto  VARCHAR(200),
    telefono         VARCHAR(30),
    correo           VARCHAR(150),            -- ampliado (antes 25, insuficiente)
    pais             VARCHAR(100),
    ciudad           VARCHAR(100),
    direccion        TEXT,
    tipos_producto   VARCHAR(200),
    activo           INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_creacion   TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 7. CLIENTES ------------------------------------------------------------
-- Clientes de la tienda (opcional en cada venta; base para analisis).
CREATE TABLE IF NOT EXISTS clientes (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100),
    telefono        VARCHAR(20),
    correo          VARCHAR(100),
    direccion       TEXT,
    ciudad          VARCHAR(100),
    estado          VARCHAR(100),            -- entidad federativa (no confundir con estatus)
    codigo_postal   VARCHAR(10),
    nacimiento      DATE,
    genero          VARCHAR(20) CHECK (genero IN ('Masculino', 'Femenino', 'Otro') OR genero IS NULL),
    fecha_creacion  TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 8. USUARIOS ------------------------------------------------------------
-- Operadores del sistema. rol controla los permisos (ver casos de uso).
CREATE TABLE IF NOT EXISTS usuarios (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario          VARCHAR(50) NOT NULL UNIQUE,
    nombre_completo  VARCHAR(100),
    correo           VARCHAR(100),
    hash_contrasena  TEXT NOT NULL,                      -- nunca contrasena en claro
    rol              VARCHAR(25) NOT NULL DEFAULT 'Vendedor'
                     CHECK (rol IN ('Gerente', 'Vendedor')),
    activo           INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    datos_perfil     TEXT,                               -- JSON opcional de preferencias
    fecha_creacion   TIMESTAMP DEFAULT (datetime('now')),
    ultimo_acceso    TIMESTAMP
);

-- ===========================================================================
-- B. PRODUCTOS Y SU SURTIDO
-- ===========================================================================

-- -- 9. PRODUCTOS -----------------------------------------------------------
-- Producto "padre" (modelo). El stock real vive en variantes_producto.
CREATE TABLE IF NOT EXISTS productos (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre               VARCHAR(200) NOT NULL,
    descripcion          TEXT,
    marca_id             INTEGER REFERENCES marcas(id)      ON DELETE SET NULL,
    categoria_id         INTEGER REFERENCES categorias(id)  ON DELETE SET NULL,
    temporada_id         INTEGER REFERENCES temporadas(id)  ON DELETE SET NULL,
    genero               VARCHAR(50),                       -- publico objetivo (Hombre/Mujer/Unisex)
    costo_base           NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (costo_base   >= 0),
    precio_venta         NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (precio_venta >= 0),
    color_venta          VARCHAR(100),                      -- color principal mostrado
    activo               INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_creacion       TIMESTAMP DEFAULT (datetime('now')),
    fecha_actualizacion  TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 10. VARIANTES DE PRODUCTO ----------------------------------------------
-- Combinacion vendible (producto + talla + color). Unidad real de inventario.
CREATE TABLE IF NOT EXISTS variantes_producto (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id          INTEGER NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    talla_id             INTEGER REFERENCES tallas(id)   ON DELETE SET NULL,
    color_id             INTEGER REFERENCES colores(id)  ON DELETE SET NULL,
    codigo_sku           VARCHAR(100) UNIQUE,
    codigo_barras        VARCHAR(100) UNIQUE,
    existencias          INTEGER NOT NULL DEFAULT 0  CHECK (existencias         >= 0),  -- RN-008
    existencias_minimas  INTEGER NOT NULL DEFAULT 5  CHECK (existencias_minimas >= 0),  -- RN-003
    precio_venta         NUMERIC(12,2) CHECK (precio_venta IS NULL OR precio_venta >= 0),
    peso                 NUMERIC(10,3),                    -- kg (antes sin escala)
    activo               INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_creacion       TIMESTAMP DEFAULT (datetime('now')),
    fecha_actualizacion  TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 11. IMAGENES DE PRODUCTO -----------------------------------------------
-- Imagenes asociadas a un producto o a una variante concreta.
CREATE TABLE IF NOT EXISTS imagenes_producto (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id  INTEGER REFERENCES productos(id)          ON DELETE CASCADE,
    variante_id  INTEGER REFERENCES variantes_producto(id) ON DELETE CASCADE,
    url_imagen   TEXT NOT NULL,
    principal    INTEGER NOT NULL DEFAULT 0 CHECK (principal IN (0, 1)),
    orden        INTEGER NOT NULL DEFAULT 0,
    CHECK (producto_id IS NOT NULL OR variante_id IS NOT NULL)
);

-- -- 12. PRODUCTOS-PROVEEDORES ----------------------------------------------
-- Que proveedor surte que producto, a que costo y plazo (N:M).
CREATE TABLE IF NOT EXISTS productos_proveedores (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id          INTEGER NOT NULL REFERENCES productos(id)   ON DELETE CASCADE,
    proveedor_id         INTEGER NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    costo                NUMERIC(12,2) CHECK (costo IS NULL OR costo >= 0),
    tiempo_entrega_dias  INTEGER CHECK (tiempo_entrega_dias IS NULL OR tiempo_entrega_dias >= 0),
    UNIQUE (producto_id, proveedor_id)
);

-- -- 13. OUTFITS ------------------------------------------------------------
-- Conjuntos sugeridos de prendas (cross-selling).
CREATE TABLE IF NOT EXISTS outfits (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre       VARCHAR(200),
    descripcion  TEXT,
    url_imagen   TEXT,
    activo       INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1))
);

-- -- 14. OUTFIT-PRODUCTOS ---------------------------------------------------
-- Productos que componen cada outfit (N:M).
CREATE TABLE IF NOT EXISTS outfit_productos (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    outfit_id    INTEGER NOT NULL REFERENCES outfits(id)   ON DELETE CASCADE,
    producto_id  INTEGER NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    UNIQUE (outfit_id, producto_id)
);

-- ===========================================================================
-- C. OPERACION COMERCIAL (VENTAS, PAGOS, INVENTARIO)
-- ===========================================================================

-- -- 15. VENTAS -------------------------------------------------------------
-- Encabezado de cada ticket de venta.
CREATE TABLE IF NOT EXISTS ventas (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    folio        VARCHAR(50) UNIQUE,
    cliente_id   INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
    cajero_id    INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,  -- usuario que cobra (rol)
    subtotal     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (subtotal   >= 0),
    descuentos   NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (descuentos >= 0),
    impuestos    NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (impuestos  >= 0),
    total        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total      >= 0),
    metodo_pago  VARCHAR(50) CHECK (metodo_pago IN ('Efectivo', 'Tarjeta', 'Mixto') OR metodo_pago IS NULL),
    estado       VARCHAR(30) NOT NULL DEFAULT 'completada'
                 CHECK (estado IN ('completada', 'cancelada', 'devuelta')),
    notas        TEXT,                                       -- ampliado (antes VARCHAR(50))
    fecha_venta  TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 16. DETALLE DE VENTAS --------------------------------------------------
-- Renglones (partidas) de cada venta, a nivel de variante.
CREATE TABLE IF NOT EXISTS detalle_ventas (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    venta_id         INTEGER NOT NULL REFERENCES ventas(id)             ON DELETE CASCADE,
    variante_id      INTEGER NOT NULL REFERENCES variantes_producto(id) ON DELETE RESTRICT,
    cantidad         INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    precio_unitario  NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    descuentos_item  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (descuentos_item >= 0),
    subtotal         NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0)
);

-- -- 17. PAGOS --------------------------------------------------------------
-- Pagos aplicados a una venta (varios renglones permiten el pago mixto).
CREATE TABLE IF NOT EXISTS pagos (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    venta_id     INTEGER NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
    monto        NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    metodo_pago  VARCHAR(50) NOT NULL
                 CHECK (metodo_pago IN ('Efectivo', 'Tarjeta', 'Transferencia')),
    referencia   VARCHAR(100),                              -- autorizacion / folio externo
    fecha_pago   TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 18. MOVIMIENTOS DE INVENTARIO ------------------------------------------
-- Kardex: toda entrada/salida de existencias por variante (trazabilidad).
CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    variante_id         INTEGER NOT NULL REFERENCES variantes_producto(id) ON DELETE CASCADE,
    tipo                VARCHAR(50) NOT NULL
                        CHECK (tipo IN ('venta', 'compra', 'ajuste', 'devolucion')),
    cantidad            INTEGER NOT NULL CHECK (cantidad <> 0),    -- + entra, - sale
    existencias_antes   INTEGER NOT NULL CHECK (existencias_antes  >= 0),
    existencias_despues INTEGER NOT NULL CHECK (existencias_despues >= 0),
    referencia          TEXT,                                      -- folio de venta/compra origen
    usuario_id          INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    fecha               TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 19. DEVOLUCIONES -------------------------------------------------------
-- Devolucion de un renglon de venta; reintegra stock.
CREATE TABLE IF NOT EXISTS devoluciones (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    detalle_venta_id  INTEGER NOT NULL REFERENCES detalle_ventas(id) ON DELETE RESTRICT,
    usuario_id        INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    cantidad          INTEGER NOT NULL CHECK (cantidad > 0),
    motivo            TEXT,
    fecha             TIMESTAMP DEFAULT (datetime('now'))
);

-- ===========================================================================
-- D. PROMOCIONES
-- ===========================================================================

-- -- 20. PROMOCIONES --------------------------------------------------------
-- Promociones con vigencia: porcentaje o monto fijo de descuento.
CREATE TABLE IF NOT EXISTS promociones (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre        VARCHAR(200) NOT NULL,
    tipo          VARCHAR(50) NOT NULL CHECK (tipo IN ('porcentaje', 'monto_fijo')),
    valor         NUMERIC(12,2) NOT NULL CHECK (valor >= 0),     -- RN-011 (tope se valida en app)
    fecha_inicio  DATE,
    fecha_fin     DATE,
    activo        INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    CHECK (fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio)
);

-- -- 21. PROMOCIONES-VARIANTES -----------------------------------------------
-- Variantes alcanzadas por cada promocion (N:M).
CREATE TABLE IF NOT EXISTS promociones_variantes (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    promocion_id  INTEGER NOT NULL REFERENCES promociones(id)        ON DELETE CASCADE,
    variante_id   INTEGER NOT NULL REFERENCES variantes_producto(id) ON DELETE CASCADE,
    UNIQUE (promocion_id, variante_id)
);

-- ===========================================================================
-- E. INTELIGENCIA DEL SISTEMA (ALERTAS, AUDITORIA, PREDICCION)
-- ===========================================================================

-- -- 22. ALERTAS ------------------------------------------------------------
-- Alertas automaticas de stock o reabastecimiento mostradas al usuario.
CREATE TABLE IF NOT EXISTS alertas (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    variante_id     INTEGER REFERENCES variantes_producto(id) ON DELETE CASCADE,
    tipo            VARCHAR(100) NOT NULL
                    CHECK (tipo IN ('stock_minimo', 'stock_agotado', 'reabastecimiento')),
    mensaje         TEXT,
    resuelta        INTEGER NOT NULL DEFAULT 0 CHECK (resuelta IN (0, 1)),
    fecha_creacion  TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 23. BITACORA DE AUDITORIA ----------------------------------------------
-- Registro de cambios sensibles (quien, que tabla, accion, antes/despues).
CREATE TABLE IF NOT EXISTS bitacora_auditoria (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id         INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    tabla_afectada     VARCHAR(100) NOT NULL,
    accion             VARCHAR(30) NOT NULL CHECK (accion IN ('INSERT', 'UPDATE', 'DELETE')),
    detalles_anterior  TEXT,                              -- snapshot JSON previo
    detalles_nuevo     TEXT,                              -- snapshot JSON nuevo
    fecha              TIMESTAMP DEFAULT (datetime('now'))
);

-- -- 24. PREDICCIONES DE REABASTECIMIENTO -----------------------------------
-- Salida del modelo Random Forest: demanda estimada y fecha sugerida por variante.
CREATE TABLE IF NOT EXISTS predicciones_reabastecimiento (
    id                               INTEGER PRIMARY KEY AUTOINCREMENT,
    variante_id                      INTEGER NOT NULL REFERENCES variantes_producto(id) ON DELETE CASCADE,
    demanda_estimada                 NUMERIC(12,2) CHECK (demanda_estimada IS NULL OR demanda_estimada >= 0),
    dias_estimados                   INTEGER CHECK (dias_estimados IS NULL OR dias_estimados >= 0),
    nivel_confianza                  NUMERIC(5,2) CHECK (nivel_confianza IS NULL OR nivel_confianza BETWEEN 0 AND 100),
    fecha_prediccion                 TIMESTAMP DEFAULT (datetime('now')),
    fecha_reabastecimiento_sugerida  DATE,
    modelo_id                        VARCHAR(100),         -- version/identificador del modelo
    detalles                         TEXT                  -- JSON con features/metricas
);

-- ===========================================================================
-- F. INDICES DE RENDIMIENTO
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_var_producto    ON variantes_producto(producto_id);
CREATE INDEX IF NOT EXISTS idx_var_barras      ON variantes_producto(codigo_barras);
CREATE INDEX IF NOT EXISTS idx_var_sku         ON variantes_producto(codigo_sku);
CREATE INDEX IF NOT EXISTS idx_prod_categoria  ON productos(categoria_id);
CREATE INDEX IF NOT EXISTS idx_prod_marca      ON productos(marca_id);
CREATE INDEX IF NOT EXISTS idx_dv_venta        ON detalle_ventas(venta_id);
CREATE INDEX IF NOT EXISTS idx_dv_variante     ON detalle_ventas(variante_id);
CREATE INDEX IF NOT EXISTS idx_ventas_fecha    ON ventas(fecha_venta);
CREATE INDEX IF NOT EXISTS idx_ventas_cliente  ON ventas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_ventas_estado   ON ventas(estado);
CREATE INDEX IF NOT EXISTS idx_pagos_venta     ON pagos(venta_id);
CREATE INDEX IF NOT EXISTS idx_mov_variante    ON movimientos_inventario(variante_id);
CREATE INDEX IF NOT EXISTS idx_mov_fecha       ON movimientos_inventario(fecha);
CREATE INDEX IF NOT EXISTS idx_alertas_var     ON alertas(variante_id);
CREATE INDEX IF NOT EXISTS idx_alertas_pend    ON alertas(resuelta);
CREATE INDEX IF NOT EXISTS idx_pred_variante   ON predicciones_reabastecimiento(variante_id);
CREATE INDEX IF NOT EXISTS idx_dev_detalle     ON devoluciones(detalle_venta_id);
