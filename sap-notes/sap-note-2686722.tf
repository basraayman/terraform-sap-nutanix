# ============================================================================
# SAP Note 2686722 - SAP HANA virtualized on Nutanix AOS
# ============================================================================
#
# This file contains configuration guidelines from SAP Note 2686722
# for running SAP HANA virtualized on Nutanix AOS.
#
# Link: https://launchpad.support.sap.com/#/notes/2686722
#
# ============================================================================

locals {
  sap_note_2686722 = {
    note_number = "2686722"
    title       = "SAP HANA virtualized on Nutanix AOS"
    version     = "Latest"
    
    # ========================================================================
    # Virtualization Requirements
    # ========================================================================
    virtualization = {
      hypervisor          = "Nutanix AHV"
      min_aos_version     = "6.5"
      recommended_version = "6.10+"
      
      # CPU requirements
      cpu = {
        processor_families = [
          "Intel Xeon Cascade Lake",
          "Intel Xeon Ice Lake", 
          "Intel Xeon Sapphire Rapids",
          "Intel Xeon Emerald Rapids"
        ]
        
        # vCPU configuration
        vcpu_overcommit = "Not recommended for production"
        vcpu_reservation = "100% CPU reservation required"
        
        # NUMA configuration
        numa_enabled = true
        numa_required_above_gb = 256
        
        # CPU pinning
        cpu_pinning_recommended = true
        cpu_pinning_note = "Use acli for advanced CPU configuration"
      }
      
      # Memory requirements
      memory = {
        memory_reservation = "100% memory reservation required"
        memory_overcommit = "Not allowed for SAP HANA"
        transparent_hugepages = "Allowed with SLES 15 SP5 or newer"
        
        # Memory hot-add
        memory_hotplug = "Not recommended for production"
      }
      
      # Storage requirements
      storage = {
        storage_protocol = "Nutanix native (not NFS/iSCSI)"
        thin_provisioning = false
        compression = "Allowed (Nutanix handles)"
        deduplication = "Allowed (Nutanix handles)"
        
        # Disk modes
        disk_mode = "SCSI"
        cache_mode = "Write-through or Write-back"
      }
      
      # Network requirements
      network = {
        min_bandwidth_gbps = 10
        recommended_bandwidth_gbps = 25
        jumbo_frames = true
        mtu_size = 9000
        
        # Network adapter
        adapter_type = "VMXNET3 or virtio"
      }
    }
    
    # ========================================================================
    # Advanced CPU Configuration via ACLI
    # ========================================================================
    acli_configuration = {
      # Note: These settings are not available via Terraform provider
      # Must be configured post-deployment using acli commands
      
      commands = {
        # Configure threads per core (1 for no HT, 2 for HT enabled)
        threads_per_core = "acli vm.update <vm_name> num_threads_per_core=<1 or 2>"
        
        # Configure vNUMA and CPU topology
        vcpu_topology = "acli vm.update <vm_name> num_vcpus=<sockets> num_vnuma_nodes=<nodes> num_cores_per_vcpu=<cores> vcpu_hard_pin=<True|False>"
        
        # Example for 64 vCPU system with 2 NUMA nodes
        example_64vcpu = "acli vm.update hana-vm num_vcpus=2 num_vnuma_nodes=2 num_cores_per_vcpu=32 vcpu_hard_pin=True num_threads_per_core=1"
        
        # Example for 32 vCPU system with 1 NUMA node
        example_32vcpu = "acli vm.update hana-vm num_vcpus=1 num_vnuma_nodes=1 num_cores_per_vcpu=32 vcpu_hard_pin=True num_threads_per_core=1"
      }
      
      # Best practices
      best_practices = {
        hyperthreading = "Disable for SAP HANA (num_threads_per_core=1)"
        cpu_pinning = "Enable for production (vcpu_hard_pin=True)"
        numa_nodes = "Match physical NUMA topology when possible"
        cores_per_vcpu = "Distribute evenly across sockets"
      }
      
      # NUMA recommendations by memory size
      numa_recommendations = {
        "64-256"    = { sockets = 1, numa_nodes = 1, cores_per_socket = "all" }
        "257-512"   = { sockets = 2, numa_nodes = 2, cores_per_socket = "all" }
        "513-1024"  = { sockets = 2, numa_nodes = 2, cores_per_socket = "all" }
        "1025-2048" = { sockets = 2, numa_nodes = 2, cores_per_socket = "all" }
      }
    }
    
    # ========================================================================
    # VM Hardware Version
    # ========================================================================
    vm_hardware = {
      vm_generation = "Latest supported by AOS"
      scsi_controller = "LSI Logic Parallel"
      network_adapter = "VMXNET3"
    }
    
    # ========================================================================
    # Performance Tuning
    # ========================================================================
    performance_tuning = {
      # CPU settings
      cpu = {
        cpu_reservation = "100%"
        cpu_limit = "Unlimited"
        cpu_shares = "High"
      }
      
      # Memory settings
      memory = {
        memory_reservation = "100%"
        memory_limit = "Equal to allocated"
        memory_shares = "High"
      }
      
      # Disk settings
      disk = {
        io_throttling = "Disabled"
        cache_policy = "Write-back"
      }
    }
    
    # ========================================================================
    # Monitoring and Management
    # ========================================================================
    monitoring = {
      vmware_tools = "Not applicable (AHV)"
      nutanix_guest_tools = "Required"
      
      metrics_to_monitor = [
        "CPU utilization",
        "Memory utilization",
        "Disk latency",
        "Network throughput",
        "Storage IOPS"
      ]
    }
    
    # ========================================================================
    # Supported Configurations
    # ========================================================================
    supported_configs = {
      single_node = true
      scale_out = true
      system_replication = true
      dynamic_tiering = true
      
      # Sizing limits
      max_memory_gb = 12288  # 12 TB
      max_vcpus = 256
      min_memory_gb = 64
      min_vcpus = 4
    }
  }
}

