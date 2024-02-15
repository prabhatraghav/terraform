# Terraform file for Google-Cloud-Platform (Put PEM file, CREDENTIALS file in the same dir with the MAIN file)


# *********************************************** BEGINS: EDITING ENVIRONMENT VARIABLES *************************************************

# Define Environmental Variables
variable "credentials_file" { default = "PATH/OF/YOUR/FILENAME.json" }                # Copy the the service account CREDENTIALS-FILE in the same folder with MAIN-FILE
variable "project_id" { default = "scenic-dynamo-xxxxx" }                             # Paste your Google Cloud PROJECT-ID
variable "region" { default = "us-west4" }                                            # Declare the default region where you want to create your resources (Las Vegas - us-west4 is the cheapest one)
variable "zone" { default = "us-west4-a" }                                            # Declare the default zone for the virtual machine (You can choose anyone from a, b and c availability zone.)
variable "vm_name" { default = "my-server" }                                          # Declare the name of the VM/Instance
variable "machine_type" { default = "e2-small" }                                      # Declare the default machine type of the VM/Instance (e2-micro is the cheapest machine, you can also choose from e2-small and e2-medium)
variable "vm_count" { default = 1 }                                                   # Declare the default No. of VM instances to be created
variable "disk_size_gb" { default = 10 }                                              # Declare the default disk size in gigabytes for the VM
variable "provisioningModel" { default = "SPOT" }                                     # Default provisioning model (Choose "SPOT" or "STANDARD") for the VM (SPOT is cheaper than STANDARD)
variable "network_tags" { default = ["Paste your TAG-1", "Paste your TAG-2"] }        # Default network tags for the virtual machine (Please create TAGS in GCP firewall policy)
variable "ssh_public_key" { default = "Paste SSH public-key" }                        # Paste your default SSH public-key here (Single PUBLIC-KEY can be used on multiple VMs/Instances)
variable "ssh_private_key" { default = "PRIVATE_KEY.pem" }                            # Copy the SSH Private key file PEM-File in the same folder with MAIN terraform file
variable "ssh_username" { default = "techomaniac83" }                                 # Mention the default username of your GCP a/c for use with the SSH command

# Select OS image for the virtual machine (only uncomment one OS-image at a time)
variable "image" { default = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240208" }              # Ubuntu 22.04 LTS (Please set 10 GB disk space - required minimum)
#variable "image" { default = "projects/debian-cloud/global/images/debian-12-bookworm-v20240110" }               # Debian GNU / Linux-12 (Bookworm) (Please set 10 GB disk space - required minimum)
#variable "image" { default = "projects/centos-cloud/global/images/centos-7-v20240110" }                         # CentOS 7 (Please set 20 GB disk space - required minimum)
#variable "image" { default = "projects/rocky-linux-cloud/global/images/rocky-linux-9-optimized-gcp-v20240111" } # Rocky Linux 9 (Please set 20 GB disk space - required minimum)

# Declare Shell Script details (to run at the time of EC2 instance creation /or to run after the EC2 instance launched successfully)
variable "sh_script_path" { default = "/home" }                                                                                        # (eg. for path - "/PATH/OF/THE/DIR") DIR in which you want to download the SCRIPT file 
variable "sh_script_name" { default = "/tomcat-install.sh" }                                                                           # (eg. for file name - "/script-name.sh")
variable "sh_script_url" { default = "https://raw.githubusercontent.com/prabhatraghav/tomcat-install/main/tomcat-install.sh" }         # Paste the Github url of the file
#variable "sh_script_name-2" { default = "/apache2-install.sh" }                                                                        # (eg. for file name - "/script-name.sh")
#variable "sh_script_url-2" { default = "https://raw.githubusercontent.com/prabhatraghav/html_test_page-repo/main/apache2-install.sh" } # Paste the Github url of the file

# ********************************************* ENDS: EDITING ENVIRONMENT VARIABLES **********************************************

# MAIN CODE STARTS FROM HERE ONLY

# Define provider
provider "google" {
  credentials = file(var.credentials_file) # Use the service account credentials file for authentication
  project     = var.project_id             # Specify the Google Cloud project ID
  region      = var.region                 # Specify the region where resources will be created
}

# Create VM instance
resource "google_compute_instance" "vm_instance_1" {
  count        = var.vm_count                    # No. of VM instances to be created
  name         = "${var.vm_name}-${count.index}" # Name of the virtual machine instance
  machine_type = var.machine_type                # Type of machine to be used for the virtual machine
  scheduling {
    # Specify the provisioning model for the virtual machine
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
    preemptible         = true
    provisioning_model  = var.provisioningModel
  }
  zone = var.zone # Zone where the virtual machine will be located

  network_interface {
    network = "default" # Default network to connect the virtual machine to
    access_config {
      # External IP address will be assigned automatically
    }
  }
  tags = var.network_tags # Network tags for the virtual machine

  boot_disk {                  # Configuration for the boot disk of the virtual machine
    initialize_params {        # Parameters for initializing the boot disk
      image = var.image        # Image to be used for the operating system of the virtual machine
      size  = var.disk_size_gb # Size of the boot disk in gigabytes
    }
  }

  metadata = {
    "ssh-keys" = "${var.ssh_username}:${var.ssh_public_key}" # SSH key metadata with customizable username
  }

  #metadata_startup_script = <<-EOF
    !/bin/bash
    # Add your bash commands or scripts here
    cd ${var.sh_script_path}
    sudo wget ${var.sh_script_url}
    sudo chmod +x ${var.sh_script_path}${var.sh_script_name}
    sudo sh ${var.sh_script_path}${var.sh_script_name}
    #echo "Hello, World!" >> /tmp/hello.txt
    # Example of running a script stored in Google Cloud Storage
    #gsutil cp gs://your-bucket-name/your-script.sh /tmp/your-script.sh
    #sudo chmod +x /tmp/test_script.sh
    #sudo sh /tmp/test_script.sh
  #EOF

}

# Fetch assigned IP of the VM instance
data "google_compute_instance" "vm_instance_data" {
  count      = var.vm_count
  name       = "${var.vm_name}-${count.index}" # Name of the virtual machine instances
  project    = var.project_id                  # Google Cloud project ID
  zone       = var.zone                        # Zone where the virtual machines are located
  depends_on = [google_compute_instance.vm_instance_1]
}

# Output VM instance IP address "vm_instance_ip"
output "vm_instance_ip" {
  value = [for instance in google_compute_instance.vm_instance_1 : instance.network_interface.0.access_config.0.nat_ip]
}

# Output VM instance name and IP address
output "vm_instance_ssh_command" {
  value = [
    for idx, instance in data.google_compute_instance.vm_instance_data :
    "ssh -i ${var.ssh_private_key} ${var.ssh_username}@${instance.network_interface.0.access_config.0.nat_ip}"
  ]
}
