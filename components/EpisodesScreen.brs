sub init()
  m.title = m.top.findNode("title")
  m.seasonTitle = m.top.findNode("seasonTitle")
  m.bd = m.top.findNode("bd")
  m.seasons = m.top.findNode("seasons")
  m.eps = m.top.findNode("eps")
  m.status = m.top.findNode("status")
  m.playStatusLbl = m.top.findNode("playStatusLbl")
  m.playStatusBg = m.top.findNode("playStatusBg")
  m.timer = m.top.findNode("debounce")
  m.timer.observeField("fire", "onTimer")
  m.seasons.observeField("itemFocused", "onSeasonFocus")
  m.seasons.observeField("itemSelected", "onSeasonPick")
  m.eps.observeField("itemSelected", "onEpPick")
  m.top.observeField("focusedChild", "onFocusChange")
  m.cache = {}
  m.seasonNums = []
  m.seasonData = []
  m.curSeason = -1
  m.inEps = false
end sub

sub onPlayStatus()
  txt = m.top.playStatus
  if txt = invalid then txt = ""
  if m.playStatusLbl = invalid then return
  if txt = "" then
    m.playStatusLbl.visible = false
    m.playStatusBg.visible = false
    m.playStatusLbl.text = ""
  else
    m.playStatusLbl.text = txt
    m.playStatusLbl.visible = true
    m.playStatusBg.visible = true
  end if
end sub

function txt(v as Dynamic) as String
  if v = invalid then return ""
  if type(v) = "roString" or type(v) = "String" then return v
  return v.toStr()
end function

function loadWatched() as Object
  sec = CreateObject("roRegistrySection", "PlayZoneTV2")
  if sec.Exists("watched") then
    w = ParseJson(sec.Read("watched"))
    if w <> invalid then
      if type(w) = "roAssociativeArray" then return w
    end if
  end if
  return {}
end function

function seasonName(n as Integer) as String
  if n = 0 then return "Especiales"
  return "Temporada " + n.toStr()
end function

sub onContent()
  c = m.top.content
  if c = invalid then return
  m.title.text = c.title
  m.bd.uri = ""
  if c.backdrop <> invalid and c.backdrop <> "" then
    if Left(c.backdrop, 1) = "/" then
      m.bd.uri = "https://image.tmdb.org/t/p/w1280" + c.backdrop
    else if Instr(1, c.backdrop, "http") = 1 then
      m.bd.uri = c.backdrop
    end if
  end if
  m.status.text = "Cargando temporadas..."
  m.seasonData = []
  m.seasonNums = []
  m.cache = {}
  ' Preferir API de la serie (extractUrl)
  extractUrl = ""
  if c.extractUrl <> invalid then extractUrl = c.extractUrl
  if extractUrl <> "" then
    task = CreateObject("roSGNode", "ApiTask")
    m.apiTask = task
    task.requestUrl = extractUrl
    task.observeField("response", "onApiSeries")
    task.control = "RUN"
    return
  end if
  ' Fallback TMDB
  loadTmdbSeasons()
end sub

sub loadTmdbSeasons()
  c = m.top.content
  if c = invalid or c.tmdbId = invalid or c.tmdbId = 0 then
    m.status.text = "Sin datos de temporadas."
    return
  end if
  t = CreateObject("roSGNode", "TmdbTask")
  m.showTask = t
  t.apiKey = m.top.apiKey
  t.path = "/tv/" + c.tmdbId.toStr()
  t.observeField("result", "onShowTmdb")
  t.control = "RUN"
end sub

sub onApiSeries()
  res = invalid
  if m.apiTask <> invalid then res = m.apiTask.response
  if res = invalid then
    loadTmdbSeasons()
    return
  end if
  ' temporadas (tvymas) o seasons (apislatam)
  list = invalid
  if res.temporadas <> invalid then list = res.temporadas
  if list = invalid and res.seasons <> invalid then list = res.seasons
  if list = invalid or list.count() = 0 then
    loadTmdbSeasons()
    return
  end if
  root = CreateObject("roSGNode", "ContentNode")
  m.seasonNums = []
  m.seasonData = []
  for each s in list
    n = 0
    if s.season_number <> invalid then n = s.season_number
    if n = 0 and s.season <> invalid then n = s.season
    if n = 0 and s.temporada <> invalid then n = s.temporada
    eps = invalid
    if s.episodios <> invalid then eps = s.episodios
    if eps = invalid and s.episodes <> invalid then eps = s.episodes
    if eps = invalid then eps = []
    node = CreateObject("roSGNode", "ContentNode")
    node.title = seasonName(n)
    if s.name <> invalid and s.name <> "" then node.title = s.name
    root.appendChild(node)
    m.seasonNums.Push(n)
    pack = CreateObject("roAssociativeArray")
    pack.num = n
    pack.eps = eps
    m.seasonData.Push(pack)
  end for
  if m.seasonNums.Count() = 0 then
    m.status.text = "Esta serie no tiene temporadas."
    return
  end if
  m.seasons.content = root
  m.status.text = ""
  m.seasons.jumpToItem = 0
  m.curSeason = -1
  m.inEps = false
  m.seasons.setFocus(true)
  loadSeasonEps(0)
