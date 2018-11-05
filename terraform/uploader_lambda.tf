data "aws_iam_policy_document" "uploader" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:HeadObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::10kb.site/*",
      "arn:aws:s3:::10kb.site",
    ]
  }
}

data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "uploader" {
  name = "10kb_s3_uploader"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "uploader" {
  role       = "${aws_iam_role.uploader.name}"
  policy_arn = "${aws_iam_policy.uploader.arn}"
}

resource "aws_iam_policy" "uploader" {
  name   = "10kb_site_upload_and_read"
  path   = "/"
  policy = "${data.aws_iam_policy_document.uploader.json}"
}

resource "aws_lambda_function" "uploader" {
  function_name = "10kb-site-uploader-0-0-2"
  handler       = "lambda_function.lambda_handler"
  memory_size   = 128
  runtime       = "python3.6"
  timeout       = 3
  role          = "${aws_iam_role.uploader.arn}"
}
