# public interface

output "table_name" {
  value = aws_dynamodb_table.exam_items.name
  description = "Exposed for CI/CD pipelines and integration testing"
}

output "api_url" {
  value = aws_api_gateway_stage.prod.invoke_url
  description = "Exposed for integration testing"
}