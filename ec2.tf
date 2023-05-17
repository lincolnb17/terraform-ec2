resource "tls_private_key" "instance_key" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}

resource "aws_key_pair" "instance_key_pair" {
  key_name   = "instance_key_pair"
  public_key = tls_private_key.instance_key.public_key_openssh
}

resource "aws_security_group" "TF_SG" {
  name        = "security group using Terraform"
  description = "security group using Terraform"
  vpc_id      = "vpc-246a5b5c"

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "TF_SG"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0fcf52bcf5db7b003"
  instance_type = "t2.micro"
  count=3
  key_name      = aws_key_pair.instance_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.TF_SG.id]
  tags={
    Name="Hello World"
  }
  
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.instance_key.private_key_pem
      host        = self.public_ip
    }

    inline = [
     "sudo apt update",
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt update",
      "sudo apt install -y docker-ce docker-ce-cli containerd.io",
      "sudo usermod -aG docker ubuntu"
    ]
  }
}
