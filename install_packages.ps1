# Step 1: Write pubspec.yaml with 'any' to let pub resolve latest versions
$dependencies = @("cupertino_icons", "get_it", "go_router", "toastification", "envied", "dio", "logger", "mobx", "flutter_mobx", "reactive_forms", "flutter_secure_storage", "freezed_annotation", "json_annotation")
$devDependencies = @("flutter_lints", "build_runner", "envied_generator", "json_serializable", "mobx_codegen", "freezed")

$pubspecAny = @'
name: templated_flutter
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.7.2

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: any
  get_it: any
  go_router: any
  toastification: any
  envied: any
  dio: any
  logger: any
  mobx: any
  flutter_mobx: any
  reactive_forms: any
  flutter_secure_storage: any
  freezed_annotation: any
  json_annotation: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: any
  build_runner: any
  envied_generator: any
  json_serializable: any
  mobx_codegen: any
  freezed: any

flutter:
  uses-material-design: true
'@

Set-Content -Path "pubspec.yaml" -Value $pubspecAny -Encoding utf8
Write-Host "Resolving latest versions..." -ForegroundColor Cyan
flutter pub get

if (-not $?) {
    Write-Host "flutter pub get failed." -ForegroundColor Red
    exit 1
}

# Step 2: Parse pubspec.lock to get resolved versions
$lockContent = Get-Content "pubspec.lock" -Raw
$resolvedVersions = @{}

foreach ($pkg in ($dependencies + $devDependencies)) {
    if ($lockContent -match "(?ms)^\s{2}${pkg}:\s*\n.*?version: `"([^`"]+)`"") {
        $resolvedVersions[$pkg] = $Matches[1]
    }
}

# Step 3: Rewrite pubspec.yaml with resolved versions
$depLines = ($dependencies | ForEach-Object {
    $ver = if ($resolvedVersions.ContainsKey($_)) { "^$($resolvedVersions[$_])" } else { "any" }
    "  ${_}: $ver"
}) -join "`n"

$devDepLines = ($devDependencies | ForEach-Object {
    $ver = if ($resolvedVersions.ContainsKey($_)) { "^$($resolvedVersions[$_])" } else { "any" }
    "  ${_}: $ver"
}) -join "`n"

$pubspecFinal = @"
name: templated_flutter
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.7.2

dependencies:
  flutter:
    sdk: flutter
$depLines

dev_dependencies:
  flutter_test:
    sdk: flutter
$devDepLines

flutter:
  uses-material-design: true
"@

Set-Content -Path "pubspec.yaml" -Value $pubspecFinal -Encoding utf8
Write-Host "`npubspec.yaml updated with resolved versions:" -ForegroundColor Cyan
foreach ($pkg in ($dependencies + $devDependencies)) {
    $ver = if ($resolvedVersions.ContainsKey($pkg)) { $resolvedVersions[$pkg] } else { "unknown" }
    Write-Host "  $pkg`: $ver" -ForegroundColor Green
}
