' ===================== PlayZoneTV v2 =====================
' Catálogo: TMDB.  TV en vivo: iptv-org (directorio público).
' Reproducción de películas/series: SOLO fuentes propias en source/sources.json.

sub init()
  m.navKeys = m.top.findNode("navKeys")
  m.navKeys.setFocus(true)
  m.bg = m.top.findNode("bg")
  m.hero = m.top.findNode("hero")
  m.title = m.top.findNode("title")
  m.meta = m.top.findNode("meta")
  m.heroGenres = m.top.findNode("heroGenres")
  m.ov = m.top.findNode("ov")
  m.rows = m.top.findNode("rows")
  m.grid = m.top.findNode("grid")
  m.posterGrid = m.top.findNode("posterGrid")
  if m.posterGrid <> invalid then
    m.posterGrid.observeField("itemSelected", "onPosterGridSelect")
    m.posterGrid.observeField("itemFocused", "onPosterFocus")
  end if
  m.videoPlayer = invalid
  m.streamTimer = CreateObject("roSGNode", "Timer")
  m.streamTimer.duration = 0.5
  m.streamTimer.repeat = false
  m.streamTimer.observeField("fire", "onStreamTimer")
  m.help = m.top.findNode("help")
  m.head = m.top.findNode("head")
  m.status = m.top.findNode("status")
  m.navGroup = m.top.findNode("navGroup")
  m.sideBg = m.top.findNode("sideBg")
  m.sideLine = m.top.findNode("sideLine")
  m.logo = m.top.findNode("logo")
  m.heroAll = m.top.findNode("heroAll")
  m.tag = m.top.findNode("tag")
  m.navHint = m.top.findNode("navHint")
  m.hint = m.top.findNode("hint")
  m.dots = m.top.findNode("dots")
  m.heroTimer = m.top.findNode("heroTimer")
  m.heroTimer.observeField("fire", "onHeroTick")
  m.focusGuard = m.top.findNode("focusGuard")
  m.focusGuard.observeField("fire", "onFocusGuard")
  m.focusGuard.control = "start"
  m.featured = []
  m.featIdx = 0
  m.eps = invalid
  m.recent = []
  m.playRec = invalid
  m.cache = {}
  m.pend = {}
  m.tasks = {}
  m.apiCfg = {}
  m.moviesApiList = []
  m.seriesApiList = []
  m.moviesApiIndex = 0
  m.seriesApiIndex = 0
  m.currentStreams = []
  m.currentStreamIndex = 0
  m.pendingPlay = invalid
  m.playingStream = false
  m.apiAccum = []
  m.apiKind = ""
  m.apiPage = 1
  m.catalogGen = 0
  m.zone = "nav"
  m.tvMode = "countries"
  m.tab = 0
  m.tabId = "home"
  m.lastErr = ""
  m.playKey = ""
  m.rows.observeField("rowItemFocused", "onFocus")
  m.rows.observeField("rowItemSelected", "onSelect")
  m.grid.observeField("itemSelected", "onGridSelect")

  m.tabs = [
    { id: "home", t: "Inicio", icon: "home" }, { id: "movies", t: "Películas", icon: "movies" }, { id: "series", t: "Series", icon: "series" },
    { id: "anime", t: "Anime", icon: "anime" }, { id: "doramas", t: "Doramas", icon: "doramas" }, { id: "tv", t: "TV en vivo", icon: "live" },
    { id: "favs", t: "Mi lista", icon: "list" }, { id: "search", t: "Buscar", icon: "search" }, { id: "help", t: "Ayuda", icon: "help" }
  ]
  m.help.text = "CÓMO USAR PLAYZONETV" + Chr(10) + Chr(10) + "Menú a la izquierda: Arriba / Abajo para cambiar de sección" + Chr(10) + "Derecha u OK: entrar al contenido      Izquierda o Atrás: volver al menú" + Chr(10) + "OK sobre un título: ver ficha, plataformas y añadir a Mi lista" + Chr(10) + "Series, anime y doramas: elige temporada y episodio en la ficha" + Chr(10) + "Tecla *: buscar en cualquier momento" + Chr(10) + "Botones << y >>: cambiar de sección      Botón de repetir: volver al menú" + Chr(10) + Chr(10) + "Los datos vienen de TMDB. La TV en vivo usa el directorio público iptv-org."

  defineTabs()
  buildCountries()
  buildNav()
  loadUser()

  m.key = ""
  m.apiCfg = {}
  cfg = ParseJson(ReadAsciiFile("pkg:/source/config.json"))
  if cfg <> invalid then
    m.apiCfg = cfg
    if cfg.tmdb_key <> invalid and cfg.tmdb_key <> "" then m.key = cfg.tmdb_key
  end if
  if m.key = "TU_API_KEY" then m.key = ""
  buildApiListsFromCfg(m.apiCfg)
  selectTab(0)
  checkForUpdates()
end sub

sub buildApiListsFromCfg(cfg as Object)
  m.moviesApiList = []
  m.seriesApiList = []
  if cfg = invalid then return
  keysM = ["moviesApiUrl1", "moviesApiUrl2", "moviesApiUrl"]
  keysS = ["seriesApiUrl1", "seriesApiUrl2", "seriesApiUrl"]
  for each k in keysM
    if cfg.DoesExist(k) then
      u = cfg[k]
      if type(u) = "roString" or type(u) = "String" then
        if u <> "" then m.moviesApiList.Push(u)
      end if
    end if
  end for
  for each k in keysS
    if cfg.DoesExist(k) then
      u = cfg[k]
      if type(u) = "roString" or type(u) = "String" then
        if u <> "" then m.seriesApiList.Push(u)
      end if
    end if
  end for
end sub


' ===== Catalogo API PlayZone =====
sub loadApiHome()
  m.status.text = "Cargando..."
  m.homeQueue = []
  h = CreateObject("roAssociativeArray")
  h.kind = "movies"
  h.title = "Peliculas"
  m.homeQueue.Push(h)
  h = CreateObject("roAssociativeArray")
  h.kind = "series"
  h.title = "Series"
  m.homeQueue.Push(h)
  h = CreateObject("roAssociativeArray")
  h.kind = "anime"
  h.title = "Anime"
  m.homeQueue.Push(h)
  h = CreateObject("roAssociativeArray")
  h.kind = "doramas"
  h.title = "Doramas"
  m.homeQueue.Push(h)
  m.homeRoot = CreateObject("roSGNode", "ContentNode")
  m.homeIdx = 0
  loadNextHomeRow()
end sub

sub loadNextHomeRow()
  if m.homeIdx >= m.homeQueue.count() then
    if m.homeRoot.getChildCount() = 0 then
      m.status.text = "No se pudo cargar el inicio."
      return
    end if
    m.cache["home"] = m.homeRoot
    if m.tabId = "home" then showRows(m.homeRoot)
    return
  end if
  item = m.homeQueue[m.homeIdx]
  m.homeKind = item.kind
  m.homeTitle = item.title
  task = CreateObject("roSGNode", "ApiTask")
  m.homeTask = task
  task.requestUrl = apiUrlFor(item.kind)
  task.observeField("response", "onHomeRowDone")
  task.control = "RUN"
end sub

sub onHomeRowDone()
  res = invalid
  if m.homeTask <> invalid then res = m.homeTask.response
  list = pickApiList(res)
  if list.count() > 0 then
    row = CreateObject("roSGNode", "ContentNode")
    row.title = m.homeTitle
    nMax = list.count()
    if nMax > 30 then nMax = 30
    for i = 0 to nMax - 1
      n = apiItemToNode(list[i], m.homeKind)
      if n <> invalid then row.appendChild(n)
    end for
    if row.getChildCount() > 0 then m.homeRoot.appendChild(row)
  end if
  m.homeIdx = m.homeIdx + 1
  loadNextHomeRow()
end sub

function apiUrlFor(kind as String) as String
  if kind = "movies" then
    if m.moviesApiList.count() > 0 then return m.moviesApiList[0] + "1"
    return "https://pelisplushd.tvymas.workers.dev/peliculas?page=1"
  end if
  if kind = "series" then
    if m.seriesApiList.count() > 0 then return m.seriesApiList[0] + "1"
    return "https://pelisplushd.tvymas.workers.dev/series?page=1"
  end if
  if kind = "anime" then
    if m.apiCfg <> invalid and m.apiCfg.DoesExist("animesApiUrl") then return m.apiCfg.animesApiUrl + "1"
    return "https://pelisplushd.tvymas.workers.dev/animes?page=1"
  end if
  if kind = "doramas" then
    if m.apiCfg <> invalid and m.apiCfg.DoesExist("doramasApiUrl") then return m.apiCfg.doramasApiUrl + "1"
    return "https://pelisplushd.tvymas.workers.dev/doramas?page=1"
  end if
  return ""
end function

