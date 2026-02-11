resource "local_file" "main" {
  count    = length(local.paths)
  filename = local.paths[count.index]
  content  = "hola\n"
}