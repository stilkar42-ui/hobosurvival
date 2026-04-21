Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$IntakeDir = Join-Path $Root "Codex use this"
$SourceDir = Join-Path $Root "assets\game\source\codex_use_this_current"
$OldSourceDir = Join-Path $Root "assets\game\source\hobo_tilesmith_2026_04_19"
$CampTileDir = Join-Path $Root "assets\game\camp\tiles"
$TownTileDir = Join-Path $Root "assets\game\town\tiles"
$TownObjectDir = Join-Path $Root "assets\game\town\objects"
$CharacterDir = Join-Path $Root "assets\game\characters"
$TitleDir = Join-Path $Root "assets\game\title"

$SourceFiles = @{
	"camp_objects.png" = "Camp Assets.png"
	"crafting_indexcard_bg.png" = "crafting indexcard BG.png"
	"hobo_walk_front_back.png" = "Hobo animation2.png"
	"hobo_walk_side.png" = "Hobo animation1.png"
	"base_objects_01.png" = "Hobo base assest1.png"
	"base_objects_02.png" = "Hobo base asset2.png"
	"base_environment.png" = "Hobo base enviroment asset1.png"
	"base_ground_01.png" = "Hobo base enviroment ground asset1.png"
	"base_ground_02.png" = "Hobo base enviroment ground asset2.png"
	"camp_ground.png" = "Hobo camp ground asset1.png"
	"hobo_avatar_sheet.png" = "Hobo character sheet avatar asset1.png"
	"title_buttons.png" = "titel page buttons.png"
	"title_page.png" = "title page.png"
	"town_ground.png" = "Town and Road ground asset1.png"
	"town_objects.png" = "Town assets.png"
}

function Assert-InWorkspace([string]$Path) {
	$resolvedRoot = [System.IO.Path]::GetFullPath($Root.Path)
	$full = [System.IO.Path]::GetFullPath($Path)
	if (-not $full.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw "Refusing to modify path outside workspace: $full"
	}
}

function Reset-Dir([string]$Path) {
	Assert-InWorkspace $Path
	if (Test-Path $Path) {
		Get-ChildItem -LiteralPath $Path -Force | Remove-Item -Recurse -Force
	} else {
		New-Item -ItemType Directory -Force -Path $Path | Out-Null
	}
}

function Remove-DirIfPresent([string]$Path) {
	Assert-InWorkspace $Path
	if (Test-Path $Path) {
		Remove-Item -LiteralPath $Path -Recurse -Force
	}
}

function Rect([int]$X, [int]$Y, [int]$W, [int]$H) {
	return [System.Drawing.Rectangle]::new($X, $Y, $W, $H)
}

function Color-Distance([System.Drawing.Color]$A, [System.Drawing.Color]$B) {
	$dr = [int]$A.R - [int]$B.R
	$dg = [int]$A.G - [int]$B.G
	$db = [int]$A.B - [int]$B.B
	return [Math]::Sqrt(($dr * $dr) + ($dg * $dg) + ($db * $db))
}

function Copy-Crop([System.Drawing.Bitmap]$Sheet, [System.Drawing.Rectangle]$Crop) {
	$out = New-Object System.Drawing.Bitmap $Crop.Width, $Crop.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	for ($y = 0; $y -lt $Crop.Height; $y++) {
		for ($x = 0; $x -lt $Crop.Width; $x++) {
			$sourceX = $Crop.X + $x
			$sourceY = $Crop.Y + $y
			if ($sourceX -lt 0 -or $sourceX -ge $Sheet.Width -or $sourceY -lt 0 -or $sourceY -ge $Sheet.Height) {
				$out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
				continue
			}
			$out.SetPixel($x, $y, $Sheet.GetPixel($sourceX, $sourceY))
		}
	}
	return $out
}

