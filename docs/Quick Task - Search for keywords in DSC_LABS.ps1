## How to search for keywords in DSC_LABS

## How to search in the DSC_LABS kit
dir c:\dsc_labs\ -Recurse -Include *.ps1 | Select-String "keyword"

## Example
## The following will show the files that mention "xDnsServer" in their contents:
dir c:\dsc_labs\ -Recurse -Include *.ps1 | Select-String "xDnsServer"

