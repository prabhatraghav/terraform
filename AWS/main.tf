# ***************************** ENVIRONMENT VARIABLES EDITING : BEGINS *************************************************

# Define Environmental Variables
variable "aws_access_key" { default = "PASTE YOUR AWS A/c ACCESS-KEY" }                     # AWS a/c access-key-ID (Change this with your keys)
variable "aws_secret_key" { default = "PASTE YOUR AWS A/c SECERT-KEY" } # AWS a/c secret-access-key (Change this with your keys)
variable "security_group_id" { default = "PASTE SECURITY-GROUP-ID" }                  # Specify your security group ID to access all the ports defined in the security group
variable "region" { default = "eu-north-1" }                                       # Specify the AWS region where you want to create the resources
variable "instance_name" { default = "my-server" }                                 # Declare the name of the EC2 instance
variable "instance_type" { default = "t3.micro" }                                  # Declare the machine type of the EC2 instance
variable "instance_count" { default = 1 }                                          # Declare the number of EC2 instances to be created
variable "disk_size_gb" { default = 8 }                                            # Declare the disk size in gigabytes for the EC2 instance
variable "ami" { default = "ami-0014ce3e52359afbd" }                               # (Default AMI - Ubuntu 22.04 LTS) - Specify the AMI ID for the EC2 instance

# Use this command to generate New Key Pair
# <ssh-keygen -t rsa -f ~/.ssh/<KEY_FILENAME> -C <USERNAME> -b 2048>
# (Pls, replace <KEY_FILENAME> with KEY-NAME.pem and <USERNAME> with your Ubuntu username)

# Paste your default SSH public-key here
variable "ssh_public_key" { default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDeRVhxyftAwznVcaKphE4ncqsch/W6ykZeE6uIUOETGhPlA0PovwW6hDBSdFvjtHeRRmnW01Nn74S6CaEBXRCzg+nm6fO5ePQa82jVyTW+KZdrsVex7/nWj8nfJvedIN+kj0JWVTFekTA5NIQmhyHYyBqCnbCwt4Bi9t2IKCrcqN4ZH5G5HXdoN7NtLdt/Xwqne41PrlFsM12tRvbecEg+rtOR96PR9ZePNw+h1tUyD2khf3z86sGsoH6ag8Vl5O5IBkcZWvRXS1a7S4DkL4jr5lhbFizuEgXpzg4TKR/rsiiGXYybfvAJuIdXukmErd850kBllI75t4Aj28A9D0pF root" }
variable "ssh_private_key" { default = "AWS_PRIVATE_KEY.pem" } 						# Path to the SSH private key file (Please copy the *.pem file to the terraform dir)
variable "ssh_username" { default = "ubuntu" } 										# Specify the username for ssh connection command
variable "ssh_key_name" { default = "my-ubuntu-key" }

# Declare Shell Script details (to run at the time of EC2 instance creation /or to run after the EC2 instance launched successfully)
variable "sh_script_path" { default = "/home" } 									# (example for path - "/home/user")
#variable "sh_script_name" { default = "/apache2-install.sh" }  					# (example for path - "/script-name.sh")
#variable "sh_script_url" { default = "https://raw.githubusercontent.com/prabhatraghav/html_test_page-repo/main/apache2-install.sh" }
variable "sh_script_name" { default = "/tomcat-install.sh" } 						# (example for path - "/script-name.sh")
variable "sh_script_url" { default = "https://raw.githubusercontent.com/prabhatraghav/tomcat-install/main/tomcat-install.sh" }


# *********************************************** EDITING : ENDS HERE *****************************************************


# Define provider
provider "aws" {
  region     = var.region # Specify the AWS region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


# Create EC2 key pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}


# Create EC2 instance
resource "aws_instance" "ec2_instance" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name = "${var.instance_name}-${count.index}"
  }

  # Block Device Mapping for EBS volume
  root_block_device {
    volume_size = var.disk_size_gb
  }

  # SSH key for instance access
  key_name = aws_key_pair.my_key_pair.key_name

  # Security group for SSH access
  vpc_security_group_ids = [var.security_group_id]

  # User data for custom initialization of scripts/commands at the time of EC2 instance creation
  #user_data = <<-EOF
  #  #!/bin/bash
  #  sudo apt update -y
  #  sudo apt install apache2 openjdk-17-jdk -y
  #  sudo service apache2 start
  #  cd /var/www/html
  #  sudo echo "<html><h1>Hello, World! This webpage belongs to Raghav....</h1><a href="https://youtu.be/zqGW6x_5N0k">ANIMAL: ARJAN VAILLY | Ranbir Kapoor | Sandeep Vanga | Bhupinder B, Manan B | Bhushan K</a></html>" > index.html
  #  cd /home
  #  sudo wget ${var.sh_script_url}
  #  sudo chmod +x ${var.sh_script_path}${var.sh_script_name}
  #  sh ${var.sh_script_path}${var.sh_script_name}
  #  rm -r ${var.sh_script_path}${var.sh_script_name}
  #EOF


  # Define a provisioner to execute commands on the EC2 instance after it's launched
  provisioner "remote-exec" {

    # Connection configuration for SSH connection to the EC2 instance
    connection {
      type        = "ssh"                     # Specify the type of connection, which is SSH in this case
      user        = var.ssh_username          # Specify the username used for SSH authentication
      private_key = file(var.ssh_private_key) # Specify the path to the private key file used for SSH authentication
      host        = self.public_ip            # Specify the public IP address of the EC2 instance to connect to
    }

    # Commands to be executed on the EC2 instance after it's launched
    inline = [
      #    "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      #    "sudo systemctl restart sshd"
      "sudo apt update -y",
      #"sudo apt install apache2 -y",
      #"sudo service apache2 start",
      "cd ${var.sh_script_path}",
      "sudo wget ${var.sh_script_url}",
      "sudo chmod +x ${var.sh_script_path}${var.sh_script_name}",
      "sudo sh ${var.sh_script_path}${var.sh_script_name}"
    ]
  }

}


# Output EC2 instance public IP addresses
output "ec2_instance_public_ips" {
  value = aws_instance.ec2_instance[*].public_ip
}


# Output EC2 instance SSH commands
output "ec2_instance_ssh_commands" {
  value = [
    for idx, instance in aws_instance.ec2_instance :
    "ssh -i ${var.ssh_private_key} ${var.ssh_username}@${instance.public_ip}"
  ]
}