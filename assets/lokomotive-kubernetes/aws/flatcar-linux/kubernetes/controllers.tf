# Discrete DNS records for each controller's private IPv4 for etcd usage
resource "aws_route53_record" "etcds" {
  count = var.controller_count

  # DNS Zone where record should be created
  zone_id = var.dns_zone_id

  name = format("%s-etcd%d.%s.", var.cluster_name, count.index, var.dns_zone)
  type = "A"
  ttl  = 300

  # private IPv4 address for etcd
  records = [aws_instance.controllers[count.index].private_ip]
}

# IAM Policy
resource "aws_iam_instance_profile" "csi-driver-instance-profile" {
  count = var.set_csi_driver_iam_role ? 1 : 0
  name  = "${var.cluster_name}-iprof"
  role  = join("", aws_iam_role.csi-driver-role.*.name)
}

resource "aws_iam_role_policy" "csi-driver-role-policy" {
  count = var.set_csi_driver_iam_role ? 1 : 0
  name  = "${var.cluster_name}-policy"
  role  = join("", aws_iam_role.csi-driver-role.*.id)

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:AttachVolume",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DetachVolume",
          "ec2:ModifyVolume"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "csi-driver-role" {
  count = var.set_csi_driver_iam_role ? 1 : 0
  name  = "${var.cluster_name}-role"
  path  = "/"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
  }
  EOF
}

# Controller instances
resource "aws_instance" "controllers" {
  count = var.controller_count

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-controller-${count.index}"
  })

  instance_type = var.controller_type

  ami                  = local.ami_id
  user_data            = data.ct_config.controller-ignitions[count.index].rendered
  iam_instance_profile = join("", aws_iam_instance_profile.csi-driver-instance-profile.*.name)

  # storage
  root_block_device {
    volume_type = var.disk_type
    volume_size = var.disk_size
    iops        = var.disk_iops
    encrypted   = true
  }

  # network
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[count.index].id
  vpc_security_group_ids      = [aws_security_group.controller.id]

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }
}

# Controller Ignition configs
data "ct_config" "controller-ignitions" {
  count        = var.controller_count
  content      = data.template_file.controller-configs[count.index].rendered
  pretty_print = false
  snippets     = var.controller_clc_snippets
}

# Controller Container Linux configs
data "template_file" "controller-configs" {
  count = var.controller_count

  template = file("${path.module}/cl/controller.yaml.tmpl")

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = "${var.cluster_name}-etcd${count.index}.${var.dns_zone}"
    # etcd0=https://cluster-etcd0.example.com,etcd1=https://cluster-etcd1.example.com,...
    etcd_initial_cluster   = join(",", data.template_file.etcds.*.rendered)
    ssh_keys               = jsonencode(var.ssh_keys)
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    cluster_domain_suffix  = var.cluster_domain_suffix
  }
}

data "template_file" "etcds" {
  count    = var.controller_count
  template = "etcd$${index}=https://$${cluster_name}-etcd$${index}.$${dns_zone}:2380"

  vars = {
    index        = count.index
    cluster_name = var.cluster_name
    dns_zone     = var.dns_zone
  }
}
