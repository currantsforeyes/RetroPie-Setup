#!/bin/bash
# Pine A64 RetroPie GPU Optimization Script
# Applies only graphics optimizations, leaves audio untouched

set -e
echo "Pine A64 GPU Optimization Script for RetroPie"
echo "=============================================="

# Check if running as root for some operations
if [[ $EUID -eq 0 ]]; then
    echo "Error: Don't run this script as root. It will ask for sudo when needed."
    exit 1
fi

# Phase 1: CPU/GPU Performance Governors
echo "Phase 1: Setting up performance governors..."

# Create systemd service for performance mode
sudo tee /etc/systemd/system/pine-performance.service > /dev/null << 'EOF'
[Unit]
Description=Pine A64 Performance Mode
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor; echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor; echo performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor; echo performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor'
ExecStart=/bin/bash -c 'echo performance > /sys/devices/platform/soc/1c40000.gpu/devfreq/1c40000.gpu/governor'

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable pine-performance.service
sudo systemctl start pine-performance.service

echo "✓ Performance governors configured"

# Phase 2: CMA Memory Allocation
echo "Phase 2: Configuring CMA memory allocation..."

# Backup original armbianEnv.txt
sudo cp /boot/armbianEnv.txt /boot/armbianEnv.txt.backup

# Add or update cma parameter
if grep -q "^cma=" /boot/armbianEnv.txt; then
    sudo sed -i 's/^cma=.*/cma=128M/' /boot/armbianEnv.txt
else
    echo "cma=128M" | sudo tee -a /boot/armbianEnv.txt
fi

echo "✓ CMA allocation set to 128MB"

# Phase 3: RetroArch Mali-400MP2 Configuration
echo "Phase 3: Configuring RetroArch for Mali-400MP2..."

RETROARCH_CONFIG="/opt/retropie/configs/all/retroarch.cfg"

# Create backup
if [ -f "$RETROARCH_CONFIG" ]; then
    sudo cp "$RETROARCH_CONFIG" "$RETROARCH_CONFIG.backup"
fi

# Apply Mali-400MP2 optimizations to RetroArch
sudo tee -a "$RETROARCH_CONFIG" > /dev/null << 'EOF'

# Pine A64 Mali-400MP2 Optimizations
video_driver = "gl"
video_context_driver = "kms" 
video_force_aspect = false
video_threaded = true
EOF

echo "✓ RetroArch configured for Mali-400MP2"

# Phase 4: N64-specific RetroArch optimizations
echo "Phase 4: N64-specific optimizations..."

N64_RETROARCH_CONFIG="/opt/retropie/configs/n64/retroarch.cfg"

# Create N64 config directory if it doesn't exist
sudo mkdir -p /opt/retropie/configs/n64/

# Create backup if exists
if [ -f "$N64_RETROARCH_CONFIG" ]; then
    sudo cp "$N64_RETROARCH_CONFIG" "$N64_RETROARCH_CONFIG.backup"
fi

# Apply N64-specific settings
sudo tee "$N64_RETROARCH_CONFIG" > /dev/null << 'EOF'
# N64 Mali-400MP2 Optimizations
video_driver = "gl"
video_context_driver = "kms"
video_force_aspect = false
video_threaded = true
video_frame_delay = 0
EOF

echo "✓ N64 RetroArch configuration applied"

# Phase 5: Verify GPU driver and frequency
echo "Phase 5: GPU status verification..."

echo -n "Lima driver status: "
if lsmod | grep -q lima; then
    echo "✓ Loaded"
else
    echo "⚠ Not loaded - ensure Lima drivers are installed"
fi

echo -n "GPU frequency: "
if [ -f /sys/devices/platform/soc/1c40000.gpu/devfreq/1c40000.gpu/cur_freq ]; then
    FREQ=$(cat /sys/devices/platform/soc/1c40000.gpu/devfreq/1c40000.gpu/cur_freq)
    echo "${FREQ} Hz"
else
    echo "⚠ Cannot read GPU frequency"
fi

echo -n "GPU governor: "
if [ -f /sys/devices/platform/soc/1c40000.gpu/devfreq/1c40000.gpu/governor ]; then
    GOV=$(cat /sys/devices/platform/soc/1c40000.gpu/devfreq/1c40000.gpu/governor)
    echo "$GOV"
else
    echo "⚠ Cannot read GPU governor"
fi

# Summary
echo ""
echo "=============================================="
echo "Pine A64 GPU Optimization Complete!"
echo "=============================================="
echo ""
echo "Applied optimizations:"
echo "• CPU/GPU performance governors (via systemd service)"
echo "• 128MB CMA memory allocation" 
echo "• RetroArch Mali-400MP2 configuration"
echo "• N64-specific optimizations"
echo ""
echo "Next steps:"
echo "1. Reboot the system: sudo reboot"
echo "2. Install RetroPie games and test"
echo "3. Audio configuration left unchanged for stability"
echo ""
echo "Backups created:"
echo "• /boot/armbianEnv.txt.backup"
echo "• $RETROARCH_CONFIG.backup (if existed)"
echo "• $N64_RETROARCH_CONFIG.backup (if existed)"
echo ""
echo "To verify after reboot:"
echo "cat /sys/devices/platform/soc/1c40000.gpu/devfreq/1c40000.gpu/governor"
echo "dmesg | grep cma"