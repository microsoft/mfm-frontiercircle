#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$EventsPath,
    [string]$CalendarOutputPath,
    [string]$IndexOutputPath,
    [string]$ScriptOutputPath,
    [string]$IndividualOutputPath,
    [string]$SiteBaseUrl = 'https://microsoft.github.io/mfm-frontiercircle'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($EventsPath)) {
    $EventsPath = Join-Path $repoRoot 'events'
}
if ([string]::IsNullOrWhiteSpace($CalendarOutputPath)) {
    $CalendarOutputPath = Join-Path $repoRoot 'calendar.ics'
}
if ([string]::IsNullOrWhiteSpace($IndexOutputPath)) {
    $IndexOutputPath = Join-Path $EventsPath 'index.json'
}
if ([string]::IsNullOrWhiteSpace($ScriptOutputPath)) {
    $ScriptOutputPath = Join-Path $EventsPath 'events.js'
}
if ([string]::IsNullOrWhiteSpace($IndividualOutputPath)) {
    $IndividualOutputPath = Join-Path $EventsPath 'ics'
}

$resolvedEventsPath = (Resolve-Path -LiteralPath $EventsPath).Path
$resolvedCalendarOutput = [IO.Path]::GetFullPath($CalendarOutputPath)
$resolvedIndexOutput = [IO.Path]::GetFullPath($IndexOutputPath)
$resolvedScriptOutput = [IO.Path]::GetFullPath($ScriptOutputPath)
$resolvedIndividualOutput = [IO.Path]::GetFullPath($IndividualOutputPath)
$generatorPath = Join-Path $PSScriptRoot 'New-FrontierCircleEvent.ps1'

$laneMap = @{
    lab = @{
        Emoji = '🧪'
        Label = 'Lab'
        Name  = 'Build & Skill Labs'
    }
    briefing = @{
        Emoji = '💡'
        Label = 'Briefing'
        Name  = 'Transformation Briefings'
    }
    exchange = @{
        Emoji = '🤝'
        Label = 'Exchange'
        Name  = 'Frontier Exchange'
    }
}

$topicCategories = @(
    [ordered]@{ id = 'ai-agents'; label = 'AI & agents' }
    [ordered]@{ id = 'data-analytics'; label = 'Data & analytics' }
    [ordered]@{ id = 'security'; label = 'Security' }
    [ordered]@{ id = 'modernization'; label = 'Modernization' }
    [ordered]@{ id = 'connected-products'; label = 'Connected products' }
)
$topicCategoryIds = [Collections.Generic.HashSet[string]]::new(
    [string[]]@($topicCategories | ForEach-Object { $_.id }),
    [StringComparer]::Ordinal
)

function Get-RequiredText {
    param(
        [object]$InputObject,
        [string]$PropertyName,
        [string]$SourcePath
    )

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if (
        $null -eq $property -or
        [string]::IsNullOrWhiteSpace([string]$property.Value)
    ) {
        throw "Missing required property '$PropertyName' in '$SourcePath'."
    }

    return ([string]$property.Value).Trim()
}

function ConvertFrom-OffsetDate {
    param(
        [string]$Value,
        [string]$PropertyName,
        [string]$SourcePath
    )

    if ($Value -notmatch '(?:Z|[+-]\d{2}:\d{2})$') {
        throw "'$PropertyName' must include an explicit offset in '$SourcePath'."
    }

    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse(
        $Value,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AllowWhiteSpaces,
        [ref]$parsed
    )) {
        throw "Invalid '$PropertyName' in '$SourcePath'."
    }

    return $parsed
}

function Get-OptionalText {
    param(
        [object]$InputObject,
        [string]$PropertyName,
        [string]$SourcePath
    )

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }
    if ($property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($property.Value)) {
        throw "'$PropertyName' must be non-empty text when provided in '$SourcePath'."
    }

    return $property.Value.Trim()
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }

    [IO.File]::WriteAllText(
        $Path,
        $Content,
        [Text.UTF8Encoding]::new($false)
    )
}

function ConvertTo-PublicIsoDate {
    param([DateTimeOffset]$Value)

    return $Value.ToString(
        "yyyy-MM-dd'T'HH:mm:sszzz",
        [Globalization.CultureInfo]::InvariantCulture
    )
}

$convertFromJsonParameters = @{}
if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
    $convertFromJsonParameters.DateKind = 'String'
}

$manifestFiles = @(
    Get-ChildItem -LiteralPath $resolvedEventsPath -Recurse -Filter '*.json' |
        Where-Object {
            $_.FullName -ne $resolvedIndexOutput -and
            $_.Directory.Name -match '^\d{4}$'
        } |
        Sort-Object FullName
)

if ($manifestFiles.Count -eq 0) {
    throw "No event manifests were found under '$resolvedEventsPath'."
}

