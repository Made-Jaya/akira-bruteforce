# Akira-Bruteforce: Deployment and Running Guide

## System Requirements

### Hardware Requirements
- NVIDIA GPU with CUDA support
  - Minimum: 4GB VRAM (GTX 1650 tested and supported)
  - Recommended: 8GB+ VRAM for larger workloads
  - Tested GPUs: GTX 1650, RTX 3060, RTX 3080, RTX 4090
  - Note: For 4GB GPUs like GTX 1650, batch sizes may need adjustment
- CPU: Modern x86_64 processor
- RAM: 16GB minimum, 32GB recommended
- Storage: 100GB+ free space for data processing

### Software Requirements
- Operating System: Linux (Ubuntu 20.04 LTS or later recommended)
- NVIDIA Driver: 450.80.02 or later (tested with 535.183.06)
- CUDA Toolkit 11.0 or later (compatible with CUDA 12.2)
- GCC/G++ 7.5+
- CMake 3.10+
- Python 3.7+ (for testing)
- Nettle Cryptographic Libraries:
  - nettle-dev: Core development files
  - libnettle-dev: Required for nettle/yarrow.h
  - gnutls-dev: Additional crypto dependencies

## Installation

### 1. Environment Setup

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install basic dependencies
sudo apt install -y build-essential cmake python3 python3-pip nettle-dev libnettle-dev gnutls-dev

# Install NVIDIA driver (if not already installed)
sudo ubuntu-drivers autoinstall
sudo reboot  # Reboot after driver installation

# Verify NVIDIA installation
nvidia-smi
```

### 2. CUDA Installation

```bash
# Download CUDA (example for 11.8 - adjust version as needed)
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run

# Install CUDA
sudo sh cuda_11.8.0_520.61.05_linux.run
```

Add to ~/.bashrc:
```bash
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### 3. Project Setup

1. **Environment Preparation**
   ```bash
   # If using Anaconda, deactivate it to avoid CFLAGS conflicts
   conda deactivate
   
   # Verify you're using system compiler
   which gcc
   # Should show /usr/bin/gcc, not Anaconda path
   ```

2. **Clone Repository**
   ```bash
   # Clone repository
   git clone https://github.com/your-repo/akira-bruteforce.git
   cd akira-bruteforce
   ```

3. **Create Makefile**
   Create or update `Makefile` with the following content (important: ensure command lines start with a TAB character, not spaces):

   > **Option 1:** Manual creation - Copy the content below and ensure command lines start with TAB characters (use `cat -A Makefile` to verify, they should appear as ^I)
   >
   > **Option 2:** Automated creation - Run the following shell script:
   > ```bash
   > # Create Makefile generator script
   > cat > create_makefile.sh << 'EOF'
   > #!/bin/bash
   > # Ensure TAB characters are preserved
   > cat > Makefile << 'EOL'
   > # CUDA architecture setting
   > # Adjust CUDA_ARCH based on your GPU:
   > # - RTX 3060, 3070, 3080, 3090: sm_86
   > # - RTX 2060, 2070, 2080: sm_75
   > # - GTX 1660, 1660 Ti, GTX 1650: sm_75
   > # - GTX 1050, 1060, 1070, 1080: sm_61
   > CUDA_ARCH = sm_75
   > 
   > # Compiler flags
   > NVCC = nvcc
   > NVCC_FLAGS = --compiler-options -Wall -arch=$(CUDA_ARCH) -O3
   > CC = gcc
   > CFLAGS = -O3 -Wall
   > 
   > # Targets
   > all: akira-bruteforce decrypt
   > 
   > akira-bruteforce: akira-bruteforce.cu chacha8.c
   >	$(NVCC) $(NVCC_FLAGS) -o $@ $^
   > 
   > decrypt: decrypt.c chacha8.c kcipher2.c
   >	$(CC) $(CFLAGS) -static -o $@ $^ -lnettle -lhogweed
   > 
   > clean:
   >	rm -f akira-bruteforce decrypt *.o
   > EOL
   > EOF
   > 
   > # Make script executable and run it
   > chmod +x create_makefile.sh
   > ./create_makefile.sh
   > ```
   >
   > After creating the Makefile using either method, verify it was created correctly:
   > ```bash
   > # Check Makefile formatting
   > cat -A Makefile  # Should show TAB characters as ^I
   > 
   > # Verify Makefile content
   > grep -n "^[[:space:]]" Makefile  # Should show properly indented lines
   > ```

