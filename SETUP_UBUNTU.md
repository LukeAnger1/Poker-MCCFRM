# Poker-MCCFRM Setup Guide for Ubuntu

## Overview
This is a Monte Carlo Counterfactual Regret Minimization (MCCFRM) poker bot written in C# targeting .NET Core 3.0. It can train AI agents to play No-Limit Texas Hold'em poker.

## System Requirements

### Hardware
- **RAM**: Minimum 16GB recommended, ideally 64GB+ for larger abstractions
  - The default configuration uses 1000 buckets for flop/turn/river which is memory-intensive
  - Training creates millions of infosets (information sets) that are stored in memory
- **CPU**: Multi-core processor recommended (default configuration uses 12 threads)
- **Storage**: Several GB for training data and saved models

### Software
- Ubuntu 18.04+ (or any Linux distribution)
- .NET SDK 3.0 or higher (3.1 or .NET 6+ will work due to backward compatibility)

## Installation Steps

### 1. Install .NET SDK

#### Option A: Install .NET 8.0 (Latest LTS - Recommended)
```bash
# Download Microsoft package repository configuration
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

# Install the repository configuration
sudo dpkg -i packages-microsoft-prod.deb

# Clean up
rm packages-microsoft-prod.deb

# Update package list
sudo apt-get update

# Install .NET SDK
sudo apt-get install -y dotnet-sdk-8.0
```

#### Option B: Install .NET 6.0 (LTS)
```bash
sudo apt-get update
sudo apt-get install -y dotnet-sdk-6.0
```

#### Verify Installation
```bash
dotnet --version
# Should output something like 8.0.x or 6.0.x
```

### 2. Navigate to Project Directory
```bash
cd /home/user/Poker-MCCFRM
```

### 3. Update Project to .NET 8.0 (If Not Already Done)

The project originally targeted .NET Core 3.0 (out of support). It has been updated to .NET 8.0.

If you cloned an older version, verify the project file:
```bash
grep "TargetFramework" Poker-MCCFRM/Poker-MCCFRM.csproj
```

Should show: `<TargetFramework>net8.0</TargetFramework>`

If it shows `net8.0`, edit the file and change line 5 from:
```xml
<TargetFramework>net8.0</TargetFramework>
```
to:
```xml
<TargetFramework>net8.0</TargetFramework>
```

### 4. Restore NuGet Dependencies
```bash
dotnet restore Poker-MCCFRM.sln
```

This will download:
- **Combinatorics** (v1.1.0.19) - For generating card combinations
- **Microsoft.FASTER** (v2019.11.18.1) - High-performance key-value store

### 5. Build the Project

#### Debug Build (includes debugging symbols)
```bash
dotnet build Poker-MCCFRM.sln --configuration Debug
```

#### Release Build (optimized for performance - RECOMMENDED)
```bash
dotnet build Poker-MCCFRM.sln --configuration Release
```

The compiled executable will be located at:
- Debug: `Poker-MCCFRM/bin/Debug/net8.0/Poker-MCCFRM.dll`
- Release: `Poker-MCCFRM/bin/Release/net8.0/Poker-MCCFRM.dll`

## Running the Application

### Run Directly (Debug)
```bash
dotnet run --project Poker-MCCFRM/Poker-MCCFRM.csproj
```

### Run Compiled Executable (Release - Faster)
```bash
dotnet Poker-MCCFRM/bin/Release/net8.0/Poker-MCCFRM.dll
```

### Run with Performance Optimizations
```bash
# Use release build with tiered compilation disabled for maximum performance
dotnet run --project Poker-MCCFRM/Poker-MCCFRM.csproj --configuration Release --no-build
```

## What the Program Does

When you run the application, it will execute three main phases:

### Phase 1: Hand Indexing (~1-2 seconds)
Creates suit-isomorphic hand indices for various card combinations:
- 2 cards (169 non-isomorphic hands)
- 2 + 3 cards (flop)
- 2 + 4 cards (turn)
- 2 + 5 cards (river)

Example output:
```
Creating 2 card index... 169 non-isomorphic hands found
Creating 2 & 3 card index... 1755 non-isomorphic hands found
...
```

### Phase 2: Information Abstraction Calculation (HOURS to DAYS)
Generates clustering tables for card abstractions:
- **OCHS (Opponent Cluster Hand Strength)**: Clusters 169 preflop hands into 16 opponent clusters
- **River histograms**: Calculates equity distributions for all river hands
- **Turn/Flop histograms**: Creates equity distributions for turn and flop
- **K-means clustering**: Groups similar hands into buckets (1000 each for river/turn/flop)