function Remove-EdgeBackground([System.Drawing.Bitmap]$Image, [double]$Threshold) {
	[int]$w = $Image.Width
	[int]$h = $Image.Height
	$out = $Image.Clone([System.Drawing.Rectangle]::new(0, 0, $w, $h), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$seen = New-Object 'bool[,]' $w, $h
	$queue = New-Object System.Collections.Generic.Queue[object]
	for ($x = 0; $x -lt $w; $x++) {
		$queue.Enqueue(@($x, 0))
		$queue.Enqueue(@($x, ($h - 1)))
	}
	for ($y = 0; $y -lt $h; $y++) {
		$queue.Enqueue(@(0, $y))
		$queue.Enqueue(@(($w - 1), $y))
	}
	while ($queue.Count -gt 0) {
		$point = $queue.Dequeue()
		$x = [int]$point[0]
		$y = [int]$point[1]
		if ($x -lt 0 -or $x -ge $w -or $y -lt 0 -or $y -ge $h -or $seen[$x, $y]) {
			continue
		}
		$seen[$x, $y] = $true
		$current = $out.GetPixel($x, $y)
		$out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
		foreach ($n in @(@(($x + 1), $y), @(($x - 1), $y), @($x, ($y + 1)), @($x, ($y - 1)))) {
			$nx = [int]$n[0]
			$ny = [int]$n[1]
			if ($nx -lt 0 -or $nx -ge $w -or $ny -lt 0 -or $ny -ge $h -or $seen[$nx, $ny]) {
				continue
			}
			$neighbor = $out.GetPixel($nx, $ny)
			if ($neighbor.A -lt 250 -or (Color-Distance $current $neighbor) -le $Threshold) {
				$queue.Enqueue(@($nx, $ny))
			}
		}
	}
	return $out
}

function Trim-Alpha([System.Drawing.Bitmap]$Image, [int]$Pad) {
	$minX = $Image.Width
	$minY = $Image.Height
	$maxX = -1
	$maxY = -1
	for ($y = 0; $y -lt $Image.Height; $y++) {
		for ($x = 0; $x -lt $Image.Width; $x++) {
			if ($Image.GetPixel($x, $y).A -gt 12) {
				$minX = [Math]::Min($minX, $x)
				$minY = [Math]::Min($minY, $y)
				$maxX = [Math]::Max($maxX, $x)
				$maxY = [Math]::Max($maxY, $y)
			}
		}
	}
	if ($maxX -lt $minX -or $maxY -lt $minY) {
		return $Image.Clone()
	}
	$minX = [Math]::Max(0, $minX - $Pad)
	$minY = [Math]::Max(0, $minY - $Pad)
	$maxX = [Math]::Min($Image.Width - 1, $maxX + $Pad)
	$maxY = [Math]::Min($Image.Height - 1, $maxY + $Pad)
	$crop = Rect $minX $minY ($maxX - $minX + 1) ($maxY - $minY + 1)
	return $Image.Clone($crop, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Save-Png([System.Drawing.Bitmap]$Image, [string]$Path) {
	Assert-InWorkspace $Path
	New-Item -ItemType Directory -Force -Path (Split-Path $Path -Parent) | Out-Null
	$Image.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Export-GroundTile([System.Drawing.Bitmap]$Sheet, [System.Drawing.Rectangle]$Crop, [string]$Path, [string]$EarthHex) {
	$source = Copy-Crop $Sheet $Crop
	$keyed = Remove-EdgeBackground $source 36
	$trimmed = Trim-Alpha $keyed 8
	$out = New-Object System.Drawing.Bitmap 32, 32, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$graphics = [System.Drawing.Graphics]::FromImage($out)
	$graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
	$graphics.DrawImage($trimmed, [System.Drawing.Rectangle]::new(0, 6, 32, 20))
	$graphics.Dispose()

	$earth = [System.Drawing.ColorTranslator]::FromHtml("#$EarthHex")
	for ($y = 0; $y -lt 32; $y++) {
		for ($x = 0; $x -lt 32; $x++) {
			$diamond = ([Math]::Abs(($x + 0.5) - 16.0) / 16.0) + ([Math]::Abs(($y + 0.5) - 16.0) / 8.0)
			$pixel = $out.GetPixel($x, $y)
			if ($diamond -gt 1.0) {
				$out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
			} elseif ($pixel.A -lt 8) {
				$out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $earth.R, $earth.G, $earth.B))
			} elseif ($diamond -gt 0.82) {
				$blend = 0.60
				$r = [int]($pixel.R * (1.0 - $blend) + $earth.R * $blend)
				$g = [int]($pixel.G * (1.0 - $blend) + $earth.G * $blend)
				$b = [int]($pixel.B * (1.0 - $blend) + $earth.B * $blend)
				$out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, $r, $g, $b))
			}
		}
	}

	Save-Png $out $Path
	$source.Dispose()
	$keyed.Dispose()
	$trimmed.Dispose()
	$out.Dispose()
}