sub loadApiCatalog(kind as String)
  m.status.text = "Cargando..."
  m.catalogGen = m.catalogGen + 1
  m.apiKind = kind
  m.apiAccum = []
  m.apiPage = 1
  loadApiCatalogPage(kind, 1)
end sub

sub loadApiCatalogPage(kind as String, page as Integer)
  url = ""
  if kind = "movies" then
    if m.moviesApiList.count() = 0 then buildApiListsFromCfg(m.apiCfg)
    if m.moviesApiList.count() = 0 then
      m.status.text = "Sin API de peliculas."
      return
    end if
    url = m.moviesApiList[0] + page.toStr()
  else if kind = "series" then
    if m.seriesApiList.count() = 0 then buildApiListsFromCfg(m.apiCfg)
    if m.seriesApiList.count() = 0 then
      m.status.text = "Sin API de series."
      return
    end if
    url = m.seriesApiList[0] + page.toStr()
  else if kind = "anime" then
    if m.apiCfg <> invalid and m.apiCfg.DoesExist("animesApiUrl") then
      url = m.apiCfg.animesApiUrl + page.toStr()
    else
      url = "https://pelisplushd.tvymas.workers.dev/animes?page=" + page.toStr()
    end if
  else if kind = "doramas" then
    if m.apiCfg <> invalid and m.apiCfg.DoesExist("doramasApiUrl") then
      url = m.apiCfg.doramasApiUrl + page.toStr()
    else
      url = "https://pelisplushd.tvymas.workers.dev/doramas?page=" + page.toStr()
    end if
  end if
  if url = "" then
    m.status.text = "URL vacia."
    return
  end if
  m.apiPage = page
  task = CreateObject("roSGNode", "ApiTask")
  m.apiTask = task
  task.requestUrl = url
  task.observeField("response", "onApiCatalog")
  task.control = "RUN"
end sub

sub onApiCatalog()
  res = invalid
  if m.apiTask <> invalid then res = m.apiTask.response
  kind = m.apiKind
  ' Ignorar respuesta vieja si ya cambio de seccion
  if m.tabId <> kind then return
  if res = invalid then
    if m.tabId = kind then m.status.text = "No se pudo cargar el catalogo."
    return
  end if
  list = pickApiList(res)
  for each item in list
    m.apiAccum.Push(item)
  end for
  ' Cargar mas paginas (hasta 12) para ver todo el catalogo
  maxPages = 12
  if res <> invalid and res.total_pages <> invalid then
    tp = res.total_pages
    if type(tp) = "roString" or type(tp) = "String" then tp = Val(tp)
    if tp > 0 and tp < maxPages then maxPages = tp
  end if
  if m.apiPage < maxPages and list.count() > 0 then
    loadApiCatalogPage(kind, m.apiPage + 1)
    return
  end if
  flat = CreateObject("roSGNode", "ContentNode")
  for each item in m.apiAccum
    n = apiItemToNode(item, kind)
    if n <> invalid then flat.appendChild(n)
  end for
  if flat.getChildCount() = 0 then
    m.status.text = "La API no devolvio titulos."
    return
  end if
  m.cache[kind] = flat
  if m.tabId = kind then showPosterGrid(flat, kind)
end sub

sub showPosterGrid(root as Object, kind as String)
  hideAll()
  m.head.text = ""
  if kind = "movies" then m.head.text = "Peliculas"
  if kind = "series" then m.head.text = "Series"
  if kind = "anime" then m.head.text = "Anime"
  if kind = "doramas" then m.head.text = "Doramas"
  m.status.text = ""
  m.hero.visible = false
  m.rows.visible = false
  m.grid.visible = false
  if m.posterGrid = invalid then
    ' fallback: una sola fila
    wrap = CreateObject("roSGNode", "ContentNode")
    row = CreateObject("roSGNode", "ContentNode")
    row.title = m.head.text
    for i = 0 to root.getChildCount() - 1
      row.appendChild(root.getChild(i))
    end for
    wrap.appendChild(row)
    showRows(wrap)
    return
  end if
  m.posterGrid.content = root
  m.posterGrid.visible = true
  m.posterGrid.jumpToItem = 0
  m.hero.visible = true
  if root.getChildCount() > 0 then updateHeroFrom(root.getChild(0))
  ' Quedarse en la barra de secciones (Derecha/OK para entrar al listado)
  m.zone = "nav"
  focusNav()
end sub

sub onPosterFocus()
  if m.posterGrid = invalid or m.posterGrid.content = invalid then return
  idx = m.posterGrid.itemFocused
  if idx = invalid then return
  it = m.posterGrid.content.getChild(idx)
  if it <> invalid then
    m.hero.visible = true
    updateHeroFrom(it)
  end if
end sub

sub onPosterGridSelect()
  if m.posterGrid = invalid or m.posterGrid.content = invalid then return
  idx = m.posterGrid.itemSelected
  it = m.posterGrid.content.getChild(idx)
  if it <> invalid then openDetails(it)
end sub

function pickApiList(res as Object) as Object
  out = []
  if res = invalid then return out
  if type(res) = "roArray" then return res
  keys = ["results", "resultados", "movies", "series", "animes", "doramas", "items", "data"]
  for each k in keys
    if res.DoesExist(k) then
      v = res[k]
      if v <> invalid and type(v) = "roArray" then return v
    end if
  end for
  return out
end function

function strVal(v as Dynamic) as String
  if v = invalid then return ""
  if type(v) = "roString" or type(v) = "String" then return v
  return v.toStr()
end function

function intVal(v as Dynamic) as Integer
  if v = invalid then return 0
  if type(v) = "roInt" or type(v) = "Integer" then return v
  if type(v) = "roFloat" or type(v) = "Float" then return Int(v)
  if type(v) = "roString" or type(v) = "String" then return Val(v)
  return 0
end function

function apiItemToNode(item as Object, kind as String) as Object
  if item = invalid then return invalid
  title = strVal(item.title)
  if title = "" then title = strVal(item.titulo)
  if title = "" then title = strVal(item.name)
  if title = "" then title = strVal(item.nombre)
  if title = "" then return invalid

  poster = strVal(item.tmdb_poster)
  if poster = "" then poster = strVal(item.poster_tmdb)
  if poster = "" then poster = strVal(item.portada)
  if poster = "" then poster = strVal(item.image)
  if poster = "" then poster = strVal(item.poster)
  if Instr(1, poster, "/original/") > 0 then poster = poster.Replace("/original/", "/w342/")
  if Instr(1, poster, "/w500/") > 0 then poster = poster.Replace("/w500/", "/w342/")
  if Instr(1, poster, "/w154/") > 0 then poster = poster.Replace("/w154/", "/w342/")

  ov = strVal(item.tmdb_overview)
  if ov = "" then ov = strVal(item.overview_tmdb)
  if ov = "" then ov = strVal(item.description)
  if ov = "" then ov = strVal(item.overview)
  if ov = "" then ov = strVal(item.descripcion)

  year = strVal(item.year)
  rating = Left(strVal(item.tmdb_rating), 3)
  if rating = "" then rating = Left(strVal(item.rating), 3)

  mt = "movie"
  if kind = "series" or kind = "anime" or kind = "doramas" then mt = "tv"
  id = intVal(item.tmdb_id)
  if id = 0 then id = intVal(item.id)

  extractUrl = strVal(item.extractUrl)
  if extractUrl = "" then extractUrl = strVal(item.url_vid)
  if extractUrl = "" then extractUrl = strVal(item.url)
  if extractUrl = "" then extractUrl = strVal(item.link)
  slug = strVal(item.slug)

  it = CreateObject("roSGNode", "ContentNode")
  it.title = title
  it.HDPosterUrl = poster
  ck = mt + ":api:" + slug
  if slug = "" then ck = mt + ":api:" + title
  it.addField("tmdbId", "integer", false)
  it.tmdbId = id
  it.addField("mediaType", "string", false)
  it.mediaType = mt
  it.addField("ckey", "string", false)
  it.ckey = ck
  it.addField("overview", "string", false)
  it.overview = ov
  ' Fondo: URL completa de API/TMDB (backdrop o poster)
  bd = strVal(item.backdrop)
  if bd = "" then bd = strVal(item.tmdb_backdrop)
  if bd = "" then bd = strVal(item.backdrop_path)
  if bd <> "" and Left(bd, 1) = "/" then bd = "https://image.tmdb.org/t/p/w1280" + bd
  if bd = "" then bd = strVal(item.tmdb_poster)
  if bd = "" then bd = strVal(item.poster_tmdb)
  if bd = "" then bd = strVal(item.image)
  if bd = "" then bd = poster
  it.addField("backdrop", "string", false)
  it.backdrop = bd
  it.addField("year", "string", false)
  it.year = year
  it.addField("rating", "string", false)
  it.rating = rating
  it.addField("watched", "boolean", false)
  it.watched = false
  it.addField("rank", "integer", false)
  it.rank = 0
  it.addField("prog", "float", false)
  it.prog = 0.0
  it.addField("extractUrl", "string", false)
  it.extractUrl = extractUrl
  it.addField("fromApi", "boolean", false)
  it.fromApi = true
  return it
