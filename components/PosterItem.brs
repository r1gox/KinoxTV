sub init()
  m.p = m.top.findNode("p")
  m.t = m.top.findNode("t")
  m.r = m.top.findNode("r")
  m.ring = m.top.findNode("ring")
  m.badge = m.top.findNode("badge")
  m.badgeT = m.top.findNode("badgeT")
  m.chip = m.top.findNode("chip")
  m.rank = m.top.findNode("rank")
  m.rankBg = m.top.findNode("rankBg")
  m.progBg = m.top.findNode("progBg")
  m.progFill = m.top.findNode("progFill")
end sub

sub onContent()
  c = m.top.itemContent
  if c = invalid then return
  m.p.uri = c.HDPosterUrl
  m.t.text = c.title
  if c.rating <> "" and c.rating <> "0" then
    m.r.text = c.rating
  else
    m.r.text = "-"
  end if
  ranked = false
  rk = c.rank
  if rk <> invalid then
    if rk > 0 then
      ranked = true
      m.rank.text = rk.toStr()
    end if
  end if
  m.rank.visible = ranked
  m.rankBg.visible = ranked
  showProg = false
  pg = c.prog
  if pg <> invalid then
    if pg > 0 then
      showProg = true
      m.progFill.width = 210 * pg
    end if
  end if
  m.progBg.visible = showProg
  m.progFill.visible = showProg
  w = (c.watched = true)
  m.badge.visible = w
  m.badgeT.visible = w
  updateFocus()
end sub

sub updateFocus()
  selected = false
  if m.top.itemHasFocus = true then selected = true
  fp = m.top.focusPercent
  if fp <> invalid then
    if fp > 0.5 then selected = true
  end if
  m.ring.visible = selected
  if selected then
    m.t.color = "0xFFFFFFFF"
  else
    m.t.color = "0xC9C0DCFF"
  end if
end sub
