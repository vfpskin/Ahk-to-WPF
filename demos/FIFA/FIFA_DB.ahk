global gFifaDB := ""
global gFifaDBPath := A_ScriptDir "\FIFA.db"

DB_Conectar()
{
    global gFifaDB, gFifaDBPath

    if IsObject(gFifaDB)
        return true

    if (!FileExist(A_ScriptDir "\Lib"))
        FileCreateDir, % A_ScriptDir "\Lib"

    gFifaDB := new SQLiteDB()
    if (!gFifaDB.OpenDB(gFifaDBPath, "W", True))
    {
        MsgBox, 16, SQLite, % "No se pudo abrir la base de datos:`n" gFifaDB.ErrorMsg
        return false
    }

    return true
}

DB_CrearTablas()
{
    global gFifaDB

    if !DB_Conectar()
        return false

    sql := ""
    sql .= "CREATE TABLE IF NOT EXISTS Paises ("
    sql .= "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    sql .= " nombre TEXT NOT NULL,"
    sql .= " bandera TEXT,"
    sql .= " confederacion TEXT,"
    sql .= " ranking_fifa INTEGER,"
    sql .= " director_tecnico TEXT,"
    sql .= " capitan TEXT,"
    sql .= " participaciones INTEGER,"
    sql .= " mejor_resultado TEXT"
    sql .= ");"
    sql .= "CREATE TABLE IF NOT EXISTS Grupos ("
    sql .= "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    sql .= " grupo TEXT NOT NULL,"
    sql .= " pais_id INTEGER NOT NULL"
    sql .= ");"
    sql .= "CREATE TABLE IF NOT EXISTS Estadios ("
    sql .= "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    sql .= " nombre TEXT NOT NULL,"
    sql .= " ciudad TEXT,"
    sql .= " pais TEXT,"
    sql .= " capacidad INTEGER,"
    sql .= " inauguracion INTEGER,"
    sql .= " imagen TEXT,"
    sql .= " latitud TEXT,"
    sql .= " longitud TEXT"
    sql .= ");"
    sql .= "CREATE TABLE IF NOT EXISTS Partidos ("
    sql .= "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    sql .= " fecha TEXT,"
    sql .= " hora TEXT,"
    sql .= " equipo_local TEXT,"
    sql .= " equipo_visitante TEXT,"
    sql .= " goles_local INTEGER DEFAULT 0,"
    sql .= " goles_visitante INTEGER DEFAULT 0,"
    sql .= " estadio_id INTEGER,"
    sql .= " fase TEXT,"
    sql .= " grupo TEXT"
    sql .= ");"
    sql .= "CREATE TABLE IF NOT EXISTS Jugadores ("
    sql .= "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    sql .= " nombre TEXT NOT NULL,"
    sql .= " edad INTEGER,"
    sql .= " posicion TEXT,"
    sql .= " pais_id INTEGER,"
    sql .= " club TEXT,"
    sql .= " goles INTEGER DEFAULT 0,"
    sql .= " asistencias INTEGER DEFAULT 0"
    sql .= ");"
    sql .= "CREATE TABLE IF NOT EXISTS Configuracion ("
    sql .= "clave TEXT PRIMARY KEY,"
    sql .= " valor TEXT"
    sql .= ");"

    if !gFifaDB.Exec(sql)
    {
        MsgBox, 16, SQLite, % "No se pudieron crear las tablas:`n" gFifaDB.ErrorMsg
        return false
    }

    DB_SeedInicial()
    return true
}