4. **Build Project**
   ```bash
   # Clean any previous builds
   make clean
   
   # Build the project
   make
   
   # Note: You may see format warnings in kcipher2.c - these are safe to ignore
   # The warnings about format strings and signedness don't affect functionality
   
   # If you encounter CUDA architecture errors, adjust CUDA_ARCH in Makefile
   # For example, for RTX 3060:
   # CUDA_ARCH = sm_86
   ```

5. **Verify Build**
   ```bash
   # Check CUDA capability of your GPU
   nvidia-smi --query-gpu=gpu_name,compute_cap --format=csv,noheader
   
   # Test the built executable
   ./akira-bruteforce --version
   ```

## Deployment

### Server Environment Setup

1. **GPU Server Configuration**
   ```bash
   # Set GPU fan control (if needed)
   sudo nvidia-xconfig -a --cool-bits=28
   sudo nvidia-settings -a "[gpu:0]/GPUFanControlState=1"
   sudo nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=70"
   
   # Set GPU persistence mode
   sudo nvidia-smi -pm 1
   
   # Optimize GPU settings
   sudo nvidia-smi -ac 3004,1590  # Adjust memory/GPU clocks as needed
   ```

2. **System Optimization**
   ```bash
   # Increase maximum open files
   echo "* soft nofile 1048576" | sudo tee -a /etc/security/limits.conf
   echo "* hard nofile 1048576" | sudo tee -a /etc/security/limits.conf
   
   # Optimize memory
   echo 'vm.swappiness = 10' | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

## Running the Tool

### Command Line Interface (CLI)

```bash
# General syntax
./akira-bruteforce <command> [options] [arguments]

# Available commands:

# Testing and Benchmarking:
random     - Generate random numbers from timestamp (CPU-based)
random-gpu - Generate random numbers using GPU (faster)
enc       - Test encryption performance and verify functionality
chacha8   - Benchmark ChaCha8 encryption speed

# Bruteforce Operations:
run       - Standard bruteforce mode using provided config
run2      - Optimized bruteforce with better GPU utilization
run3      - Offset-based bruteforce for distributed workloads
runchacha - ChaCha8-specific optimization for better performance

# Examples with all options:
./akira-bruteforce random <count>                    # Generate <count> random numbers
./akira-bruteforce random-gpu <count>                # Generate using GPU
./akira-bruteforce enc <count>                       # Encryption benchmark
./akira-bruteforce chacha8 <count>                   # ChaCha8 benchmark
./akira-bruteforce run <config.json> <gpu_index>     # Standard bruteforce
./akira-bruteforce run2 <config.json> <gpu_index>    # Optimized bruteforce
./akira-bruteforce run3 <config.json> <gpu_index>    # Offset-based bruteforce
./akira-bruteforce runchacha <config.json> <gpu_index>  # ChaCha8 bruteforce
```

### Basic Usage

1. **Generate Random Numbers**
   ```bash
   # From timestamp
   ./akira-bruteforce random 1000000
   
   # Using GPU
   ./akira-bruteforce random-gpu 1000000
   ```

2. **Test Encryption**
   ```bash
   # Test encryption performance
   ./akira-bruteforce enc 1000000
   
   # Test ChaCha8 speed
   ./akira-bruteforce chacha8 1000000
   ```

### Bruteforce Operations

> **Choosing the Right Mode:**
> - `run`: Basic mode, good for initial testing and smaller workloads
> - `run2`: Best for most cases, optimized GPU memory usage
> - `run3`: Use when distributing work across multiple machines
> - `runchacha`: Specialized for ChaCha8, fastest for this algorithm
>
> **Recommended Batch Sizes:**
> - 4GB VRAM (GTX 1650): Start with count=500000, adjust based on memory usage
> - 8GB VRAM: Safe to use count=1000000 or higher
> - 12GB+ VRAM: Can handle count=2000000+ for maximum performance
> Note: Monitor GPU memory with `nvidia-smi` and adjust count as needed

1. **Configuration Setup**
   Create a config file (e.g., `config.json`):
   ```json
   {
       "start_timestamp": 1739876543000000000,
       "count": 1000000,
       "offset": 5000,
       "brute_force_time_range": 10000,
       "matches": [
           {
               "plaintext": "0x0000000000000000",
               "encrypted": "0x1234567890ABCDEF",
               "bitmask": "0xFFFFFFFFFFFFFFFF",
               "filename": "target.bin"
           }
       ]
   }
   ```

2. **Running Bruteforce**
   ```bash
   # Standard bruteforce
   ./akira-bruteforce run config.json 0  # 0 is GPU index
   
   # Optimized bruteforce
   ./akira-bruteforce run2 config.json 0
   
   # Offset-based bruteforce
   ./akira-bruteforce run3 config.json 0
   ```

3. **ChaCha8 Specific**
   ```bash
   ./akira-bruteforce runchacha config.json 0
   ```

### Server Deployment Scripts

1. **Monitoring Script**
   ```bash
   #!/bin/bash
   # monitor.sh
   
   while true; do
       nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,utilization.memory --format=csv
       sleep 5
   done
   ```

2. **Auto-Recovery Script**
   ```bash
   #!/bin/bash
   # run_with_recovery.sh
   
   while true; do
       ./akira-bruteforce run2 config.json 0
       if [ $? -eq 0 ]; then
           echo "Process completed successfully"
           break
       else
           echo "Process failed, restarting in 30 seconds..."
           sleep 30
       fi
   done
   ```

### Production Deployment

1. **System Service Setup**
   Create `/etc/systemd/system/akira-bruteforce.service`:
   ```ini
   [Unit]
   Description=Akira Bruteforce Service
   After=network.target
   
   [Service]
   Type=simple
   User=your_user
   WorkingDirectory=/path/to/akira-bruteforce
   ExecStart=/path/to/run_with_recovery.sh
   Restart=always
   RestartSec=30
   
   [Install]
   WantedBy=multi-user.target
   ```

2. **Enable and Start Service**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable akira-bruteforce
   sudo systemctl start akira-bruteforce
   ```