end function

sub defineTabs()
  m.defs = {
    home: [
      { t: "Top 10 de hoy", p: "/trending/all/day", q: "", mt: "", rank: true },
      { t: "Series del momento", p: "/trending/tv/week", q: "", mt: "tv" },
      { t: "Estrenos en cines", p: "/movie/now_playing", q: "&region=MX", mt: "movie" },
      { t: "Anime recomendado", p: "/discover/tv", q: "&with_genres=16&with_original_language=ja&sort_by=popularity.desc", mt: "tv" },
      { t: "Doramas coreanos", p: "/discover/tv", q: "&with_origin_country=KR&sort_by=popularity.desc", mt: "tv" },
      { t: "Películas populares", p: "/discover/movie", q: "&sort_by=popularity.desc", mt: "movie" },
      { t: "Mejor calificadas", p: "/movie/top_rated", q: "", mt: "movie" }
    ],
    movies: [
      { t: "Populares", p: "/discover/movie", q: "&sort_by=popularity.desc", mt: "movie" },
      { t: "En cartelera", p: "/movie/now_playing", q: "&region=MX", mt: "movie" },
      { t: "Mejor calificadas", p: "/movie/top_rated", q: "", mt: "movie" },
      { t: "Acción", p: "/discover/movie", q: "&with_genres=28&sort_by=popularity.desc", mt: "movie" },
      { t: "Comedia", p: "/discover/movie", q: "&with_genres=35&sort_by=popularity.desc", mt: "movie" },
      { t: "Terror", p: "/discover/movie", q: "&with_genres=27&sort_by=popularity.desc", mt: "movie" },
      { t: "Animación", p: "/discover/movie", q: "&with_genres=16&sort_by=popularity.desc", mt: "movie" },
      { t: "Ciencia ficción", p: "/discover/movie", q: "&with_genres=878&sort_by=popularity.desc", mt: "movie" }
    ],
    series: [
      { t: "Tendencias", p: "/trending/tv/week", q: "", mt: "tv" },
      { t: "Mejor calificadas", p: "/tv/top_rated", q: "", mt: "tv" },
      { t: "Drama", p: "/discover/tv", q: "&with_genres=18&sort_by=popularity.desc", mt: "tv" },
      { t: "Comedia", p: "/discover/tv", q: "&with_genres=35&sort_by=popularity.desc", mt: "tv" },
      { t: "Crimen", p: "/discover/tv", q: "&with_genres=80&sort_by=popularity.desc", mt: "tv" },
      { t: "Ciencia ficción y fantasía", p: "/discover/tv", q: "&with_genres=10765&sort_by=popularity.desc", mt: "tv" }
    ],
    anime: [
      { t: "Anime popular", p: "/discover/tv", q: "&with_genres=16&with_original_language=ja&sort_by=popularity.desc", mt: "tv" },
      { t: "Mejor calificado", p: "/discover/tv", q: "&with_genres=16&with_original_language=ja&sort_by=vote_average.desc&vote_count.gte=300", mt: "tv" },
      { t: "Acción y aventura", p: "/discover/tv", q: "&with_genres=16,10759&with_original_language=ja&sort_by=popularity.desc", mt: "tv" },
      { t: "Películas de anime", p: "/discover/movie", q: "&with_genres=16&with_original_language=ja&sort_by=popularity.desc", mt: "movie" }
    ],
    doramas: [
      { t: "Doramas coreanos populares", p: "/discover/tv", q: "&with_origin_country=KR&sort_by=popularity.desc", mt: "tv" },
      { t: "Mejor calificados", p: "/discover/tv", q: "&with_origin_country=KR&sort_by=vote_average.desc&vote_count.gte=100", mt: "tv" },
      { t: "Misterio", p: "/discover/tv", q: "&with_origin_country=KR&with_genres=9648&sort_by=popularity.desc", mt: "tv" },
      { t: "Doramas japoneses", p: "/discover/tv", q: "&with_origin_country=JP&without_genres=16&sort_by=popularity.desc", mt: "tv" }
    ]
  }
end sub

' ---------- Menú vertical izquierdo ----------
sub buildNav()
  m.navBars = []
  m.navMarks = []
  m.navIcons = []
  m.navLabels = []
  y = 140
  for i = 0 to m.tabs.count() - 1
    bar = m.navGroup.createChild("Rectangle")
    bar.translation = [16, y]
    bar.width = 330
    bar.height = 70
    bar.color = "0xA66BFFFF"
    bar.visible = false
    mark = m.navGroup.createChild("Rectangle")
    mark.translation = [0, y + 15]
    mark.width = 6
    mark.height = 40
    mark.color = "0xA66BFFFF"
    mark.visible = false
    ic = m.navGroup.createChild("Poster")
    ic.translation = [33, y + 13]
    ic.width = 44
    ic.height = 44
    ic.loadDisplayMode = "scaleToFit"
    ic.uri = "pkg:/images/nav/" + m.tabs[i].icon + ".png"
    lb = m.navGroup.createChild("Label")
    lb.translation = [104, y]
    lb.width = 236
    lb.height = 70
    lb.vertAlign = "center"
    lb.font = "font:MediumSystemFont"
    lb.text = m.tabs[i].t
    lb.visible = false
    m.navBars.Push(bar)
    m.navMarks.Push(mark)
    m.navIcons.Push(ic)
    m.navLabels.Push(lb)
    y = y + 80
  end for
end sub

sub renderNav()
  expanded = (m.zone = "nav")
  if expanded then
    m.sideBg.width = 360
    m.sideLine.translation = [360, 0]
    m.logo.translation = [36, 50]
    m.logo.width = 300
    m.logo.horizAlign = "left"
    m.logo.text = "PlayZoneTV"
    m.heroAll.translation = [210, 0]
  else
    m.sideBg.width = 110
    m.sideLine.translation = [110, 0]
    m.logo.translation = [0, 50]
    m.logo.width = 110
    m.logo.horizAlign = "center"
    m.logo.text = "PZ"
    m.heroAll.translation = [0, 0]
  end if
  for i = 0 to m.tabs.count() - 1
    sel = (i = m.tab)
    m.navBars[i].visible = (sel and expanded)
    m.navMarks[i].visible = (sel and not expanded)
    m.navLabels[i].visible = expanded
    if sel then
      m.navLabels[i].color = "0xFFFFFFFF"
      m.navIcons[i].blendColor = "0xFFFFFFFF"
    else
      m.navLabels[i].color = "0xB5A9CCFF"
      m.navIcons[i].blendColor = "0x9A8FB5FF"
    end if
  end for
  m.navHint.visible = (m.zone = "content")
  updateHomeUi()
end sub

sub moveTab(d as Integer)
  n = m.tab + d
  if n < 0 or n >= m.tabs.count() then return
  selectTab(n)
  focusNav()
end sub

sub hideAll()
  m.rows.visible = false
  m.grid.visible = false
  if m.posterGrid <> invalid then m.posterGrid.visible = false
  m.help.visible = false
  m.hero.visible = false
  m.head.text = ""
  m.status.text = ""
  m.heroFetchId = 0
  m.tag.text = ""
  m.bg.uri = ""
  m.hint.visible = false
  m.dots.visible = false
  m.heroTimer.control = "stop"
end sub

sub selectTab(i as Integer)
  m.tab = i
  m.tabId = m.tabs[i].id
  renderNav()
  hideAll()
  id = m.tabId
  if id = "tv" then
    showCountries()
  else if id = "help" then
    m.help.visible = true
  else if id = "favs" then
    showRows(buildFavsContent())
  else if id = "search" then
    if m.cache.DoesExist("search") then
      showRows(m.cache["search"])
    else
      m.status.text = "Pulsa OK para buscar películas y series."
    end if
  else
    if m.cache.DoesExist(id) then
      if id = "movies" or id = "series" or id = "anime" or id = "doramas" then
        showPosterGrid(m.cache[id], id)
      else if id = "home" then
        showRows(m.cache[id])
      else
        showRows(m.cache[id])
      end if
    else
      loadTab(id)
    end if
  end if
end sub

sub focusNav()
  m.zone = "nav"
  renderNav()
  m.navKeys.setFocus(true)
  if m.tabId = "home" and m.featured.count() > 0 and m.rows.visible then showFeatured(m.featIdx)
end sub

sub focusContent()
  if m.tabId = "tv" then
    m.zone = "content"
    m.grid.setFocus(true)
  else if m.posterGrid <> invalid and m.posterGrid.visible then
    m.zone = "content"
    m.posterGrid.setFocus(true)
  else if m.rows.visible then
    m.zone = "content"
    m.rows.setFocus(true)
  else
    return
  end if
  renderNav()
  if m.tabId <> "tv" and m.rows.visible then onFocus()
end sub

