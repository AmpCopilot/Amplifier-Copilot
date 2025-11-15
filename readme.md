# Amplifier-Copilot

<p align="center">
  <img src="Pic_for_readme/Main_GUI.png" alt="Amplifier-Copilot Main GUI" width="500"/>
</p>

**An open-source MATLAB-based tool designed to assist analog IC design engineers in rapidly selecting and designing amplifiers.** It has a proven track record with successful tape-outs.

---

## Features

- ✨ **Free & Open-Source**: Built with MATLAB, completely open-source and free to use.
- 🔬 Supports **T22 (0.9V & 1.8V) and T180 (1.8V & 5V)** technologies.
- 📚 **22** distinct amplifier topologies, over **2800** netlists with varying device sizes. Covers a vast design space, from **20-170 dB gain and 100 kHz to 10 GHz bandwidth**.
- 🎯 Evaluates designs across **5 PVT** (Process, Voltage, Temperature) corners. Considers **13** key performance metrics.

---

## Table of Contents

- [Amplifier-Copilot](#amplifier-copilot)
  - [Features](#features)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
    - [Installation](#installation)
    - [Usage](#usage)
  - [Compatibility](#compatibility)
  - [Development Guide](#development-guide)
    - [Code Structure](#code-structure)
    - [Database Structure](#database-structure)
    - [Customization](#customization)
  - [Requesting New Features](#requesting-new-features)
  - [License](#license)
  - [Contact](#contact)

---

## Quick Start

### Installation

**Step 1: Download the Code**

You can either clone this repository or download the source code as a ZIP file.

![Startup](Pic_for_readme/Startup.png)

**Step 2: Install MATLAB**

- A base MATLAB installation is sufficient. No additional toolboxes are required.
- University users may be able to install a licensed version through their institution's IT department or information center.

### Usage

**Step 1: Unzip and Run**

- Unzip the downloaded file and open `./SRC/main.m` in MATLAB.
- Run the script and check the MATLAB Command Window for any output messages.

<p align="center">
  <img src="Pic_for_readme/Startup_2.png" alt="Unzip and Run" width="400"/>
</p>

**Step 2: Input Your Requirements**

1.  **Topology Selection**: The topology selection box defaults to all selected; no action is needed unless you want to narrow the search.
2.  **Process & VDD**: Select the desired process technology and supply voltage (VDD).
3.  **Load Capacitance**: Choose the load capacitance (CL).
4.  **Select a Design**: Click the "Search" (or equivalent) button, then select a point on the resulting scatter plot that meets your needs.

<p align="center">
  <img src="Pic_for_readme/Startup_3.png" alt="Input Requirements" width="400"/>
</p>

**Step 3: Get the Results**

After selecting a point, you can:
1.  View the amplifier's schematic and simulation results.
2.  Export the corresponding netlist for further use.
<p align="center">
  <img src="Pic_for_readme/Startup_4.png" alt="View Results" width="400"/>
</p>

---

## Compatibility

We have confirmed that Amplifier-Copilot runs on the following environments:

- [x] **Windows 11 (x64)**
  - [x] MATLAB R2023b
  - [x] MATLAB R2025a (Pre-release)
- [x] **macOS 13 (x64)**
  - [x] MATLAB R2025a (Pre-release)

We are continuously testing on more environments and will update this list accordingly. If you successfully run it on a different setup, please let us know!

## Development Guide

The Amplifier-Copilot team welcomes developers to contribute, build upon this project, and create more interesting applications.

### Code Structure

Here is an overview of the source code organization:

<p align="center">
  <img src="Pic_for_readme/SRC_guide.png" alt="Source Code Structure" width="400"/>
</p>

### Database Structure

The database is structured as follows to store topology and performance data:

<p align="center">
  <img src="Pic_for_readme/DB_guide.png" alt="Database  Structure" width="400"/>
</p>

### Customization

You can easily customize key settings in `Amplifier_Copilot.m`.

**Modifying the DB Location and Scatter Plot Axes:**
The file `Amplifier_Copilot.m` contains the GUI definitions and callback functions for each element. You can modify the database location and the x/y axes of the performance scatter plot at the beginning of this file.

![Main Function Customization](Pic_for_readme/Main_func.png)

## Requesting New Features

The database is continuously being updated. If you require additional topologies, process technologies, or other features, please **[open an issue](https://github.com/AmpCopilot/Amplifier-Copilot/issues/new)** and provide detailed information.

## License

This project is open-source and licensed under the [MIT License](LICENSE).

## Contact

For questions, collaborations, or support, please open an issue in this repository or contact [Amp-Copilot_Team/230238418@seu.edu.cn] directly.