**This is the most time-consuming step** and may take:
- Several hours on a fast multi-core system
- Multiple days on slower hardware
- Results are saved to disk and reused on subsequent runs

### Phase 3: Training (ONGOING)
Runs Monte Carlo CFR training:
- Plays poker hands against itself
- Updates strategy based on regret minimization
- Periodically saves progress to disk
- Prints statistics and sample games every 100,000 iterations

Training metrics shown:
- Number of training steps completed
- Number of infosets visited
- Starting hand action probabilities
- Sample self-play games

## Configuration

Edit `/home/user/Poker-MCCFRM/Poker-MCCFRM/Global.cs` to adjust:

```csharp
// Hardware
public const int NOF_THREADS = 12;  // Adjust to your CPU core count

// Game parameters
public static List<float> raises = new List<float>() { 1f, 1.5f, 2.0f };
public const int buyIn = 200;       // Starting chips
public const int nofPlayers = 2;    // Only 2-player is tested
public const int BB = 2;            // Big blind
public const int SB = 1;            // Small blind

// Information abstraction (reduce for less RAM usage)
public const int nofRiverBuckets = 1000;  // Reduce to 200 for less RAM
public const int nofTurnBuckets = 1000;   // Reduce to 200 for less RAM
public const int nofFlopBuckets = 1000;   // Reduce to 200 for less RAM
```

### Recommended Settings for Limited RAM (< 32GB)
```csharp
public const int nofRiverBuckets = 200;
public const int nofTurnBuckets = 200;
public const int nofFlopBuckets = 200;
```

## Saved Files

The application creates several files in the working directory:
- `nodeMap` / `nodeMapBaseline` - Strategy/regret tables (binary format)
- `preflop_OCHS_clusters_*.dat` - Preflop opponent clusters
- `river_histograms_*.dat` - River equity histograms
- `turn_histograms_*.dat` - Turn equity histograms
- `flop_histograms_*.dat` - Flop equity histograms
- Various clustering result files

These files are reused on subsequent runs to skip recalculation.

## Stopping and Resuming

- Press `Ctrl+C` to stop training
- Training progress is saved periodically (every ~1 million iterations)
- Restart the program to resume from last save point
- Information abstraction tables are saved permanently and won't be recalculated

## Expected Timeline

### First Run (Cold Start)
1. Hand indexing: ~1-2 seconds
2. OCHS preflop clustering: ~5-30 minutes
3. River histogram generation: ~1-6 hours (depends on CPU)
4. River k-means clustering: ~30 minutes - 2 hours
5. Turn histogram generation: ~30 minutes - 2 hours
6. Turn clustering: ~15-60 minutes
7. Flop histogram generation: ~10-30 minutes
8. Flop clustering: ~10-30 minutes
9. Training begins (ongoing)

### Subsequent Runs
1. Hand indexing: ~1-2 seconds
2. Load saved abstractions: ~1-10 seconds
3. Training resumes: ongoing

## Troubleshooting

### Out of Memory Errors
Reduce bucket counts in `Global.cs` or increase system swap space:
```bash
# Add 16GB swap file
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Slow Performance
1. Use Release build instead of Debug
2. Reduce `NOF_THREADS` if CPU is oversubscribed
3. Ensure no other memory-intensive applications are running
4. Check if system is swapping (use `htop` or `free -h`)

### File Permission Errors
Ensure the working directory is writable:
```bash
chmod -R u+w /home/user/Poker-MCCFRM
```

### Build Errors
Clean and rebuild:
```bash
dotnet clean Poker-MCCFRM.sln
dotnet restore Poker-MCCFRM.sln
dotnet build Poker-MCCFRM.sln --configuration Release
```

## Performance Monitoring

Monitor system resources while running:
```bash
# Install htop if not available
sudo apt-get install htop

# Monitor CPU, RAM, and threads
htop

# Watch memory usage
watch -n 1 free -h

# Monitor specific process
top -p $(pgrep -f Poker-MCCFRM)
```

## Notes

- This is the **C# version** marked as "Discontinued" in the README
- A C++ version exists with better performance but requires more complex setup
- The C# version works fine for learning and experimentation
- Training for millions of iterations may take days/weeks
- Meaningful results start appearing after ~10-50 million training iterations
- The bot learns optimal strategies through self-play