sub enterContent()
  if m.tabId = "search" then
    openSearch()
  else if m.tabId <> "help" then
    focusContent()
  end if
end sub

' ---------- Carga TMDB ----------
sub loadTab(id as String)
  if id = "home" or id = "movies" or id = "series" or id = "anime" or id = "doramas" then
    if id = "home" then
      loadApiHome()
    else
      loadApiCatalog(id)
    end if
    return
  end if
  if m.key = "" then
    m.status.text = "Falta tu API key de TMDB. Editala en source/config.json y vuelve a instalar el canal."
    return
  end if
  if m.pend.DoesExist(id) then
    if m.pend[id].n > 0 then
      m.status.text = "Cargando..."
      return
    end if
  end if
  defs = m.defs[id]
  m.pend[id] = { n: defs.count(), res: {}, defs: defs }
  m.status.text = "Cargando..."
  for i = 0 to defs.count() - 1
    fetch(id, i, defs[i].p, defs[i].q, "")
  end for
end sub

sub fetch(tabId as String, idx as Integer, path as String, params as String, query as String)
  t = CreateObject("roSGNode", "TmdbTask")
  t.tab = tabId
  t.idx = idx
  t.apiKey = m.key
  t.path = path
  t.params = params
  t.query = query
  t.observeField("result", "onResult")
  m.tasks[tabId + idx.toStr()] = t
  t.control = "RUN"
end sub

sub onResult(evt as Object)
  t = evt.getRoSGNode()
  if not m.pend.DoesExist(t.tab) then return
  pend = m.pend[t.tab]
  if t.tab = "search" then
    if t.query <> pend.q then return
  end if
  if pend.n <= 0 then return
  pend.res[t.idx.toStr()] = evt.getData()
  pend.n = pend.n - 1
  if pend.n > 0 then return
  root = buildContent(t.tab, pend)
  if root.getChildCount() > 0 then
    m.cache[t.tab] = root
  else
    m.pend.Delete(t.tab)
  end if
  if m.tabId = t.tab then
    showRows(root)
    if t.tab = "search" and root.getChildCount() > 0 then focusContent()
  end if
end sub

function buildContent(tabName as String, pend as Object) as Object
  root = CreateObject("roSGNode", "ContentNode")
  if tabName = "home" then
    r0 = listRow("Seguir viendo", m.recent, "")
    if r0.getChildCount() > 0 then root.appendChild(r0)
    r1 = listRow("Mi lista", m.favs, "")
    if r1.getChildCount() > 0 then root.appendChild(r1)
    buildFeatured(pend.res["0"])
  end if
  m.lastErr = ""
  for i = 0 to pend.defs.count() - 1
    d = pend.defs[i]
    res = pend.res[i.toStr()]
    if res <> invalid then
      if res.results <> invalid then
        row = makeRow(d.t, res.results, d.mt, d.DoesExist("rank"))
        if row.getChildCount() > 0 then root.appendChild(row)
      else if res.error <> invalid then
        m.lastErr = res.error
      else if res.status_message <> invalid then
        m.lastErr = res.status_message
      end if
    end if
  end for
  return root
end function

function txt(v as Dynamic) as String
  if v = invalid then return ""
  if type(v) = "roString" or type(v) = "String" then return v
  return v.toStr()
end function

function makeNode(title as String, poster as String, kind as String, id as Integer, ov as String, bd as String, year as String, rating as String) as Object
  it = CreateObject("roSGNode", "ContentNode")
  it.title = title
  it.HDPosterUrl = poster
  ck = kind + ":" + id.toStr()
  it.addFields({ tmdbId: id, mediaType: kind, ckey: ck, overview: ov, backdrop: bd, year: year, rating: rating, watched: m.watched.DoesExist(ck), rank: 0, prog: 0.0 })
  return it
end function

function makeItem(x as Object, mt as String) as Object
  title = txt(x.title)
  if title = "" then title = txt(x.name)
  kind = mt
  if kind = "" then kind = txt(x.media_type)
  if kind = "" then kind = "movie"
  date = txt(x.release_date)
  if date = "" then date = txt(x.first_air_date)
  return makeNode(title, "https://image.tmdb.org/t/p/w342" + txt(x.poster_path), kind, x.id, txt(x.overview), txt(x.backdrop_path), Left(date, 4), Left(txt(x.vote_average), 3))
end function

function makeRow(title as String, results as Object, mt as String, ranked as Boolean) as Object
  row = CreateObject("roSGNode", "ContentNode")
  row.title = title
  n = 0
  for each x in results
    if x.poster_path <> invalid then
      if txt(x.media_type) <> "person" then
        it = makeItem(x, mt)
        if ranked then
          n = n + 1
          it.rank = n
        end if
        row.appendChild(it)
        if ranked and n >= 10 then exit for
      end if
    end if
  end for
  return row
end function

' ---------- Mostrar contenido ----------
sub showRows(root as Object)
  m.status.text = ""
  m.grid.visible = false
  m.help.visible = false
  first = root.getChild(0)
  if first = invalid then
    m.rows.visible = false
    m.hero.visible = false
    if m.tabId = "favs" then
      m.status.text = "Aún no tienes títulos en Mi lista. Abre una ficha y elige Añadir a mi lista."
    else if m.lastErr <> "" then
      m.status.text = "No se pudo cargar TMDB: " + m.lastErr
    else
      m.status.text = "No hay contenido para mostrar."
    end if
    return
  end if
  m.rows.content = root
  m.rows.visible = true
  m.hero.visible = true
  if m.tabId = "home" and m.featured.count() > 0 and m.zone = "nav" then
    showFeatured(m.featIdx)
  else
    m.tag.text = first.title
    updateHeroFrom(first.getChild(0))
  end if
  updateHomeUi()
  if m.tabId = "home" then
    ' En inicio: foco en filas para poder moverse al entrar
    m.zone = "content"
    renderNav()
    m.rows.setFocus(true)
  else if m.zone = "content" then
    m.rows.setFocus(true)
  else
    focusNav()
  end if
end sub

' ---------- Portada destacada del inicio ----------
sub buildFeatured(res as Dynamic)
  m.featured = []
  m.featIdx = 0
  m.dots.removeChildrenIndex(m.dots.getChildCount(), 0)
  if res = invalid then return
  if res.results = invalid then return
  for each x in res.results
    if x.backdrop_path <> invalid and x.poster_path <> invalid then
      if txt(x.media_type) <> "person" then m.featured.Push(makeItem(x, ""))
    end if
    if m.featured.count() >= 6 then exit for
  end for
  for i = 1 to m.featured.count()
    dot = m.dots.createChild("Rectangle")
    dot.height = 6
  end for
  updateDots()
end sub

sub updateDots()
  x = 0
  for i = 0 to m.dots.getChildCount() - 1
    dt = m.dots.getChild(i)
    if i = m.featIdx then
      dt.width = 56
      dt.color = "0xA66BFFFF"
    else
      dt.width = 26
      dt.color = "0x5B4B7AFF"
    end if
    dt.translation = [x, 0]
    x = x + dt.width + 10
  end for
end sub

sub showFeatured(i as Integer)
  if m.featured.count() = 0 then return
  m.featIdx = i
  m.tag.text = "DESTACADO DE HOY"
  updateHeroFrom(m.featured[i])
  updateDots()
end sub

sub updateHomeUi()
  isHome = (m.tabId = "home" and m.rows.visible and m.featured.count() > 0)
  inNav = (m.zone = "nav")
  m.hint.visible = (isHome and inNav)
  m.dots.visible = (isHome and inNav)
  if isHome and inNav then
    m.heroTimer.control = "start"
  else
    m.heroTimer.control = "stop"
  end if
end sub

sub onHeroTick()
  if m.tabId <> "home" or m.zone <> "nav" then return
  if m.details <> invalid or m.video <> invalid then return
  if m.featured.count() < 2 then return
  showFeatured((m.featIdx + 1) mod m.featured.count())
end sub

sub updateHeroFrom(it as Object)
  if it = invalid then return
  m.title.text = it.title
  kind = "Pelicula"
  if it.mediaType = "tv" then kind = "Serie"
  yr = ""
  if it.year <> invalid then yr = it.year
  rt = ""
  if it.rating <> invalid then rt = it.rating
  m.meta.text = kind + "   |   " + yr + "   |   TMDB " + rt + " / 10"
  if m.heroGenres <> invalid then m.heroGenres.text = ""
  ov = ""
  if it.overview <> invalid then ov = it.overview
  m.ov.text = ov
  m.hero.visible = true
  ' Banner: path TMDB o URL completa
  m.bg.uri = ""
  bd = ""
  if it.backdrop <> invalid then bd = it.backdrop
  if bd <> "" then
    if Left(bd, 1) = "/" then
      m.bg.uri = "https://image.tmdb.org/t/p/w1280" + bd
    else if Instr(1, bd, "http") = 1 then
      ' Si es portada w342/w500 no usarla como banner
      if Instr(1, bd, "/w1280/") > 0 or Instr(1, bd, "/w780/") > 0 or Instr(1, bd, "/original/") > 0 or Instr(1, bd, "/backdrop") > 0 then
        m.bg.uri = bd
      else if Instr(1, bd, "/w342/") = 0 and Instr(1, bd, "/w500/") = 0 and Instr(1, bd, "/w154/") = 0 then
        m.bg.uri = bd
      end if
    end if
  end if
  ' Siempre enriquecer con TMDB (banner + sinopsis completa)
  if it.tmdbId <> invalid and it.tmdbId > 0 and m.key <> "" then
    fetchHeroBackdrop(it)
  end if