3. **Monitoring Setup**
   ```bash
   # Log monitoring
   tail -f /var/log/syslog | grep akira-bruteforce
   
   # GPU monitoring
   watch -n 1 nvidia-smi
   ```

## Troubleshooting

### Common Issues

1. **Missing Headers**
   ```bash
   # If you see "nettle/yarrow.h: No such file or directory"
   sudo apt update
   sudo apt install -y nettle-dev libnettle-dev gnutls-dev
   
   # Verify header locations
   find /usr -name "yarrow.h"
   # Should show something like /usr/include/nettle/yarrow.h
   ```

2. **CUDA Errors**
   ```bash
   # Check CUDA version
   nvcc --version
   
   # Verify GPU compatibility
   nvidia-smi -L
   
   # Test CUDA installation
   cuda-install-samples-11.8.sh ~
   cd ~/NVIDIA_CUDA-11.8_Samples
   make
   ```

3. **Performance Issues**
   ```bash
   # Monitor GPU temperature and throttling
   nvidia-smi -l 1
   
   # Check system resources
   htop
   
   # Monitor disk I/O
   iostat -x 1
   ```

4. **Memory Issues**
   ```bash
   # Check GPU memory
   nvidia-smi --query-gpu=memory.used,memory.total --format=csv
   
   # Monitor system memory
   free -h
   ```

### Recovery Procedures

1. **GPU Reset**
   ```bash
   sudo nvidia-smi --gpu-reset
   ```

2. **Process Cleanup**
   ```bash
   # Kill hanging processes
   pkill -f akira-bruteforce
   
   # Remove temporary files
   rm -f *.tmp
   ```

3. **Service Reset**
   ```bash
   sudo systemctl restart akira-bruteforce
   ```

## Performance Optimization

### GPU Settings

1. **Power and Clock Settings**
   ```bash
   # Set maximum performance
   sudo nvidia-smi -pm 1
   sudo nvidia-smi -ac 3004,1590
   
   # Lock GPU clock (if supported)
   sudo nvidia-smi --lock-gpu-clocks=1590
   ```

2. **Memory Configuration**
   ```bash
   # Check current limits
   ulimit -a
   
   # Set memory limits
   ulimit -n 1048576
   
   # For GTX 1650 (4GB VRAM), monitor available memory
   nvidia-smi --query-gpu=memory.free,memory.total --format=csv
   
   # Consider closing other GPU applications
   # Desktop environment typically uses ~400MB VRAM
   ```

### Process Priority

```bash
# Run with high priority
nice -n -20 ./akira-bruteforce run2 config.json 0
```

### Multiple GPU Setup

When running on multiple GPUs:
```bash
# Run on GPU 0
./akira-bruteforce run2 config.json 0 &

# Run on GPU 1
./akira-bruteforce run2 config.json 1 &

# Monitor all GPUs
watch -n 1 'nvidia-smi'
```
