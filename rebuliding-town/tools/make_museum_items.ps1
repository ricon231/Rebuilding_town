Add-Type -AssemblyName System.Drawing

$outDir = Join-Path (Resolve-Path "assets").Path "items_museum"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-Canvas {
    New-Object Drawing.Bitmap 64, 64, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Save-Item($bitmap, $name) {
    $large = New-Object Drawing.Bitmap 128, 128, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($large)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.DrawImage($bitmap, [Drawing.Rectangle]::new(0, 0, 128, 128))
    $graphics.Dispose()
    $large.Save((Join-Path $outDir "$name.png"), [Drawing.Imaging.ImageFormat]::Png)
    $large.Dispose()
    $bitmap.Dispose()
}

function Pen($color, $width = 2) { New-Object Drawing.Pen $color, $width }
function Brush($color) { New-Object Drawing.SolidBrush $color }

$outline = [Drawing.Color]::FromArgb(30, 27, 27)
$gold = [Drawing.Color]::FromArgb(190, 142, 61)
$ivory = [Drawing.Color]::FromArgb(226, 218, 191)
$red = [Drawing.Color]::FromArgb(166, 42, 49)
$navy = [Drawing.Color]::FromArgb(39, 55, 86)
$wood = [Drawing.Color]::FromArgb(82, 47, 39)
$celadon = [Drawing.Color]::FromArgb(103, 145, 133)

# Phoenix embroidered disc
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillEllipse((Brush $outline), 8, 8, 48, 48); $g.FillEllipse((Brush $gold), 10, 10, 44, 44)
$g.FillEllipse((Brush $red), 13, 13, 38, 38); $g.DrawEllipse((Pen $ivory 2), 16, 16, 32, 32)
$g.DrawArc((Pen $ivory 3), 19, 20, 18, 19, 190, 145); $g.DrawArc((Pen $ivory 3), 28, 20, 18, 19, 205, 145)
$g.FillEllipse((Brush $navy), 24, 30, 5, 5); $g.FillEllipse((Brush $navy), 35, 30, 5, 5)
$g.Dispose(); Save-Item $b "embroidered_phoenix_disc"

# Blue-white phoenix vase
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$p = [Drawing.Point[]]@([Drawing.Point]::new(24,8),[Drawing.Point]::new(40,8),[Drawing.Point]::new(40,16),[Drawing.Point]::new(45,25),[Drawing.Point]::new(43,48),[Drawing.Point]::new(38,56),[Drawing.Point]::new(26,56),[Drawing.Point]::new(21,48),[Drawing.Point]::new(19,25),[Drawing.Point]::new(24,16))
$g.FillPolygon((Brush $outline), $p); $p2 = [Drawing.Point[]]@([Drawing.Point]::new(26,10),[Drawing.Point]::new(38,10),[Drawing.Point]::new(38,18),[Drawing.Point]::new(42,27),[Drawing.Point]::new(40,47),[Drawing.Point]::new(36,53),[Drawing.Point]::new(28,53),[Drawing.Point]::new(24,47),[Drawing.Point]::new(22,27),[Drawing.Point]::new(26,18))
$g.FillPolygon((Brush $ivory), $p2); $g.DrawArc((Pen $navy 2), 24, 23, 18, 15, 185, 170)
$g.DrawArc((Pen $navy 2), 22, 31, 20, 15, 5, 170); $g.DrawLine((Pen $navy 2), 28, 38, 37, 26)
$g.Dispose(); Save-Item $b "blue_white_phoenix_vase"

# Celadon bowl
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillEllipse((Brush $outline), 8, 12, 48, 36); $g.FillEllipse((Brush $celadon), 11, 14, 42, 30)
$g.FillEllipse((Brush ([Drawing.Color]::FromArgb(62,96,91))), 16, 18, 32, 19)
$g.DrawArc((Pen $ivory 1), 18, 20, 28, 18, 10, 160); $g.DrawArc((Pen $ivory 1), 20, 23, 24, 14, 190, 150)
$g.FillRectangle((Brush $outline), 23, 45, 18, 5); $g.FillRectangle((Brush $celadon), 25, 45, 14, 3)
$g.Dispose(); Save-Item $b "celadon_inlaid_bowl"

# Octagonal lacquer brush stand
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$poly = [Drawing.Point[]]@([Drawing.Point]::new(19,10),[Drawing.Point]::new(45,10),[Drawing.Point]::new(53,19),[Drawing.Point]::new(49,54),[Drawing.Point]::new(15,54),[Drawing.Point]::new(11,19))
$g.FillPolygon((Brush $outline), $poly); $poly2 = [Drawing.Point[]]@([Drawing.Point]::new(21,13),[Drawing.Point]::new(43,13),[Drawing.Point]::new(49,20),[Drawing.Point]::new(46,50),[Drawing.Point]::new(18,50),[Drawing.Point]::new(15,20))
$g.FillPolygon((Brush ([Drawing.Color]::FromArgb(55,38,37))), $poly2)
$g.DrawLine((Pen $gold 2), 18, 27, 47, 27); $g.DrawLine((Pen $gold 2), 17, 39, 47, 39)
$g.DrawArc((Pen $gold 2), 22, 29, 12, 10, 180, 180); $g.DrawArc((Pen $gold 2), 31, 29, 12, 10, 180, 180)
$g.Dispose(); Save-Item $b "octagonal_lacquer_brush_stand"

# Carved wooden stationery box
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillRectangle((Brush $outline), 9, 15, 46, 38); $g.FillRectangle((Brush $wood), 12, 18, 40, 32)
$g.DrawRectangle((Pen $gold 2), 16, 21, 32, 24); $g.DrawArc((Pen $gold 2), 20, 24, 20, 15, 200, 140)
$g.DrawLine((Pen $gold 1), 17, 40, 47, 24); $g.DrawLine((Pen $gold 1), 17, 24, 47, 40)
$g.FillEllipse((Brush $gold), 29, 29, 6, 6); $g.Dispose(); Save-Item $b "carved_wood_stationery_box"

# Embroidered flower-bird board
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillRectangle((Brush $outline), 17, 5, 30, 54); $g.FillRectangle((Brush $red), 19, 7, 26, 50)
$g.DrawLine((Pen $gold 2), 31, 10, 31, 53)
foreach ($y in @(14,27,40)) { $g.FillEllipse((Brush $ivory), 22, $y, 8, 8); $g.FillEllipse((Brush $gold), 27, $y+2, 8, 8); $g.DrawLine((Pen $navy 1), 34, $y+5, 41, $y+1) }
$g.Dispose(); Save-Item $b "embroidered_flower_bird_board"

# Embroidered iron rest
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillEllipse((Brush $outline), 10, 18, 34, 25); $g.FillEllipse((Brush ([Drawing.Color]::FromArgb(203,171,125))), 13, 20, 28, 20)
for ($x=17; $x -le 35; $x+=5) { $g.FillRectangle((Brush $ivory), $x, 23, 3, 15) }
$g.DrawLine((Pen $red 2), 43, 29, 55, 13); $g.FillEllipse((Brush $red), 50, 8, 9, 9)
$g.Dispose(); Save-Item $b "embroidered_iron_rest"

# White porcelain sundial
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillRectangle((Brush $outline), 10, 14, 44, 36); $g.FillRectangle((Brush $ivory), 13, 17, 38, 30)
$g.FillEllipse((Brush ([Drawing.Color]::FromArgb(181,172,147))), 24, 22, 16, 16); $g.FillEllipse((Brush $outline), 30, 28, 4, 4)
for ($a=0; $a -lt 8; $a++) { $x=32+[Math]::Cos($a*[Math]::PI/4)*14; $y=32+[Math]::Sin($a*[Math]::PI/4)*12; $g.FillRectangle((Brush $navy), [int]$x, [int]$y, 2, 2) }
$g.Dispose(); Save-Item $b "white_porcelain_sundial"

# Embroidered pouch set
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillPolygon((Brush $outline), [Drawing.Point[]]@([Drawing.Point]::new(10,22),[Drawing.Point]::new(28,16),[Drawing.Point]::new(30,48),[Drawing.Point]::new(13,52)))
$g.FillPolygon((Brush $red), [Drawing.Point[]]@([Drawing.Point]::new(13,23),[Drawing.Point]::new(26,19),[Drawing.Point]::new(27,46),[Drawing.Point]::new(15,49)))
$g.FillPolygon((Brush $outline), [Drawing.Point[]]@([Drawing.Point]::new(35,17),[Drawing.Point]::new(53,22),[Drawing.Point]::new(49,51),[Drawing.Point]::new(33,47)))
$g.FillPolygon((Brush ([Drawing.Color]::FromArgb(121,135,91))), [Drawing.Point[]]@([Drawing.Point]::new(37,20),[Drawing.Point]::new(50,24),[Drawing.Point]::new(47,48),[Drawing.Point]::new(36,45)))
$g.DrawLine((Pen $gold 2), 8, 13, 55, 13); $g.FillEllipse((Brush $gold), 29, 9, 6, 6)
$g.Dispose(); Save-Item $b "embroidered_pouch_set"

function Make-Tassel($name, $thread) {
    $b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
    $g.FillEllipse((Brush $outline), 23, 7, 18, 15); $g.DrawArc((Pen $gold 3), 27, 3, 11, 13, 180, 180)
    $g.FillEllipse((Brush ([Drawing.Color]::FromArgb(84,72,67))), 26, 10, 12, 9)
    $g.FillRectangle((Brush $outline), 24, 21, 16, 5); $g.FillRectangle((Brush $thread), 26, 24, 12, 30)
    for ($x=26; $x -le 38; $x+=3) { $g.DrawLine((Pen $outline 1), $x, 26, $x-1, 56) }
    $g.Dispose(); Save-Item $b $name
}
Make-Tassel "tiger_claw_tassel_pink" ([Drawing.Color]::FromArgb(165,100,103))
Make-Tassel "tiger_claw_tassel_blue" ([Drawing.Color]::FromArgb(62,55,94))

# Dragon round fan
$b = New-Canvas; $g = [Drawing.Graphics]::FromImage($b)
$g.FillEllipse((Brush $outline), 5, 7, 49, 46); $g.FillEllipse((Brush ([Drawing.Color]::FromArgb(119,79,48))), 8, 10, 43, 40)
$g.DrawArc((Pen $gold 2), 14, 15, 29, 24, 20, 280); $g.DrawArc((Pen $outline 2), 19, 18, 21, 17, 170, 230)
$g.FillEllipse((Brush $gold), 26, 24, 6, 5); $g.DrawLine((Pen $outline 2), 30, 28, 42, 20)
$g.DrawLine((Pen $wood 3), 29, 52, 31, 63); $g.DrawLine((Pen $red 2), 12, 43, 5, 57); $g.DrawLine((Pen $red 2), 47, 43, 58, 55)
$g.Dispose(); Save-Item $b "dragon_round_fan"