end sub

sub fetchHeroBackdrop(it as Object)
  if it = invalid then return
  if it.tmdbId = invalid or it.tmdbId = 0 then return
  if m.heroFetchId <> invalid and m.heroFetchId = it.tmdbId then return
  m.heroFetchId = it.tmdbId
  task = CreateObject("roSGNode", "TmdbTask")
  m.heroTmdbTask = task
  task.apiKey = m.key
  path = "/movie/" + it.tmdbId.toStr()
  if it.mediaType = "tv" then path = "/tv/" + it.tmdbId.toStr()
  task.path = path
  task.params = ""
  task.observeField("result", "onHeroTmdb")
  task.control = "RUN"
end sub

sub onHeroTmdb()
  d = invalid
  if m.heroTmdbTask <> invalid then d = m.heroTmdbTask.result
  if d = invalid then return
  if d.error <> invalid then return
  if d.backdrop_path <> invalid and d.backdrop_path <> "" then
    m.bg.uri = "https://image.tmdb.org/t/p/w1280" + d.backdrop_path
  end if
  if d.overview <> invalid and d.overview <> "" then
    m.ov.text = d.overview
  end if
  rt = ""
  if d.vote_average <> invalid then rt = Left(strVal(d.vote_average), 3)
  yr = ""
  if d.release_date <> invalid and Len(strVal(d.release_date)) >= 4 then yr = Left(strVal(d.release_date), 4)
  if d.first_air_date <> invalid and Len(strVal(d.first_air_date)) >= 4 then yr = Left(strVal(d.first_air_date), 4)
  kind = "Pelicula"
  if m.meta.text <> invalid then
    if Instr(1, m.meta.text, "Serie") > 0 then kind = "Serie"
  end if
  if rt <> "" or yr <> "" then
    m.meta.text = kind + "   |   " + yr + "   |   TMDB " + rt + " / 10"
  end if
  ' Guardar en el nodo enfocado para al salir del detalle no se pierda
  itn = invalid
  if m.posterGrid <> invalid and m.posterGrid.visible and m.posterGrid.content <> invalid then
    idx = m.posterGrid.itemFocused
    if idx <> invalid then itn = m.posterGrid.content.getChild(idx)
  end if
  if itn = invalid and m.rows <> invalid and m.rows.visible and m.rows.content <> invalid then
    rc = m.rows.rowItemFocused
    if rc <> invalid then
      row = m.rows.content.getChild(rc[0])
      if row <> invalid then itn = row.getChild(rc[1])
    end if
  end if
  if itn <> invalid then
    if yr <> "" then itn.year = yr
    if rt <> "" then itn.rating = rt
    if d.overview <> invalid and d.overview <> "" then itn.overview = d.overview
    if d.backdrop_path <> invalid and d.backdrop_path <> "" then itn.backdrop = d.backdrop_path
  end if
  ' Generos
  if m.heroGenres <> invalid then
    gtxt = ""
    if d.genres <> invalid then
      for each g in d.genres
        if g.name <> invalid then
          if gtxt <> "" then gtxt = gtxt + "  ·  "
          gtxt = gtxt + g.name
        end if
      end for
    end if
    m.heroGenres.text = gtxt
  end if
end sub

sub onFocus()
  rc = m.rows.rowItemFocused
  if rc = invalid or m.rows.content = invalid then return
  row = m.rows.content.getChild(rc[0])
  if row = invalid then return
  m.tag.text = row.title
  updateHeroFrom(row.getChild(rc[1]))
end sub

sub onSelect()
  rc = m.rows.rowItemSelected
  row = m.rows.content.getChild(rc[0])
  if row = invalid then return
  it = row.getChild(rc[1])
  if it <> invalid then openDetails(it)
end sub

' ---------- Mi lista y "visto" (registro del Roku) ----------
sub loadUser()
  sec = CreateObject("roRegistrySection", "PlayZoneTV2")
  m.favs = []
  m.recent = []
  m.watched = {}
  if sec.Exists("favs") then
    p = ParseJson(sec.Read("favs"))
    if p <> invalid then
      if type(p) = "roArray" then m.favs = p
    end if
  end if
  if sec.Exists("recent") then
    rr = ParseJson(sec.Read("recent"))
    if rr <> invalid then
      if type(rr) = "roArray" then m.recent = rr
    end if
  end if
  if sec.Exists("watched") then
    w = ParseJson(sec.Read("watched"))
    if w <> invalid then
      if type(w) = "roAssociativeArray" then m.watched = w
    end if
  end if
end sub

sub saveUser()
  sec = CreateObject("roRegistrySection", "PlayZoneTV2")
  sec.Write("favs", FormatJson(m.favs))
  sec.Write("recent", FormatJson(m.recent))
  sec.Write("watched", FormatJson(m.watched))
  sec.Flush()
end sub

function recOf(it as Object) as Object
  ' overview completo (antes Left 120 cortaba la sinopsis en Mi lista)
  ovFull = it.overview
  if ovFull = invalid then ovFull = ""
  return { ckey: it.ckey, id: it.tmdbId, mt: it.mediaType, title: it.title, poster: it.HDPosterUrl, backdrop: it.backdrop, overview: ovFull, year: it.year, rating: it.rating }
end function

sub saveRecent(rec as Object, t as Dynamic, d as Dynamic)
  tt = t + 0.0
  dd = d + 0.0
  for i = m.recent.count() - 1 to 0 step -1
    if m.recent[i].id = rec.id and m.recent[i].mt = rec.mt then m.recent.Delete(i)
  end for
  prog = 0.0
  if dd > 0 then prog = tt / dd
  if tt >= 15 and prog < 0.95 then
    rec.t = Int(tt)
    rec.prog = prog
    m.recent.Unshift(rec)
    if m.recent.count() > 15 then m.recent.Pop()
  end if
  saveUser()
  m.cache.Delete("home")
end sub

function isFav(ck as String) as Boolean
  for each f in m.favs
    if f.ckey = ck then return true
  end for
  return false
end function

sub toggleFav(it as Object)
  idx = -1
  for i = 0 to m.favs.count() - 1
    if m.favs[i].ckey = it.ckey then idx = i
  end for
  if idx >= 0 then
    m.favs.Delete(idx)
  else
    m.favs.Unshift(recOf(it))
    if m.favs.count() > 40 then m.favs.Pop()
  end if
  saveUser()
  m.cache.Delete("home")
end sub

sub markWatched(ck as String)
  if ck = "" then return
  m.watched[ck] = true
  saveUser()
  m.cache = {}
end sub

function listRow(title as String, arr as Object, kind as String) as Object
  row = CreateObject("roSGNode", "ContentNode")
  row.title = title
  for each f in arr
    if kind = "" or f.mt = kind then
      n = makeNode(f.title, f.poster, f.mt, f.id, f.overview, f.backdrop, f.year, f.rating)
      if f.DoesExist("prog") then n.prog = f.prog
      row.appendChild(n)
    end if
  end for
  return row
end function

function favsRow(title as String, kind as String) as Object
  return listRow(title, m.favs, kind)
end function

function buildFavsContent() as Object
  root = CreateObject("roSGNode", "ContentNode")
  r1 = favsRow("Películas", "movie")
  r2 = favsRow("Series, anime y doramas", "tv")
  if r1.getChildCount() > 0 then root.appendChild(r1)
  if r2.getChildCount() > 0 then root.appendChild(r2)
  return root
end function

' ---------- Detalle ----------
sub openDetails(it as Object)
  m.details = m.top.createChild("DetailsScreen")
  m.details.apiKey = m.key
  m.details.isFav = isFav(it.ckey)
  m.details.observeField("action", "onDetailsAction")
  m.details.content = it
  m.details.setFocus(true)
end sub

sub closeDetails()
  hidePlayStatus()
  if m.details <> invalid then
    m.top.removeChild(m.details)
    m.details = invalid
  end if
  ' Restaurar banner/año/sinopsis del item enfocado
  m.heroFetchId = 0
  refreshHeroFromFocus()
  if m.zone = "content" then
    if m.tabId = "favs" then selectTab(m.tab)
    focusContent()
    refreshHeroFromFocus()
  else
    m.navKeys.setFocus(true)
  end if
end sub

