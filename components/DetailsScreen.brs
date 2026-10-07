sub init()
  m.bd = m.top.findNode("bd")
  m.poster = m.top.findNode("poster")
  m.title = m.top.findNode("title")
  m.meta = m.top.findNode("meta")
  m.genres = m.top.findNode("genres")
  m.ov = m.top.findNode("ov")
  m.prov = m.top.findNode("prov")
  m.btns = m.top.findNode("btns")
  m.playStatusLbl = m.top.findNode("playStatusLbl")
  m.playStatusBg = m.top.findNode("playStatusBg")
  m.btns.observeField("buttonSelected", "onBtn")
  m.top.observeField("focusedChild", "onFocusChange")
  setButtons()
end sub

sub onPlayStatus()
  txt = m.top.playStatus
  if txt = invalid then txt = ""
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

sub setButtons()
  fav = "Añadir a mi lista"
  if m.top.isFav then fav = "Quitar de mi lista"
  labels = []
  m.actions = []
  isTv = false
  c = m.top.content
  if c <> invalid then
    if c.mediaType = "tv" then isTv = true
  end if
  if isTv then
    labels.Push("Temporadas y episodios")
    m.actions.Push("seasons")
  else
    labels.Push("Reproducir")
    m.actions.Push("play")
  end if
  m.favIdx = labels.Count()
  labels.Push(fav)
  m.actions.Push("fav")
  labels.Push("Volver")
  m.actions.Push("close")
  m.btns.buttons = labels
end sub

sub onFavChanged()
  setButtons()
  m.btns.focusButton = m.favIdx
end sub

sub onContent()
  c = m.top.content
  if c = invalid then return
  m.poster.uri = c.HDPosterUrl
  m.bd.uri = ""
  if c.backdrop <> invalid and c.backdrop <> "" then
    if Left(c.backdrop, 1) = "/" then
      m.bd.uri = "https://image.tmdb.org/t/p/w1280" + c.backdrop
    else if Instr(1, c.backdrop, "http") = 1 then
      m.bd.uri = c.backdrop
    end if
  end if
  setButtons()
  m.title.text = c.title
  m.kind = "Película"
  if c.mediaType = "tv" then m.kind = "Serie"
  yr = ""
  if c.year <> invalid then yr = c.year
  rt = ""
  if c.rating <> invalid then rt = c.rating
  m.meta.text = m.kind + "   |   " + yr + "   |   TMDB " + rt + " / 10"
  if c.overview = "" then
    m.ov.text = "Sin sinopsis en español."
  else
    m.ov.text = c.overview
  end if
  m.prov.text = ""
  m.genres.text = ""
  ' Completar datos desde API (serie/pelicula) si hay extractUrl
  if c.extractUrl <> invalid and c.extractUrl <> "" then
    at = CreateObject("roSGNode", "ApiTask")
    m.apiDetailTask = at
    at.requestUrl = c.extractUrl
    at.observeField("response", "onApiDetail")
    at.control = "RUN"
  end if
  if c.tmdbId <> invalid and c.tmdbId > 0 and m.top.apiKey <> "" then
    t = CreateObject("roSGNode", "TmdbTask")
    m.task = t
    t.apiKey = m.top.apiKey
    t.path = "/" + c.mediaType + "/" + c.tmdbId.toStr()
    t.params = "&append_to_response=watch/providers"
    t.observeField("result", "onDetail")
    t.control = "RUN"
  end if
end sub

sub onApiDetail()
  res = invalid
  if m.apiDetailTask <> invalid then res = m.apiDetailTask.response
  if res = invalid then return
  c = m.top.content
  ' Sinopsis de la API si falta
  ov = ""
  if res.description <> invalid then ov = res.description
  if ov = "" and res.overview_tmdb <> invalid then ov = res.overview_tmdb
  if ov = "" and res.overview <> invalid then ov = res.overview
  if ov <> "" then
    cur = m.ov.text
    if cur = "" or cur = "Sin sinopsis en español." then m.ov.text = ov
    if c <> invalid then c.overview = ov
  end if
  ' Portada
  poster = ""
  if res.poster_tmdb <> invalid then poster = res.poster_tmdb
  if poster = "" and res.image <> invalid then poster = res.image
  if poster = "" and res.portada <> invalid then poster = res.portada
  if poster <> "" then
    m.poster.uri = poster
    if c <> invalid then c.HDPosterUrl = poster
  end if
  ' Banner
  if res.backdrop <> invalid and res.backdrop <> "" then
    m.bd.uri = res.backdrop
    if c <> invalid then c.backdrop = res.backdrop
  end if
  ' Año y rating
  yr = ""
  if res.year <> invalid then yr = res.year.toStr()
  if yr = "" and res.release_date <> invalid and Len(res.release_date) >= 4 then yr = Left(res.release_date, 4)
  rt = ""
  if res.rating <> invalid then rt = Left(res.rating.toStr(), 3)
  if res.tmdb_rating <> invalid and rt = "" then rt = Left(res.tmdb_rating.toStr(), 3)
  if yr <> "" or rt <> "" then
    m.meta.text = m.kind + "   |   " + yr + "   |   TMDB " + rt + " / 10"
    if c <> invalid then
      if yr <> "" then c.year = yr
      if rt <> "" then c.rating = rt
    end if
  end if
  ' Generos API
  if res.genres <> invalid then
    gtxt = ""
    if type(res.genres) = "roArray" then
      for each g in res.genres
        if type(g) = "roString" or type(g) = "String" then
          if gtxt <> "" then gtxt = gtxt + "  ·  "
          gtxt = gtxt + g
        else if g.name <> invalid then
          if gtxt <> "" then gtxt = gtxt + "  ·  "
          gtxt = gtxt + g.name
        end if
      end for
    end if
    if gtxt <> "" and m.genres.text = "" then m.genres.text = gtxt
  end if
  ' Corregir tmdb_id si la API trae el bueno
  if res.tmdb_id <> invalid and c <> invalid then
    tid = res.tmdb_id
    if type(tid) = "roString" or type(tid) = "String" then tid = Val(tid)
    if tid > 0 then
      c.tmdbId = tid
      if m.top.apiKey <> "" then
        t = CreateObject("roSGNode", "TmdbTask")
        m.task = t
        t.apiKey = m.top.apiKey
        t.path = "/" + c.mediaType + "/" + tid.toStr()
        t.params = "&append_to_response=watch/providers"
        t.observeField("result", "onDetail")
        t.control = "RUN"
      end if
    end if
  end if
