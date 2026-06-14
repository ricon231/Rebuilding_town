Add-Type -AssemblyName System.Drawing

$outDir = Join-Path (Resolve-Path "assets").Path "items_museum"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Brush([string]$hex) {
    New-Object Drawing.SolidBrush ([Drawing.ColorTranslator]::FromHtml($hex))
}

function Pen([string]$hex, [float]$width = 1) {
    New-Object Drawing.Pen ([Drawing.ColorTranslator]::FromHtml($hex)), $width
}

function New-Canvas {
    $bitmap = New-Object Drawing.Bitmap 128, 128, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::None
    return @($bitmap, $graphics)
}

function Save-Canvas($bitmap, $graphics, [string]$name) {
    $graphics.Dispose()
    $bitmap.Save((Join-Path $outDir "$name.png"), [Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

# Left painting: red sun, pine tree, and a pair of phoenix-like birds.
$canvas = New-Canvas
$b = $canvas[0]
$g = $canvas[1]
$shadow = Brush "#171619"
$frameDark = Brush "#5A3026"
$frame = Brush "#A85B3D"
$frameLight = Brush "#D68A5D"
$mat = Brush "#E8E2D2"
$paper = Brush "#CDBF9F"
$paperLight = Brush "#DFD1AD"
$ink = Brush "#343533"
$pine = Brush "#31554D"
$pineLight = Brush "#4A6C5D"
$red = Brush "#B73338"
$redDark = Brush "#76272C"
$birdCream = Brush "#C7B791"
$birdBrown = Brush "#735244"
$birdBlue = Brush "#384A68"
$gold = Brush "#C29251"
$outlinePen = Pen "#211D1C" 2
$branchPen = Pen "#5E3D31" 4
$twigPen = Pen "#5E3D31" 2

$g.FillRectangle($shadow, 22, 5, 62, 118)
$g.FillRectangle($frameDark, 18, 2, 62, 118)
$g.FillRectangle($frame, 21, 5, 56, 112)
$g.FillRectangle($frameLight, 24, 8, 50, 106)
$g.FillRectangle($mat, 28, 12, 42, 98)
$g.FillRectangle($paper, 32, 17, 34, 88)
$g.FillRectangle($paperLight, 35, 20, 28, 82)

# Sun and clouds.
$g.FillEllipse($redDark, 43, 22, 17, 17)
$g.FillEllipse($red, 45, 22, 15, 15)
$g.FillRectangle($birdBlue, 39, 35, 22, 4)
$g.FillRectangle($birdBlue, 44, 32, 13, 7)
$g.FillRectangle($redDark, 34, 28, 8, 3)
$g.FillRectangle($red, 58, 29, 7, 3)

# Pine trunk and branches.
$g.DrawLine($branchPen, 59, 38, 55, 94)
$g.DrawLine($branchPen, 55, 60, 42, 54)
$g.DrawLine($twigPen, 44, 55, 37, 43)
$g.DrawLine($twigPen, 56, 48, 48, 40)
$g.DrawLine($twigPen, 56, 66, 65, 57)
$g.DrawLine($twigPen, 56, 78, 45, 70)

foreach ($cluster in @(
    @(35, 40), @(43, 38), @(49, 42), @(34, 49), @(43, 51),
    @(59, 52), @(64, 57), @(45, 67), @(38, 70), @(48, 73),
    @(57, 78), @(62, 84), @(48, 88)
)) {
    $x = $cluster[0]
    $y = $cluster[1]
    $g.FillEllipse($pine, $x - 4, $y - 3, 8, 6)
    $g.FillRectangle($pineLight, $x - 1, $y - 2, 4, 3)
}

# Two birds with distinct crests, wings, and tails.
$g.FillEllipse($outlinePen.Brush, 34, 70, 15, 12)
$g.FillEllipse($birdCream, 36, 71, 11, 9)
$g.FillEllipse($birdBrown, 43, 66, 7, 7)
$g.FillRectangle($red, 46, 62, 3, 6)
$g.FillRectangle($gold, 49, 68, 5, 2)
$g.DrawArc($outlinePen, 34, 68, 15, 14, 175, 160)
$g.FillPolygon($birdBlue, [Drawing.Point[]]@(
    [Drawing.Point]::new(37, 77),
    [Drawing.Point]::new(28, 82),
    [Drawing.Point]::new(39, 82)
))
$g.FillPolygon($redDark, [Drawing.Point[]]@(
    [Drawing.Point]::new(39, 80),
    [Drawing.Point]::new(31, 91),
    [Drawing.Point]::new(43, 83)
))

$g.FillEllipse($outlinePen.Brush, 47, 76, 15, 12)
$g.FillEllipse($birdCream, 49, 77, 11, 9)
$g.FillEllipse($birdBrown, 57, 71, 7, 7)
$g.FillRectangle($red, 59, 67, 3, 6)
$g.FillRectangle($gold, 63, 73, 4, 2)
$g.FillPolygon($birdBlue, [Drawing.Point[]]@(
    [Drawing.Point]::new(51, 83),
    [Drawing.Point]::new(43, 91),
    [Drawing.Point]::new(55, 87)
))
$g.FillPolygon($redDark, [Drawing.Point[]]@(
    [Drawing.Point]::new(54, 86),
    [Drawing.Point]::new(48, 98),
    [Drawing.Point]::new(60, 88)
))

# Bamboo leaves near the bottom.
$leafPen = Pen "#263F3A" 2
$g.DrawLine($leafPen, 37, 91, 57, 101)
$g.DrawLine($leafPen, 42, 94, 35, 99)
$g.DrawLine($leafPen, 47, 96, 42, 103)
$g.DrawLine($leafPen, 52, 98, 58, 104)

Save-Canvas $b $g "painting_sun_pine_phoenix_pair"

foreach ($resource in @(
    $shadow, $frameDark, $frame, $frameLight, $mat, $paper, $paperLight,
    $ink, $pine, $pineLight, $red, $redDark, $birdCream, $birdBrown,
    $birdBlue, $gold, $outlinePen, $branchPen, $twigPen, $leafPen
)) {
    $resource.Dispose()
}

# Right painting: folk talisman with two black birds, red flames, and calligraphy.
$canvas = New-Canvas
$b = $canvas[0]
$g = $canvas[1]
$shadow = Brush "#171619"
$frameDark = Brush "#583126"
$frame = Brush "#A85B3D"
$frameLight = Brush "#D68A5D"
$mat = Brush "#DDD9CC"
$paper = Brush "#D7D2C2"
$paperLight = Brush "#E7E1D2"
$ink = Brush "#303439"
$inkLight = Brush "#596067"
$red = Brush "#B74C45"
$redDark = Brush "#78332F"
$blue = Brush "#3A515E"
$seal = Brush "#9F3B37"
$inkPen = Pen "#303439" 2
$fineInk = Pen "#596067" 1
$redPen = Pen "#B74C45" 2

$g.FillRectangle($shadow, 39, 5, 70, 118)
$g.FillRectangle($frameDark, 35, 2, 70, 118)
$g.FillRectangle($frame, 38, 5, 64, 112)
$g.FillRectangle($frameLight, 41, 8, 58, 106)
$g.FillRectangle($mat, 45, 12, 50, 98)
$g.FillRectangle($paper, 49, 17, 42, 88)
$g.FillRectangle($paperLight, 52, 20, 36, 82)

# Rough paper fibers.
foreach ($line in @(
    @(54, 27, 82, 27), @(56, 39, 86, 39), @(53, 54, 84, 54),
    @(57, 69, 86, 69), @(54, 87, 83, 87)
)) {
    $g.DrawLine($fineInk, $line[0], $line[1], $line[2], $line[3])
}

# Red flame/cloud crest.
$g.DrawArc($redPen, 57, 25, 13, 17, 115, 220)
$g.DrawArc($redPen, 67, 22, 15, 18, 110, 230)
$g.DrawArc($redPen, 76, 26, 10, 15, 170, 190)
$g.FillRectangle($redDark, 66, 31, 13, 3)

# Upper guardian face.
$g.FillRectangle($ink, 65, 29, 14, 11)
$g.FillRectangle($blue, 68, 26, 8, 5)
$g.FillRectangle($paperLight, 68, 32, 3, 2)
$g.FillRectangle($paperLight, 74, 32, 3, 2)
$g.FillRectangle($red, 71, 36, 4, 2)

# Two large birds and striped wings.
foreach ($offset in @(0, 17)) {
    $x = 56 + $offset
    $g.FillEllipse($ink, $x, 55, 12, 23)
    $g.FillEllipse($blue, $x + 2, 57, 8, 17)
    $g.DrawArc($inkPen, $x - 5, 42, 19, 23, 190, 145)
    $g.DrawLine($inkPen, $x + 1, 49, $x + 6, 58)
    $g.DrawLine($fineInk, $x - 3, 49, $x + 1, 49)
    $g.DrawLine($fineInk, $x - 4, 53, $x + 1, 53)
    $g.DrawLine($fineInk, $x - 4, 57, $x + 1, 57)
    $g.DrawLine($inkPen, $x + 3, 77, $x + 1, 88)
    $g.DrawLine($inkPen, $x + 8, 77, $x + 10, 88)
    $g.FillRectangle($ink, $x - 1, 87, 5, 3)
    $g.FillRectangle($ink, $x + 8, 87, 5, 3)
}

# Side spirals and red ritual strokes.
$g.DrawArc($redPen, 52, 41, 9, 15, 90, 220)
$g.DrawArc($redPen, 82, 42, 8, 15, 220, 210)
$g.DrawArc($redPen, 51, 67, 8, 13, 100, 220)
$g.DrawArc($redPen, 83, 67, 7, 13, 210, 220)

# Calligraphy columns and bottom notes.
foreach ($y in @(25, 31, 37, 43, 49, 55, 61, 67)) {
    $g.FillRectangle($ink, 52, $y, 2, 4)
    $g.FillRectangle($ink, 86, $y + 1, 2, 4)
}
foreach ($x in @(55, 61, 67, 73, 79, 85)) {
    $g.FillRectangle($inkLight, $x, 94, 2, 5)
}
$g.FillRectangle($seal, 52, 94, 4, 5)
$g.FillRectangle($seal, 57, 98, 4, 4)

Save-Canvas $b $g "painting_twin_bird_talisman"

foreach ($resource in @(
    $shadow, $frameDark, $frame, $frameLight, $mat, $paper, $paperLight,
    $ink, $inkLight, $red, $redDark, $blue, $seal, $inkPen, $fineInk, $redPen
)) {
    $resource.Dispose()
}