sub refreshHeroFromFocus()
  it = invalid
  if m.posterGrid <> invalid and m.posterGrid.visible and m.posterGrid.content <> invalid then
    idx = m.posterGrid.itemFocused
    if idx = invalid then idx = 0
    it = m.posterGrid.content.getChild(idx)
  else if m.rows <> invalid and m.rows.visible and m.rows.content <> invalid then
    rc = m.rows.rowItemFocused
    if rc <> invalid then
      row = m.rows.content.getChild(rc[0])
      if row <> invalid then it = row.getChild(rc[1])
    else if m.rows.content.getChildCount() > 0 then
      row = m.rows.content.getChild(0)
      if row <> invalid and row.getChildCount() > 0 then it = row.getChild(0)
    end if
  end if
  if it <> invalid then
    m.hero.visible = true
    updateHeroFrom(it)
  end if
end sub

sub onDetailsAction(evt as Object)
  a = evt.getData()
  if m.details = invalid then return
  it = m.details.content
  if a = "close" then
    closeDetails()
  else if a = "play" then
    playItem(it)
  else if a = "seasons" then
    openEpisodes(it)
  else if a = "fav" then
    toggleFav(it)
    m.details.isFav = isFav(it.ckey)
  end if
end sub

' ---------- Reproducción (solo fuentes propias) ----------
sub playItem(it as Object)
  extractUrl = ""
  if it <> invalid then
    if it.extractUrl <> invalid then extractUrl = it.extractUrl
  end if
  if extractUrl = "" then
    msg("Sin fuente de video", ["Este titulo no trae URL de la API (extractUrl vacio)."])
    return
  end if
  m.pendingPlay = CreateObject("roAssociativeArray")
  m.pendingPlay.it = it
  m.pendingPlay.title = it.title
  m.pendingPlay.ckey = it.ckey
  m.pendingStreamUrls = []
  m.pendingStreamUrlIndex = 0
  ' Mensaje EN detalle (dialogo), sin salir a inicio
  showPlayStatus("Cargando reproductor...")
  task = CreateObject("roSGNode", "ApiTask")
  m.streamTask = task
  task.requestUrl = extractUrl
  task.observeField("response", "onMovieExtract")
  task.control = "RUN"
end sub

sub showPlayStatus(txt as String)
  if m.eps <> invalid then
    m.eps.playStatus = txt
  end if
  if m.details <> invalid then
    m.details.playStatus = txt
  end if
  if m.eps = invalid and m.details = invalid then
    m.status.text = txt
  end if
end sub

sub hidePlayStatus()
  if m.eps <> invalid then
    m.eps.playStatus = ""
  end if
  if m.details <> invalid then
    m.details.playStatus = ""
  end if
  m.status.text = ""
end sub

' Respuesta del detalle pelicula/serie (Pelisplus): embeds.video[].stream_url
sub onMovieExtract()
  res = invalid
  if m.streamTask <> invalid then res = m.streamTask.response
  if res = invalid then
    m.status.text = ""
    hidePlayStatus()
    msg("Sin reproductor", ["No se pudo cargar el extract de la API."])
    return
  end if
  m.pendingStreamUrls = []
  m.pendingStreamUrlIndex = 0

  ' 1) Formato Pelisplus: embeds.video
  if res.embeds <> invalid then
    vids = invalid
    if res.embeds.video <> invalid then
      vids = res.embeds.video
    else if type(res.embeds) = "roArray" then
      vids = res.embeds
    end if
    if vids <> invalid then
      for each emb in vids
        su = ""
        if emb.stream_url <> invalid then su = emb.stream_url
        if su = "" and emb.url <> invalid then su = emb.url
        if su <> "" then m.pendingStreamUrls.Push(su)
      end for
    end if
  end if

  ' 2) streams ya resueltos (otras APIs)
  if m.pendingStreamUrls.count() = 0 and res.streams <> invalid then
    m.currentStreams = []
    for each s in res.streams
      url = ""
      fmt = "hls"
      if s.proxyUrlHLS <> invalid and s.proxyUrlHLS <> "" then
        url = s.proxyUrlHLS
        fmt = "hls"
      else if s.proxyUrlMP4 <> invalid and s.proxyUrlMP4 <> "" then
        url = s.proxyUrlMP4
        fmt = "mp4"
      else if s.url <> invalid then
        url = s.url
      end if
      if url <> "" then
        st = CreateObject("roAssociativeArray")
        st.url = url
        st.format = fmt
        m.currentStreams.Push(st)
      end if
    end for
    if m.currentStreams.count() > 0 then
      m.currentStreamIndex = 0
      tryPlayCurrentStream()
      return
    end if
  end if

  if m.pendingStreamUrls.count() = 0 then
    hidePlayStatus()
    msg("Sin reproductor", ["La API no trajo servidores de video."])
    return
  end if
  showPlayStatus("Resolviendo " + m.pendingStreamUrls.count().toStr() + " servidores...")
  resolveAndPlayOneMovieServer()
end sub

' Como PlayZoneTV: cada stream_url se resuelve a HLS/proxy
sub resolveAndPlayOneMovieServer()
  if m.pendingStreamUrls = invalid then
    hidePlayStatus()
    msg("Sin reproductor", ["No hay servidores."])
    return
  end if
  if m.pendingStreamUrlIndex >= m.pendingStreamUrls.count() then
    hidePlayStatus()
    msg("Sin reproductor", ["Ningun servidor respondio."])
    return
  end if
  total = m.pendingStreamUrls.count()
  idx = m.pendingStreamUrlIndex + 1
  showPlayStatus("Servidor " + idx.toStr() + " de " + total.toStr() + "...")
  url = m.pendingStreamUrls[m.pendingStreamUrlIndex]
  task = CreateObject("roSGNode", "ApiTask")
  m.resolveTask = task
  task.requestUrl = url
  task.observeField("response", "onMovieStreamResolved")
  task.control = "RUN"
end sub

sub onMovieStreamResolved()
  res = invalid
  if m.resolveTask <> invalid then res = m.resolveTask.response
  m.currentStreams = []
  m.currentStreamIndex = 0
  if res <> invalid then
    ' 1) proxy_url de qualities (mejor para Roku)
    if res.qualities <> invalid then
      for each q in res.qualities
        pu = ""
        if q.proxy_url <> invalid then pu = q.proxy_url
        if pu <> "" then
          st = CreateObject("roAssociativeArray")
          st.url = pu
          st.format = "hls"
          m.currentStreams.Push(st)
        end if
      end for
    end if
    ' 2) hls marcado "activo" en hls_status
    if m.currentStreams.count() = 0 and res.videos <> invalid then
      if res.videos.hls_status <> invalid then
        for each hs in res.videos.hls_status
          stt = ""
          if hs.status <> invalid then stt = LCase(strVal(hs.status))
          if Instr(1, stt, "activo") > 0 and hs.url <> invalid and hs.url <> "" then
            st = CreateObject("roAssociativeArray")
            st.url = hs.url
            st.format = "hls"
            m.currentStreams.Push(st)
          end if
        end for
      end if
    end if
    ' 3) videos.hls (cualquiera)
    if m.currentStreams.count() = 0 and res.videos <> invalid then
      if res.videos.hls <> invalid then
        for each h in res.videos.hls
          hu = ""
          if type(h) = "roString" or type(h) = "String" then
            hu = h
          else if h <> invalid and h.url <> invalid then
            hu = h.url
          end if
          if hu <> "" then
            st = CreateObject("roAssociativeArray")
            st.url = hu
            st.format = "hls"
            m.currentStreams.Push(st)
          end if
        end for
      end if
    end if
    ' 4) url suelta en qualities
    if m.currentStreams.count() = 0 and res.qualities <> invalid then
      for each q in res.qualities
        if q.url <> invalid and q.url <> "" then
          st = CreateObject("roAssociativeArray")
          st.url = q.url
          st.format = "hls"
          m.currentStreams.Push(st)
        end if
      end for
    end if
  end if
  if m.currentStreams.count() > 0 then
    tryPlayCurrentStream()
  else
    m.pendingStreamUrlIndex = m.pendingStreamUrlIndex + 1
    resolveAndPlayOneMovieServer()
  end if
end sub

sub tryPlayCurrentStream()
  if m.currentStreams = invalid then return
  if m.playingStream = true then return
  if m.currentStreamIndex < 0 or m.currentStreamIndex >= m.currentStreams.count() then
    m.playingStream = false
    ' Probar siguiente embed de la API
    if m.pendingStreamUrls <> invalid then
      if m.pendingStreamUrlIndex < m.pendingStreamUrls.count() - 1 then
        m.pendingStreamUrlIndex = m.pendingStreamUrlIndex + 1
        resolveAndPlayOneMovieServer()
        return
      end if
    end if
    hidePlayStatus()
    msg("No se pudo reproducir", ["Ningun servidor funciono."])
    return
  end if
  m.playingStream = true
  s = m.currentStreams[m.currentStreamIndex]
  title = "Video"
  ckey = "api:stream"
  rec = invalid
  if m.pendingPlay <> invalid then
    title = m.pendingPlay.title
    ckey = m.pendingPlay.ckey
    if m.pendingPlay.it <> invalid then rec = recOf(m.pendingPlay.it)
  end if
  hidePlayStatus()
  m.status.text = ""
  startVideo(s.url, s.format, title, ckey, false, 0, rec)
