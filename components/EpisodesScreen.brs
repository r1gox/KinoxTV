sub init()
  m.title = m.top.findNode("title")
  m.seasonTitle = m.top.findNode("seasonTitle")
  m.bd = m.top.findNode("bd")
  m.seasons = m.top.findNode("seasons")
  m.eps = m.top.findNode("eps")
  m.status = m.top.findNode("status")
  m.timer = m.top.findNode("debounce")
  m.timer.observeField("fire", "onTimer")
  m.seasons.observeField("itemFocused", "onSeasonFocus")
  m.seasons.observeField("itemSelected", "onSeasonPick")
  m.eps.observeField("itemSelected", "onEpPick")
  m.top.observeField("focusedChild", "onFocusChange")
  m.cache = {}
  m.tasks = {}
  m.seasonNums = []
  m.curSeason = -1
  m.inEps = false
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
  if c.backdrop <> "" then m.bd.uri = "https://image.tmdb.org/t/p/w1280" + c.backdrop
  m.status.text = "Cargando temporadas…"
  t = CreateObject("roSGNode", "TmdbTask")
  m.showTask = t
  t.apiKey = m.top.apiKey
  t.path = "/tv/" + c.tmdbId.toStr()
  t.observeField("result", "onShow")
  t.control = "RUN"
end sub

sub onShow(evt as Object)
  d = evt.getData()
  if d = invalid then return
  if d.seasons = invalid then
    m.status.text = "No se pudieron cargar las temporadas."
    return
  end if
  root = CreateObject("roSGNode", "ContentNode")
  m.seasonNums = []
  for each pass in [1, 2]
    for each s in d.seasons
      n = s.season_number
      if n <> invalid then
        isReg = (n > 0)
        if (pass = 1 and isReg) or (pass = 2 and not isReg) then
          cnt = 0
          if s.episode_count <> invalid then cnt = s.episode_count
          if isReg or cnt > 0 then
            node = CreateObject("roSGNode", "ContentNode")
            node.title = seasonName(n)
            root.appendChild(node)
            m.seasonNums.Push(n)
          end if
        end if
      end if
    end for
  end for
  if m.seasonNums.Count() = 0 then
    m.status.text = "Esta serie no tiene temporadas registradas en TMDB."
    return
  end if
  m.status.text = ""
  m.seasons.content = root
  m.seasons.jumpToItem = 0
  loadSeasonAt(0)
  if not m.inEps then m.seasons.setFocus(true)
end sub

sub onSeasonFocus()
  m.timer.control = "stop"
  m.timer.control = "start"
end sub

sub onTimer()
  loadSeasonAt(m.seasons.itemFocused)
end sub

sub loadSeasonAt(idx as Integer)
  if idx < 0 or idx >= m.seasonNums.Count() then return
  n = m.seasonNums[idx]
  if n = m.curSeason then return
  m.curSeason = n
  m.seasonTitle.text = seasonName(n)
  if m.cache.DoesExist(n.toStr()) then
    showSeason(n, 0)
    return
  end if
  m.eps.content = CreateObject("roSGNode", "ContentNode")
  m.status.text = "Cargando episodios…"
  t = CreateObject("roSGNode", "TmdbTask")
  t.tab = "season"
  t.idx = n
  t.apiKey = m.top.apiKey
  t.path = "/tv/" + m.top.content.tmdbId.toStr() + "/season/" + n.toStr()
  t.observeField("result", "onSeasonData")
  m.tasks[n.toStr()] = t
  t.control = "RUN"
end sub

sub onSeasonData(evt as Object)
  t = evt.getRoSGNode()
  res = evt.getData()
  n = t.idx
  if res = invalid then return
  if res.episodes = invalid then
    if n = m.curSeason then
      m.status.text = "No se pudieron cargar los episodios. Cambia de temporada y vuelve a intentar."
      m.curSeason = -1
    end if
    return
  end if
  m.cache[n.toStr()] = res
  if n = m.curSeason then showSeason(n, 0)
end sub

sub showSeason(n as Integer, keepIdx as Integer)
  raw = m.cache[n.toStr()]
  if raw = invalid then return
  seen = loadWatched()
  root = CreateObject("roSGNode", "ContentNode")
  showId = m.top.content.tmdbId.toStr()
  for each e in raw.episodes
    ep = e.episode_number
    if ep <> invalid then
      node = CreateObject("roSGNode", "ContentNode")
      name = txt(e.name)
      if name = "" then name = "Episodio " + ep.toStr()
      node.title = ep.toStr() + ". " + name
      still = txt(e.still_path)
      if still <> "" then node.HDPosterUrl = "https://image.tmdb.org/t/p/w300" + still
      parts = []
      if e.runtime <> invalid then
        if e.runtime > 0 then parts.Push(e.runtime.toStr() + " min")
      end if
      ad = txt(e.air_date)
      if ad <> "" then
        dp = ad.Split("-")
        if dp.Count() = 3 then parts.Push(dp[2] + "/" + dp[1] + "/" + dp[0])
      end if
      meta = ""
      for i = 0 to parts.Count() - 1
        if i > 0 then meta = meta + "   |   "
        meta = meta + parts[i]
      end for
      ov = txt(e.overview)
      if ov = "" then ov = "Sin sinopsis."
      key = "tv:" + showId + ":" + n.toStr() + ":" + ep.toStr()
      node.addFields({ epNum: ep, epName: name, meta: meta, epOverview: ov, epRating: Left(txt(e.vote_average), 3), watched: seen.DoesExist(key) })
      root.appendChild(node)
    end if
  end for
  m.eps.content = root
  total = root.getChildCount()
  if total = 0 then
    m.status.text = "Esta temporada aún no tiene episodios."
  else
    m.status.text = ""
    if keepIdx >= total then keepIdx = 0
    m.eps.jumpToItem = keepIdx
  end if
  m.seasonTitle.text = seasonName(n) + "   ·   " + total.toStr() + " episodios"
end sub

sub onRefresh()
  if m.curSeason < 0 then return
  if not m.cache.DoesExist(m.curSeason.toStr()) then return
  showSeason(m.curSeason, m.eps.itemFocused)
end sub

sub onSeasonPick()
  focusEps()
end sub

sub onEpPick()
  node = m.eps.content.getChild(m.eps.itemSelected)
  if node = invalid then return
  m.top.episode = { season: m.curSeason, episode: node.epNum, name: node.epName }
  m.top.action = "play"
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