end sub

sub onDetail(evt as Object)
  d = evt.getData()
  c = m.top.content
  if d = invalid or c = invalid then return
  if d.error <> invalid then return
  ' Fondo / poster / sinopsis desde TMDB
  if d.backdrop_path <> invalid and d.backdrop_path <> "" then
    m.bd.uri = "https://image.tmdb.org/t/p/w1280" + d.backdrop_path
  end if
  if d.poster_path <> invalid and d.poster_path <> "" then
    if c.HDPosterUrl = invalid or c.HDPosterUrl = "" then
      m.poster.uri = "https://image.tmdb.org/t/p/w500" + d.poster_path
    end if
  end if
  ' Completar sinopsis si venía cortada (favoritos antiguos con Left 120)
  if d.overview <> invalid and d.overview <> "" then
    cur = m.ov.text
    if cur = "" or cur = "Sin sinopsis en español." or Len(cur) < Len(d.overview) then
      m.ov.text = d.overview
    end if
  end if
  names = []
  if d.genres <> invalid then
    for each g in d.genres
      names.Push(g.name)
    end for
  end if
  m.genres.text = joinList(names, "  ·  ")
  yr = ""
  if c.year <> invalid then yr = c.year
  if yr = "" or yr = "0" then
    if d.release_date <> invalid and Len(d.release_date) >= 4 then yr = Left(d.release_date, 4)
    if d.first_air_date <> invalid and Len(d.first_air_date) >= 4 then yr = Left(d.first_air_date, 4)
  end if
  ' Preferir siempre fecha TMDB si existe
  if d.release_date <> invalid and Len(d.release_date) >= 4 then yr = Left(d.release_date, 4)
  if d.first_air_date <> invalid and Len(d.first_air_date) >= 4 then yr = Left(d.first_air_date, 4)
  rt = ""
  if c.rating <> invalid then rt = c.rating
  if d.vote_average <> invalid then
    va = d.vote_average
    if type(va) = "roString" or type(va) = "String" then
      rt = Left(va, 3)
    else
      rt = Left(va.toStr(), 3)
    end if
  end if
  parts = [m.kind]
  if yr <> "" then parts.Push(yr)
  if d.runtime <> invalid then
    if d.runtime > 0 then parts.Push(d.runtime.toStr() + " min")
  end if
  if d.number_of_seasons <> invalid then
    if d.number_of_seasons > 0 then parts.Push(d.number_of_seasons.toStr() + " temporada(s)")
  end if
  if rt <> "" then parts.Push("TMDB " + rt + " / 10")
  m.meta.text = joinList(parts, "   |   ")
  txt = "No hay plataformas registradas en México."
  pv = d["watch/providers"]
  if pv <> invalid then
    if pv.results <> invalid then
      mx = pv.results.MX
      if mx <> invalid then
        pn = []
        for each k in ["flatrate", "rent", "buy"]
          if mx[k] <> invalid then
            for each p in mx[k]
              if not hasItem(pn, p.provider_name) and pn.Count() < 6 then pn.Push(p.provider_name)
            end for
          end if
        end for
        if pn.Count() > 0 then txt = "Disponible en: " + joinList(pn, "  ·  ")
      end if
    end if
  end if
  m.prov.text = txt
end sub

function joinList(arr as Object, sep as String) as String
  out = ""
  for i = 0 to arr.Count() - 1
    if i > 0 then out = out + sep
    out = out + arr[i]
  end for
  return out
end function

function hasItem(arr as Object, v as String) as Boolean
  for each x in arr
    if x = v then return true
  end for
  return false
end function

sub onFocusChange()
  if m.top.hasFocus() then m.btns.setFocus(true)
end sub

sub onBtn()
  i = m.btns.buttonSelected
  if i >= 0 and i < m.actions.Count() then m.top.action = m.actions[i]
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if press and key = "back" then
    m.top.action = "close"
    return true
  end if
  return false
end function
