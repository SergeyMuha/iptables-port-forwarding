provider "aws" {
  region     = "us-east-1"
}
resource "aws_internet_gateway" "gwmuhas" {
  vpc_id = "${aws_vpc.vpcmuhas.id}"

  tags {
    Name = "muhas"
  }
}
resource "aws_vpc" "vpcmuhas" {
  cidr_block       = "192.168.0.0/24"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags {
    Name = "muhas"
  }
}

resource "aws_subnet" "subnetmuhas" {
  availability_zone = "us-east-1a"
  vpc_id     = "${aws_vpc.vpcmuhas.id}"
  cidr_block = "192.168.0.0/26"
  map_public_ip_on_launch = "true"

  tags {
    Name = "public_muhas"
  }
}

resource "aws_subnet" "subnetmuhass" {
  availability_zone = "us-east-1b"
  vpc_id     = "${aws_vpc.vpcmuhas.id}"
  cidr_block = "192.168.0.64/26"

  tags {
    Name = "private_muhas"
  }
}


resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.vpcmuhas.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.muhas.id}"
}

resource "aws_vpc_dhcp_options" "muhas" {
  domain_name          = "ec2.muhas"
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags {
    Name = "muhas"
  }
}

resource "aws_default_route_table" "OutRouteMuhas" {
  default_route_table_id = "${aws_vpc.vpcmuhas.default_route_table_id}"

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gwmuhas.id}"
  }


  tags {
    Name = "public_muhas"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.vpcmuhas.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags {
    Name = "muhas_private"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.subnetmuhass.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_eip" "ip" {
  vpc      = true
  tags {
    Name = "muhas"
  }

}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.ip.id}"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  tags {
    Name = "muhas"
  }
}

resource "aws_default_security_group" "secgrmuhas" {
  vpc_id      = "${aws_vpc.vpcmuhas.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "muhas"
  }

}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.vpcmuhas.default_network_acl_id}"
  subnet_ids = ["${aws_subnet.subnetmuhas.id}"]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags {
    Name = "muhas"
  }
}

data "template_file" "route" {
  template = "${file("${path.module}/route.tpl")}"

  vars {
     ip = "${aws_instance.private.private_ip}"
  }
}


resource "aws_instance" "public" {
  count = 1
  ami           = "ami-38708b45"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  key_name      = "terraformwp"
  user_data = "${data.template_file.route.rendered}"

  provisioner "file" {
    source      = "~/.ssh/terraformwp.pem"
    destination = "~/.ssh/terraformwp.pem"
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("~/.ssh/terraformwp.pem")}"
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("~/.ssh/terraformwp.pem")}"
    }
    inline = [
      "chmod 400 ~/.ssh/terraformwp.pem",
    ]
  }

  tags {
    Name = "public_muha"
  }
}


data "template_file" "apache" {
  template = "${file("${path.module}/apache.tpl")}"

}

resource "aws_instance" "private" {
  count = 1
  ami           = "ami-38708b45"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnetmuhass.id}"
  key_name      = "terraformwp"
  user_data = "${data.template_file.apache.rendered}"


  tags {
    Name = "private_muha"
  }
} 


output "Route host" {
  value = "${aws_instance.public.public_dns}"
}

