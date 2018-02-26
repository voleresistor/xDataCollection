#region New-RandomPhrase
function New-RandomPhrase
{
    <#
    .Synopsis
    Generate random phrases from 2-5 words.
    
    .Description
    Using a remote API call to wordnik.com, collect random words and use them to generate passphrases. 
    
    .Parameter WordPer
    The number of words to include in each unique object. Default: 3
    
    .Parameter Limit
    The number of unique objects to return. Default: 10
    
    .Example
    New-RandomPhrase -WordsPer 3
    
    Generate 5 objects of 3 random words each.
    #>
    param
    (
        [ValidateRange(2,4)]
        [int]
        $WordsPer = 3,
        
        [ValidateRange(1,50)]
        [int]
        $Limit = 10
    )
    # An array for our results
    $RandomResults = @()

    $Adjectives = Get-RandomWords -Limit ($Limit*5) -IncludePartOfSpeech adjective -HasDictionaryDef true
    $Nouns = Get-RandomWords -Limit ($Limit*5) -IncludePartOfSpeech noun -HasDictionaryDef true

    if ($WordsPer -ge 3)
    {
        $Verbs = Get-RandomWords -Limit ($Limit*5) -IncludePartOfSpeech verb -HasDictionaryDef true
    }

    if ($WordsPer -eq 4)
    {
        $Adverbs = Get-RandomWords -Limit ($Limit*5) -IncludePartOfSpeech adverb -HasDictionaryDef true
    }
    
    $i = 1
    while ($i -le $Limit)
    {
        # New object
        $NameObj = New-Object -TypeName psobject

        # Count phrase length
        $PhraseLength = 0

        # (adverb) (verb) adjective noun
        $CurrentAdj = $Adjectives | Get-Random
        $CurrentNoun = $Nouns | Get-Random

        if ($WordsPer -eq 4)
        {
            $CurrentAdverb = $Adverbs | Get-Random
            $NameObj | Add-Member -MemberType NoteProperty -Name Adverb -Value $CurrentAdverb
            $PhraseLength += $CurrentAdverb.Length

            # Remove from list
            $Adverbs = $Adverbs -ne $CurrentAdverb
        }

        if ($WordsPer -ge 3)
        {
            $CurrentVerb = $Verbs | Get-Random
            $NameObj | Add-Member -MemberType NoteProperty -Name Verb -Value $CurrentVerb
            $PhraseLength += $CurrentVerb.Length

            # Remove from list
            $Verbs = $Verbs -ne $CurrentVerb
        }

        $NameObj | Add-Member -MemberType NoteProperty -Name Adjective -Value $CurrentAdj
        $PhraseLength += $CurrentAdj.Length

        $NameObj | Add-Member -MemberType NoteProperty -Name Noun -Value $CurrentNoun
        $PhraseLength += $CurrentNoun.Length

        $Adjectives = $Adjectives -ne $CurrentAdj
        $Nouns = $Nouns -ne $CurrentNoun

        # Add a total count as a simple measure of complexity in a potential passphrase
        $NameObj | Add-Member -MemberType NoteProperty -Name Length -Value $PhraseLength
        
        $RandomResults += $NameObj
        Clear-Variable -Name NameObj
        
        $i++
    }
    
    return $RandomResults
}
<#
Example output:

PS C:\> New-RandomPhrase -Limit 5 -WordsPer 3

FirstWord       SecondWord ThirdWord    Count
---------       ---------- ---------    -----
grazing-ground  whisperer  tail-feather    35
insists         mop-head   forgathering    27
deludes         connoting  bulldogs        24
sophomorically  toddled    crinkling       30
xenoarchaeology throatily  boobless        32

#>
#endregion
