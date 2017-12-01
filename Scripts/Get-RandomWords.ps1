#region Get-RandomWords
function Get-RandomWords
{
    <#
    .Synopsis
    Get random words from remote APIs.
    
    .Description
    Get a list of words from api.wordnik.com to create randomized usernames or passphrases.
    
    .Parameter Limit
    Maximum number of results to get in one query. Default: 10
    
    .Parameter MinLength
    Minimum number of characters in words. Default: 5
    
    .Parameter MaxLength
    Maximum number of characters in words. Default: -1 (unlimited)
    
    .Parameter IncludePartOfSpeech
    Part of speech of words to return. Default: any
    
    .Parameter ExcludePartOfSpeech
    Do not include the following parts of speech in the results.
        family-name
        given-name
        proper-noun
        proper-noun-plural
        proper-noun-posessive
        affix
        suffix
        
    .Parameter HasDictionaryDef
    Only include words with dictionary definitions in results.
    
    .Parameter ApiKey
    API key to allow the script to download results from web host.
    
    .Example
    Get-RandomWords -Limit 25
    Get 25 random nouns at least 5 characters in length.
    
    .Example
    Get-RandomWords -Limit 5 -PartOfSpeech adjective -MaxLength 7 -MinLength 3
    Get 5 random adjectives between 3 and 7 characters in length.
    #>

    param
    (
        [ValidateRange(5,250)]
        [int]
        $Limit = 10,
        
        [ValidateRange(1,9)]
        [int]
        $MinLength = 5,
        
        [ValidateRange(-1,10)]
        [int]
        $MaxLength = -1,
        
        [ValidateSet('verb','noun','adjective','conjunction','article','any')]
        [string]
        $IncludePartOfSpeech = 'any',
        
        [switch]
        $ExcludePartOfSpeech,
        
        [switch]
        $HasDictionaryDef,
        
        [string]
        $ApiKey = 'a2a73e7b926c924fad7001ca3111acd55af2ffabf50eb4ae5'
    )
        
    # Initialize an array to store our words
    $WordList = @()
    
    ###### Build individual components of the URI ######
    # Base URI
    $baseURI = 'http://api.wordnik.com:80/v4/words.json/randomWords?'
    
    # Include parts of speech
    if ($IncludePartOfSpeech -eq 'any')
    {
        $IncludePOS = "includePartOfSpeech="
    }
    else
    {
        $IncludePOS = "includePartOfSpeech=$IncludePartOfSpeech"
    }
    
    # Exclude parts of speech
    if ($ExcludePartOfSpeech)
    {
        $ExcludePOS = "excludePartOfSpeech=family-name,given-name,proper-noun,proper-noun-plural,proper-noun-posessive,affix,suffix"
    }
    else
    {
        $ExcludePOS = 'excludePartOfSpeech='
    }
    
    # Max length of words
    $MaxWordLength = "maxLength=$MaxLength"
    
    # Min length of words
    $MinWordLength = "minLength=$MinLength"
    
    # Limit of words to return
    $WordLimit = "limit=$Limit"
    
    # Has dictionary definition
    if ($HasDictionaryDef)
    {
        $HasDictDef = 'hasDefinition=true'
    }
    else
    {
        $HasDictDef = 'hasDefinition=false'
    }
    
    # API key
    $API = "api_key=$ApiKey"
    ###### End section ######
    
    # Build our URI and get a list of random words
    $URI = "$baseURI$IncludePOS&$ExcludePoS&$MinWordLength&$MaxWordLength&$WordLimit&$HasDictDef&$API"
    $Result = Invoke-WebRequest -Uri $URI
    
    # Convert JSON result into PS object array
    $Result = $Result.Content | ConvertFrom-Json

    # Populate $WordList with words from $Result
    foreach ($word in $Result)
    {
        $WordList += $word.word
    }

    return $WordList
}
<#
Example output:

PS C:\> Get-RandomWords -Limit 5 -PartOfSpeech adjective -MaxLength 7 -MinLength 3
cult
fauvist
punkest
safest
saltier

#>
#endregion