DB_SeedInicial()
{
    if (DB_ContarFilas("Paises") > 0)
        return true

    sql := ""
    sql .= "INSERT INTO Paises (nombre, bandera, confederacion, ranking_fifa, director_tecnico, capitan, participaciones, mejor_resultado) VALUES "
    sql .= "('Argentina', 'argentina.png', 'CONMEBOL', 1, 'Lionel Scaloni', 'Lionel Messi', 18, 'Campeón'),"
    sql .= "('Brasil', 'brasil.png', 'CONMEBOL', 3, 'Fernando Diniz', 'Casemiro', 22, 'Campeón'),"
    sql .= "('Francia', 'francia.png', 'UEFA', 2, 'Didier Deschamps', 'Kylian Mbappé', 16, 'Campeón'),"
    sql .= "('México', 'mexico.png', 'CONCACAF', 12, 'Jaime Lozano', 'Edson Álvarez', 17, 'Cuartos'),"
    sql .= "('Uruguay', 'uruguay.png', 'CONMEBOL', 11, 'Marcelo Bielsa', 'Federico Valverde', 14, 'Campeón'),"
    sql .= "('Japón', 'japon.png', 'AFC', 18, 'Hajime Moriyasu', 'Wataru Endo', 8, 'Octavos'),"
    sql .= "('Marruecos', 'marruecos.png', 'CAF', 13, 'Walid Regragui', 'Romain Saïss', 6, 'Semifinales');"

    sql .= "INSERT INTO Grupos (grupo, pais_id) VALUES "
    sql .= "('A', 1),"
    sql .= "('A', 2),"
    sql .= "('B', 3),"
    sql .= "('B', 4),"
    sql .= "('C', 5),"
    sql .= "('C', 6),"
    sql .= "('D', 7);"

    sql .= "INSERT INTO Estadios (nombre, ciudad, pais, capacidad, inauguracion, imagen, latitud, longitud) VALUES "
    sql .= "('MetLife Stadium', 'Nueva York', 'EE.UU.', 82500, 2010, 'metlife.jpg', '40.8135', '-74.0745'),"
    sql .= "('Azteca', 'Ciudad de México', 'México', 87000, 1966, 'azteca.jpg', '19.3021', '-99.1500'),"
    sql .= "('SoFi Stadium', 'Los Ángeles', 'EE.UU.', 70000, 2020, 'sofi.jpg', '33.9535', '-118.3392'),"
    sql .= "('BMO Field', 'Toronto', 'Canadá', 30000, 2007, 'bmo.jpg', '43.6332', '-79.4180'),"
    sql .= "('Estadio BBVA', 'Monterrey', 'México', 53000, 2015, 'bbva.jpg', '25.6695', '-100.2443');"

    sql .= "INSERT INTO Partidos (fecha, hora, equipo_local, equipo_visitante, goles_local, goles_visitante, estadio_id, fase, grupo) VALUES "
    sql .= "('11/06/2026', '19:00', 'México', 'Canadá', 0, 0, 1, 'Grupos', 'A'),"
    sql .= "('12/06/2026', '17:00', 'Argentina', 'Japón', 0, 0, 2, 'Grupos', 'A'),"
    sql .= "('13/06/2026', '21:00', 'Brasil', 'Uruguay', 0, 0, 3, 'Grupos', 'B'),"
    sql .= "('14/06/2026', '18:00', 'Francia', 'Senegal', 0, 0, 4, 'Grupos', 'C'),"
    sql .= "('15/06/2026', '20:00', 'Inglaterra', 'Alemania', 0, 0, 5, 'Grupos', 'D'),"
    sql .= "('20/06/2026', '19:00', 'México', 'Estados Unidos', 0, 0, 5, 'Grupos', 'B');"

    sql .= "INSERT INTO Jugadores (nombre, edad, posicion, pais_id, club, goles, asistencias) VALUES "
    sql .= "('Lionel Messi', 37, 'Delantero', 1, 'Inter Miami', 0, 0),"
    sql .= "('Vinícius Júnior', 24, 'Delantero', 2, 'Real Madrid', 0, 0),"
    sql .= "('Kylian Mbappé', 25, 'Delantero', 3, 'PSG', 0, 0);"

    if !gFifaDB.Exec(sql)
        return false

    DB_SetConfig("LastTheme", "Oscuro")
    return true
}