# ============================================================================
# Post-Deployment Configuration Notes
# ============================================================================

locals {
  post_deployment_notes = {
    title = "Post-Deployment CPU Configuration Required"
    
    note = <<-EOT
      The Nutanix Terraform provider does not currently support advanced CPU 
      configuration options like vNUMA, CPU pinning, and threads per core.
      
      After VM deployment, run these acli commands on the Nutanix CVM:
      
      1. Disable Hyper-Threading (recommended for SAP HANA):
         acli vm.update <vm_name> num_threads_per_core=1
      
      2. Configure vNUMA and CPU pinning:
         acli vm.update <vm_name> num_vcpus=<sockets> \
           num_vnuma_nodes=<numa_nodes> \
           num_cores_per_vcpu=<cores> \
           vcpu_hard_pin=True
      
      Example for a 64 vCPU system with 2 NUMA nodes:
         acli vm.update hana-prod num_vcpus=2 \
           num_vnuma_nodes=2 \
           num_cores_per_vcpu=32 \
           vcpu_hard_pin=True \
           num_threads_per_core=1
      
      Note: VM must be powered off for these changes.
    EOT
    
    automation = <<-EOT
      To automate this configuration, you can:
      1. Use Terraform null_resource with local-exec provisioner
      2. Use Ansible post-deployment playbook
      3. Create a custom script that runs after terraform apply
      4. Use Nutanix Calm for advanced orchestration
    EOT
  }
}

# ============================================================================
# Validation
# ============================================================================

locals {
  validate_2686722 = {
    # Memory must be >= 64 GB
    memory_sufficient = var.memory_gb >= local.sap_note_2686722.supported_configs.min_memory_gb
    
    # vCPUs must be >= 4
    vcpu_sufficient = var.num_vcpus >= local.sap_note_2686722.supported_configs.min_vcpus
    
    # Check NUMA requirement
    numa_required = var.memory_gb > local.sap_note_2686722.virtualization.cpu.numa_required_above_gb
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "sap_note_2686722_info" {
  description = "SAP Note 2686722 virtualization requirements"
  value = {
    note_number = local.sap_note_2686722.note_number
    title       = local.sap_note_2686722.title
    
    post_deployment_required = true
    post_deployment_note     = local.post_deployment_notes.note
    
    numa_required = local.validate_2686722.numa_required
    
    recommended_numa_config = local.validate_2686722.numa_required ? (
      var.memory_gb <= 512 ? 
        local.sap_note_2686722.acli_configuration.numa_recommendations["257-512"] :
        local.sap_note_2686722.acli_configuration.numa_recommendations["513-1024"]
    ) : null
  }
}

