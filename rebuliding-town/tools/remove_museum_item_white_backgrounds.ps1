Add-Type -AssemblyName System.Drawing

$assetDirectory = Join-Path $PSScriptRoot "..\assets\items_museum"
$targetFiles = @(
	"embroidered_phoenix_pillow_end_256.png",
	"blue_white_phoenix_vase_item_256.png",
	"painting_sun_pine_phoenix_pair_256.png"
)

function Test-BackgroundPixel {
	param([System.Drawing.Color]$Color)

	$minimum = [Math]::Min($Color.R, [Math]::Min($Color.G, $Color.B))
	$maximum = [Math]::Max($Color.R, [Math]::Max($Color.G, $Color.B))
	return $Color.A -gt 0 -and $minimum -ge 190 -and ($maximum - $minimum) -le 42
}

foreach ($fileName in $targetFiles) {
	$path = Join-Path $assetDirectory $fileName
	$source = [System.Drawing.Bitmap]::new($path)
	$result = [System.Drawing.Bitmap]::new(
		$source.Width,
		$source.Height,
		[System.Drawing.Imaging.PixelFormat]::Format32bppArgb
	)
	$graphics = [System.Drawing.Graphics]::FromImage($result)

	try {
		$graphics.DrawImageUnscaled($source, 0, 0)

		$left = $source.Width
		$top = $source.Height
		$right = -1
		$bottom = -1
		for ($y = 0; $y -lt $source.Height; $y++) {
			for ($x = 0; $x -lt $source.Width; $x++) {
				if ($source.GetPixel($x, $y).A -gt 0) {
					$left = [Math]::Min($left, $x)
					$top = [Math]::Min($top, $y)
					$right = [Math]::Max($right, $x)
					$bottom = [Math]::Max($bottom, $y)
				}
			}
		}

		$visited = New-Object 'bool[,]' $source.Width, $source.Height
		$queue = [System.Collections.Generic.Queue[System.Drawing.Point]]::new()

		for ($x = $left; $x -le $right; $x++) {
			$queue.Enqueue([System.Drawing.Point]::new($x, $top))
			$queue.Enqueue([System.Drawing.Point]::new($x, $bottom))
		}
		for ($y = $top; $y -le $bottom; $y++) {
			$queue.Enqueue([System.Drawing.Point]::new($left, $y))
			$queue.Enqueue([System.Drawing.Point]::new($right, $y))
		}

		while ($queue.Count -gt 0) {
			$point = $queue.Dequeue()
			$x = $point.X
			$y = $point.Y
			if ($x -lt $left -or $x -gt $right -or $y -lt $top -or $y -gt $bottom) {
				continue
			}
			if ($visited[$x, $y]) {
				continue
			}
			$visited[$x, $y] = $true

			$color = $source.GetPixel($x, $y)
			if (-not (Test-BackgroundPixel $color)) {
				continue
			}

			$distanceFromWhite = [Math]::Max(
				255 - $color.R,
				[Math]::Max(255 - $color.G, 255 - $color.B)
			)
			$alpha = [Math]::Min([int]$color.A, [Math]::Max(0, [int]$distanceFromWhite * 4))
			if ($alpha -eq 0) {
				$result.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
			}
			else {
				$result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $color.R, $color.G, $color.B))
			}

			$queue.Enqueue([System.Drawing.Point]::new($x - 1, $y))
			$queue.Enqueue([System.Drawing.Point]::new($x + 1, $y))
			$queue.Enqueue([System.Drawing.Point]::new($x, $y - 1))
			$queue.Enqueue([System.Drawing.Point]::new($x, $y + 1))
		}

		for ($y = 0; $y -lt $result.Height; $y++) {
			for ($x = 0; $x -lt $result.Width; $x++) {
				if ($result.GetPixel($x, $y).A -eq 0) {
					$result.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
				}
			}
		}

		$source.Dispose()
		$source = $null
		$result.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
	}
	finally {
		$graphics.Dispose()
		if ($null -ne $source) {
			$source.Dispose()
		}
		$result.Dispose()
	}
}
