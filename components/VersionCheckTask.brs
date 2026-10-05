sub init()
  m.top.functionName = "executeRequest"
end sub

sub executeRequest()
  url = m.top.requestUrl
  if url = "" then return
  req = CreateObject("roUrlTransfer")
  req.SetCertificatesFile("common:/certs/ca-bundle.crt")
  req.InitClientCertificates()
  req.SetUrl(url)
  port = CreateObject("roMessagePort")
  req.SetMessagePort(port)
  if not req.AsyncGetToString() then return
  msg = wait(8000, port)
  if msg = invalid then
    req.AsyncCancel()
    return
  end if
  if type(msg) = "roUrlEvent" then
    json = ParseJson(msg.GetString())
    if json <> invalid then m.top.response = json
  end if
end sub
