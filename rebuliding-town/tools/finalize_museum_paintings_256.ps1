param(
    [Parameter(Mandatory = $true)][string]$LeftSource,
    [Parameter(Mandatory = $true)][string]$RightSource,
    [string]$LeftOutput = "painting_sun_pine_phoenix_pair_256.png",
    [string]$RightOutput = "painting_twin_bird_talisman_256.png"
)

Add-Type -AssemblyName System.Drawing

$outputDirectory = Join-Path (Resolve-Path "assets").Path "items_museum"
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

function Test-BackgroundPixel([Drawing.Color]$color) {
    $maximum = [Math]::Max($color.R, [Math]::Max($color.G, $color.B))
    $minimum = [Math]::Min($color.R, [Math]::Min($color.G, $color.B))
    return $minimum -ge 165 -and ($maximum - $minimum) -le 52
}

function Convert-Painting([string]$sourcePath, [string]$outputName) {
    $source = New-Object Drawing.Bitmap $sourcePath
    $width = $source.Width
    $height = $source.Height
    $visited = New-Object 'bool[]' ($width * $height)
    $queue = New-Object 'System.Collections.Generic.Queue[int]'

    for ($x = 0; $x -lt $width; $x++) {
        $queue.Enqueue($x)
        $queue.Enqueue((($height - 1) * $width) + $x)
    }
    for ($y = 1; $y -lt ($height - 1); $y++) {
        $queue.Enqueue($y * $width)
        $queue.Enqueue(($y * $width) + $width - 1)
    }

    while ($queue.Count -gt 0) {
        $index = $queue.Dequeue()
        if ($visited[$index]) {
            continue
        }
        $visited[$index] = $true
        $x = $index % $width
        $y = [Math]::Floor($index / $width)
        $color = $source.GetPixel($x, $y)
        if (-not (Test-BackgroundPixel $color)) {
            continue
        }

        $source.SetPixel($x, $y, [Drawing.Color]::Transparent)
        if ($x -gt 0) { $queue.Enqueue($index - 1) }
        if ($x -lt ($width - 1)) { $queue.Enqueue($index + 1) }
        if ($y -gt 0) { $queue.Enqueue($index - $width) }
        if ($y -lt ($height - 1)) { $queue.Enqueue($index + $width) }
    }

    $left = $width
    $top = $height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            if ($source.GetPixel($x, $y).A -gt 8) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }

    $contentWidth = $right - $left + 1
    $contentHeight = $bottom - $top + 1
    $scale = [Math]::Min(236.0 / $contentWidth, 236.0 / $contentHeight)
    $drawWidth = [Math]::Max(1, [int][Math]::Round($contentWidth * $scale))
    $drawHeight = [Math]::Max(1, [int][Math]::Round($contentHeight * $scale))
    $destinationX = [int][Math]::Floor((256 - $drawWidth) / 2)
    $destinationY = [int][Math]::Floor((256 - $drawHeight) / 2)

    $result = New-Object Drawing.Bitmap 256, 256, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($result)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.DrawImage(
        $source,
        (New-Object Drawing.Rectangle $destinationX, $destinationY, $drawWidth, $drawHeight),
        (New-Object Drawing.Rectangle $left, $top, $contentWidth, $contentHeight),
        [Drawing.GraphicsUnit]::Pixel
    )

    $outputPath = Join-Path $outputDirectory $outputName
    $result.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $result.Dispose()
    $source.Dispose()
}

Convert-Painting $LeftSource $LeftOutput
Convert-Painting $RightSource $RightOutput
