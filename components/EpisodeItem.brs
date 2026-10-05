sub init()
  m.still = m.top.findNode("still")
  m.title = m.top.findNode("title")
  m.meta = m.top.findNode("meta")
  m.ov = m.top.findNode("ov")
  m.chip = m.top.findNode("chip")
  m.rate = m.top.findNode("rate")
  m.badge = m.top.findNode("badge")
  m.badgeT = m.top.findNode("badgeT")
  m.ring = m.top.findNode("ring")
end sub

sub onContent()
  c = m.top.itemContent
  if c = invalid then return
  m.title.text = c.title
  m.meta.text = c.meta
  m.ov.text = c.epOverview
  m.still.uri = c.HDPosterUrl
  hasRate = (c.epRating <> "" and c.epRating <> "0")
  m.chip.visible = hasRate
  m.rate.visible = hasRate
  if hasRate then m.rate.text = c.epRating
  w = (c.watched = true)
  m.badge.visible = w
  m.badgeT.visible = w
  updateFocus()
end sub

sub updateFocus()
  m.ring.visible = m.top.itemHasFocus
end sub
