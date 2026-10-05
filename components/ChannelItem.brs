sub init()
  m.logo = m.top.findNode("logo")
  m.code = m.top.findNode("code")
  m.name = m.top.findNode("name")
  m.ring = m.top.findNode("ring")
end sub

sub onContent()
  c = m.top.itemContent
  if c = invalid then return
  m.name.text = c.title
  m.logo.uri = c.HDPosterUrl
  m.code.text = c.code
  m.code.visible = (c.code <> "")
end sub

sub updateFocus()
  m.ring.visible = (m.top.itemHasFocus and m.top.gridHasFocus)
end sub