function Export-Object([System.Drawing.Bitmap]$Sheet, [System.Drawing.Rectangle]$Crop, [string]$Path, [int]$Pad) {
	$source = Copy-Crop $Sheet $Crop
	$keyed = Remove-EdgeBackground $source 22
	$trimmed = Trim-Alpha $keyed $Pad
	Save-Png $trimmed $Path
	$source.Dispose()
	$keyed.Dispose()
	$trimmed.Dispose()
}

function Export-Frame([System.Drawing.Bitmap]$Sheet, [System.Drawing.Rectangle]$Crop, [string]$Path) {
	$source = Copy-Crop $Sheet $Crop
	$keyed = Remove-EdgeBackground $source 4
	$trimmed = Trim-Alpha $keyed 4
	$out = New-Object System.Drawing.Bitmap 96, 128, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$graphics = [System.Drawing.Graphics]::FromImage($out)
	$graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$scale = [Math]::Min(72.0 / $trimmed.Width, 116.0 / $trimmed.Height)
	$drawW = [int]($trimmed.Width * $scale)
	$drawH = [int]($trimmed.Height * $scale)
	$drawX = [int]((96 - $drawW) / 2)
	$drawY = 124 - $drawH
	$graphics.DrawImage($trimmed, [System.Drawing.Rectangle]::new($drawX, $drawY, $drawW, $drawH))
	$graphics.Dispose()
	Save-Png $out $Path
	$source.Dispose()
	$keyed.Dispose()
	$trimmed.Dispose()
	$out.Dispose()
}

function Export-TitleAsset([System.Drawing.Bitmap]$Sheet, [System.Drawing.Rectangle]$Crop, [string]$Path, [bool]$KeyBackground) {
	$source = Copy-Crop $Sheet $Crop
	if ($KeyBackground) {
		$keyed = Remove-EdgeBackground $source 22
		$trimmed = Trim-Alpha $keyed 4
		Save-Png $trimmed $Path
		$keyed.Dispose()
		$trimmed.Dispose()
	} else {
		Save-Png $source $Path
	}
	$source.Dispose()
}

if (-not (Test-Path $IntakeDir)) {
	throw "Missing intake folder: $IntakeDir"
}

Reset-Dir $SourceDir
foreach ($name in $SourceFiles.Keys) {
	$source = Join-Path $IntakeDir $SourceFiles[$name]
	if (-not (Test-Path $source)) {
		throw "Missing source sheet: $source"
	}
	Copy-Item -LiteralPath $source -Destination (Join-Path $SourceDir $name) -Force
}
Remove-DirIfPresent $OldSourceDir

Reset-Dir $CampTileDir
Reset-Dir $TownTileDir
Reset-Dir $TownObjectDir
Reset-Dir $CharacterDir
Reset-Dir $TitleDir

$campGround = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "camp_ground.png"))
$baseGround = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "base_ground_01.png"))
$campObject = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "camp_objects.png"))
$baseObject = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "base_objects_01.png"))
$baseObject2 = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "base_objects_02.png"))
$baseEnvironment = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "base_environment.png"))
$townObject = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "town_objects.png"))
$townGround = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "town_ground.png"))
$hoboFrontBack = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "hobo_walk_front_back.png"))
$hoboSide = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "hobo_walk_side.png"))
$titlePage = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "title_page.png"))
$titleButtons = [System.Drawing.Bitmap]::FromFile((Join-Path $SourceDir "title_buttons.png"))

$campGroundSpecs = @(
	@("dirt.png", 0, 0, "5a4a36"), @("dirt_alt.png", 1, 0, "544737"), @("camp.png", 2, 0, "5b513b"), @("grass_edge.png", 3, 0, "4e5631"),
	@("path.png", 0, 1, "5d4c39"), @("mud.png", 1, 1, "403b31"), @("ash.png", 2, 1, "363535"), @("campfire_scorch.png", 3, 1, "302920"),
	@("gravel.png", 0, 2, "5c5546"), @("cinder.png", 1, 2, "383632"), @("grass.png", 2, 2, "4b552d"), @("ash_edge.png", 3, 2, "3c3a32"),
	@("stone_dirt.png", 0, 3, "555044"), @("weed_dirt.png", 1, 3, "4d5032"), @("water.png", 2, 3, "3e4640"), @("coal_dirt.png", 3, 3, "302c27"),
	@("path_light.png", 0, 4, "62533d"), @("gravel_edge.png", 1, 4, "5d5746"), @("mud_puddle.png", 2, 4, "383f3c"), @("coal_edge.png", 3, 4, "332f2a")
)
foreach ($spec in $campGroundSpecs) {
	$crop = Rect (24 + ($spec[1] * 242)) (52 + ($spec[2] * 188)) 210 118
	Export-GroundTile $campGround $crop (Join-Path $CampTileDir $spec[0]) $spec[3]
}

