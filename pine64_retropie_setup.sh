#!/bin/bash

# Pine A64 RetroPie Installation Script for Armbian
# Addresses graphics (Lima/Mali-400MP2) and audio issues specific to Pine A64
# Based on RetroPie installation methodology

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running on Pine A64
check_hardware() {
    log "Checking hardware compatibility..."
    
    if ! grep -q "sun50i-a64" /proc/device-tree/compatible 2>/dev/null; then
        if ! grep -q "Pine A64" /proc/cpuinfo 2>/dev/null; then
            error "This script is designed for Pine A64 hardware"
            exit 1
        fi
    fi
    
    log "Pine A64 hardware detected"
}

# Check if running on Armbian
check_armbian() {
    log "Checking Armbian distribution..."
    
    if ! grep -q "armbian" /etc/os-release 2>/dev/null; then
        error "This script requires Armbian OS"
        exit 1
    fi
    
    log "Armbian detected"
}

# Update system and install base packages
update_system() {
    log "Updating system packages..."
    
    sudo apt update
    sudo apt upgrade -y
    
    log "Installing base development tools..."
    sudo apt install -y \
        build-essential \
        cmake \
        git \
        pkg-config \
        wget \
        curl \
        unzip \
        xmlstarlet \
        python3-dev \
        python3-pip \
        libfreeimage-dev \
        libfreetype6-dev \
        libcurl4-openssl-dev \
        rapidjson-dev \
        libasound2-dev \
        libpulse-dev \
        libopenal-dev \
        libpng-dev \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libswscale-dev \
        libswresample-dev
}

# Configure Mali-400MP2 GPU with Lima drivers
setup_gpu() {
    log "Configuring Mali-400MP2 GPU with Lima drivers..."
    
    # Install Mesa with Lima support
    sudo apt install -y \
        mesa-utils \
        mesa-vulkan-drivers \
        libgl1-mesa-dri \
        libgles2-mesa \
        libegl1-mesa \
        libgles2-mesa-dev \
        libegl1-mesa-dev
    
    # Configure GPU memory split
    info "Configuring GPU memory allocation..."
    
    # Add GPU memory configuration to armbianEnv.txt
    sudo tee -a /boot/armbianEnv.txt << EOF

# GPU Configuration for Gaming
cma=128M
extraargs=mem=1024M
EOF
    
    # Create Lima GPU configuration
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/01-lima.conf << EOF
Section "Device"
    Identifier "Lima"
    Driver "modesetting"
    Option "AccelMethod" "glamor"
    Option "DRI" "3"
EndSection
EOF
    
    log "GPU configuration completed"
}

# Configure audio for Pine A64
setup_audio() {
    log "Configuring audio for Pine A64..."
    
    # Install audio packages
    sudo apt install -y \
        alsa-utils \
        pulseaudio \
        pulseaudio-utils \
        pavucontrol
    
    # Configure ALSA for Pine A64's audio codec
    sudo tee /etc/asound.conf << EOF
pcm.!default {
    type pulse
}
ctl.!default {
    type pulse
}

# Pine A64 specific audio configuration
pcm.pine64 {
    type hw
    card 0
    device 0
}

ctl.pine64 {
    type hw
    card 0
}
EOF
    
    # Configure PulseAudio for low latency gaming
    sudo mkdir -p /etc/pulse/daemon.conf.d
    sudo tee /etc/pulse/daemon.conf.d/gaming.conf << EOF
# Low latency configuration for gaming
default-sample-format = s16le
default-sample-rate = 44100
alternate-sample-rate = 48000
default-sample-channels = 2
default-fragments = 2
default-fragment-size-msec = 5
resample-method = speex-float-1
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 9
rlimit-rtprio = 9
daemonize = no
EOF
    
    # Enable audio services
    sudo systemctl --global enable pulseaudio.service pulseaudio.socket
    
    log "Audio configuration completed"
}

# Install EmulationStation
install_emulationstation() {
    log "Installing EmulationStation..."
    
    # Install dependencies
    sudo apt install -y \
        libsdl2-dev \
        vlc \
        libvlc-bin \
        libvlc-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        libboost-date-time-dev \
        libboost-locale-dev \
        libfreeimage-dev \
        libfreetype6-dev \
        libeigen3-dev \
        libcurl4-openssl-dev \
        libasound2-dev \
        libgl1-mesa-dev \
        libgles2-mesa-dev
    
    # Clone and build EmulationStation
    cd /tmp
    git clone --recursive https://github.com/RetroPie/EmulationStation.git
    cd EmulationStation
    
    # Configure build for ARM64 with GPU acceleration
    mkdir build
    cd build
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-O3 -mcpu=cortex-a53 -mtune=cortex-a53" \
        -DGLES=ON \
        -DGL=OFF
    
    make -j$(nproc)
    sudo make install
    
    # Create EmulationStation directories
    mkdir -p /home/$USER/.emulationstation/{themes,downloaded_images}
    mkdir -p /home/$USER/RetroPie/{roms,BIOS,configs}
    
    log "EmulationStation installation completed"
}

