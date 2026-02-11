variable "user_text" {
  type = map(string)

  default = {
    QA  = "See its easy"
    STG = "Testing staging"
    PRD = "Production ready"
  }
}