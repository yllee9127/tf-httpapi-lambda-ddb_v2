
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.name_prefix}-topmovies-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.http_api.id

  name        = "$default"
  auto_deploy = true
}

resource "aws_cloudwatch_log_group" "api_gateway_execution_logs" {
  name = "API-Gateway-Execution-Logs_${aws_apigatewayv2_api.http_api.id}"

  retention_in_days = "7"
}

resource "aws_apigatewayv2_integration" "apigw_lambda" {
  api_id = aws_apigatewayv2_api.http_api.id

  integration_uri        = aws_lambda_function.http_api_lambda.invoke_arn # todo: fill with apporpriate value
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_topmovies" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /topmovies"

  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}"
}

resource "aws_apigatewayv2_route" "get_topmovies_by_year" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /topmovies/{year}"

  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}"
}

resource "aws_apigatewayv2_route" "put_topmovies" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /topmovies"

  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}"
}

resource "aws_apigatewayv2_route" "delete_topmovies_by_year" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE /topmovies/{year}"

  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http_api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
/*
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = "yl.sctp-sandbox.com"
  zone_id      = data.aws_route53_zone.sctp_zone.zone_id

  validation_method = "DNS"

  #subject_alternative_names = [
  #  "*.my-domain.com",
  #  "app.sub.my-domain.com",
  #]

  wait_for_validation = true

  tags = {
    Name = "yl.sctp-sandbox.com"
  }
}
*/

resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "yl.sctp-sandbox.com"
  validation_method = "DNS"

  tags = {
    Name = "api_gateway_domain_cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "yl.sctp-sandbox.com"
  validation_method = "DNS"
}
*/
/*
resource "aws_route53_record" "route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300 # changed from 60 to overcome ACM cert RequestInProgressException issue during terraform apply
  type            = each.value.type
  zone_id         = data.aws_route53_zone.sctp_zone.zone_id
}
*/

resource "aws_acm_certificate_validation" "acm_cert_validation" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  #validation_record_fqdns = [for record in aws_route53_record.route53_record : record.fqdn]
}

resource "aws_apigatewayv2_domain_name" "api_domain_name" {
  domain_name = "yl.sctp-sandbox.com"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.acm_cert.arn
    #certificate_arn = module.acm.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  #depends_on = [ aws_acm_certificate.cert ]
}


resource "aws_route53_record" "route53_record" {
  name    = aws_apigatewayv2_domain_name.api_domain_name.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.sctp_zone.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain_name.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain_name.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}


# To map API gateway to custom domain name
resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain_name.id
  stage       = aws_apigatewayv2_stage.default.id    #var.api_stage
}
/*
resource "aws_acm_certificate_validation" "acm_valid" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.route53 : record.fqdn]
}
*/
