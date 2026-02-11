locals {
  folders = ["QA", "STG", "PRD"]

  paths_nested = [
    for folder in local.folders : [
      for i in range(1, 11) : "${folder}/file${i}.txt"
    ]
  ]

  paths = flatten(local.paths_nested)
}