if (-not (Test-Path -LiteralPath $resolvedIndividualOutput)) {
    New-Item -ItemType Directory -Path $resolvedIndividualOutput | Out-Null
}

$seenIds = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
$records = [Collections.Generic.List[object]]::new()
$eventBlocks = [Collections.Generic.List[object]]::new()
$expectedIndividualFiles = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)

foreach ($manifestFile in $manifestFiles) {
    $sourcePath = $manifestFile.FullName
    $event = Get-Content -LiteralPath $sourcePath -Raw |
        ConvertFrom-Json @convertFromJsonParameters

    $id = Get-RequiredText $event 'id' $sourcePath
    if (-not $seenIds.Add($id)) {
        throw "Duplicate event id '$id'."
    }

    $laneKey = (Get-RequiredText $event 'lane' $sourcePath).ToLowerInvariant()
    if (-not $laneMap.ContainsKey($laneKey)) {
        throw "Unknown lane '$laneKey' in '$sourcePath'."
    }

    $categoriesProperty = $event.PSObject.Properties['topicCategories']
    if (
        $null -eq $categoriesProperty -or
        $categoriesProperty.Value -isnot [array] -or
        $categoriesProperty.Value.Count -eq 0
    ) {
        throw "'topicCategories' must be a non-empty array of reviewed topic IDs in '$sourcePath'."
    }
    $seenCategories = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($categoryId in $categoriesProperty.Value) {
        if ($categoryId -isnot [string] -or -not $topicCategoryIds.Contains($categoryId)) {
            throw "Unknown topic category '$categoryId' in '$sourcePath'. Use the fixed topic taxonomy."
        }
        if (-not $seenCategories.Add($categoryId)) {
            throw "Duplicate topic category '$categoryId' in '$sourcePath'."
        }
    }

    $status = Get-RequiredText $event 'status' $sourcePath
    if ($status -notin @('Scheduled', 'Completed', 'Cancelled')) {
        throw "Invalid status '$status' in '$sourcePath'."
    }

    $sequence = 0
    if (
        -not [int]::TryParse(
            (Get-RequiredText $event 'sequence' $sourcePath),
            [ref]$sequence
        ) -or
        $sequence -lt 0
    ) {
        throw "Invalid sequence in '$sourcePath'."
    }

    $createdText = Get-RequiredText $event 'created' $sourcePath
    $lastModifiedText = Get-RequiredText $event 'lastModified' $sourcePath
    $startText = Get-RequiredText $event 'start' $sourcePath
    $endText = Get-RequiredText $event 'end' $sourcePath
    $created = ConvertFrom-OffsetDate $createdText 'created' $sourcePath
    $lastModified = ConvertFrom-OffsetDate (
        $lastModifiedText
    ) 'lastModified' $sourcePath
    $start = ConvertFrom-OffsetDate $startText 'start' $sourcePath
    $end = ConvertFrom-OffsetDate $endText 'end' $sourcePath

    if ($lastModified -lt $created) {
        throw "'lastModified' precedes 'created' in '$sourcePath'."
    }
    if ($end -le $start) {
        throw "'end' must be later than 'start' in '$sourcePath'."
    }

    $timeZone = Get-RequiredText $event 'timeZone' $sourcePath
    try {
        [void][TimeZoneInfo]::FindSystemTimeZoneById($timeZone)
    }
    catch {
        if ($timeZone -ne 'America/New_York') {
            throw "Unsupported IANA time zone '$timeZone' in '$sourcePath'."
        }
    }

    $lane = $laneMap[$laneKey]
    $audienceSummary = Get-OptionalText $event 'audienceSummary' $sourcePath
    $takeaway = Get-OptionalText $event 'takeaway' $sourcePath
    $summary = "$($lane.Emoji) $($lane.Label) | $($event.title)"
    $individualFileName = "$($manifestFile.BaseName).ics"
    $individualPath = Join-Path $resolvedIndividualOutput $individualFileName
    [void]$expectedIndividualFiles.Add($individualPath)

    & $generatorPath `
        -InputPath $sourcePath `
        -OutputPath $individualPath |
        Out-Null

    $individualLines = [IO.File]::ReadAllLines($individualPath)
    $eventStartIndex = [Array]::IndexOf($individualLines, 'BEGIN:VEVENT')
    $eventEndIndex = [Array]::IndexOf($individualLines, 'END:VEVENT')
    if ($eventStartIndex -lt 0 -or $eventEndIndex -le $eventStartIndex) {
        throw "Generated file '$individualPath' does not contain one VEVENT."
    }

    $eventBlocks.Add(
        @($individualLines[$eventStartIndex..$eventEndIndex])
    )

    $topics = @()
    $topicsProperty = $event.PSObject.Properties['topics']
    if ($null -ne $topicsProperty -and $null -ne $topicsProperty.Value) {
        $topics = @(
            $topicsProperty.Value |
                ForEach-Object { ([string]$_).Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    $registrationDeadline = $null
    $deadlineProperty = $event.PSObject.Properties['registrationDeadline']
    if (
        $null -ne $deadlineProperty -and
        -not [string]::IsNullOrWhiteSpace([string]$deadlineProperty.Value)
    ) {
        $registrationDeadline = (
            ConvertFrom-OffsetDate (
                [string]$deadlineProperty.Value
            ) 'registrationDeadline' $sourcePath
        ).ToString('o')
    }

    $records.Add([ordered]@{
        id                   = $id
        lane                 = $laneKey
        laneName             = $lane.Name
        laneLabel            = $lane.Label
        laneEmoji            = $lane.Emoji
        status               = $status
        sequence             = $sequence
        created              = ConvertTo-PublicIsoDate $created
        lastModified         = ConvertTo-PublicIsoDate $lastModified
        summary              = $summary
        title                = [string]$event.title
        start                = ConvertTo-PublicIsoDate $start
        end                  = ConvertTo-PublicIsoDate $end
        timeZone             = $timeZone
        timeZoneLabel        = [string]$event.timeZoneLabel
        location             = [string]$event.location
        description          = [string]$event.description
        audience             = [string]$event.audience
        audienceSummary      = $audienceSummary
        takeaway             = $takeaway
        topicCategories      = @($categoriesProperty.Value)
        topics               = $topics
        registrationDeadline = if ($null -ne $registrationDeadline) {
            ConvertTo-PublicIsoDate (
                [DateTimeOffset]::Parse(
                    $registrationDeadline,
                    [Globalization.CultureInfo]::InvariantCulture
                )
            )
        }
        else {
            $null
        }
        registrationUrl      = [string]$event.registrationUrl
        eventIcsUrl          = (
            'events/ics/' +
            [Uri]::EscapeDataString($individualFileName)
        )
    })
}

$records = @($records | Sort-Object {
    [DateTimeOffset]::Parse(
        [string]$_.start,
        [Globalization.CultureInfo]::InvariantCulture
    )
})

Get-ChildItem -LiteralPath $resolvedIndividualOutput -Filter '*.ics' |
    Where-Object { -not $expectedIndividualFiles.Contains($_.FullName) } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

$latestModified = (
    $records |
        ForEach-Object {
            [DateTimeOffset]::Parse(
                [string]$_.lastModified,
                [Globalization.CultureInfo]::InvariantCulture
            )
        } |
        Sort-Object -Descending |
        Select-Object -First 1
)
$latestModified = ConvertTo-PublicIsoDate $latestModified

$siteBase = $SiteBaseUrl.TrimEnd('/')
$payload = [ordered]@{
    schemaVersion = 1
    lastUpdated   = $latestModified
    calendarUrl   = "$siteBase/calendar.ics"
    topicCategories = $topicCategories
    events        = $records
}

$json = $payload | ConvertTo-Json -Depth 12
Write-Utf8NoBom $resolvedIndexOutput ($json + "`n")
Write-Utf8NoBom $resolvedScriptOutput (
    "window.frontierCircleEventData = $json;`n"
)

$calendarLines = [Collections.Generic.List[string]]::new()
$calendarLines.Add('BEGIN:VCALENDAR')
$calendarLines.Add('VERSION:2.0')
$calendarLines.Add(
    'PRODID:-//Microsoft//Manufacturing and Mobility Frontier Circle//EN'
)
$calendarLines.Add('CALSCALE:GREGORIAN')
$calendarLines.Add('METHOD:PUBLISH')
$calendarLines.Add('X-WR-CALNAME:Manufacturing & Mobility Frontier Circle')
$calendarLines.Add(
    'X-WR-CALDESC:Public events for Manufacturing & Mobility Frontier Circle'
)
$calendarLines.Add('REFRESH-INTERVAL;VALUE=DURATION:PT6H')
$calendarLines.Add('X-PUBLISHED-TTL:PT6H')

foreach ($eventBlock in $eventBlocks) {
    foreach ($line in $eventBlock) {
        $calendarLines.Add([string]$line)
    }
}

$calendarLines.Add('END:VCALENDAR')
$calendarContent = ($calendarLines -join "`r`n") + "`r`n"
Write-Utf8NoBom $resolvedCalendarOutput $calendarContent

$overlongLines = @(
    [IO.File]::ReadAllLines($resolvedCalendarOutput) |
        Where-Object {
            [Text.Encoding]::UTF8.GetByteCount($_) -gt 75
        }
)
if ($overlongLines.Count -gt 0) {
    throw "Aggregate calendar contains lines over 75 UTF-8 bytes."
}

[pscustomobject]@{
    EventCount          = $records.Count
    CalendarPath        = $resolvedCalendarOutput
    IndexPath           = $resolvedIndexOutput
    ScriptPath          = $resolvedScriptOutput
    IndividualEventPath = $resolvedIndividualOutput
    LastUpdated         = $latestModified
}