$sharedGroundSpecs = @(
	@("forest.png", 0, 0, "40492b"), @("forest_alt.png", 1, 0, "3d452a"), @("grass_alt.png", 2, 0, "4b552e")
)
foreach ($spec in $sharedGroundSpecs) {
	$crop = Rect (40 + ($spec[1] * 248)) 50 215 120
	Export-GroundTile $baseGround $crop (Join-Path $CampTileDir $spec[0]) $spec[3]
}

$campObjects = @(
	@("tarp_shelter.png", $campObject, 0, 0, 255, 170), @("dirt_mound.png", $campObject, 1, 0, 210, 120), @("campfire_embers.png", $campObject, 2, 0, 190, 130), @("campfire.png", $campObject, 3, 0, 190, 150),
	@("campfire_coals.png", $campObject, 0, 1, 190, 130), @("coffee_setup.png", $campObject, 1, 1, 190, 145), @("bedroll.png", $campObject, 2, 1, 210, 130), @("rolled_bedroll.png", $campObject, 3, 1, 190, 130),
	@("crate.png", $campObject, 0, 2, 180, 140), @("sack.png", $campObject, 1, 2, 165, 135), @("woodpile.png", $campObject, 2, 2, 180, 135), @("rock_pile.png", $campObject, 3, 2, 190, 120),
	@("wash_line.png", $campObject, 0, 3, 235, 150), @("tin_bucket.png", $campObject, 1, 3, 155, 125), @("tool_area.png", $campObject, 2, 3, 175, 135), @("cook_stones.png", $campObject, 3, 3, 190, 125),
	@("small_fire.png", $baseObject, 4, 3, 190, 125), @("lantern.png", $baseObject, 2, 4, 140, 140), @("stove.png", $baseObject2, 0, 0, 230, 210)
)
foreach ($spec in $campObjects) {
	$crop = Rect (24 + ($spec[2] * 246)) (38 + ($spec[3] * 202)) $spec[4] $spec[5]
	Export-Object $spec[1] $crop (Join-Path $CampTileDir $spec[0]) 6
}

$foliageObjects = @(
	@("brush_clump.png", 0, 0, 230, 120), @("brush_clump_alt.png", 1, 0, 230, 120), @("stump.png", 4, 0, 220, 130),
	@("dead_tree.png", 0, 2, 235, 210), @("small_tree.png", 1, 2, 235, 210), @("leafy_tree.png", 2, 2, 250, 220), @("snag_tree.png", 3, 2, 235, 215),
	@("dead_tree_alt.png", 0, 3, 235, 215), @("tree_pair.png", 1, 3, 255, 215), @("dead_tree_thin.png", 2, 3, 235, 215), @("stump_pair.png", 4, 3, 230, 170)
)
foreach ($spec in $foliageObjects) {
	$crop = Rect (44 + ($spec[1] * 278)) (56 + ($spec[2] * 190)) $spec[3] $spec[4]
	Export-Object $baseEnvironment $crop (Join-Path $CampTileDir $spec[0]) 6
}

$townGroundSpecs = @(
	@("dirt.png", 0, 0, "5c5547"), @("dirt_alt.png", 1, 0, "5c5445"), @("path.png", 2, 0, "625b4c"), @("mud.png", 3, 0, "514b3f"), @("gravel.png", 4, 0, "555552"), @("camp.png", 5, 0, "5d5545"),
	@("yard.png", 0, 1, "5e5748"), @("yard_alt.png", 1, 1, "5b5548"), @("ash.png", 3, 1, "454547"), @("cinder.png", 4, 1, "3c3d3f"), @("stone_dust.png", 5, 1, "5d5d59"),
	@("grass.png", 0, 2, "4b5135"), @("grass_alt.png", 1, 2, "4e5136"), @("gravel_edge.png", 3, 2, "51514d"), @("coal.png", 4, 2, "36373a"), @("packed_dirt.png", 5, 2, "585044"),
	@("forest.png", 0, 3, "464b32"), @("forest_alt.png", 1, 3, "444832"), @("ash_edge.png", 3, 3, "42423e"), @("plank_path.png", 1, 5, "6b6048"), @("plank_alt.png", 2, 5, "6b6048"),
	@("water.png", 2, 3, "464c4b")
)
foreach ($spec in $townGroundSpecs) {
	$crop = Rect (22 + ($spec[1] * 250)) (32 + ($spec[2] * 160)) 220 118
	Export-GroundTile $townGround $crop (Join-Path $TownTileDir $spec[0]) $spec[3]
}

