$serviceType="HTTP"
$spns = @{}
$filter = "(servicePrincipalName=$serviceType/*)"
$domain = New-Object System.DirectoryServices.DirectoryEntry
$searcher = New-Object System.DirectoryServices.DirectorySearcher
$searcher.SearchRoot = $domain
$searcher.PageSize = 1000
$searcher.Filter = $filter
$results = $searcher.FindAll()
foreach ($result in $results){
 $account = $result.GetDirectoryEntry()
 foreach ($spn in $account.servicePrincipalName.Value){
  if($spn.contains("$serviceType/")){
   $spns[$("$spn`t$($account.samAccountName)")]=1;
  }
 }
}
$spns.keys