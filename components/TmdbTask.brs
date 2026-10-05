sub init()
  m.top.functionName = "doRequest"
end sub

sub doRequest()
  req = CreateObject("roUrlTransfer")
  req.SetCertificatesFile("common:/certs/ca-bundle.crt")
  req.InitClientCertificates()
  url = "https://api.themoviedb.org/3" + m.top.path + "?api_key=" + m.top.apiKey + "&language=es-MX" + m.top.params
  if m.top.query <> "" then url = url + "&query=" + req.Escape(m.top.query)
  req.SetUrl(url)
  port = CreateObject("roMessagePort")
  req.SetMessagePort(port)
  if not req.AsyncGetToString() then
    m.top.result = { error: "No se pudo iniciar la petición." }
    return
  end if
  msg = wait(10000, port)
  if msg = invalid then
    req.AsyncCancel()
    m.top.result = { error: "Tiempo de espera agotado." }
    return
  end if
  if type(msg) = "roUrlEvent" then
    json = ParseJson(msg.GetString())
    if json <> invalid then
      m.top.result = json
      return
    end if
  end if
  m.top.result = { error: "Respuesta no válida de TMDB." }
end sub