# Install RetroArch with optimized configuration
install_retroarch() {
    log "Installing RetroArch..."
    
    # Install RetroArch from repository (usually more stable)
    sudo apt install -y retroarch retroarch-assets
    
    # Configure RetroArch for Pine A64
    mkdir -p /home/$USER/.config/retroarch
    
    # Create optimized RetroArch configuration
    tee /home/$USER/.config/retroarch/retroarch.cfg << EOF
# Pine A64 Optimized RetroArch Configuration

# Video settings optimized for Mali-400MP2
video_driver = "gl"
video_context_driver = "kms"
video_threaded = true
video_vsync = true
video_hard_sync = false
video_frame_delay = 0
video_gpu_screenshot = true

# Audio settings for low latency
audio_driver = "pulse"
audio_latency = 64
audio_block_frames = 0
audio_device = ""

# Input settings
input_driver = "udev"
input_autodetect_enable = true

# Performance settings
video_smooth = false
video_bilinear_filtering = false
video_scale_integer = true
video_crop_overscan = true

# Menu settings
menu_driver = "xmb"
menu_linear_filter = false

# Core settings
auto_overrides_enable = true
auto_remaps_enable = true
save_file_compression = true
savestate_compression = true

# Logging
log_verbosity = false
frontend_log_level = 1
EOF
    
    # Set proper ownership
    chown -R $USER:$USER /home/$USER/.config/retroarch
    chown -R $USER:$USER /home/$USER/RetroPie
    
    log "RetroArch installation completed"
}

# Emulators will be installed from source via RetroPie

# Create startup scripts and desktop entries
create_startup_scripts() {
    log "Creating startup scripts..."
    
    # Create EmulationStation launcher
    sudo tee /usr/local/bin/emulationstation-launcher << 'EOF'
#!/bin/bash

# Set GPU governor for gaming performance
echo performance | sudo tee /sys/devices/platform/1c20000.gpu/devfreq/1c20000.gpu/governor

# Set CPU governor for gaming performance  
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Start EmulationStation
cd /home/$USER
emulationstation
EOF
    
    sudo chmod +x /usr/local/bin/emulationstation-launcher
    
    # Create desktop entry
    tee /home/$USER/Desktop/EmulationStation.desktop << EOF
[Desktop Entry]
Name=EmulationStation
Comment=Retro Gaming Frontend
Exec=/usr/local/bin/emulationstation-launcher
Icon=emulationstation
Terminal=false
Type=Application
Categories=Game;
EOF
    
    chmod +x /home/$USER/Desktop/EmulationStation.desktop
    
    log "Startup scripts created"
}

# Configure services and optimizations
configure_system() {
    log "Configuring system optimizations..."
    
    # Create systemd service for performance tuning
    sudo tee /etc/systemd/system/pine64-gaming.service << EOF
[Unit]
Description=Pine A64 Gaming Optimizations
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo performance > /sys/devices/platform/1c20000.gpu/devfreq/1c20000.gpu/governor || true'
ExecStart=/bin/bash -c 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor || true'
ExecStart=/bin/bash -c 'echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor || true'
ExecStart=/bin/bash -c 'echo performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor || true'
ExecStart=/bin/bash -c 'echo performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable pine64-gaming.service
    
    # Configure tmpfs for better performance
    echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0" | sudo tee -a /etc/fstab
    
    log "System optimizations configured"
}

# Main installation function
main() {
    log "Starting Pine A64 RetroPie installation..."
    
    check_hardware
    check_armbian
    update_system
    setup_gpu
    setup_audio
    install_emulationstation
    install_retroarch
    create_startup_scripts
    configure_system
    
    log "Installation completed successfully!"
    info "Please reboot your system to apply all changes"
    info "After reboot, launch by running: emulationstation-launcher"
    warning "Remember to copy ROMs to /home/$USER/RetroPie/roms/ and BIOS files to /home/$USER/RetroPie/BIOS/"
}

# Run main function
main "$@"
