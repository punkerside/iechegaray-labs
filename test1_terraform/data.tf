locals {
  folders = ["QA", "STG", "PRD"]

  files_nested = [
    for folder in local.folders : [
      for i in range(1, 11) : {
        folder = folder
        idx    = i
        path   = "${folder}/file${i}.txt"
      }
    ]
  ]

  files = flatten(local.files_nested)
}