DB_ContarFilas(tabla)
{
    tb := ""
    if !DB_Conectar()
        return 0
    if !gFifaDB.GetTable("SELECT COUNT(*) AS total FROM " tabla, tb, 1)
        return 0
    if (tb.RowCount < 1)
        return 0
    return tb.Rows[1][1] + 0
}

DB_GetConfig(clave, valorPorDefecto := "")
{
    tb := ""
    if !DB_Conectar()
        return valorPorDefecto
    sql := "SELECT valor FROM Configuracion WHERE clave='" DB_Escape(clave) "' LIMIT 1"
    if !gFifaDB.GetTable(sql, tb, 1)
        return valorPorDefecto
    if (tb.RowCount < 1)
        return valorPorDefecto
    return tb.Rows[1][1]
}

DB_SetConfig(clave, valor)
{
    if !DB_Conectar()
        return false
    sql := ""
    sql .= "INSERT OR REPLACE INTO Configuracion (clave, valor) VALUES ('"
    sql .= DB_Escape(clave) "', '"
    sql .= DB_Escape(valor) "');"
    return gFifaDB.Exec(sql)
}

DB_InsertarPais(nombre, bandera, confederacion, ranking_fifa, director_tecnico, capitan, participaciones, mejor_resultado)
{
    if !DB_Conectar()
        return false
    sql := ""
    sql .= "INSERT INTO Paises (nombre, bandera, confederacion, ranking_fifa, director_tecnico, capitan, participaciones, mejor_resultado) VALUES ('"
    sql .= DB_Escape(nombre) "', '"
    sql .= DB_Escape(bandera) "', '"
    sql .= DB_Escape(confederacion) "', "
    sql .= ranking_fifa ", '"
    sql .= DB_Escape(director_tecnico) "', '"
    sql .= DB_Escape(capitan) "', "
    sql .= participaciones ", '"
    sql .= DB_Escape(mejor_resultado) "');"
    return gFifaDB.Exec(sql)
}

DB_ActualizarPais(id, nombre, bandera, confederacion, ranking_fifa, director_tecnico, capitan, participaciones, mejor_resultado)
{
    if !DB_Conectar()
        return false
    sql := ""
    sql .= "UPDATE Paises SET nombre='"
    sql .= DB_Escape(nombre) "', bandera='"
    sql .= DB_Escape(bandera) "', confederacion='"
    sql .= DB_Escape(confederacion) "', ranking_fifa="
    sql .= ranking_fifa ", director_tecnico='"
    sql .= DB_Escape(director_tecnico) "', capitan='"
    sql .= DB_Escape(capitan) "', participaciones="
    sql .= participaciones ", mejor_resultado='"
    sql .= DB_Escape(mejor_resultado) "' WHERE id="
    sql .= id ";"
    return gFifaDB.Exec(sql)
}

DB_EliminarPais(id)
{
    if !DB_Conectar()
        return false
    return gFifaDB.Exec("DELETE FROM Paises WHERE id=" id ";")
}

DB_ObtenerPaises(nombreFiltro := "", confFiltro := "")
{
    tb := ""
    if !DB_Conectar()
        return tb
    sql := "SELECT id, nombre, bandera, confederacion, ranking_fifa, director_tecnico, capitan, participaciones, mejor_resultado FROM Paises WHERE 1=1"
    if (nombreFiltro != "")
        sql .= " AND nombre LIKE '%" DB_Escape(nombreFiltro) "%'"
    if (confFiltro != "")
        sql .= " AND confederacion LIKE '%" DB_Escape(confFiltro) "%'"
    sql .= " ORDER BY ranking_fifa ASC, nombre ASC"
    gFifaDB.GetTable(sql, tb)
    return tb
}

