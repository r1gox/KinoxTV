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
  m.ov = m.top.findNode("ov")
  m.rows = m.top.findNode("rows")
  m.grid = m.top.findNode("grid")
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
  cfg = ParseJson(ReadAsciiFile("pkg:/source/config.json"))
  if cfg <> invalid then
    if cfg.tmdb_key <> invalid then m.key = cfg.tmdb_key
  end if
  if m.key = "TU_API_KEY" then m.key = ""
  selectTab(0)
  checkForUpdates()
end sub

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
end sub

sub hideAll()
  m.rows.visible = false
  m.grid.visible = false
  m.help.visible = false
  m.hero.visible = false
  m.head.text = ""
  m.status.text = ""
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
      showRows(m.cache[id])
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
  else if m.rows.visible then
    m.zone = "content"
    m.rows.setFocus(true)
  else
    return
  end if
  renderNav()
  if m.tabId <> "tv" then onFocus()
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
  if m.key = "" then
    m.status.text = "Falta tu API key de TMDB. Edítala en source/config.json y vuelve a instalar el canal."
    return
  end if
  if m.pend.DoesExist(id) then
    if m.pend[id].n > 0 then
      m.status.text = "Cargando…"
      return
    end if
  end if
  defs = m.defs[id]
  m.pend[id] = { n: defs.count(), res: {}, defs: defs }
  m.status.text = "Cargando…"
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
  if m.zone = "content" then m.rows.setFocus(true)
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
  kind = "Película"
  if it.mediaType = "tv" then kind = "Serie"
  m.meta.text = kind + "   |   " + it.year + "   |   TMDB " + it.rating + " / 10"
  m.ov.text = it.overview
  if it.backdrop <> "" then m.bg.uri = "https://image.tmdb.org/t/p/w1280" + it.backdrop
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
  if m.details <> invalid then
    m.top.removeChild(m.details)
    m.details = invalid
  end if
  if m.zone = "content" then
    if m.tabId = "favs" then selectTab(m.tab)
    focusContent()
  else
    m.navKeys.setFocus(true)
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
  src = invalid
  j = ParseJson(ReadAsciiFile("pkg:/source/sources.json"))
  if j <> invalid then src = j[it.ckey]
  if src = invalid then
    msg("Sin fuente de video", ["Agrega una fuente propia para este título en source/sources.json con la clave " + it.ckey + "."])
    return
  end if
  fmt = ""
  if src.format <> invalid then
    fmt = src.format
  else if Instr(1, LCase(src.url), ".m3u8") > 0 then
    fmt = "hls"
  else
    fmt = "mp4"
  end if
  start = 0
  for each r in m.recent
    if r.ckey = it.ckey and r.t <> invalid then start = r.t
  end for
  startVideo(src.url, fmt, it.title, it.ckey, false, start, recOf(it))
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
    closeVideo()
    msg("No se pudo reproducir", ["Revisa que el enlace sea directo (.m3u8 o .mp4) y que siga activo."])
  else if s = "finished" then
    markWatched(m.playKey)
    closeVideo()
  end if
end sub

sub closeVideo()
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
    m.status.text = "Cargando canales de " + node.title + "…"
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
  m.head.text = "TV · " + m.tvCountry + "  (" + chs.Count().toStr() + " canales)"
  m.grid.content = root
  m.grid.jumpToItem = 0
  m.grid.setFocus(true)
end sub

' ---------- Búsqueda ----------
sub openSearch()
  if m.key = "" then
    m.status.text = "Falta tu API key de TMDB. Edítala en source/config.json."
    return
  end if
  d = CreateObject("roSGNode", "StandardKeyboardDialog")
  d.title = "Buscar películas y series"
  d.buttons = ["Buscar", "Cancelar"]
  d.observeFieldScoped("buttonSelected", "onSearchBtn")
  m.top.dialog = d
end sub

sub onSearchBtn(evt as Object)
  d = m.top.dialog
  if d = invalid then return
  q = d.text
  idx = evt.getData()
  d.close = true
  m.navKeys.setFocus(true)
  if idx = 0 and q <> "" then
    m.pend["search"] = { n: 1, res: {}, q: q, defs: [{ t: "Resultados: " + q, mt: "" }] }
    m.cache.Delete("search")
    m.status.text = "Buscando…"
    fetch("search", 0, "/search/multi", "", q)
  end if
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
  inContent = (m.rows.hasFocus() or m.grid.hasFocus())
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
  if m.top.dialog <> invalid then return
  if m.zone = "content" then
    if m.tabId = "tv" then
      if m.grid.visible and not m.grid.hasFocus() then m.grid.setFocus(true)
    else if m.rows.visible then
      if not m.rows.hasFocus() then m.rows.setFocus(true)
    else
      m.zone = "nav"
      renderNav()
      m.navKeys.setFocus(true)
    end if
  else
    if not m.navKeys.hasFocus() then m.navKeys.setFocus(true)
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
    playEpisode(m.eps.content, ep.season, ep.episode, ep.name)
  end if
end sub

function detectFmt(src as Object) as String
  if src.format <> invalid then return src.format
  if Instr(1, LCase(src.url), ".m3u8") > 0 then return "hls"
  return "mp4"
end function

sub playEpisode(show as Object, sn as Integer, en as Integer, name as String)
  ck = "tv:" + show.tmdbId.toStr() + ":" + sn.toStr() + ":" + en.toStr()
  src = invalid
  j = ParseJson(ReadAsciiFile("pkg:/source/sources.json"))
  if j <> invalid then
    src = j[ck]
    if src = invalid then src = j[show.ckey]
  end if
  if src = invalid then
    msg("Sin fuente de video", ["Agrega la fuente en source/sources.json con la clave " + ck + " (o " + show.ckey + " para toda la serie)."])
    return
  end if
  url = src.url
  url = url.Replace("{ss}", Right("0" + sn.toStr(), 2))
  url = url.Replace("{ee}", Right("0" + en.toStr(), 2))
  url = url.Replace("{s}", sn.toStr())
  url = url.Replace("{e}", en.toStr())
  rec = recOf(show)
  rec.ckey = ck
  rec.title = show.title + "  T" + sn.toStr() + " E" + en.toStr()
  start = 0
  for each r in m.recent
    if r.ckey = ck and r.t <> invalid then start = r.t
  end for
  startVideo(url, detectFmt(src), show.title + "  T" + sn.toStr() + " · E" + en.toStr(), ck, false, start, rec)
end sub
