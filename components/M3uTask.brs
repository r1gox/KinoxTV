sub init()
  m.top.functionName = "doRequest"
end sub

sub doRequest()
  chs = []
  req = CreateObject("roUrlTransfer")
  req.SetCertificatesFile("common:/certs/ca-bundle.crt")
  req.InitClientCertificates()
  req.SetUrl(m.top.url)
  port = CreateObject("roMessagePort")
  req.SetMessagePort(port)
  if req.AsyncGetToString() then
    msg = wait(15000, port)
    if msg = invalid then
      req.AsyncCancel()
    else if type(msg) = "roUrlEvent" then
      chs = parseM3u(msg.GetString())
    end if
  end if
  m.top.channels = chs
  m.top.done = true
end sub

function parseM3u(body as String) as Object
  chs = []
  logoRe = CreateObject("roRegex", "tvg-logo=""([^""]*)""", "")
  name = ""
  logo = ""
  for each ln in body.Split(Chr(10))
    l = ln.Trim()
    if Left(l, 7) = "#EXTINF" then
      p = l.Split(",")
      name = p[p.Count() - 1].Trim()
      mm = logoRe.Match(l)
      logo = ""
      if mm.Count() > 1 then logo = mm[1]
    else if l <> "" and Left(l, 1) <> "#" and name <> "" then
      chs.Push({ name: name, logo: logo, url: l })
      name = ""
      if chs.Count() >= 400 then exit for
    end if
  end for
  return chs
end function