end sub

sub onStreamTimer()
  m.playingStream = false
  tryPlayCurrentStream()
end sub

sub startVideo(url as String, fmt as String, title as String, ck as String, isLive as Boolean, startAt as Integer, rec as Dynamic)
  c = CreateObject("roSGNode", "ContentNode")
  c.url = url
  c.title = title
  if fmt <> "" then c.streamFormat = fmt
  c.live = isLive
  if startAt > 0 then c.PlayStart = startAt
  m.playRec = rec
  m.playKey = ck
  m.video = m.top.createChild("Video")
  m.video.width = 1920
  m.video.height = 1080
  m.video.content = c
  m.video.observeField("state", "onVideoState")
  m.video.control = "play"
  m.video.setFocus(true)
end sub

sub onVideoState()
  if m.video = invalid then return
  s = m.video.state
  if s = "error" then
    m.playRec = invalid
    m.playingStream = false
    if m.video <> invalid then
      m.video.control = "stop"
      m.top.removeChild(m.video)
      m.video = invalid
    end if
    if m.currentStreams <> invalid and m.currentStreamIndex < m.currentStreams.count() - 1 then
      m.currentStreamIndex = m.currentStreamIndex + 1
      m.streamTimer.control = "stop"
      m.streamTimer.control = "start"
      return
    end if
    if m.pendingStreamUrls <> invalid and m.pendingStreamUrlIndex < m.pendingStreamUrls.count() - 1 then
      m.pendingStreamUrlIndex = m.pendingStreamUrlIndex + 1
      resolveAndPlayOneMovieServer()
      return
    end if
    msg("No se pudo reproducir", ["Ningun servidor respondio."])
  else if s = "finished" then
    markWatched(m.playKey)
    closeVideo()
  end if
end sub

sub closeVideo()
  m.status.text = ""
  if m.video = invalid then return
  if m.playRec <> invalid then
    saveRecent(m.playRec, m.video.position, m.video.duration)
    m.playRec = invalid
  end if
  m.video.control = "stop"
  m.top.removeChild(m.video)
  m.video = invalid
  if m.eps <> invalid then
    m.eps.setFocus(true)
    m.eps.refresh = true
  else if m.details <> invalid then
    m.details.visible = true
    m.details.setFocus(true)
  else if m.zone = "content" then
    focusContent()
  else
    m.navKeys.setFocus(true)
  end if
end sub

sub msg(title as String, lines as Object)
  d = CreateObject("roSGNode", "StandardMessageDialog")
  d.title = title
  d.message = lines
  d.buttons = ["Aceptar"]
  d.observeFieldScoped("buttonSelected", "onMsgClose")
  m.top.dialog = d
end sub

sub onMsgClose()
  if m.top.dialog <> invalid then m.top.dialog.close = true
end sub

' ---------- TV en vivo por país (iptv-org) ----------
sub buildCountries()
  list = [
    ["mx", "México"], ["ar", "Argentina"], ["co", "Colombia"], ["cl", "Chile"], ["pe", "Perú"], ["ve", "Venezuela"],
    ["ec", "Ecuador"], ["uy", "Uruguay"], ["py", "Paraguay"], ["bo", "Bolivia"], ["cr", "Costa Rica"], ["pa", "Panamá"],
    ["gt", "Guatemala"], ["do", "Rep. Dominicana"], ["es", "España"], ["us", "Estados Unidos"], ["br", "Brasil"],
    ["pt", "Portugal"], ["fr", "Francia"], ["it", "Italia"], ["de", "Alemania"], ["gb", "Reino Unido"]
  ]
  m.countryContent = CreateObject("roSGNode", "ContentNode")
  for each c in list
    n = CreateObject("roSGNode", "ContentNode")
    n.title = c[1]
    n.addFields({ code: UCase(c[0]), streamUrl: "" })
    m.countryContent.appendChild(n)
  end for
end sub

sub showCountries()
  m.tvMode = "countries"
  m.hero.visible = false
  m.rows.visible = false
  m.head.text = "TV en vivo por país"
  m.grid.content = m.countryContent
  m.grid.visible = true
  m.status.text = ""
  if m.zone = "content" then m.grid.setFocus(true)
end sub

sub onGridSelect()
  node = m.grid.content.getChild(m.grid.itemSelected)
  if node = invalid then return
  if m.tvMode = "countries" then
    m.tvCountry = node.title
    m.status.text = "Cargando canales de " + node.title + "..."
    t = CreateObject("roSGNode", "M3uTask")
    m.m3u = t
    t.url = "https://iptv-org.github.io/iptv/countries/" + LCase(node.code) + ".m3u"
    t.observeField("done", "onChannels")
    t.control = "RUN"
  else
    fmt = ""
    if Instr(1, LCase(node.streamUrl), ".m3u8") > 0 then fmt = "hls"
    startVideo(node.streamUrl, fmt, node.title, "", true, 0, invalid)
  end if
end sub

sub onChannels()
  chs = m.m3u.channels
  m.status.text = ""
  if chs = invalid or chs.Count() = 0 then
    m.status.text = "No se encontraron canales para " + m.tvCountry + "."
    return
  end if
  root = CreateObject("roSGNode", "ContentNode")
  for each c in chs
    n = CreateObject("roSGNode", "ContentNode")
    n.title = c.name
    n.HDPosterUrl = c.logo
    n.addFields({ code: "", streamUrl: c.url })
    root.appendChild(n)
  end for
  m.tvMode = "channels"
  m.head.text = "TV - " + m.tvCountry + "  (" + chs.Count().toStr() + " canales)"
  m.grid.content = root
  m.grid.jumpToItem = 0
  m.grid.setFocus(true)
end sub

' ---------- Búsqueda ----------
sub openSearch()
  d = CreateObject("roSGNode", "StandardKeyboardDialog")
  d.title = "Buscar peliculas y series"
  d.buttons = ["Buscar", "Cancelar"]
  d.observeFieldScoped("buttonSelected", "onSearchBtn")
  m.top.dialog = d
end sub

sub onSearchBtn(evt as Object)
  d = m.top.dialog
  if d = invalid then return
  idx = evt.getData()
  q = ""
  if d.text <> invalid then q = d.text
  ' Cerrar teclado primero (no hacer selectTab aqui: congela)
  d.close = true
  m.top.dialog = invalid
  if idx <> 0 then
    focusNav()
    return
  end if
  if q = "" then
    focusNav()
    return
  end if
  m.pendingSearchQ = q
  m.status.text = "Buscando..."
  m.cache.Delete("search")
  ' Escapar query de forma segura
  eq = q
  u = CreateObject("roUrlTransfer")
  if u <> invalid then
    eq = u.Escape(q)
  end if
  url = "https://pelisplushd.tvymas.workers.dev/search?q=" + eq + "&page=1"
  task = CreateObject("roSGNode", "ApiTask")
  m.searchTask = task
  task.requestUrl = url
  task.observeField("response", "onSearchApi")
  task.control = "RUN"
  focusNav()
end sub

sub onSearchApi()
  res = invalid
  if m.searchTask <> invalid then res = m.searchTask.response
  m.searchTask = invalid
  if res = invalid then
    m.status.text = "No se pudo buscar. Intenta de nuevo."
    focusNav()
    return
  end if
  list = []
  if res.results <> invalid then list = res.results
  if type(list) <> "roArray" then list = []
  if list.count() = 0 then
    tmp = pickApiList(res)
    if tmp <> invalid then list = tmp
  end if
  root = CreateObject("roSGNode", "ContentNode")
  row = CreateObject("roSGNode", "ContentNode")
  row.title = "Resultados"
  for each item in list
    kind = "movies"
    u = strVal(item.url)
    if u = "" then u = strVal(item.link)
    if Instr(1, u, "/serie/") > 0 then kind = "series"
    if Instr(1, u, "/anime/") > 0 then kind = "anime"
    if Instr(1, u, "/dorama/") > 0 then kind = "doramas"
    if Instr(1, u, "/pelicula/") > 0 then kind = "movies"
    tp = LCase(strVal(item.type))
    if tp = "" then tp = LCase(strVal(item.tipo))
    if Instr(1, tp, "serie") > 0 then kind = "series"
    if Instr(1, tp, "anime") > 0 then kind = "anime"
    if Instr(1, tp, "pelicul") > 0 or Instr(1, tp, "movie") > 0 then kind = "movies"
    n = apiItemToNode(item, kind)
    if n <> invalid then row.appendChild(n)
  end for
  if row.getChildCount() = 0 then
    m.status.text = "Sin resultados."
    focusNav()
    return
  end if
  root.appendChild(row)
  m.cache["search"] = root
  m.status.text = ""
  ' Ahora si ir a la pestana Buscar y mostrar
  for si = 0 to m.tabs.count() - 1
    if m.tabs[si].id = "search" then
      m.tab = si
      m.tabId = "search"
      renderNav()
      exit for
    end if
  end for
  showRows(root)
  m.zone = "content"
  renderNav()
  m.rows.setFocus(true)
