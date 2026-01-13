# Poker-MCCFRM Configuration Guide

## Quick Configuration Reference

All main configuration is in `/home/user/Poker-MCCFRM/Poker-MCCFRM/Global.cs`

## Configuration Profiles

### Profile 1: Fast Testing (Minimal RAM ~4-8GB)
**Use case:** Quick testing, learning how the code works, limited hardware

```csharp
// Global.cs settings
public const int NOF_THREADS = 4;

public const int nofRiverBuckets = 50;
public const int nofTurnBuckets = 50;
public const int nofFlopBuckets = 50;

public const int nofOpponentClusters = 8;  // Reduced from 16
public const int flopHistogramSize = 20;   // Reduced from 50
public const int turnHistogramSize = 20;   // Reduced from 50
public const int nofMCSimsPerPreflopHand = 100;  // Reduced from 500
```

**Expected time:**
- Information abstraction: 30-90 minutes
- Training iteration speed: Fast

**Quality:** Low (suitable for testing only)

---

### Profile 2: Balanced (Moderate RAM ~16-32GB)
**Use case:** Development, experimentation, decent results

```csharp
// Global.cs settings
public const int NOF_THREADS = 8;  // Adjust to your CPU

public const int nofRiverBuckets = 200;
public const int nofTurnBuckets = 200;
public const int nofFlopBuckets = 200;

public const int nofOpponentClusters = 16;
public const int flopHistogramSize = 50;
public const int turnHistogramSize = 50;
public const int nofMCSimsPerPreflopHand = 500;
```

**Expected time:**
- Information abstraction: 2-6 hours
- Training iteration speed: Moderate

**Quality:** Medium (good for learning and experimentation)

---

### Profile 3: High Quality (High RAM ~64GB+)
**Use case:** Research, competitive play, publication-quality results

```csharp
// Global.cs settings (DEFAULT)
public const int NOF_THREADS = 12;  // Or more if available

public const int nofRiverBuckets = 1000;
public const int nofTurnBuckets = 1000;
public const int nofFlopBuckets = 1000;

public const int nofOpponentClusters = 16;
public const int flopHistogramSize = 50;
public const int turnHistogramSize = 50;
public const int nofMCSimsPerPreflopHand = 500;
```

**Expected time:**
- Information abstraction: 6-24 hours
- Training iteration speed: Slower (more infosets)

**Quality:** High (close to research-paper quality)

---

### Profile 4: Maximum Quality (Very High RAM ~128GB+)
**Use case:** Reproducing research results, maximum quality

```csharp
// Global.cs settings
public const int NOF_THREADS = 16;  // Or maximum available

public const int nofRiverBuckets = 2000;
public const int nofTurnBuckets = 2000;
public const int nofFlopBuckets = 2000;

public const int nofOpponentClusters = 32;  // Increased
public const int flopHistogramSize = 100;   // Increased
public const int turnHistogramSize = 100;   // Increased
public const int nofMCSimsPerPreflopHand = 1000;  // Increased
```

**Expected time:**
- Information abstraction: 1-3 days
- Training iteration speed: Very slow

**Quality:** Maximum (research-grade results)

---

## Game Configuration

### Standard Heads-Up No-Limit Hold'em (Default)
```csharp
public static List<float> raises = new List<float>() { 1f, 1.5f, 2.0f };
public const int buyIn = 200;
public const int nofPlayers = 2;
public const int BB = 2;
public const int SB = 1;
```

### Tournament Style (Shorter stacks)
```csharp
public static List<float> raises = new List<float>() { 1f, 1.5f, 2.0f };
public const int buyIn = 50;   // 25 big blinds
public const int nofPlayers = 2;
public const int BB = 2;
public const int SB = 1;
```

### Deep Stack Cash Game
```csharp
public static List<float> raises = new List<float>() { 1f, 1.5f, 2.0f, 3.0f };
public const int buyIn = 500;  // 250 big blinds
public const int nofPlayers = 2;
public const int BB = 2;
public const int SB = 1;
```

### Different Raise Sizes (More Actions)
```csharp
// More actions = exponentially more infosets = much more RAM needed
public static List<float> raises = new List<float>() { 0.5f, 1f, 2.0f, 3.0f };
```

**⚠️ Warning:** Adding more raise sizes dramatically increases memory usage!

