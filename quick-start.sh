#!/bin/bash

# Poker-MCCFRM Quick Start Script for Ubuntu
# This script automates the setup and running of the poker bot

set -e  # Exit on error

echo "=========================================="
echo "Poker-MCCFRM Quick Start Setup"
echo "=========================================="
echo ""

# Check if .NET is installed
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK is not installed"
    echo ""
    echo "Installing .NET SDK 8.0..."
    echo ""

    # Detect Ubuntu version
    UBUNTU_VERSION=$(lsb_release -rs)

    # Download and install Microsoft package repository
    wget -q https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    # Update and install .NET SDK
    sudo apt-get update
    sudo apt-get install -y dotnet-sdk-8.0

    echo ""
    echo "✓ .NET SDK installed successfully"
else
    echo "✓ .NET SDK is already installed"
    dotnet --version
fi

echo ""
echo "=========================================="
echo "Building Project"
echo "=========================================="
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Restore dependencies
echo "Restoring NuGet packages..."
dotnet restore Poker-MCCFRM.sln

echo ""
echo "Building in Release mode (optimized)..."
dotnet build Poker-MCCFRM.sln --configuration Release

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "System Information:"
echo "  - CPU Cores: $(nproc)"
echo "  - Total RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "  - Available RAM: $(free -h | awk '/^Mem:/ {print $7}')"
echo ""
echo "Configuration Notes:"
echo "  - Current thread count in Global.cs: 12"
echo "  - Current bucket configuration: 1000/1000/1000"
echo "  - Edit Poker-MCCFRM/Global.cs to adjust settings"
echo ""
echo "=========================================="
echo "Starting Poker Bot..."
echo "=========================================="
echo ""
echo "IMPORTANT: The first run will take HOURS to calculate"
echo "information abstractions. Subsequent runs will be faster."
echo ""
echo "Press Ctrl+C to stop at any time. Progress is saved periodically."
echo ""
read -p "Press Enter to start, or Ctrl+C to cancel..."
echo ""

# Run the application
dotnet run --project Poker-MCCFRM/Poker-MCCFRM.csproj --configuration Release --no-build
