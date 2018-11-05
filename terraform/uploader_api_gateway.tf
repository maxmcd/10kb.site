resource "aws_api_gateway_rest_api" "uploader" {
  name        = "10kb_site_uploader"
  description = "10kb site uploader thing"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.uploader.id}"
  parent_id   = "${aws_api_gateway_rest_api.uploader.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.uploader.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "uploader" {
  rest_api_id = "${aws_api_gateway_rest_api.uploader.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.uploader.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.uploader.id}"
  resource_id   = "${aws_api_gateway_rest_api.uploader.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "uploader_root" {
  rest_api_id = "${aws_api_gateway_rest_api.uploader.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.uploader.invoke_arn}"
}

resource "aws_api_gateway_deployment" "uploader_fourth" {
  depends_on = [
    "aws_api_gateway_integration.uploader",
    "aws_api_gateway_integration.uploader_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.uploader.id}"
  stage_name  = "v0_0_1"
}

resource "aws_api_gateway_domain_name" "uploader" {
  domain_name     = "up.10kb.site"
  certificate_arn = "${aws_acm_certificate.10kb_site.arn}"
}

resource "aws_api_gateway_base_path_mapping" "test" {
  api_id      = "${aws_api_gateway_rest_api.uploader.id}"
  stage_name  = "${aws_api_gateway_deployment.uploader_fourth.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.uploader.domain_name}"
}

output "uploader_cname" {
  value = "Set up.10kb.site CNAME to ${aws_api_gateway_domain_name.uploader.cloudfront_domain_name}"
}

resource "aws_api_gateway_method_settings" "uploader" {
  rest_api_id = "${aws_api_gateway_rest_api.uploader.id}"
  stage_name  = "${aws_api_gateway_deployment.uploader_fourth.stage_name}"

  method_path = "*/*"

  # this is supposed to be the following:
  # method_path = "${aws_api_gateway_resource.proxy.path}/${aws_api_gateway_method.proxy.http_method}"
  # aws doesn't like consistent wildcard settings. I guess * in a path would match, but star shouldn't
  # need to be a replacement for ANY...

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_lambda_permission" "uploader" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.uploader.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.uploader_fourth.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.uploader_fourth.invoke_url}"
}

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = "${aws_iam_role.cloudwatch.arn}"
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = "${aws_iam_role.cloudwatch.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
