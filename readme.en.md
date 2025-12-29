# Amplifier-Copilot

<div align="center">
  <img src="Pic_for_readme/LOGO.png" alt="Amplifier-Copilot Logo" width=700"/>
  
  
  ### 🚀 An MATLAB Tool for Analog IC Amplifier Design
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![MATLAB](https://img.shields.io/badge/MATLAB-R2023b+-orange.svg)](https://www.mathworks.com/products/matlab.html)
  [![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-lightgrey.svg)]()
  
  **Open-source • Production-Ready • Tape-out Proven**
  
  [Quick Start](#-quick-start) • [Features](#-features) • [Documentation](#-development-guide) • [Contributing](#-requesting-new-features)

  • Readme in zh_CN [点击跳转到简体中文](./README.zh-CN.md)
  <br>
  
  <img src="Pic_for_readme/Main_GUI.png" alt="Amplifier-Copilot Main GUI" width="600"/>
  
</div>

---

## 📋 Table of Contents

- [Amplifier-Copilot](#amplifier-copilot)
  - [📋 Table of Contents](#-table-of-contents)
  - [✨ Features](#-features)
  - [🚀 Quick Start](#-quick-start)
  - [💻 Compatibility](#-compatibility)
  - [🔧 Development Guide](#-development-guide)
  - [💡 Requesting New Features](#-requesting-new-features)
  - [📄 License](#-license)
  - [📬 Contact](#-contact)
  - [📚 Related Publications](#-related-publications)
---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 Comprehensive Design Space
- **22** distinct amplifier topologies
- **4000+** pre-characterized netlists
- Coverage from **20-170 dB** gain
- Bandwidth range: **100 kHz - 10 GHz**

</td>
<td width="50%">

### 🔬 Process Support
- **T22nn** VDD:(0.9V&1.8V)
- **T40nm [New]** VDD:(0.9V&2.5V)
- **T65nm [New]** VDD:(1.2V&3.3V)
- **T180nm** VDD:(1.8V&5V)

</td>
</tr>
<tr>
<td width="50%">

### 🆓 Open & Accessible
- Completely **free and open-source**
- Built with **MATLAB** 
- No additional toolboxes required
- Link to Cadence design flow

</td>
<td width="50%">

### ✅ Production Ready
- **Tape-out proven** designs
- **5 PVT corners** validation
- **13** performance metrics evaluation
- Export-ready netlists

</td>
</tr>
</table>

---
<details open>
<summary><b>📅 Update Log & Release Notes</b></summary>
<br>

### 🎄 v2025.12.24 - Christmas Eve Special Release

- **Expanded Database Coverage**  
  Added support for **40nm and 65nm process nodes**, bringing total database size to **4,000+ design points**

- **Enhanced Visualization Quality**  
  Performance plots are no longer compressed based on user feedback

- **Schematic Updates & Data Cleanup**  
  Removed legacy data for **NMCNR, NMCF, and DFCFC1** topologies due to schematic refinements

- **🔜 Coming Soon (Next Week)**  
  Adding **Rail-to-Rail, Class-AB** operational amplifier topologies

</details>


## 🚀 Quick Start

We provide both video and text-based user guides to help you get started quickly:

**🎬 Video Tutorial:** [`Pic_for_readme/Copilot_Video_UG.mp4`](Pic_for_readme/Copilot_Video_UG.mp4)

**📖 Text Guide:** See detailed step-by-step instructions below
### 📥 Installation

<details open>
<summary><b>Step 1: Get the Code</b></summary>

<br>

Clone the repository or download as ZIP:

```bash
git clone https://github.com/AmpCopilot/Amplifier-Copilot.git
```

<p align="center">
  <img src="Pic_for_readme/Startup.png" alt="Download Options" width="500"/>
</p>

</details>

<details open>
<summary><b>Step 2: Install MATLAB</b></summary>

<br>

- **Minimum requirement**: Base MATLAB installation (no toolboxes needed)
- **Recommended version**: R2023b or later
- **For students**: Check with your university's IT department for free licenses

</details>

### 🎮 Usage

<details open>
<summary><b>Step 1: Launch the Application</b></summary>

<br>

1. Navigate to the project directory
2. Open `./SRC/main.m` in MATLAB
3. Run the script and monitor the Command Window

<p align="center">
  <img src="Pic_for_readme/Startup_2.png" alt="Launch Application" width="450"/>
</p>

</details>

<details open>
<summary><b>Step 2: Define Your Requirements</b></summary>

<br>

Configure your design specifications:

1. **Topology**: All topologies selected by default (customize if needed)
2. **Process & VDD**: Choose technology node and supply voltage
3. **Load Capacitance (CL)**: Select target load
4. **Search**: Click search and select optimal design from scatter plot

<p align="center">
  <img src="Pic_for_readme/Startup_3.png" alt="Configure Requirements" width="450"/>
</p>

</details>

<details open>
<summary><b>Step 3: Analyze Results</b></summary>

<br>

After selection, you can:

- 📊 **View**: Schematic diagrams and simulation results
- 📤 **Export**: Netlists and raw data
- 📈 **Compare**: Performance across PVT corners

<p align="center">
  <img src="Pic_for_readme/Startup_4.png" alt="View Results" width="450"/>
</p>

</details>

<details open>
<summary><b>Step 4: Import to Cadence Virtuoso</b></summary>

<br>

Automatically load exported netlist's parameters into **Virtuoso Cadence ADE L** using our helper script:

**4.1. Setup Script Directory**

Copy the `./Read_scs_Script` directory to your Virtuoso run directory.

**4.2. Prepare Virtuoso Environment**

1. Import `Cadence_Lib/TSMC22ULL_Std_AMP_LIB` into your Virtuoso Library Manager
2. Open any TB cell's `spectre_state` view
3. Launch **only one ADE L window** 

**4.3. Prepare Netlist File**

1. Place the `.scs` netlist exported from Amplifier Copilot into `Read_scs_Script/input_scs/`
2. Rename it to `1.scs`

**4.4. Execute Import Script**

In the **CIW (Command Interpreter Window)**, enter the following commands:

```skill
load("./Read_scs_Script/script/extractNetlistParams.il")
lnp("./Read_scs_Script/input_scs/1.scs")
```

<p align="center">
<img src="Pic_for_readme/Read_param_script.png" alt="Execute Import Script" width="500"/>
</p>

**4.5. Verify Parameters**

All parameters will be automatically rounded and loaded into **Design Variables**:

<p align="center">
<img src="Pic_for_readme/Read_param_script_2.png" alt="Imported Design Variables" width="500"/>
</p>


</details>


## 💻 Compatibility

### ✅ Tested Environments

| Platform | MATLAB Version | Status |
|----------|---------------|---------|
| 🪟 **Windows 11 (x64)** | R2023b | ✅ Verified |
| 🪟 **Windows 11 (x64)** | R2025a (Pre-release) | ✅ Verified |
| 🍎 **macOS 13 (x64)** | R2025a (Pre-release) | ✅ Verified |

**If text is obscured or buttons appear outside the screen, drag the window edges to resize the UI.**

> 💡 **Running on a different setup?** Let us know! We're continuously expanding our compatibility testing.

---

### 🔬 Process Node & Device Library Mapping

Our database uses the following device models for each process/voltage configuration:
<table>
<thead>
  <tr>
    <th>Process Node</th>
    <th>Supply Voltage</th>
    <th>NMOS Device</th>
    <th>PMOS Device</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="2">✅ <b>22nm</b></td>
    <td>0.9V</td>
    <td><code>nch_ulvt_mac</code></td>
    <td><code>pch_ulvt_mac</code></td>
  </tr>
  <tr>
    <td>1.8V</td>
    <td><code>nch_18_mac</code></td>
    <td><code>pch_18_mac</code></td>
  </tr>
  <tr>
    <td rowspan="2">✅ <b>40nm</b></td>
    <td>0.9V</td>
    <td><code>nch_elvt_mac</code></td>
    <td><code>pch_elvt_mac</code></td>
  </tr>
  <tr>
    <td>2.5V</td>
    <td><code>nch_25_mac</code></td>
    <td><code>pch_25_mac</code></td>
  </tr>
  <tr>
    <td rowspan="2">✅ <b>65nm</b></td>
    <td>1.2V</td>
    <td><code>nch_mac</code></td>
    <td><code>pch_mac</code></td>
  </tr>
  <tr>
    <td>3.3V</td>
    <td><code>nch_33_mac</code></td>
    <td><code>pch_33_mac</code></td>
  </tr>
  <tr>
    <td rowspan="2">✅ <b>180nm</b></td>
    <td>1.8V</td>
    <td><code>nch_mac</code></td>
    <td><code>pch_mac</code></td>
  </tr>
  <tr>
    <td>5V</td>
    <td><code>nch5_lvt_gb</code></td>
    <td><code>pch5_lvt_mac</code></td>
  </tr>
</tbody>
</table>


## 🔧 Development Guide


<details open>
<summary><b>🗂️Source Code Organization</b></summary>

<br>

| **File** | **Function** | **Description** |
|---------|-------------|-----------------|
| **`main.m`** | Main function | Entry point - launches the GUI |
| **`Amplifier_Copilot.m`** | Graphic user interface | Main GUI implementation |
| **`Get_Perf_Table.m`** | Database query | Retrieves performance table from database |
| **`Get_Size_TBM_Figure.m`** | Database query | Retrieves sizing table from database |
| **`Plot_Perf_Table.m`** | Visualization | Plots performance scatter diagrams |
| **`range.m`** | Utility function | Helper function for data processing |
| **`Show_Schematic_With_Values.m`** | Schematic display | Shows interactive schematic with component values |
| **`Startup_UG_1.png`** | Startup guide (Page 1) | First page of quick start guide |
| **`Startup_UG_2.png`** | Startup guide (Page 2) | Second page of quick start guide |

</details>

---

<details open>
<summary><b>📊Database Architecture</b></summary>

<br>

| **Folder/File** | **Description** | **Contents** |
|----------------|-----------------|--------------|
| **`[Topology_Name]`** | Root folder for each topology | Contains all configurations for this topology |
| **`[Topo]-[Tech]-[VDD]-[VCM]-[CL]`** | Configuration-specific folder | Format: `Tech_VDD_VCM_CL` <br> e.g., `180-1.8-0.9-800` |
| **`Netlist_and_Figure/`** | Circuit files | SPICE netlists and performance plots |
| **`Perf_and_Size_Table/`** | Performance data | Design space exploration results |
| **`all_combined_data.csv`** | Combined database | Performance metrics + device sizing table |
| **`GUI_data/`** | GUI resources | Schematic and component information |
| **`[Topology_Name].png`** | Schematic diagram | Circuit topology visualization |
| **`Label_data.csv`** | Component locations | Coordinates for interactive schematic display |

Our database structure efficiently stores topology information, device sizing, and performance characteristics across multiple PVT corners.

</details>

---
<details open>
<summary><b>⚙️Modifying Database Location & Visualization</b></summary>

<br>

Edit `Amplifier_Copilot.m` to customize:

- **Database path**: Change the location of topology and performance data
- **Scatter plot axes**: Modify x/y axis parameters for visualization
- **GUI callbacks**: Customize user interaction behavior

<p align="center">
  <img src="Pic_for_readme/Main_func.png" alt="Customization Options" width="500"/>
</p>

</details>

<details open>
<summary><b>🔬 Cadence Library Information  &  Testbench Design</b></summary>

<br>

- **Process:** TSMC 22nm standard library (attachable to similar TSMC standard PDKs)
- **Organization:** Circuits are categorized into three groups:
  - `Circuits` - Amplifier topologies
  - `Basic_TB` - Basic testbenches
  - `Tran_TB` - Transient analysis testbenches
- **Tip:** Enable **"Show categories"** in Cadence Library Manager to view the organized structure

The basic testbench instantiates three amplifier copies, each configured for a specific measurement. Both schematic and Spectre netlist can be found in **Cadence_Lib/TSMC22ULL_Std_AMP_LIB** (TB_* naming convention).

<p align="center">
<img src="Pic_for_readme/TB_Overview.png" alt="TB Overview" width="650"/>
</p>


Simulations are controlled via the ADE setup shown below:

<p align="center">
<img src="Pic_for_readme/TB_ADE.png" alt="ADE Settings" width="550"/>
</p>

---

### 📈 Measurement Circuits

| Circuit | Purpose | Configuration | Simulation Type |
|---------|---------|---------------|-----------------|
| **#1: Bode** | Gain & Phase Margin | Unity-gain feedback, loop broken with `iprobe` | STB Analysis |
| **#2: CMRR** | Common-Mode Rejection | Common-mode input stimulus | AC Analysis |
| **#3: PSRR** | Supply Rejection | AC noise on VDD/VSS | AC Analysis |

<table>
<tr>
<td width="33%">
<p align="center"><b>Bode Plot Extraction</b></p>
<img src="Pic_for_readme/TB_Bode.png" alt="Bode TB"/>
<p align="center"><i>STB simulation with loop break</i></p>
</td>
<td width="33%">
<p align="center"><b>CMRR Measurement</b></p>
<img src="Pic_for_readme/TB_CMRR.png" alt="CMRR TB"/>
<p align="center"><i>Common-mode stimulus</i></p>
</td>
<td width="33%">
<p align="center"><b>PSRR Measurement</b></p>
<img src="Pic_for_readme/TB_PSRR.png" alt="PSRR TB"/>
<p align="center"><i>Supply noise injection</i></p>
</td>
</tr>
</table>

</details>

### 📄  Command Line Simulation

The exported netlists are base on **Spectre** and can be used directly for circuit simulation after updating the library paths.

**Example Spectre simulation command:**
```bash
spectre -64 /input/TB0_ff_3.4_85_1.6.scs \
+escchars \
=log /output/spectre.out \
-format psfascii \
-raw /output/out_file0_ff_3.4_85_1.6 \
+aps \
+lqtimeout 900 \
-maxw 5 \
-maxn 5 \
-env ade
```


---

## 💡 Requesting New Features

We're continuously expanding our database and capabilities!

### 🎯 Need Additional Features?

**Request new topologies, process nodes, or features:**

1. 📝 **[Open an Issue](https://github.com/AmpCopilot/Amplifier-Copilot/issues/new)**
2. 📋 Provide detailed requirements and use cases
3. 🤝 Our team will review and prioritize your request

### 🔬 Regarding Process Node Support

We understand that many users have requested support for additional process nodes. We're addressing this through two approaches:

**Short-term (Community-Driven):**
- We will prioritize and add the most requested process nodes to our database based on community feedback
- Submit your process node requests via [GitHub Issues](https://github.com/AmpCopilot/Amplifier-Copilot/issues/new)

**Long-term (Technology Transfer):**
- Our team is developing a transistor behavior-based transfer method that will enable users to compute device sizing for new process nodes directly on their local machines
- This technology leverages transistor data from existing and target process nodes
- While promising results have been achieved in small-scale experiments, further development is needed
- This will ultimately become our primary approach for future design porting

---

### 📌 Using Existing Process Nodes as References

While we work on expanding our database, you can reference existing process nodes for similar technologies:

| **Your Target Process** | **Recommended Reference** | **Notes** |
|------------------------|---------------------------|-----------|
| **28nm** | 22nm | Tape-out proven that's negligible differences |
| **90nm** | 65nm | Comparable device behavior |
| **130nm** | 180nm| Comparable device behavior |
| **Mature nodes (>180nm)** | 180nm / 5V | Suitable for legacy process technologies |


**Note:** These references provide reasonable starting points for design exploration. For production designs, we recommend validating with your target process specifications.

## 📄 License

This project is released under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License - Free for commercial and private use
```

---

## 📬 Contact

### Get in Touch

<table>
<tr>
<td width="50%">

**🐛 Bug Reports & Issues**
<br>
[Open an Issue](https://github.com/AmpCopilot/Amplifier-Copilot/issues/new)

</td>
<td width="50%">

**📧 Direct Contact**
<br>
[230238418@seu.edu.cn](mailto:230238418@seu.edu.cn)

</td>
</tr>
</table>

---

## 📚 Related Publications

We sincerely invite developers and researchers interested in the methodologies behind Amplifier-Copilot to explore our published works. These studies represent the foundational research that powers the techniques used in this tool:


### 🔬 Core Technologies

#### Transistor Modeling & Transfer Learning
**[1] Analog Circuit Transfer Method Across Technology Nodes via Transistor Behavior**  
*H. Zhi, J. Li, Y. Li, and W. Shan*  
ASP-DAC 2025 | [Paper](https://doi.org/10.1145/3658617.3697702)

> Enables transistor-level modeling for cross-node optimization, allowing efficient design transfer across different technology nodes. Poor written and hard to understand, a more clear journal version is up-coming. 

#### Benchmark & Testing Framework
**[2] AnalogGym: An Open and Practical Testing Suite for Analog Circuit Synthesis**  
*J. Li et al.*  
ICCAD 2024 (Invited) | [Paper](https://doi.org/10.1145/3676536.3697117) | [GitHub](https://github.com/CODA-Team/AnalogGym)

> Open-source benchmark suite featuring 30 circuit topologies with Ngspice and SkyWater PDK support.

#### Behavior-Centric Optimization
**[3] Decoupling Analog Circuit Representation from Technology for Behavior-Centric Optimization**  
*J. Li, H. Zhi, J. Xiao, K. Zhu, and Y. Li*  
DAC 2025 | [Paper](https://doi.org/10.1109/DAC63849.2025.11133189)

> Introduces symbolic optimization methods based on transistor behavior, decoupling circuit design from specific technology nodes.

---

### 🎯 Advanced Analysis & Optimization

#### Multi-Stage Amplifier Analysis
**[4] Closed-Loop Pole Analysis via Output Impedance in Miller-Compensated Amplifiers**  
*H. Zhi et al.*  
IEEE TCAS-II 2025 | [Paper](https://doi.org/10.1109/TCSII.2025.3618605)

> AI-discovered analytical and intuitive methods for multi-stage amplifier pole analysis.

#### PVT-Robust Design
**[5] Knowledge Transfer Framework for PVT Robustness in Analog Integrated Circuits**  
*J. Li et al.*  
IEEE TCAS-I 2023 | [Paper](https://doi.org/10.1109/TCSI.2023.3340683)

> Improves sizing efficiency under multiple PVT (Process-Voltage-Temperature) corners.

#### Multi-Objective Optimization
**[6] Balancing Objective Optimization and Constraint Satisfaction for Robust Analog Circuit Optimization**  
*J. Li, H. Zhi, J. Xiao, Y. Zeng, W. Shan, and Y. Li*  
ASP-DAC 2025 | [Paper](https://doi.org/10.1145/3658617.3697701)

> Enhances sizing efficiency for multi-performance metrics with complex constraints.


---

<div align="center">
  
  ### 🌟 Star us on GitHub!
  
  If you find Amplifier-Copilot useful, please consider giving it a star ⭐
  
  **Made with ❤️ by the Amplifier-Copilot Team**
  
  [⬆ Back to Top](#amplifier-copilot)
  
</div>