end sub

' ---------- Teclas ----------
function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  if m.video <> invalid then
    if key = "back" then
      closeVideo()
      return true
    end if
    return false
  end if
  if m.details <> invalid then return false
  ' Sincroniza la zona con el foco real (evita quedarse "atascado" sin poder subir al menú)
  inContent = (m.rows.hasFocus() or m.grid.hasFocus() or (m.posterGrid <> invalid and m.posterGrid.hasFocus()))
  if inContent and m.zone <> "content" then
    m.zone = "content"
    renderNav()
  else if not inContent and m.zone = "content" then
    m.zone = "nav"
    renderNav()
  end if
  if key = "rev" or key = "fwd" then
    if m.zone = "content" then focusNav()
    if key = "rev" then
      moveTab(-1)
    else
      moveTab(1)
    end if
    return true
  end if
  if key = "replay" then
    focusNav()
    return true
  end if
  if key = "options" then
    selectTab(7)
    focusNav()
    openSearch()
    return true
  end if
  if m.zone = "nav" then
    if key = "up" then
      moveTab(-1)
      return true
    else if key = "down" then
      moveTab(1)
      return true
    else if key = "right" then
      enterContent()
      return true
    else if key = "OK" then
      if m.tabId = "home" and m.featured.count() > 0 and m.rows.visible then
        openDetails(m.featured[m.featIdx])
      else
        enterContent()
      end if
      return true
    end if
    return false
  end if
  if key = "left" then
    focusNav()
    return true
  else if key = "back" then
    if m.tabId = "tv" and m.tvMode = "channels" then
      showCountries()
      m.grid.setFocus(true)
    else
      focusNav()
    end if
    return true
  end if
  return false
end function

' ---------- Guardián de foco: evita quedarse sin poder moverse ----------
sub onFocusGuard()
  if m.details <> invalid or m.video <> invalid then return
  if m.eps <> invalid then return
  if m.top.dialog <> invalid then return
  ' Si ya hay un control con foco, no tocar
  if m.navKeys.hasFocus() then return
  if m.rows.hasFocus() then return
  if m.grid.hasFocus() then return
  if m.posterGrid <> invalid and m.posterGrid.hasFocus() then return
  if m.zone = "content" then
    if m.tabId = "tv" and m.grid.visible then
      m.grid.setFocus(true)
    else if m.posterGrid <> invalid and m.posterGrid.visible then
      m.posterGrid.setFocus(true)
    else if m.rows.visible then
      m.rows.setFocus(true)
    else
      m.zone = "nav"
      renderNav()
      m.navKeys.setFocus(true)
    end if
  else
    m.navKeys.setFocus(true)
  end if
end sub

' ---------- Aviso de actualización (version.json) ----------
sub checkForUpdates()
  m.installed = CreateObject("roAppInfo").GetVersion()
  t = CreateObject("roSGNode", "VersionCheckTask")
  m.updateTask = t
  t.requestUrl = "https://raw.githubusercontent.com/r1gox/PlayZoneTV/main/version.json"
  t.observeField("response", "onUpdateInfo")
  t.control = "RUN"
end sub

function compareVer(a as String, b as String) as Integer
  pa = a.Split(".")
  pb = b.Split(".")
  n = pa.Count()
  if pb.Count() > n then n = pb.Count()
  for i = 0 to n - 1
    x = 0
    y = 0
    if i < pa.Count() then x = Val(pa[i])
    if i < pb.Count() then y = Val(pb[i])
    if x > y then return 1
    if x < y then return -1
  end for
  return 0
end function

sub onUpdateInfo(evt as Object)
  res = evt.getData()
  if res = invalid then return
  latest = txt(res.latest_version)
  if latest = "" then return
  if compareVer(latest, m.installed) <= 0 then return
  sec = CreateObject("roRegistrySection", "PlayZoneTV2")
  if sec.Exists("skipVer") then
    if sec.Read("skipVer") = latest then return
  end if
  m.pendingVer = latest
  extra = txt(res.message)
  if extra = "" then extra = "Vuelve a descargar el canal desde GitHub e instálalo de nuevo en tu Roku."
  d = CreateObject("roSGNode", "StandardMessageDialog")
  d.title = "Actualización disponible"
  d.message = ["Tienes la versión " + m.installed + " y ya existe la " + latest + ".", extra]
  d.buttons = ["Entendido", "No avisar de esta versión"]
  d.observeFieldScoped("buttonSelected", "onUpdateBtn")
  m.top.dialog = d
end sub

sub onUpdateBtn(evt as Object)
  if evt.getData() = 1 then
    sec = CreateObject("roRegistrySection", "PlayZoneTV2")
    sec.Write("skipVer", m.pendingVer)
    sec.Flush()
  end if
  if m.top.dialog <> invalid then m.top.dialog.close = true
end sub

' ---------- Temporadas y episodios ----------
sub openEpisodes(it as Object)
  m.eps = m.top.createChild("EpisodesScreen")
  m.eps.apiKey = m.key
  m.eps.observeField("action", "onEpsAction")
  m.eps.content = it
  m.eps.setFocus(true)
end sub

sub closeEpisodes()
  if m.eps <> invalid then
    m.top.removeChild(m.eps)
    m.eps = invalid
  end if
  if m.details <> invalid then m.details.setFocus(true)
end sub

sub onEpsAction(evt as Object)
  if m.eps = invalid then return
  a = evt.getData()
  if a = "close" then
    closeEpisodes()
  else if a = "play" then
    ep = m.eps.episode
    playEpisode(m.eps.content, ep)
  end if
end sub

function detectFmt(src as Object) as String
  if src.format <> invalid then return src.format
  if Instr(1, LCase(src.url), ".m3u8") > 0 then return "hls"
  return "mp4"
end function

' Serie: usa extractUrl del episodio (API), mismo flujo que peliculas
sub playEpisode(show as Object, ep as Object)
  if show = invalid or ep = invalid then return
  sn = 1
  en = 1
  name = ""
  extractUrl = ""
  if ep.season <> invalid then sn = ep.season
  if ep.episode <> invalid then en = ep.episode
  if ep.name <> invalid then name = ep.name
  if ep.extractUrl <> invalid then extractUrl = ep.extractUrl
  ' Armar desde extractUrl de la serie
  base = ""
  if show.extractUrl <> invalid then base = show.extractUrl
  if base = "" and show.DoesExist("extractUrl") then base = show.extractUrl
  if extractUrl = "" and base <> "" then
    if Right(base, 1) = "/" then
      extractUrl = base + sn.toStr() + "/" + en.toStr()
    else
      extractUrl = base + "/" + sn.toStr() + "/" + en.toStr()
    end if
  end if
  ' Ultimo recurso: slug en ckey tv:api:slug
  if extractUrl = "" and show.ckey <> invalid then
    ck0 = show.ckey
    if Instr(1, ck0, "api:") > 0 then
      slug = Mid(ck0, Instr(1, ck0, "api:") + 4)
      if slug <> "" then
        extractUrl = "https://pelisplushd.tvymas.workers.dev/serie/" + slug + "/" + sn.toStr() + "/" + en.toStr()
      end if
    end if
  end if
  ck = "tv:"
  if show.tmdbId <> invalid then ck = ck + show.tmdbId.toStr()
  ck = ck + ":" + sn.toStr() + ":" + en.toStr()
  title = show.title + "  T" + sn.toStr() + " E" + en.toStr()
  if name <> "" then title = show.title + " - " + name
  if extractUrl = "" then
    msg("Sin fuente de video", ["Este episodio no tiene URL de la API."])
    return
  end if
  fake = CreateObject("roSGNode", "ContentNode")
  fake.title = title
  fake.addField("ckey", "string", false)
  fake.ckey = ck
  fake.addField("extractUrl", "string", false)
  fake.extractUrl = extractUrl
  fake.addField("tmdbId", "integer", false)
  if show.tmdbId <> invalid then fake.tmdbId = show.tmdbId
  fake.addField("mediaType", "string", false)
  fake.mediaType = "tv"
  fake.addField("overview", "string", false)
  fake.overview = ""
  fake.addField("backdrop", "string", false)
  fake.backdrop = ""
  if show.backdrop <> invalid then fake.backdrop = show.backdrop
  fake.addField("year", "string", false)
  fake.year = ""
  fake.addField("rating", "string", false)
  fake.rating = ""
  fake.HDPosterUrl = ""
  if show.HDPosterUrl <> invalid then fake.HDPosterUrl = show.HDPosterUrl
  playItem(fake)
end sub