---

## Thread Configuration

### Setting Optimal Thread Count

```bash
# Check your CPU core count
nproc

# For physical cores (without hyperthreading)
lscpu | grep "^CPU(s):"

# For threads per core
lscpu | grep "Thread(s) per core:"
```

**Recommended:**
- Use physical core count (not including hyperthreading)
- Or use `nproc - 2` to leave cores for system
- Example: 8-core CPU → set `NOF_THREADS = 6` or `8`

---

## Memory Estimation

Rough memory usage formula (very approximate):

```
RAM (GB) ≈ (nofFlopBuckets + nofTurnBuckets + nofRiverBuckets) * 0.02 * nofPlayers^2
          + (histogram generation phase)
          + (training infosets)
```

### Actual Usage Examples:
- **50/50/50 buckets:** ~4-8 GB during training
- **200/200/200 buckets:** ~12-24 GB during training
- **1000/1000/1000 buckets:** ~48-96 GB during training
- **2000/2000/2000 buckets:** ~120-200 GB during training

**Note:** Peak usage occurs during k-means clustering of river histograms.

---

## Training Parameters

Located in `Program.cs` (around line 64):

```csharp
// These values are divided by NOF_THREADS, so scale with thread count
long StrategyInterval = Math.Max(1, 1000 / Global.NOF_THREADS);
long PruneThreshold = 20000000 / Global.NOF_THREADS;
long LCFRThreshold = 20000000 / Global.NOF_THREADS;
long DiscountInterval = 1000000 / Global.NOF_THREADS;
long SaveToDiskInterval = 1000000 / Global.NOF_THREADS;
long testGamesInterval = 100000 / Global.NOF_THREADS;
```

### Adjust Save Frequency
To save more frequently (in case of crashes):
```csharp
long SaveToDiskInterval = 500000 / Global.NOF_THREADS;  // Save every 500k iterations
```

### Adjust Test Game Display
To see progress more often:
```csharp
long testGamesInterval = 50000 / Global.NOF_THREADS;  // Show every 50k iterations
```

---

## Applying Configuration Changes

After editing `Global.cs` or `Program.cs`:

```bash
# Rebuild the project
cd /home/user/Poker-MCCFRM
dotnet build Poker-MCCFRM.sln --configuration Release

# If changing bucket sizes, DELETE old abstraction files
# (Otherwise it will load old abstractions with wrong sizes)
rm -f *.dat
rm -f nodeMap*

# Run with new configuration
dotnet run --project Poker-MCCFRM/Poker-MCCFRM.csproj --configuration Release --no-build
```

---

## Checking Current Configuration

```bash
# View current settings
grep "const int NOF_THREADS" Poker-MCCFRM/Global.cs
grep "const int nofRiverBuckets" Poker-MCCFRM/Global.cs
grep "const int nofTurnBuckets" Poker-MCCFRM/Global.cs
grep "const int nofFlopBuckets" Poker-MCCFRM/Global.cs
```

---

## Common Issues

### "Out of Memory" Error
- Reduce bucket counts
- Reduce thread count
- Add swap space
- Close other applications

### Very Slow Histogram Generation
- Reduce `nofMCSimsPerPreflopHand`
- Reduce `nofOpponentClusters`
- Reduce histogram sizes

### K-means Clustering Stuck/Slow
- Reduce bucket counts (especially river)
- Be patient - river clustering with 1000 buckets can take 1-2 hours
- Watch CPU usage to confirm it's working

---

## Recommended Starting Point

For your first run, use **Profile 2 (Balanced)** with adjustments:

1. Check your system:
   ```bash
   free -h  # Check RAM
   nproc    # Check CPU cores
   ```

2. Edit `Poker-MCCFRM/Global.cs`:
   - Set `NOF_THREADS` to your core count minus 2
   - Start with 200/200/200 buckets if you have 16GB+ RAM
   - Start with 50/50/50 buckets if you have less than 16GB RAM

3. Build and run:
   ```bash
   ./quick-start.sh
   ```

4. Monitor first run:
   - Watch memory usage with `htop`
   - First run will calculate abstractions (hours)
   - Subsequent runs load saved abstractions (seconds)

5. Let it train:
   - Training improves with more iterations
   - Meaningful strategies emerge after 10-50 million iterations
   - Can take days/weeks for full training