$townObjects = @(
	@("jobs_board.png", $townObject, 1090, 790, 190, 160),
	@("hardware_store.png", $townObject, 540, 55, 520, 310),
	@("remittance_office.png", $townObject, 1060, 70, 440, 305),
	@("dirt_patch_01.png", $townObject, 35, 405, 240, 120),
	@("gravel_patch_01.png", $townObject, 570, 410, 310, 125),
	@("cinder_patch_01.png", $townObject, 560, 540, 310, 125),
	@("crate_stack.png", $townObject, 25, 680, 570, 140),
	@("wheelbarrow.png", $townObject, 330, 850, 260, 130),
	@("depot_building.png", $townObject, 885, 405, 500, 310),
	@("street_lamp.png", $townObject, 1390, 380, 110, 290),
	@("board_stack.png", $townObject, 1160, 840, 260, 120),
	@("handcart.png", $townObject, 620, 690, 250, 130),
	@("lantern_group.png", $townObject, 610, 835, 420, 130),
	@("camp_road_sign.png", $townObject, 1085, 785, 200, 170),
	@("trash_barrel.png", $townObject, 1360, 850, 150, 105)
)
foreach ($spec in $townObjects) {
	$crop = Rect $spec[2] $spec[3] $spec[4] $spec[5]
	Export-Object $spec[1] $crop (Join-Path $TownObjectDir $spec[0]) 8
}

for ($i = 0; $i -lt 5; $i++) {
	Export-Frame $hoboFrontBack (Rect (24 + ($i * 300)) 34 255 330) (Join-Path $CharacterDir ("hobo_front_{0:00}.png" -f ($i + 1)))
	Export-Frame $hoboFrontBack (Rect (24 + ($i * 300)) 500 255 360) (Join-Path $CharacterDir ("hobo_back_{0:00}.png" -f ($i + 1)))
}
for ($i = 0; $i -lt 5; $i++) {
	Export-Frame $hoboSide (Rect (24 + ($i * 300)) 34 255 330) (Join-Path $CharacterDir ("hobo_side_{0:00}.png" -f ($i + 1)))
	Export-Frame $hoboSide (Rect (24 + ($i * 300)) 508 255 350) (Join-Path $CharacterDir ("hobo_side_alt_{0:00}.png" -f ($i + 1)))
}

Export-TitleAsset $titlePage (Rect 0 0 $titlePage.Width $titlePage.Height) (Join-Path $TitleDir "title_page.png") $false
$buttonColumns = @("normal", "hover", "pressed")
$buttonRows = @(
	@("start", 0),
	@("quit", 1),
	@("settings", 2),
	@("debug", 3),
	@("load", 4)
)
foreach ($columnIndex in 0..2) {
	foreach ($row in $buttonRows) {
		$crop = Rect (82 + ($columnIndex * 466)) (124 + ($row[1] * 145)) 380 88
		Export-TitleAsset $titleButtons $crop (Join-Path $TitleDir ("{0}_{1}.png" -f $row[0], $buttonColumns[$columnIndex])) $true
	}
}

foreach ($bitmap in @($campGround, $baseGround, $campObject, $baseObject, $baseObject2, $baseEnvironment, $townObject, $townGround, $hoboFrontBack, $hoboSide, $titlePage, $titleButtons)) {
	$bitmap.Dispose()
}

Write-Host "Imported Codex-use-this source sheets and rebuilt runtime assets."
Write-Host "Intake: $IntakeDir"
Write-Host "Source: $SourceDir"
Write-Host "Camp runtime: $CampTileDir"
Write-Host "Town ground: $TownTileDir"
Write-Host "Town objects: $TownObjectDir"
Write-Host "Characters: $CharacterDir"
Write-Host "Title: $TitleDir"
