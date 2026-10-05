sub init()
  m.bd = m.top.findNode("bd")
  m.poster = m.top.findNode("poster")
  m.title = m.top.findNode("title")
  m.meta = m.top.findNode("meta")
  m.genres = m.top.findNode("genres")
  m.ov = m.top.findNode("ov")
  m.prov = m.top.findNode("prov")
  m.btns = m.top.findNode("btns")
  m.btns.observeField("buttonSelected", "onBtn")
  m.top.observeField("focusedChild", "onFocusChange")
  setButtons()
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
  if c.backdrop <> "" then m.bd.uri = "https://image.tmdb.org/t/p/w1280" + c.backdrop
  setButtons()
  m.title.text = c.title
  m.kind = "Película"
  if c.mediaType = "tv" then m.kind = "Serie"
  m.meta.text = m.kind + "   |   " + c.year + "   |   TMDB " + c.rating + " / 10"
  if c.overview = "" then
    m.ov.text = "Sin sinopsis en español."
  else
    m.ov.text = c.overview
  end if
  m.prov.text = ""
  m.genres.text = ""
  t = CreateObject("roSGNode", "TmdbTask")
  m.task = t
  t.apiKey = m.top.apiKey
  t.path = "/" + c.mediaType + "/" + c.tmdbId.toStr()
  t.params = "&append_to_response=watch/providers"
  t.observeField("result", "onDetail")
  t.control = "RUN"
end sub

sub onDetail(evt as Object)
  d = evt.getData()
  c = m.top.content
  if d = invalid or c = invalid then return
  if d.error <> invalid then return
  names = []
  if d.genres <> invalid then
    for each g in d.genres
      names.Push(g.name)
    end for
  end if
  m.genres.text = joinList(names, "  ·  ")
  parts = [m.kind, c.year]
  if d.runtime <> invalid then
    if d.runtime > 0 then parts.Push(d.runtime.toStr() + " min")
  end if
  if d.number_of_seasons <> invalid then
    parts.Push(d.number_of_seasons.toStr() + " temporada(s)")
  end if
  parts.Push("TMDB " + c.rating + " / 10")
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
