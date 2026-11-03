#requires -Version 7.0

[CmdletBinding()]
param(
    [datetime]$StartDate,
    [datetime]$EndDate,
    [string]$EventsPath,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($StartDate -eq [datetime]::MinValue) {
    $today = Get-Date
    $quarterMonth = ([math]::Floor(($today.Month - 1) / 3) * 3) + 1
    $StartDate = Get-Date -Year $today.Year -Month $quarterMonth -Day 1
}

if ($EndDate -eq [datetime]::MinValue) {
    $EndDate = $StartDate.AddMonths(3).AddDays(-1)
}

if ($EndDate.Date -lt $StartDate.Date) {
    throw "'EndDate' must be on or after 'StartDate'."
}

if ([string]::IsNullOrWhiteSpace($EventsPath)) {
    $EventsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'events'
}

$resolvedEventsPath = (Resolve-Path -LiteralPath $EventsPath).Path
$convertFromJsonParameters = @{}
if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
    $convertFromJsonParameters.DateKind = 'String'
}

$laneMap = @{
    lab       = @{ Name = 'Build & Skill Labs'; Prefix = '🧪 Lab' }
    briefing  = @{ Name = 'Transformation Briefings'; Prefix = '💡 Briefing' }
    exchange  = @{ Name = 'Frontier Exchange'; Prefix = '🤝 Exchange' }
}

$events = @(
    Get-ChildItem -LiteralPath $resolvedEventsPath -Recurse -Filter '*.json' |
        Where-Object { $_.Directory.Name -match '^\d{4}$' } |
        ForEach-Object {
            $sourcePath = $_.FullName
            $event = Get-Content -LiteralPath $sourcePath -Raw |
                ConvertFrom-Json @convertFromJsonParameters

            $laneKey = ([string]$event.lane).ToLowerInvariant()
            if (-not $laneMap.ContainsKey($laneKey)) {
                throw "Unknown lane '$laneKey' in '$sourcePath'."
            }

            $start = [DateTimeOffset]::Parse(
                [string]$event.start,
                [Globalization.CultureInfo]::InvariantCulture
            )
            $end = [DateTimeOffset]::Parse(
                [string]$event.end,
                [Globalization.CultureInfo]::InvariantCulture
            )
            $statusProperty = $event.PSObject.Properties['status']
            $status = if (
                $null -ne $statusProperty -and
                -not [string]::IsNullOrWhiteSpace([string]$statusProperty.Value)
            ) {
                ([string]$statusProperty.Value).Trim()
            }
            else {
                'Scheduled'
            }

            [pscustomobject]@{
                Date            = $start.Date
                Start           = $start
                End             = $end
                DurationHours   = ($end - $start).TotalHours
                LaneKey         = $laneKey
                Lane            = $laneMap[$laneKey].Name
                Prefix          = $laneMap[$laneKey].Prefix
                Title           = [string]$event.title
                Status          = $status
                Location        = [string]$event.location
                RegistrationUrl = [string]$event.registrationUrl
                Source          = $sourcePath
            }
        } |
        Where-Object {
            $_.Date -ge $StartDate.Date -and $_.Date -le $EndDate.Date
        } |
        Sort-Object Date, Title
)

$activeEvents = @($events | Where-Object { $_.Status -ne 'Cancelled' })
[double]$scheduledHours = 0
foreach ($activeEvent in $activeEvents) {
    $scheduledHours += [double]$activeEvent.DurationHours
}

$laneCounts = @{}
foreach ($laneKey in $laneMap.Keys) {
    $laneCounts[$laneKey] = @(
        $activeEvents | Where-Object { $_.LaneKey -eq $laneKey }
    ).Count
}

function ConvertTo-MarkdownText {
    param([string]$Value)
    return ($Value -replace '\|', '\|') -replace '\r?\n', ' '
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Frontier Circle event report')
$lines.Add('')
$lines.Add(
    "**Period:** $($StartDate.ToString('MMMM d, yyyy')) – " +
    $EndDate.ToString('MMMM d, yyyy')
)
$lines.Add('')
$lines.Add('## Summary')
$lines.Add('')
$lines.Add('| Metric | Value |')
$lines.Add('| --- | ---: |')
$lines.Add("| Events | $($activeEvents.Count) |")
$lines.Add("| Build & Skill Labs | $($laneCounts.lab) |")
$lines.Add("| Transformation Briefings | $($laneCounts.briefing) |")
$lines.Add("| Frontier Exchange | $($laneCounts.exchange) |")
$lines.Add("| Scheduled hours | $($scheduledHours.ToString('0.0')) |")
$lines.Add('')
$lines.Add('## Events')
$lines.Add('')
$lines.Add('| Date | Lane | Event | Status | Hours | Location | Registration |')
$lines.Add('| --- | --- | --- | --- | ---: | --- | --- |')

foreach ($event in $events) {
    $eventTitle = ConvertTo-MarkdownText $event.Title
    $location = ConvertTo-MarkdownText $event.Location
    $lines.Add(
        "| $($event.Start.ToString('MMM d, yyyy')) " +
        "| $($event.Prefix) " +
        "| $eventTitle " +
        "| $($event.Status) " +
        "| $($event.DurationHours.ToString('0.0')) " +
        "| $location " +
        "| [Open]($($event.RegistrationUrl)) |"
    )
}

if ($events.Count -eq 0) {
    $lines.Add('| — | — | No events in this period | — | — | — | — |')
}

$markdown = ($lines -join "`r`n") + "`r`n"

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Parent $resolvedOutput
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }
    [IO.File]::WriteAllText(
        $resolvedOutput,
        $markdown,
        [Text.UTF8Encoding]::new($false)
    )
    [pscustomobject]@{
        Path          = $resolvedOutput
        StartDate     = $StartDate.Date
        EndDate       = $EndDate.Date
        EventCount    = $activeEvents.Count
        ScheduledHours = $scheduledHours
    }
}
else {
    $markdown
}
