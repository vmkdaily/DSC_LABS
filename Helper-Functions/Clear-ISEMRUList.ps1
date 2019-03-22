Function Clear-ISEMRUList {
  $count = $psise.Options.MruCount
  $psise.Options.MruCount = 0
  $psise.Options.MruCount = $count
}