end sub

sub onShowTmdb(evt as Object)
  d = evt.getData()
  if d = invalid then return
  if d.seasons = invalid then
    m.status.text = "No se pudieron cargar las temporadas."
    return
  end if
  root = CreateObject("roSGNode", "ContentNode")
  m.seasonNums = []
  m.seasonData = []
  for each s in d.seasons
    n = s.season_number
    if n <> invalid and n > 0 then
      node = CreateObject("roSGNode", "ContentNode")
      node.title = seasonName(n)
      root.appendChild(node)
      m.seasonNums.Push(n)
      pack = CreateObject("roAssociativeArray")
      pack.num = n
      pack.eps = invalid
      pack.tmdb = true
      m.seasonData.Push(pack)
    end if
  end for
  if m.seasonNums.Count() = 0 then
    m.status.text = "Esta serie no tiene temporadas."
    return
  end if
  m.seasons.content = root
  m.status.text = ""
  m.seasons.jumpToItem = 0
  m.curSeason = -1
  m.seasons.setFocus(true)
  loadSeasonEps(0)
end sub

sub onSeasonFocus()
  m.timer.control = "stop"
  m.timer.control = "start"
end sub

sub onTimer()
  idx = m.seasons.itemFocused
  if idx = invalid then return
  loadSeasonEps(idx)
end sub

sub onSeasonPick()
  idx = m.seasons.itemSelected
  if idx = invalid then return
  loadSeasonEps(idx)
  focusEps()
end sub

sub loadSeasonEps(idx as Integer)
  if idx < 0 or idx >= m.seasonNums.Count() then return
  if idx = m.curSeason and m.eps.content <> invalid then return
  m.curSeason = idx
  sn = m.seasonNums[idx]
  m.seasonTitle.text = seasonName(sn) + "  ·  episodios"
  pack = m.seasonData[idx]
  ' Cache
  key = sn.toStr()
  if m.cache.DoesExist(key) then
    m.eps.content = m.cache[key]
    return
  end if
  if pack.eps <> invalid then
    buildEpsFromApi(sn, pack.eps)
    return
  end if
  ' TMDB episodes
  c = m.top.content
  m.status.text = "Cargando episodios..."
  t = CreateObject("roSGNode", "TmdbTask")
  m.epTask = t
  t.apiKey = m.top.apiKey
  t.path = "/tv/" + c.tmdbId.toStr() + "/season/" + sn.toStr()
  t.observeField("result", "onEpsTmdb")
  t.control = "RUN"
end sub

sub buildEpsFromApi(sn as Integer, eps as Object)
  c = m.top.content
  watched = loadWatched()
  root = CreateObject("roSGNode", "ContentNode")
  base = ""
  if c.extractUrl <> invalid then base = c.extractUrl
  for each e in eps
    en = 0
    if e.episode_number <> invalid then en = e.episode_number
    if en = 0 and e.episode <> invalid then en = e.episode
    if en = 0 and e.episodio <> invalid then en = e.episodio
    name = txt(e.name)
    if name = "" then name = txt(e.title)
    if name = "" then name = txt(e.titulo)
    if name = "" then name = "Episodio " + en.toStr()
    ov = txt(e.overview)
    if ov = "" then ov = txt(e.descripcion)
    still = txt(e.still)
    if still = "" then still = txt(e.image)
    if still = "" then still = txt(e.back_img)
    rate = ""
    if e.rating <> invalid then rate = Left(txt(e.rating), 3)
    extractUrl = txt(e.extract_url)
    if extractUrl = "" then extractUrl = txt(e.url)
    if extractUrl = "" and base <> "" then
      extractUrl = base
      if Right(base, 1) = "/" then
        extractUrl = base + sn.toStr() + "/" + en.toStr()
      else
        extractUrl = base + "/" + sn.toStr() + "/" + en.toStr()
      end if
    end if
    ck = "tv:" + c.tmdbId.toStr() + ":" + sn.toStr() + ":" + en.toStr()
    node = CreateObject("roSGNode", "ContentNode")
    node.title = "E" + en.toStr() + "  ·  " + name
    node.HDPosterUrl = still
    node.addField("meta", "string", false)
    node.meta = "T" + sn.toStr() + " E" + en.toStr()
    node.addField("epOverview", "string", false)
    node.epOverview = ov
    node.addField("epRating", "string", false)
    node.epRating = rate
    node.addField("watched", "boolean", false)
    node.watched = watched.DoesExist(ck)
    node.addField("season", "integer", false)
    node.season = sn
    node.addField("episode", "integer", false)
    node.episode = en
    node.addField("name", "string", false)
    node.name = name
    node.addField("extractUrl", "string", false)
    node.extractUrl = extractUrl
    node.Description = extractUrl
    root.appendChild(node)
  end for
  m.cache[sn.toStr()] = root
  m.eps.content = root
  m.status.text = ""
