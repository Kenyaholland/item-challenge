# public interface

output "table_name" {
  value = aws_dynamodb_table.exam_items.name
  description = "Exposed for CI/CD pipelines and integration testing"
}