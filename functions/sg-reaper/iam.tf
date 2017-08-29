resource "aws_iam_role" "iam_for_sg_reaper" {
  name = "iam_for_sg_reaper"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "sg-reaper-access" {
  statement {
    actions = [
      "ec2:TerminateInstances",
      "ec2:DescribeInstances",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "sg-reaper-access" {
  name = "sg-reaper-access"
  policy = "${data.aws_iam_policy_document.sg-reaper-access.json}"
}

resource "aws_iam_policy_attachment" "sg-reaper-access" {
  name = "sg-reaper-access"
  roles = ["${aws_iam_role.iam_for_sg_reaper.name}"]
  policy_arn = "${aws_iam_policy.sg-reaper-access.arn}"
}

resource "aws_iam_policy_attachment" "basic-exec-role" {
  name = "basic-exec-role"
  roles = ["${aws_iam_role.iam_for_sg_reaper.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "sg_reaper" {
  statement_id = "AllowExecutionFromEvent"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sg_reaper.function_name}"
  principal = "events.amazonaws.com"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_sg_reaper" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.sg_reaper.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.everyday.arn}"
}

resource "aws_lambda_function" "sg_reaper" {
  filename = "sg-reaper.zip"
  function_name = "sg_reaper"
  handler = "sg-reaper.handler"
  role = "${aws_iam_role.iam_for_sg_reaper.arn}"
  runtime = "python3.6"
  source_code_hash = "${base64sha256(file("sg-reaper.zip"))}"
  timeout = 60
}