end sub

sub onEpsTmdb(evt as Object)
  d = evt.getData()
  m.status.text = ""
  if d = invalid or d.episodes = invalid then
    m.status.text = "Sin episodios."
    return
  end if
  sn = m.seasonNums[m.curSeason]
  c = m.top.content
  watched = loadWatched()
  root = CreateObject("roSGNode", "ContentNode")
  base = ""
  if c.extractUrl <> invalid then base = c.extractUrl
  for each e in d.episodes
    en = e.episode_number
    name = txt(e.name)
    if name = "" then name = "Episodio " + en.toStr()
    still = ""
    if e.still_path <> invalid and e.still_path <> "" then
      still = "https://image.tmdb.org/t/p/w500" + e.still_path
    end if
    extractUrl = ""
    if base <> "" then
      if Right(base, 1) = "/" then
        extractUrl = base + sn.toStr() + "/" + en.toStr()
      else
        extractUrl = base + "/" + sn.toStr() + "/" + en.toStr()
      end if
    end if
    ck = "tv:" + c.tmdbId.toStr() + ":" + sn.toStr() + ":" + en.toStr()
    node = CreateObject("roSGNode", "ContentNode")
    node.title = "E" + en.toStr() + "  ·  " + name
    node.HDPosterUrl = still
    node.addField("meta", "string", false)
    node.meta = "T" + sn.toStr() + " E" + en.toStr()
    node.addField("epOverview", "string", false)
    node.epOverview = txt(e.overview)
    node.addField("epRating", "string", false)
    node.epRating = Left(txt(e.vote_average), 3)
    node.addField("watched", "boolean", false)
    node.watched = watched.DoesExist(ck)
    node.addField("season", "integer", false)
    node.season = sn
    node.addField("episode", "integer", false)
    node.episode = en
    node.addField("name", "string", false)
    node.name = name
    node.addField("extractUrl", "string", false)
    node.extractUrl = extractUrl
    node.Description = extractUrl
    root.appendChild(node)
  end for
  m.cache[sn.toStr()] = root
  m.eps.content = root
end sub

sub onEpPick()
  idx = m.eps.itemSelected
  if m.eps.content = invalid then return
  node = m.eps.content.getChild(idx)
  if node = invalid then return
  ep = CreateObject("roAssociativeArray")
  sn = 1
  en = 1
  if node.season <> invalid then sn = node.season
  if node.episode <> invalid then en = node.episode
  ep.season = sn
  ep.episode = en
  ep.name = ""
  if node.name <> invalid then ep.name = node.name
  extractUrl = ""
  if node.extractUrl <> invalid then extractUrl = node.extractUrl
  if extractUrl = "" and node.Description <> invalid then extractUrl = node.Description
  if extractUrl = "" then
    c = m.top.content
    base = ""
    if c <> invalid and c.extractUrl <> invalid then base = c.extractUrl
    if base <> "" then
      if Right(base, 1) = "/" then
        extractUrl = base + sn.toStr() + "/" + en.toStr()
      else
        extractUrl = base + "/" + sn.toStr() + "/" + en.toStr()
      end if
    end if
  end if
  ep.extractUrl = extractUrl
  m.top.episode = ep
  m.top.action = "play"
end sub

sub onRefresh()
  m.cache = {}
  if m.curSeason >= 0 then
    m.curSeason = -1
    loadSeasonEps(m.seasons.itemFocused)
  end if
end sub

sub focusEps()
  if m.eps.content = invalid then return
  if m.eps.content.getChildCount() = 0 then return
  m.inEps = true
  m.eps.setFocus(true)
end sub

sub focusSeasons()
  m.inEps = false
  m.seasons.setFocus(true)
end sub

sub onFocusChange()
  if m.top.hasFocus() then
    if m.inEps then
      m.eps.setFocus(true)
    else
      m.seasons.setFocus(true)
    end if
  end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  if key = "back" then
    if m.inEps then
      focusSeasons()
    else
      m.top.action = "close"
    end if
    return true
  else if key = "right" and not m.inEps then
    focusEps()
    return true
  else if key = "left" and m.inEps then
    focusSeasons()
    return true
  end if
  return false
end function