DB_InsertarEstadio(nombre, ciudad, pais, capacidad, inauguracion, imagen, latitud := "", longitud := "")
{
    if !DB_Conectar()
        return false
    sql := ""
    sql .= "INSERT INTO Estadios (nombre, ciudad, pais, capacidad, inauguracion, imagen, latitud, longitud) VALUES ('"
    sql .= DB_Escape(nombre) "', '"
    sql .= DB_Escape(ciudad) "', '"
    sql .= DB_Escape(pais) "', "
    sql .= capacidad ", "
    sql .= inauguracion ", '"
    sql .= DB_Escape(imagen) "', '"
    sql .= DB_Escape(latitud) "', '"
    sql .= DB_Escape(longitud) "');"
    return gFifaDB.Exec(sql)
}

DB_ObtenerEstadios()
{
    tb := ""
    if !DB_Conectar()
        return tb
    gFifaDB.GetTable("SELECT id, nombre, ciudad, pais, capacidad, inauguracion, imagen, latitud, longitud FROM Estadios ORDER BY capacidad DESC", tb)
    return tb
}

DB_InsertarPartido(fecha, hora, equipo_local, equipo_visitante, goles_local, goles_visitante, estadio_id, fase, grupo)
{
    if !DB_Conectar()
        return false
    sql := ""
    sql .= "INSERT INTO Partidos (fecha, hora, equipo_local, equipo_visitante, goles_local, goles_visitante, estadio_id, fase, grupo) VALUES ('"
    sql .= DB_Escape(fecha) "', '"
    sql .= DB_Escape(hora) "', '"
    sql .= DB_Escape(equipo_local) "', '"
    sql .= DB_Escape(equipo_visitante) "', "
    sql .= goles_local ", "
    sql .= goles_visitante ", "
    sql .= estadio_id ", '"
    sql .= DB_Escape(fase) "', '"
    sql .= DB_Escape(grupo) "');"
    return gFifaDB.Exec(sql)
}

DB_ObtenerPartidos(fase := "", equipo := "", estadio := "", fecha := "")
{
    tb := ""
    if !DB_Conectar()
        return tb
    sql := "SELECT p.id, p.fecha, p.hora, p.equipo_local, p.equipo_visitante, p.goles_local, p.goles_visitante, p.estadio_id, p.fase, p.grupo, e.nombre AS estadio_nombre, e.ciudad AS estadio_ciudad FROM Partidos p LEFT JOIN Estadios e ON e.id = p.estadio_id WHERE 1=1"
    if (fase != "")
        sql .= " AND p.fase LIKE '%" DB_Escape(fase) "%'"
    if (equipo != "")
        sql .= " AND (p.equipo_local LIKE '%" DB_Escape(equipo) "%' OR p.equipo_visitante LIKE '%" DB_Escape(equipo) "%')"
    if (estadio != "")
        sql .= " AND e.nombre LIKE '%" DB_Escape(estadio) "%'"
    if (fecha != "")
        sql .= " AND p.fecha LIKE '%" DB_Escape(fecha) "%'"
    sql .= " ORDER BY p.fecha ASC, p.hora ASC"
    gFifaDB.GetTable(sql, tb)
    return tb
}

DB_ObtenerJugadores()
{
    tb := ""
    if !DB_Conectar()
        return tb
    gFifaDB.GetTable("SELECT id, nombre, edad, posicion, pais_id, club, goles, asistencias FROM Jugadores ORDER BY goles DESC, asistencias DESC, nombre ASC", tb)
    return tb
}

DB_NombreEstadioPorId(id)
{
    tb := ""
    if !DB_Conectar()
        return ""
    if !gFifaDB.GetTable("SELECT nombre FROM Estadios WHERE id=" id " LIMIT 1", tb, 1)
        return ""
    if (tb.RowCount < 1)
        return ""
    return tb.Rows[1][1]
}

DB_CiudadEstadioPorId(id)
{
    tb := ""
    if !DB_Conectar()
        return ""
    if !gFifaDB.GetTable("SELECT ciudad FROM Estadios WHERE id=" id " LIMIT 1", tb, 1)
        return ""
    if (tb.RowCount < 1)
        return ""
    return tb.Rows[1][1]
}

DB_Escape(valor)
{
    return StrReplace(valor, "'", "''")
}
