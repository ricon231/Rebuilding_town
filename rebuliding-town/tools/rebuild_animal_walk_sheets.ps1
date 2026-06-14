Add-Type -AssemblyName System.Drawing

$assetDirectory = Join-Path $PSScriptRoot "..\assets"
$frameWidth = 320
$frameHeight = 224
$groundY = 209

function Test-ChromaPixel {
	param([System.Drawing.Color]$Color)

	return (
		$Color.R -ge 190 -and
		$Color.B -ge 150 -and
		$Color.G -le 150 -and
		($Color.R - $Color.G) -ge 70
	)
}

function Copy-SourceFrame {
	param(
		[System.Drawing.Bitmap]$Source,
		[int]$Left,
		[int]$Top,
		[int]$Right,
		[int]$Bottom,
		[float]$Scale
	)

	$width = $Right - $Left + 1
	$height = $Bottom - $Top + 1
	$targetWidth = [int][Math]::Round($width * $Scale)
	$targetHeight = [int][Math]::Round($height * $Scale)
	$sourceCrop = [System.Drawing.Bitmap]::new(
		$width,
		$height,
		[System.Drawing.Imaging.PixelFormat]::Format32bppArgb
	)
	$frame = [System.Drawing.Bitmap]::new(
		$frameWidth,
		$frameHeight,
		[System.Drawing.Imaging.PixelFormat]::Format32bppArgb
	)
	$offsetX = [int](($frameWidth - $targetWidth) / 2)
	$offsetY = $groundY - $targetHeight + 1

	for ($sourceY = $Top; $sourceY -le $Bottom; $sourceY++) {
		for ($sourceX = $Left; $sourceX -le $Right; $sourceX++) {
			$color = $Source.GetPixel($sourceX, $sourceY)
			if (-not (Test-ChromaPixel $color)) {
				$sourceCrop.SetPixel($sourceX - $Left, $sourceY - $Top, $color)
			}
		}
	}

	$graphics = [System.Drawing.Graphics]::FromImage($frame)
	try {
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
		$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
		$graphics.DrawImage(
			$sourceCrop,
			[System.Drawing.Rectangle]::new($offsetX, $offsetY, $targetWidth, $targetHeight),
			0,
			0,
			$width,
			$height,
			[System.Drawing.GraphicsUnit]::Pixel
		)
	}
	finally {
		$graphics.Dispose()
		$sourceCrop.Dispose()
	}

	return $frame
}

function Write-WalkSheet {
	param(
		[string]$AnimalName,
		[object[]]$Bounds,
		[float]$Scale
	)

	$sourcePath = Join-Path $assetDirectory ("animal_{0}_source.png" -f $AnimalName)
	$outputPath = Join-Path $assetDirectory ("animal_{0}_walk.png" -f $AnimalName)
	$source = [System.Drawing.Bitmap]::new($sourcePath)
	$sheet = [System.Drawing.Bitmap]::new(
		$frameWidth * 4,
		$frameHeight,
		[System.Drawing.Imaging.PixelFormat]::Format32bppArgb
	)
	$graphics = [System.Drawing.Graphics]::FromImage($sheet)
	$frames = @()

	try {
		$graphics.Clear([System.Drawing.Color]::Transparent)
		for ($index = 0; $index -lt $Bounds.Count; $index++) {
			$bound = $Bounds[$index]
			$frame = Copy-SourceFrame `
				-Source $source `
				-Left $bound[0] `
				-Top $bound[1] `
				-Right $bound[2] `
				-Bottom $bound[3] `
				-Scale $Scale
			$frames += $frame
			$graphics.DrawImageUnscaled($frame, $index * $frameWidth, 0)
		}
		$sheet.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
	}
	finally {
		$graphics.Dispose()
		foreach ($frame in $frames) {
			$frame.Dispose()
		}
		$sheet.Dispose()
		$source.Dispose()
	}
}

Write-WalkSheet -AnimalName "bear" -Scale 0.68 -Bounds @(
	@(21, 338, 290, 524),
	@(322, 334, 569, 525),
	@(608, 333, 853, 524),
	@(892, 334, 1136, 525)
)

Write-WalkSheet -AnimalName "tiger" -Scale 0.84 -Bounds @(
	@(5, 333, 266, 459),
	@(290, 333, 561, 459),
	@(588, 333, 850, 459),
	@(874, 333, 1102, 460)
)
