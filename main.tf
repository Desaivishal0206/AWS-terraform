resource "aws_key_pair" "deployer" {
    key_name   = "key-for-demo"  # Replace with your desired key name
    public_key = "addyourpublickey"
}
resource "aws_vpc" "my_vpc" {
    cidr_block = var.cidr
  
}

resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
  
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id
  
}

resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block ="0.0.0.0/0"
        gateway_id= aws_internet_gateway.igw.id
    }
  
}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.RT.id
  
}

resource "aws_security_group" "sg" {

    name = "web"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        description = "HTTP from VPC"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
    Name = "Web-sg"
  }
  
}

resource "aws_instance" "instance-terraform" {

    ami = "ami-03f4878755434977f"
    instance_type = "t2.micro"
    key_name = aws_key_pair.deployer.key_name
    subnet_id = aws_subnet.sub1.id
    vpc_security_group_ids = [ aws_security_group.sg.id ]

    connection {
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = file("/key-for-demo")  # Replace with the path to your private key
    host        = self.public_ip
    }

    provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
    }

    provisioner "remote-exec" {
        inline = [
        "echo 'Hello from the remote instance'",
        "sudo apt update -y",  # Update package lists (for ubuntu)
        "sudo apt-get install -y python3-pip",  # Example package installation
        "cd /home/ubuntu",
        "sudo pip3 install flask",
        "sudo python3 app.py &",
        ]
    }


  
}

